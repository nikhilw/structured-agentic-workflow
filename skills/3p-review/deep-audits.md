# Deep Audits (conditional)

Run the matching audit only when the change touches that area. Each item is a question to answer with evidence from disk, not a box to tick.

## Derived state
Caches, indexes, materialized views, search indexes, generated artifacts.

- Rebuildable **only** from authoritative data? Name the command. If rebuilding needs something only the derived store holds, it is a second source of truth.
- Generations/pointers: is a new generation built then swapped atomically, or mutated in place while readers read?
- Stale reads: what does a reader get between write and reconcile? Is that window bounded and acceptable?
- Retention: are old generations cleaned up, and does cleanup failure block or leak?
- **Security**: can stale derived state grant visibility that current authoritative state denies (deleted record still in the index, revoked permission still cached)?
- Loss: if the derived store is deleted, does recovery rebuild from authority — or invent authority from what survived?

## Migrations & schema change

- **Fresh database** vs **already-dirty deployed database** — both paths tested? The second is the one that breaks.
- Preflight: does it check preconditions and report what it found, or does it just start writing?
- Fail-closed: on unexpected data, does it stop — or skip rows and report success?
- Transactionality: what is on disk if it dies mid-run? Is a partial migration detectable and resumable?
- Reversible? If not, is that stated, and is there an operator remediation path?
- Schema snapshot / generated artifacts regenerated and committed?
- Startup: what does the app do when it boots against an un-migrated or partially-migrated DB — refuse, or serve wrong answers?

## Failure timelines
For any operation with an external or non-transactional side effect, write the actual step order:

1. resolve authoritative input → 2. claim the work → 3. acquire lock/lease → 4. revalidate before side effect → 5. external write → 6. confirm write → 7. record completion → 8. retry/reconcile

Then walk every gap between consecutive steps and answer: **crash here leaves what, and what cleans it up?** Specifically check:

- lease lost or expired mid-work (step 3–7) — does the work continue anyway?
- cancellation and lock timeout — is the side effect already committed?
- duplicate completion — is step 7 idempotent under retry?
- crash between two stores (external write done, completion unrecorded)
- input changed during work — is step 4 present at all, or was validity assumed from step 1?
- partial batches — does one bad item abort, skip, or corrupt the rest?
- process restart — is in-flight work reclaimed or orphaned?
- shared object aliases — two call sites mutating one instance

Missing step 4 (revalidate immediately before the side effect) is the single most common defect this audit finds.

## Third-party & deployment

- Is the **installed/locked** version the one whose behavior you are relying on? Check the lockfile and the actual installed version, not the docs.
- Does the call shape match that version's real API — not the latest docs, and not the version the model remembers?
- Expected deprecation warnings present or newly appearing?
- Packaging constraints: wheels/ABI/CPU/arch, container base, image size, offline or air-gapped install.
- Runtime downloads: does it fetch anything at run time? What happens when that fetch fails or is blocked?
- Cleanup on failure: partial images, temp dirs, half-written files.
- Operational thresholds: measured, with the command that measured them — never asserted from documentation.
