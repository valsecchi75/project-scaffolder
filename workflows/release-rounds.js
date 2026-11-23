export const meta = {
  name: 'release-rounds',
  description: 'Phase 5 verification rounds: security, reliability, accessibility, performance and regression hunts, refutation-first re-checks, stop when dry or when a blocking finding needs a fix',
  whenToUse: 'Only from /5-release, after the user chose the number of rounds. Never start it on your own.',
  phases: [
    { title: 'Hunt', detail: 'one bug-hunter per lens, in parallel' },
    { title: 'Refute', detail: 'sweeper (Sonnet) tries to refute every new finding' },
  ],
}

// args (all optional except version): { version, rounds: 1|5|10|100, startRound, dryStreak,
//   sinceRef, lenses: [...], seen: ['<where> — <summary>'], fixed: ['<where> — <fix>'], maxVerifyPerRound }
const A = args || {}
const CAP = Math.max(1, Math.min(100, A.rounds || 1))
const START = Math.max(1, A.startRound || 1)
const MAX_VERIFY = Math.max(1, Math.min(20, A.maxVerifyPerRound || 12))
const AGENT_CAP = 900 // the runtime stops a run at 1000 agents; stay below it
const ALL_LENSES = ['security', 'reliability', 'accessibility', 'performance', 'regression']
const LENSES = (A.lenses && A.lenses.length ? A.lenses : ALL_LENSES).filter(l => ALL_LENSES.includes(l))
const SEC_EFFORT = ['high', 'xhigh', 'medium'] // security scans are nondeterministic: vary effort per round
const SEV = { CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3 }

const FOCUS = {
  security: 'trust boundaries: server-side authorization for every object, user input reaching a query, shell, path, template or redirect, secrets or personal data in logs, errors, URLs or client bundles; run the dependency audit command from wiki/tech-stack.md',
  reliability: 'failure paths (network down, timeout, partial response, quota), state (retry, interrupted operation, stale cache, two tabs), concurrency (double submit, races), time zones and boundaries, migration of existing data',
  accessibility: 'keyboard reachability and focus order, visible focus, accessible names and labels, contrast, reduced motion, error messages announced; run the accessibility check from wiki/tech-stack.md if there is one. No user interface: return no findings and say so in note',
  performance: 'unbounded loops or queries, N+1 access, work repeated on every render or request, missing cleanup of listeners and timers, oversized bundles or payloads; measure with a command, never estimate',
  regression: 'run the full test suite; check every caller of what changed since the last tag and of the fixes listed below, and prove each fix still holds without breaking its neighbours',
}

