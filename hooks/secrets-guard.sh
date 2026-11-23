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

# Candidate secret values, one "value<TAB>label" line each; the label (file
# and variable name or line, never the value) goes into deny reasons. One awk
# process reads every file, so the cost does not grow with a process per file.
# The awk text must never hold two adjacent braces: find -exec ... + would take
# them for its file placeholder.
#   NAME=value, NAME: value, "name": "value"  -> the value, unless NAME says
#       it is an identifier (…_ID, _REF, _HOST, _USER, _EMAIL, _REGION, _URL…)
#       and holds no key word; at least 12 characters for KEY/SECRET/TOKEN/
#       PASS…-like names, 16 for any other name.
#   URLs (named or bare)  -> the password of user:pass@, and long key-like
#       path or query parts; the whole URL too when its name is key-like
#       (webhooks, DSNs). A bare URL or a hostname is never a secret itself.
#   any other text        -> key-like tokens: 20+ characters of
#       [A-Za-z0-9_+/=.~-] with a letter and a digit, not a hostname or an
#       e-mail (free text, Markdown tables, Bearer lines, minified JSON,
#       PEM and base64 lines, "\n"-joined private keys).
ps_secret_map() {
  find "$SECRETS" -type f ! -iname 'README.md' -size -256k -exec awk -v root="$SECRETS/" '
function host(s) { return s ~ /^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z][a-z]+$/ }
function mail(s) { return s ~ /^[^@]+@[^@]+\.[a-z][a-z]+$/ }
function strong(s) {
  return length(s) >= 20 && s ~ /[0-9]/ && s ~ /[A-Za-z]/ && s ~ /^[A-Za-z0-9_+\/=.~-]+$/ && !host(s) && !mail(s)
}
function emit(v, l) { if (v != "" && !(v in seen)) { seen[v] = 1; print v "\t" l } }
function urlparts(u, l,   ui, pw, n, i, p) {
  sub(/^[A-Za-z][A-Za-z0-9+.-]*:\/\//, "", u)
  if (match(u, /^[^\/@]*@/)) {
    ui = substr(u, 1, RLENGTH - 1); u = substr(u, RLENGTH + 1)
    if (index(ui, ":") > 0) { pw = substr(ui, index(ui, ":") + 1); if (length(pw) >= 8) emit(pw, l) }
  }
  n = split(u, p, /[\/?&=#:]/)
  for (i = 1; i <= n; i++) if (strong(p[i])) emit(p[i], l)
}
function tokens(t, l,   n, i, s, k) {
  gsub(/\\n/, " ", t)
  n = split(t, k, /[ \t"\047`,;{(<>)}|\[\]]+/)
  for (i = 1; i <= n; i++) {
    s = k[i]
    if (s ~ /:\/\//) { urlparts(s, l); continue }
    sub(/^[A-Za-z_][A-Za-z0-9_.-]*[=:]/, "", s)
    if (strong(s)) emit(s, l)
  }
}
{
  f = FILENAME; if (index(f, root) == 1) f = substr(f, length(root) + 1)
  line = $0; gsub(/\r/, "", line)
  if (line ~ /^[ \t]*(#|$)/) next
  if (line !~ /^[ \t]*[A-Za-z][A-Za-z0-9+.-]*:\/\// && match(line, /^[ \t]*(export[ \t]+)?["\047]?[A-Za-z_][A-Za-z0-9_.-]*["\047]?[ \t]*[=:]/)) {
    name = substr(line, 1, RLENGTH); val = substr(line, RLENGTH + 1)
    gsub(/^[ \t]*(export[ \t]+)?["\047]?|["\047]?[ \t]*[=:]$/, "", name)
    sub(/^[ \t]+/, "", val); sub(/[ \t]+#.*$/, "", val); sub(/[ \t]+$/, "", val); sub(/[,;]+$/, "", val)
    sub(/^["\047`]/, "", val); sub(/["\047`]$/, "", val)
    u = toupper(name); l = f " " name
    keyish = u ~ /KEY|SECRET|TOKEN|PASS|PWD|PRIVATE|AUTH|CRED|SIGN|DSN|SALT|COOKIE|WEBHOOK/
    ident = !keyish && u ~ /(^|_)(ID|REF|HOST|HOSTNAME|DOMAIN|PORT|REGION|ZONE|USER|USERNAME|EMAIL|NAME|ENV|MODE|VERSION|LOCALE|TZ|TIMEZONE|BUCKET|PROJECT|ORG|ACCOUNT|ENDPOINT|URL)$/
    if (val ~ /:\/\//) { urlparts(val, l); if (keyish && val !~ /[ \t]/) emit(val, l); next }
    if (ident) next
    if (val ~ /[ \t]|\\n/) { tokens(val, l); next }
    if (length(val) >= (keyish ? 12 : 16) && !host(val) && !mail(val)) emit(val, l)
    next
  }
  tokens(line, f " line " FNR)
}' {} + 2>/dev/null
}

# The values are read once per run (PS_VALUES, below), never once per check:
# a timeout refuses the call (onFailure "block"), and on Windows every
# process costs tens of milliseconds.
ps_has_secret() {   # stdin contains a secret value?
  [ -n "$PS_VALUES" ] && grep -qF -e "$PS_VALUES"
}

# Which secret a text contains, as its label (file and name), for the reason.
# Only characters that are safe inside the JSON reason are kept.
ps_secret_label() {   # $1 = text
  local hit
  hit=$(printf '%s' "$1" | grep -oF -e "$PS_VALUES" 2>/dev/null | head -n 1)
  [ -n "$hit" ] || return 0
  printf '%s\n' "$PS_MAP" | awk -F '\t' -v h="$hit" '$1 == h { print $2; exit }' | tr -cd 'A-Za-z0-9 ._:/-'
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
    ps_deny "project-scaffolder: this $1 would send a value from secrets/$(ps_where "$INPUT") off this machine. Secret values are never published or sent anywhere except by a local command that loads them from their file."
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
    ps_deny "project-scaffolder: a file this $1 sends contains a value from secrets/$(ps_where "$(cat -- "${SMALL[@]}" 2>/dev/null)"). Remove it before publishing."
  fi
  return 0
}

# " (file NAME)" for a deny reason, or nothing when the label is unknown.
ps_where() { local l; l=$(ps_secret_label "$1"); [ -n "$l" ] && printf ' (%s)' "$l"; }

PS_MAP=$(ps_secret_map)
PS_VALUES=$(printf '%s\n' "$PS_MAP" | cut -f1 | grep -v '^$')
TOOL=$(ps_field "$INPUT" tool_name)

case "$TOOL" in
  Bash|PowerShell)
    CMD=$(ps_field "$INPUT" command)

    if printf '%s' "$CMD" | ps_has_secret; then
      ps_deny "project-scaffolder: this command contains a value from secrets/$(ps_where "$CMD"). Commands are recorded in transcripts and logs. Load the value from its file instead (for example: set -a; . secrets/<file>.env; set +a) and reference the variable."
    fi

    if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+(add|commit|push)'; then
      if git -C "$PS_PROJECT" rev-parse --git-dir >/dev/null 2>&1; then
        # Only the arguments of the git add itself, up to the next ; & or |:
        # a commit message that mentions secrets is not an add of the folder.
        ADDARGS=$(printf '%s' "$CMD" | grep -oE 'git[[:space:]]+add[^;&|]*')
        if [ -n "$ADDARGS" ] \
           && printf '%s' "$ADDARGS" | grep -qE "(^|[[:space:]/\\\\\"'])secrets([/\\\\[:space:]\"']|\$)"; then
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
        # A value copied into another file: what a commit records (staged,
        # plus tracked changes with -a), and what a push sends (the tree at HEAD).
        if [ -n "$PS_VALUES" ]; then
          if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit'; then
            DIFF=$(git -C "$PS_PROJECT" diff --cached -U0 2>/dev/null | grep '^+')
            if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit[^;&|]*[[:space:]]-[a-zA-Z]*a'; then
              DIFF="$DIFF
$(git -C "$PS_PROJECT" diff -U0 2>/dev/null | grep '^+')"
            fi
            if printf '%s' "$DIFF" | ps_has_secret; then
              ps_deny "project-scaffolder: this commit would record a value from secrets/$(ps_where "$DIFF") in another file. Replace it with the variable name, then commit."
            fi
          fi
          if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+push' \
             && git -C "$PS_PROJECT" grep -q -F -f <(printf '%s\n' "$PS_VALUES") HEAD -- 2>/dev/null; then
            ps_deny "project-scaffolder: a committed file contains a value from secrets/. Remove it in a new commit (and rotate the key if it was ever pushed) before pushing."
          fi
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
      .env|.env.*|*/.env|*/.env.*)                             # local env files are where keys go,
        git -C "$PS_PROJECT" rev-parse --git-dir >/dev/null 2>&1 || exit 0   # as long as git ignores them
        git -C "$PS_PROJECT" check-ignore -q -- "$REL" 2>/dev/null && exit 0 ;;
    esac
    # The text an Edit replaces is not written: removing a leaked value is fine.
    NEW=$(printf '%s' "$INPUT" | sed -E 's/"old_string"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"//')
    if printf '%s' "$NEW" | ps_has_secret; then
      ps_deny "project-scaffolder: this write would copy a value from secrets/$(ps_where "$NEW") into another file. Reference the variable name instead; real values live only in secrets/ and in git-ignored .env files."
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
