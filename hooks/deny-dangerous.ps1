# PreToolUse guard (project-scaffolder v3) - PowerShell variant. Same contract as deny-dangerous.sh.
# Optional PowerShell-first variant. hooks.json wires the .sh version; use this in projects that prefer PowerShell hooks.
$inputJson = [Console]::In.ReadToEnd()
if ($inputJson -notmatch '"tool_name"\s*:\s*"(Bash|PowerShell)"') { exit 0 }
$patternsFile = Join-Path $PSScriptRoot "dangerous-patterns.txt"
$csPatternsFile = Join-Path $PSScriptRoot "dangerous-patterns-case-sensitive.txt"

$hit = $false

if (Test-Path $patternsFile) {
  $patterns = Get-Content $patternsFile | Where-Object { $_ -and ($_ -notmatch '^#') }
  foreach ($p in $patterns) {
    $rx = $p -replace '\[\[:space:\]\]', '\s'   # translate POSIX class for .NET regex
    if ($inputJson -match $rx) { $hit = $true; break }   # -match: case-insensitive
  }
}

# Case-SENSITIVE patterns (-cmatch on purpose): e.g. "git branch -D"
# (force-delete, destructive) must not fire on the safe, everyday
# "git branch -d" (delete-if-merged) that a case-insensitive -match would
# also catch. See hooks/dangerous-patterns-case-sensitive.txt.
if (-not $hit -and (Test-Path $csPatternsFile)) {
  $csPatterns = Get-Content $csPatternsFile | Where-Object { $_ -and ($_ -notmatch '^#') }
  foreach ($p in $csPatterns) {
    $rx = $p -replace '\[\[:space:\]\]', '\s'
    if ($inputJson -cmatch $rx) { $hit = $true; break }
  }
}

if ($hit) {
  '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Guardrail project-scaffolder: comando potenzialmente distruttivo. Approva solo se intenzionale."}}'
}
exit 0
