export const meta = {
  name: 'improve-segment',
  description: 'One checkpoint segment of an improvement loop: per iteration a lens, one proposal, a build in its own worktree, a refutation-first verdict, keep or discard',
  whenToUse: 'Only from /improve, after the user chose iterations, focus, scope and approval policy. Never start it on your own.',
  phases: [
    { title: 'Baseline', detail: 'sweeper (Sonnet) re-runs the checks on the current tip' },
    { title: 'Iterate', detail: 'architect proposes, builder builds in a worktree, verifier tries to refute' },
  ],
}

// status: segment-done | done | dry | agent-cap | budget | baseline-red | regression | bad-args
// args: { run, base, tip, start, end, total, focus: [dims], scope: [path prefixes] (empty = whole repo),
//   checks: [commands], agentsLeft, maxLines, tried: ['<id> <title>'] }
// The script never touches the user's checkout: builds and checks happen in worktrees, kept work is a
// commit on the branch improve/<run>/<id>. The main session writes the journal from the returned result.
const A = args || {}
const missing = ['run', 'base', 'tip', 'start', 'end', 'focus', 'checks'].filter(k =>
  A[k] === undefined || A[k] === null || (Array.isArray(A[k]) && A[k].length === 0))
if (missing.length) return { status: 'bad-args', missing, iterations: [] }

const HARD_MAX = 100
// At most 10 iterations per run: the main session writes the journal between runs, so a lost
// session never costs more than one segment. A longer approval policy is several segments in a row.
const SEGMENT_MAX = 10
const TOTAL = Math.min(HARD_MAX, A.total || HARD_MAX)
const END = Math.min(A.end, TOTAL, A.start + SEGMENT_MAX - 1)
// 'done' tells the main session the iteration cap is reached: go to the final report, never relaunch.
if (A.start <= TOTAL && A.end < A.start) return { status: 'bad-args', missing: ['end (before start)'], iterations: [] }
if (A.start > END) return { status: 'done', next: A.start, tip: A.tip, agents: 0, kept: [], iterations: [], worktrees: [] }
const MAX_LINES = Math.max(10, Math.min(300, A.maxLines || 150))
// agentsLeft is what the journal's agent-cap leaves: 0 means spent, never "use the default".
const AGENT_CAP = Math.min(900, typeof A.agentsLeft === 'number' ? A.agentsLeft : 3 * (END - A.start + 1) + 1)
if (AGENT_CAP < 4) return { status: 'agent-cap', next: A.start, tip: A.tip, agents: 0, kept: [], iterations: [], worktrees: [] }
// Root paths the loop never changes, including its own permissions, hooks and MCP servers, and the
// pull-request approval policy (Claude Approvals): an edit there can let changes merge unreviewed.
const PROTECTED = ['secrets/', 'raw/', 'docs/brief/', '.scaffolder/', 'logs/', 'wiki/log.md', 'wiki/product/decisions.md',
  '.claude/settings.json', '.claude/settings.local.json', '.claude/hooks/', '.mcp.json',
  '.claude/approvals.yml', '.claude/classifiers/']
// At any depth: a secrets/ folder and .env files (.env.example stays editable), as in hooks/secrets-guard.sh, plus .envrc.
const PROTECTED_ANY = /(^|\/)(secrets\/|\.env(rc|\.(?!example$)[^/]*)?$)/i
const PROTECTED_TEXT = `${PROTECTED.join(', ')}, any secrets/ folder or .env file`
const SCOPE = A.scope || []
const CHECKS = A.checks.map((c, i) => `${i + 1}. ${c}`).join('\n')
const scopeText = SCOPE.length ? SCOPE.join(', ') : 'the whole repository'

