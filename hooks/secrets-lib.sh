#!/usr/bin/env bash
# How project-scaffolder recognises the secret values in a secrets/ folder.
# Sourced, never executed: by hooks/secrets-guard.sh (every outward call) and
# by skills/release/scripts/build-secrets.sh (the release gate's scan of the
# build output), so the guard and the gate always look for the same values.
# Callers set SECRETS to the folder first. Nothing here prints a value to the
# user: callers keep the map in memory and show only its labels.
#
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