const FINDINGS = {
  type: 'object', required: ['couldRun', 'findings'],
  properties: {
    couldRun: { type: 'boolean' },
    note: { type: 'string' },
    findings: { type: 'array', items: { type: 'object',
      required: ['severity', 'where', 'summary', 'reproduction', 'observed', 'expected'],
      properties: {
        severity: { type: 'string', enum: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'] },
        where: { type: 'string' }, summary: { type: 'string' }, reproduction: { type: 'string' },
        observed: { type: 'string' }, expected: { type: 'string' },
      } } },
  },
}
const VERDICT = {
  type: 'object', required: ['refuted', 'ran', 'evidence'],
  properties: { refuted: { type: 'boolean' }, ran: { type: 'boolean' }, evidence: { type: 'string' } },
}

const keyOf = f => String(f.where || '').toLowerCase().replace(/\\/g, '/').replace(/\s+/g, '')
const seen = new Map((A.seen || []).map(s => [keyOf({ where: String(s).split(' — ')[0] }), String(s)]))
const seenText = () => Array.from(seen.values()).slice(-60)
const fixed = A.fixed || []
const rounds = []
const blocking = []
const deferred = []
let dry = A.dryStreak || 0
let agents = 0
let status = 'cap'
let last = START - 1

const hunt = (lens, round) => agent(
  `Release rounds, round ${round} of at most ${CAP}, for v${A.version || '?'} (changes since ${A.sinceRef || 'the first commit'}).\n` +
  `Lens: ${lens} across the whole project. Focus: ${FOCUS[lens]}.\n` +
  (fixed.length ? `Fixes applied since the previous round:\n- ${fixed.join('\n- ')}\n` : '') +
  (seen.size ? `Already reported in earlier rounds, do not report again:\n- ${seenText().join('\n- ')}\n` : '') +
  `Look where earlier rounds did not. Apply your proof gate: only reproduced, observed, reachable defects are findings; leads stay out. Zero findings is a valid answer. "where" is path:line of the defect (findings are deduplicated on it). Keep each field to one or two lines.`,
  Object.assign({ agentType: 'project-scaffolder:bug-hunter', label: `r${round} ${lens}`, phase: 'Hunt', schema: FINDINGS },
    lens === 'security' ? { effort: SEC_EFFORT[(round - 1) % SEC_EFFORT.length] } : {}))

const refute = (f, angle, round) => agent(
  `Try to REFUTE this ${f.severity} finding (round ${round}). Do not trust it: re-derive it with your own commands.\n` +
  `Where: ${f.where}\nClaim: ${f.summary}\nReproduction: ${f.reproduction}\n` +
  `Angle: ${angle}\n` +
  `If the reproduction does not trigger it, or a guard makes it unreachable, refuted=true. If you checked and are still uncertain, refuted=true. If you could not run the checks, ran=false. Evidence: the command and the relevant output lines, at most five lines, never a secret value.`,
  { agentType: 'project-scaffolder:sweeper', label: `r${round} refute ${f.where}`, phase: 'Refute', schema: VERDICT })

for (let round = START; round <= CAP; round++) {
  if (agents + LENSES.length + MAX_VERIFY > AGENT_CAP) { status = 'agent-cap'; break }
  // budget: the user's token target for the turn ("+500k"), from the bundled /workflow-authoring script API;
  // total is null without a target. Stop cleanly before agent() calls start throwing.
  if (typeof budget !== 'undefined' && budget.total && budget.remaining() < 100000) { status = 'budget'; break }
  last = round
  log(`Round ${round}/${CAP}: ${LENSES.join(', ')}`)

  // Barrier on purpose: findings from all lenses are deduplicated before any re-check is paid for.
  const reports = await parallel(LENSES.map(lens => () => hunt(lens, round)))
  agents += LENSES.length
  const found = []
  reports.forEach((r, i) => (r && r.findings ? r.findings : []).forEach(f => found.push({ ...f, lens: LENSES[i] })))
  const notRun = LENSES.filter((l, i) => !reports[i] || reports[i].couldRun === false)

  const fresh = []
  found.forEach(f => { const k = keyOf(f); if (k && !seen.has(k) && !fresh.some(x => keyOf(x) === k)) fresh.push(f) })
  fresh.sort((a, b) => SEV[a.severity] - SEV[b.severity])

  const toCheck = fresh.filter(f => f.severity !== 'LOW')
  const leads = fresh.filter(f => f.severity === 'LOW')
  const checked = []
  let slots = MAX_VERIFY
  toCheck.forEach(f => { const cost = f.severity === 'CRITICAL' ? 2 : 1; if (slots >= cost) { checked.push(f); slots -= cost } })
  const unverified = toCheck.filter(f => !checked.includes(f)).concat(leads)
  leads.forEach(f => seen.set(keyOf(f), `${f.where} — ${f.summary}`)) // LOW: reported once, not re-hunted every round
  const overCap = toCheck.length > checked.length
  if (unverified.length) log(`Round ${round}: ${unverified.length} finding(s) not re-checked (LOW or over the cap of ${MAX_VERIFY}); reported as unverified`)

  const verdicts = await parallel(checked.map(f => () => {
    const angles = ['follow the reproduction exactly as written']
    if (f.severity === 'CRITICAL') angles.push('look for a guard upstream or downstream that makes it unreachable for a real user')
    return parallel(angles.map(a => () => refute(f, a, round)))
  }))
  agents += checked.reduce((n, f) => n + (f.severity === 'CRITICAL' ? 2 : 1), 0)

  const confirmed = []
  const unchecked = []
  let refutedCount = 0
  checked.forEach((f, i) => {
    const ran = (verdicts[i] || []).filter(v => v && v.ran)
    const want = f.severity === 'CRITICAL' ? 2 : 1
    if (ran.some(v => v.refuted)) { refutedCount++; seen.set(keyOf(f), `${f.where} — ${f.summary}`) }
    else if (ran.length === want) { confirmed.push({ ...f, evidence: ran.map(v => v.evidence).join(' | ') }); seen.set(keyOf(f), `${f.where} — ${f.summary}`) }
    // A re-check that died or could not run neither refutes nor confirms: unverified, kept out of seen so a later round can report and re-check it.
    else unchecked.push(f)
  })
  if (unchecked.length) log(`Round ${round}: ${unchecked.length} re-check(s) failed or could not run; those findings stay unverified, not refuted`)

  rounds.push({ round, lenses: LENSES, notRun, found: found.length, fresh: fresh.length,
    confirmed, refuted: refutedCount, recheckFailed: unchecked.length,
    unverified: unverified.concat(unchecked).map(f => ({ severity: f.severity, where: f.where, summary: f.summary, lens: f.lens })) })
  confirmed.forEach(f => (SEV[f.severity] <= 1 ? blocking : deferred).push({ round, ...f }))

  const roundBlocking = confirmed.filter(f => SEV[f.severity] <= 1)
  // A round counts as dry only when every lens ran, every new finding was re-checked to a verdict and nothing new was confirmed.
  dry = confirmed.length ? 0 : (notRun.length || overCap || unchecked.length ? dry : dry + 1)
  log(`Round ${round}: ${found.length} found, ${fresh.length} new, ${confirmed.length} confirmed, ${refutedCount} refuted, ${unchecked.length} unchecked; dry streak ${dry}`)

  if (roundBlocking.length) { status = 'needs-fix'; break }
  if (notRun.length === LENSES.length || (checked.length && unchecked.length === checked.length)) { status = 'not-run'; break }
  if (dry >= 2) { status = 'dry'; break }
}

return {
  status, // dry | needs-fix | not-run (no hunter, or no re-check of a round, could run) | cap | agent-cap | budget
  lastRound: last, cap: CAP, dryStreak: dry, agentsUsed: agents,
  nextStartRound: last + 1,
  blocking, deferred, rounds,
  seen: Array.from(seen.values()),
}
