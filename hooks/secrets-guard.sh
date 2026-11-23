#!/usr/bin/env bash
# PreToolUse guard for the secrets/ folder (project-scaffolder v4).
# Contract: secrets/ holds hand-over files with API keys. The agent may READ
# them to use the keys locally. Nothing in there may ever be published:
# not to git, not to an Artifact, not copied into wiki, docs, logs or code,
# not inlined in a shell command (commands end up in transcripts and logs),
# not sent through an MCP server, a web request or a message to another session.
#
# Best effort by design: it catches the common leaks, it is not a DLP system.
# Projects without a secrets/ folder pass through untouched.
# Fail closed: hooks.json sets onFailure "block"; lib.sh missing exits 1,
# which refuses the call. Decisions always exit 0 with valid JSON.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh" || exit 1

# secrets/ is git-ignored, so a worktree has none: then the values come from
# the checkout the session started in.
SECRETS="$PS_PROJECT/secrets"
[ -d "$SECRETS" ] || [ -z "${CLAUDE_PROJECT_DIR:-}" ] || SECRETS="$CLAUDE_PROJECT_DIR/secrets"
[ -d "$SECRETS" ] || exit 0

# Candidate secret values: the right-hand side of KEY=VALUE / KEY: VALUE /
# "key": "value" lines, plus lines that are one long bare token. Values under
# 16 characters, with spaces, or that are URLs are ignored to keep false
# positives down.
ps_secret_values() {
  find "$SECRETS" -type f ! -iname 'README.md' -size -256k 2>/dev/null \
    | while IFS= read -r f; do
        tr -d '\r' < "$f" | sed -nE \
          -e "s/^[[:space:]]*(export[[:space:]]+)?[\"']?[A-Za-z_][A-Za-z0-9_.-]*[\"']?[[:space:]]*[=:][[:space:]]*//p"
        tr -d '\r' < "$f" | grep -E '^[A-Za-z0-9_+/=.-]{20,}$'
      done \
    | sed -E -e 's/[[:space:]]+#.*$//' -e 's/[,;]+$//' -e "s/^[\"']//" -e "s/[\"']\$//" \
    | awk 'length($0) >= 16 && $0 !~ /[[:space:]]/ && $0 !~ /:\/\//' \
    | sort -u
}

# The values are read once per run (PS_VALUES, below), never once per check:
# a timeout refuses the call (onFailure "block"), and on Windows every
# process costs tens of milliseconds.
ps_has_secret() {   # stdin contains a secret value?
  [ -n "$PS_VALUES" ] && grep -qF -e "$PS_VALUES"
}

