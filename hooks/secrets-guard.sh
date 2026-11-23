#!/usr/bin/env bash
# PreToolUse guard for the secrets/ folder (project-scaffolder v4).
# Contract: secrets/ holds hand-over files with API keys. The agent may READ
# them to use the keys locally. Nothing in there may ever be published:
# not to git, not to an Artifact, not copied into wiki, docs, logs or code,
# not inlined in a shell command (commands end up in transcripts and logs).
#
# Best effort by design: it catches the common leaks, it is not a DLP system.
# Projects without a secrets/ folder pass through untouched.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh"

[ -d "$PS_PROJECT/secrets" ] || exit 0

# Candidate secret values: the right-hand side of KEY=VALUE / KEY: VALUE /
# "key": "value" lines, plus lines that are one long bare token. Values under
# 16 characters, with spaces, or that are URLs are ignored to keep false
# positives down.
ps_secret_values() {
  find "$PS_PROJECT/secrets" -type f ! -iname 'README.md' -size -256k 2>/dev/null \
    | while IFS= read -r f; do
        tr -d '\r' < "$f" | sed -nE \
          -e "s/^[[:space:]]*(export[[:space:]]+)?[\"']?[A-Za-z_][A-Za-z0-9_.-]*[\"']?[[:space:]]*[=:][[:space:]]*//p"
        tr -d '\r' < "$f" | grep -E '^[A-Za-z0-9_+/=.-]{20,}$'
      done \
    | sed -E -e 's/[[:space:]]+#.*$//' -e 's/[,;]+$//' -e "s/^[\"']//" -e "s/[\"']\$//" \
    | awk 'length($0) >= 16 && $0 !~ /[[:space:]]/ && $0 !~ /:\/\//' \
    | sort -u
}

ps_has_secret() {   # stdin contains a secret value?
  grep -qF -f <(ps_secret_values)
}

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

  Artifact)
    FILE=$(ps_field "$INPUT" file_path)
    [ -z "$FILE" ] && exit 0
    REL=$(ps_rel "$FILE")
    case "$REL" in
      secrets/*) ps_deny "project-scaffolder: files under secrets/ are never published as Artifacts." ;;
    esac
    FS=$(ps_fs "$FILE")
    if [ -f "$FS" ] && ps_has_secret < "$FS"; then
      ps_deny "project-scaffolder: the page to publish contains a value from secrets/. Remove it before publishing."
    fi
    ;;
esac
exit 0
