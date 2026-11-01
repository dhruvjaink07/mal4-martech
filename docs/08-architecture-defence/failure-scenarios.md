# Failure Scenarios — Defence Material

> **Purpose:** The question-and-answer framing of this project's failure modes, for live defence. The complete technical scenario table (detection, recovery, and test approach for nine scenarios) is the authoritative source and lives in `docs/02-solution-design/HLD/MAL4-HLD.md` §4.14 and `docs/02-solution-design/LLD/MAL4-LLD.md` §6.4 — this document is the rehearsed, narrative version for presentation, not a duplicate of that table.

---

## Scenario 1: Two Reviewers Act on the Same Campaign

**If asked "what happens here":** The first decision to be written succeeds. The second reviewer's write is rejected because the stored version has already advanced past what they loaded — they get an explicit conflict, reload, and see the current (already-decided) state.

**Why this is the right behavior:** Silently allowing both decisions, or silently picking one without telling the second reviewer, would hide a real coordination problem. An explicit conflict surfaces it.

---

## Scenario 2: A Reviewer Approves a Version That's No Longer Current

**If asked "what happens here":** Rejected before any approval record is created — the system compares the version the reviewer believes they're acting on against the campaign's actual current version at the moment of the decision, not at the moment the reviewer opened the screen.

**Why this matters more than ordinary concurrency:** This isn't just a write conflict — it's the specific failure mode (a stale approval silently applying to content the reviewer never actually evaluated) that would make the whole approval system untrustworthy if left unguarded.

---

## Scenario 3: The Notification Service Is Down

**If asked "what happens here":** Nothing happens to the campaign. The approval (or rejection, or any other decision) is already durably committed before the notification is even attempted. The failed notification is logged and retried in the background.

**If pressed further:** If the app process terminates before a queued retry completes, that specific notification can be permanently lost — there's no durable outbox table yet. This is named as an open item, not claimed as solved.

---

## Scenario 4: The App Is Killed Mid-Action

**If asked "what happens here":** On restart, the campaign reflects exactly the last committed transaction — nothing more, nothing less. There's no partial state to detect or repair, because the atomic commit design means a transition either fully happened or didn't happen at all.

---

## Scenario 5: A Marketer Tries to Edit a Campaign Under Review

**If asked "what happens here":** Rejected at the domain layer — editing is only valid from Draft or Changes Requested states. This is enforced the same way every other illegal transition is: a guard inside the aggregate, not a UI restriction that could be bypassed.

---

## Scenario 6: An Approved Campaign Is Edited

**If asked "what happens here":** Treated as a material change. The existing approval is invalidated (marked superseded, not deleted — it stays in the audit trail) and the campaign returns to Draft, before the edit itself is applied. The campaign must go through review again before it can be scheduled.

---

## Scenario 7 (The One Most Likely to Be Pressed On): What If the Database Write Itself Fails?

**If asked "what happens here":** The entire transaction — the state change and its audit entry together — rolls back. Neither is left in a partial state. The user sees a clear "unable to save, please try again" message, distinct from a conflict message.

**If asked "what if the disk is corrupted or the device is lost":** Out of scope for the current architecture — there is no backup/disaster-recovery layer beyond SQLite's own crash-safety guarantees. Named explicitly in `risks-and-limitations.md`.

---

## The Meta-Question: "Have you actually tested any of this?"

**Honest answer:** No — no Flutter/Dart code exists yet. Every scenario above describes the intended, designed behavior, specified precisely enough to be tested once implementation begins (see the test specifications in `docs/02-solution-design/LLD/MAL4-LLD.md` §5.2.K). Presenting it as already-verified would be a false claim; presenting it as a precise, testable specification is accurate.