# Existing files named by any string of the tool input (an Artifact's page, its
# `files` map and `file_paths`, an upload path given to an MCP tool), one per
# line. The session's own fields are dropped first: the transcript may hold a
# value the agent read, and it is never what the tool sends. Builtins only
# inside the loop (the two substitutions are ps_fs): a publish can name
# hundreds of files.
ps_named_files() {
  printf '%s' "$INPUT" \
    | sed -E 's/"(transcript_path|agent_transcript_path|cwd|session_id)"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"//g' \
    | grep -oE '"([^"\\]|\\.)*"' | sed -e 's/^"//' -e 's/"$//' | head -n 400 \
    | while IFS= read -r s; do
        case "$s" in *[/\\.]*) ;; *) continue ;; esac
        p=${s//\\\\//}; p=${p//\\//}
        case "$p" in /*|[A-Za-z]:/*) ;; *) p="$PS_PROJECT/$p" ;; esac
        [ -f "$p" ] && printf '%s\n' "$p"
      done
}

# Outward call check: the input itself, then every file it names, in two
# batched passes whatever the number of files. $1 = what.
ps_guard_outward() {
  if printf '%s' "$INPUT" | ps_has_secret; then
    ps_deny "project-scaffolder: this $1 would send a value from secrets/ off this machine. Secret values are never published or sent anywhere except by a local command that loads them from their file."
  fi
  NAMED=()
  while IFS= read -r p; do NAMED+=("$p"); done < <(ps_named_files)
  [ "${#NAMED[@]}" -gt 0 ] || return 0
  if printf '%s\n' "${NAMED[@]}" | ps_rel_lines | grep -q '^secrets/'; then
    ps_deny "project-scaffolder: files under secrets/ are never published or sent to an online service."
  fi
  # Files of 4 MiB or more (media, archives) are not scanned, so the time stays bounded.
  SMALL=()
  while IFS= read -r p; do SMALL+=("$p"); done < <(find "${NAMED[@]}" -maxdepth 0 -type f -size -4096k 2>/dev/null)
  if [ "${#SMALL[@]}" -gt 0 ] && [ -n "$PS_VALUES" ] && grep -qsF -e "$PS_VALUES" -- "${SMALL[@]}"; then
    ps_deny "project-scaffolder: a file this $1 sends contains a value from secrets/. Remove it before publishing."
  fi
  return 0
}

PS_VALUES=$(ps_secret_values)
TOOL=$(ps_field "$INPUT" tool_name)

case "$TOOL" in
  Bash|PowerShell)
    CMD=$(ps_field "$INPUT" command)

    if printf '%s' "$CMD" | ps_has_secret; then
      ps_deny "project-scaffolder: this command contains a value from secrets/. Commands are recorded in transcripts and logs. Load the value from its file instead (for example: set -a; . secrets/<file>.env; set +a) and reference the variable."
    fi

    if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+(add|commit|push)'; then
      if git -C "$PS_PROJECT" rev-parse --git-dir >/dev/null 2>&1; then
        if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+add' \
           && printf '%s' "$CMD" | grep -qE "(^|[[:space:]/\\\\\"'])secrets([/\\\\[:space:]\"']|\$)"; then
          ps_deny "project-scaffolder: secrets/ is never added to git. It must stay local and ignored."
        fi
        if ! git -C "$PS_PROJECT" check-ignore -q secrets/.probe 2>/dev/null; then
          ps_deny "project-scaffolder: secrets/ is not covered by .gitignore. Add the line secrets/ to .gitignore before any git add, commit or push."
        fi
        TRACKED=$(git -C "$PS_PROJECT" ls-files -- secrets 2>/dev/null | head -n 1)
        STAGED=$(git -C "$PS_PROJECT" diff --cached --name-only -- secrets 2>/dev/null | head -n 1)
        if [ -n "$TRACKED$STAGED" ]; then
          ps_deny "project-scaffolder: files under secrets/ are tracked or staged. Untrack them first (git rm -r --cached secrets) and rotate any key that was already committed."
        fi
      fi
    fi

    if printf '%s' "$CMD" | grep -qE "(^|[[:space:]/\\\\\"'@=])secrets[/\\\\]" \
       && printf '%s' "$CMD" | grep -qiE '(curl|wget|scp|sftp|rsync|ftp|gh[[:space:]]+(gist|release|issue|pr)|invoke-webrequest|invoke-restmethod|iwr|irm)([[:space:]]|$)'; then
      ps_ask "project-scaffolder: this command sends something from secrets/ over the network. Approve only if the destination is the service the key belongs to."
    fi
    ;;

  Write|Edit|NotebookEdit)
    FILE=$(ps_field "$INPUT" file_path)
    [ -z "$FILE" ] && FILE=$(ps_field "$INPUT" notebook_path)
    REL=$(ps_rel "$FILE")
    case "$REL" in
      secrets/*) exit 0 ;;
      *.example|*.sample|*.template|*.dist) ;;                 # templates never get real values
      .env|.env.*|*/.env|*/.env.*) exit 0 ;;                   # local env files are where keys go
    esac
    if printf '%s' "$INPUT" | ps_has_secret; then
      ps_deny "project-scaffolder: this write would copy a value from secrets/ into another file. Reference the variable name instead; real values live only in secrets/ and in git-ignored .env files."
    fi
    ;;

  Artifact*)
    # The page, its supporting files and uploaded assets, plus database rows
    # and comments: all of it is served online.
    ps_guard_outward "publish"
    ;;

  WebFetch|WebSearch|SendMessage|SendToProject*|RemoteTrigger|PushNotification|mcp__*)
    # Everything else that leaves the machine: MCP servers (GitHub, mail, docs,
    # chat, hosting), web requests, messages to other or cloud sessions.
    ps_guard_outward "call"
    ;;
esac
exit 0