const LENSES = {
  design: ['visual hierarchy and spacing', 'consistency with the design system tokens', 'empty, loading and error states'],
  security: ['input reaching queries, shells, paths or templates', 'authorization and secrets handling', 'dependencies and unsafe defaults'],
  features: ['a missing step in the most used flow', 'an edge case the brief implies and the code ignores', 'a small capability users of this product expect'],
  performance: ['work repeated on every request or render', 'data loading, caching and payload size', 'startup and build time'],
  accessibility: ['keyboard reach and focus order', 'names, labels and semantics for assistive technology', 'contrast, motion and text resizing'],
  tokens: ['always-loaded instructions that can be shorter', 'duplicated or stale text in wiki and docs', 'agent prompts and reports that can be tighter'],
}
const lensFor = i => {
  const dims = A.focus
  const dim = dims[(i - 1) % dims.length]
  const angles = LENSES[dim] || [dim]
  return { dim, angle: angles[Math.floor((i - 1) / dims.length) % angles.length] }
}
const norm = p => String(p || '').replace(/\\/g, '/').replace(/^\.\//, '')
const allowed = p => !PROTECTED.some(x => norm(p).startsWith(x)) && !PROTECTED_ANY.test(norm(p)) &&
  (!SCOPE.length || SCOPE.some(s => norm(p).startsWith(norm(s))))

const str = { type: 'string' }
const BASELINE = { type: 'object', required: ['green', 'failing', 'worktree'], properties: { green: { type: 'boolean' }, failing: str, worktree: str } }
const PROPOSAL = { type: 'object', required: ['none', 'title', 'files', 'change', 'acceptance'], properties: {
  none: { type: 'boolean' }, title: str, files: { type: 'array', items: str }, change: str, acceptance: str } }
const BUILD = { type: 'object', required: ['built', 'sha', 'files', 'lines', 'note', 'worktree'], properties: {
  built: { type: 'boolean' }, sha: str, files: { type: 'array', items: str }, lines: { type: 'number' }, note: str, worktree: str } }
const VERDICT = { type: 'object', required: ['verdict', 'checksPass', 'regression', 'parents', 'tipFull', 'files', 'lines', 'value', 'risk', 'reason', 'worktree'], properties: {
  verdict: { type: 'string', enum: ['keep', 'discard'] }, checksPass: { type: 'boolean' }, regression: { type: 'boolean' }, parents: str, tipFull: str,
  files: { type: 'array', items: str }, lines: { type: 'number' }, value: { type: 'number' }, risk: { type: 'number' }, reason: str, worktree: str } }

let tip = A.tip
let agents = 0
let dry = 0
let regressions = 0
let status = 'segment-done'
const iterations = []
const worktrees = []
const tried = (A.tried || []).slice(-40)
// Awaited directly, an agent that fails (six stalls) would end the whole segment before the main session
// writes the journal. Turn that failure into a null result: the iteration is discarded with its reason.
const call = async (prompt, opts) => {
  try { return await agent(prompt, opts) } catch (e) {
    log(`${opts.label}: agent failed (${String((e && e.message) || e).slice(0, 160)}); counted as no result`)
    return null
  }
}

phase('Baseline')
const base = await call(
  `You are in your own git worktree. Run \`git checkout --detach ${tip}\`, then run every check below to completion:\n${CHECKS}\n` +
  `If a check needs dependencies the worktree lacks, run the install command from wiki/tech-stack.md first. green = every check exits 0. ` +
  `failing: the failing commands with one line of output each. worktree: the output of pwd. Change nothing.`,
  { agentType: 'project-scaffolder:sweeper', isolation: 'worktree', schema: BASELINE, label: 'baseline', phase: 'Baseline' })
agents++
if (base && base.worktree) worktrees.push(base.worktree)
if (!base || !base.green) return { status: 'baseline-red', failing: base ? base.failing : 'baseline agent failed', tip, agents, iterations, worktrees }

phase('Iterate')
for (let i = A.start; i <= END; i++) {
  if (agents + 3 > AGENT_CAP) { status = 'agent-cap'; break }
  // budget: the user's token target for the turn ("+500k"), from the bundled /workflow-authoring script API;
  // total is null without a target. Stop cleanly before agent() calls start throwing.
  if (typeof budget !== 'undefined' && budget.total && budget.remaining() < 150000) { status = 'budget'; break }
  const id = String(i).padStart(3, '0')
  const { dim, angle } = lensFor(i)
  const row = { id, lens: `${dim}: ${angle}`, outcome: 'discarded', title: '', sha: '', value: 0, risk: 0, lines: 0, reason: '' }
  iterations.push(row)

  const p = await call(
    `Improvement loop ${A.run}, iteration ${id} of ${TOTAL}. Lens: ${dim}, angle: ${angle}.\n` +
    `Propose exactly ONE improvement to this project through that lens, small enough to build and verify in one pass (at most ${MAX_LINES} changed lines). Read only: do not edit anything.\n` +
    `The project as it stands is commit ${tip}: base ${A.base} plus the improvements kept so far (\`git log --oneline ${A.base}..${tip}\`). Read files at that commit with \`git show ${tip}:<path>\`.\n` +
    (tried.length ? `Already tried in this run, do not repeat or undo:\n- ${tried.join('\n- ')}\n` : '') +
    `Scope: ${scopeText}. Never touch: ${PROTECTED_TEXT}.\n` +
    `Choose the change with the most value for the people who use this product; prefer fixing or removing over adding. ` +
    `change: concrete steps. acceptance: checks someone else can run or read in the diff. Nothing in this lens worth doing: none=true and say why in change.`,
    { agentType: 'project-scaffolder:architect', schema: PROPOSAL, label: `${id} propose · ${dim}`, phase: 'Iterate' })
  agents++
  // A failed agent is not a lens with nothing to do: only a real "none" counts toward the dry stop.
  if (!p) { row.reason = 'proposal agent failed'; continue }
  if (p.none) {
    row.outcome = 'dry'; row.reason = p.change
    if (++dry >= 3) { status = 'dry'; break }
    continue
  }
  dry = 0
  row.title = p.title
  tried.push(`${id} ${p.title}`)
  const outside = (p.files || []).filter(f => !allowed(f))
  if (outside.length) { row.reason = `proposal outside scope: ${outside.join(', ')}`; continue }

  const b = await call(
    `You are in your own git worktree. Iteration ${id} of improvement loop ${A.run}.\n` +
    `1. Run \`git checkout --detach ${tip}\`: start from exactly this commit.\n` +
    `2. Implement this plan and nothing else. Title: ${p.title}\nFiles: ${(p.files || []).join(', ')}\nChange: ${p.change}\nAcceptance: ${p.acceptance}\n` +
    `Stay inside ${scopeText}; never touch ${PROTECTED_TEXT}; at most ${MAX_LINES} changed lines.\n` +
    `3. Run every check:\n${CHECKS}\n(install dependencies first if the worktree lacks them, with the command from wiki/tech-stack.md).\n` +
    `4. All checks pass: \`git switch -c improve/${A.run}/${id}\`, \`git add -A\`, \`git commit -m "improve(${A.run}#${id}): ${p.title.replace(/"/g, "'")}"\`. ` +
    `Exactly one commit whose parent is ${tip}: no amend, rebase, merge or second commit. ` +
    `Report sha, files (\`git diff --name-only ${tip} HEAD\`) and lines (insertions plus deletions from \`git diff --shortstat ${tip} HEAD\`).\n` +
    `5. Checks still failing after a real attempt: commit nothing, built=false, note = the failing check and one line of output.\n` +
    `worktree: the output of pwd.`,
    { agentType: 'project-scaffolder:builder', isolation: 'worktree', schema: BUILD, label: `${id} build`, phase: 'Iterate' })
  agents++
  if (b && b.worktree) worktrees.push(b.worktree)
  if (!b || !b.built || !b.sha) { row.reason = b ? `not built: ${b.note}` : 'builder failed'; continue }
  row.sha = b.sha; row.lines = b.lines
  const stray = (b.files || []).filter(f => !allowed(f))
  if (stray.length) { row.reason = `changed files outside scope: ${stray.join(', ')}`; continue }
  if (b.lines > MAX_LINES) { row.reason = `${b.lines} changed lines, cap ${MAX_LINES}`; continue }

  const v = await call(
    `You are in your own git worktree. Try to REFUTE improvement ${id} of loop ${A.run}. Re-derive every claim yourself; do not trust the builder.\n` +
    `Candidate: commit ${b.sha}. Accepted state before it: ${tip}. Run \`git checkout --detach ${b.sha}\`.\n` +
    `Plan: ${p.title}. Acceptance: ${p.acceptance}. Lens: ${dim} (${angle}).\n` +
    `1. Run every check:\n${CHECKS}\nchecksPass = every check exits 0.\n` +
    `2. regression = something that works at ${tip} fails or is worse at ${b.sha}. Before claiming one, run the same check at ${tip} to prove it passed there.\n` +
    `parents: the output of \`git rev-list --parents -n 1 ${b.sha}\`. tipFull: the output of \`git rev-parse ${tip}\`.\n` +
    `files: the output of \`git diff --name-only ${tip} ${b.sha}\`, not the builder's list. lines: insertions plus deletions from \`git diff --shortstat ${tip} ${b.sha}\`.\n` +
    `3. Read \`git diff ${tip} ${b.sha}\` and review it against the plan and every acceptance item, not against taste. Skip style.\n` +
    `verdict=keep only if every check passes, there is no regression, every acceptance item is met and the gain is visible in the diff. Uncertain, or a check you could not run: discard.\n` +
    `value 1-5 (how much it helps users), risk 1-5 (how likely it hides a problem). reason: one sentence with the evidence. worktree: the output of pwd. Leave the worktree unchanged.`,
    { agentType: 'project-scaffolder:verifier', isolation: 'worktree', schema: VERDICT, label: `${id} refute`, phase: 'Iterate' })
  agents++
  if (v && v.worktree) worktrees.push(v.worktree)
  if (!v) { row.reason = 'verifier failed'; continue }
  row.value = v.value; row.risk = v.risk; row.reason = v.reason
  // Kept work must be ONE commit on the accepted tip: a commit built on another base would become the new
  // tip and silently drop the improvements kept before it, while the journal still lists them as kept.
  const [own, parent, extra] = String(v.parents || '').trim().split(/\s+/)
  if (!own || !parent || extra || parent !== String(v.tipFull || '').trim()) {
    row.reason = `not one commit on ${tip}: parents "${String(v.parents || '').trim()}"`; continue }
  row.sha = own
  // Scope and size are judged on the verifier's own git output, never on the builder's report alone.
  const strayV = (v.files || []).filter(f => !allowed(f))
  if (strayV.length) { row.reason = `diff touches files outside scope: ${strayV.join(', ')}`; continue }
  if (typeof v.lines === 'number') row.lines = v.lines
  if (row.lines > MAX_LINES) { row.reason = `${row.lines} changed lines measured by the verifier, cap ${MAX_LINES}`; continue }
  if (v.regression) {
    row.outcome = 'regression'
    if (++regressions >= 2) { status = 'regression'; break }
    continue
  }
  regressions = 0
  if (v.verdict === 'keep' && v.checksPass) { row.outcome = 'kept'; tip = own }
}

const kept = iterations.filter(r => r.outcome === 'kept')
const last = iterations.length ? Number(iterations[iterations.length - 1].id) : A.start - 1
if (status === 'segment-done' && last >= TOTAL) status = 'done'
log(`Segment ${A.start}-${last}: ${kept.length} kept, ${iterations.length - kept.length} not kept, ${agents} agents, status ${status}`)
return { status, next: last + 1, tip, agents, kept: kept.map(r => r.id), iterations, worktrees }
