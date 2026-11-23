---
bc-version: [all]
domain: finance-extensions
keywords: [recurring-journal, gen-jnl-allocation, gen-jnl-post-batch, postallocations, copyfromgenjnlallocation, onpostallocationsonbeforecopyfromgenjnlalloc, onaftercopygenjnllinefromgenjnlallocation, reversing-entry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields through recurring journal allocations

## Description

A recurring general journal line can have allocations in `Gen. Jnl. Allocation` (221). `Gen. Jnl.-Post Batch` posts the recurring line and then calls `PostAllocations`. That procedure does not copy the recurring line. It starts a new `Gen. Journal Line` with `Init()` and assigns a fixed list of fields, such as posting date, document number, description, source code and reason code. A custom field on the recurring line is not among them.

Before the allocation loop, `OnPostAllocationsOnBeforeCopyFromGenJnlAlloc(var GenJournalLine; var AllocateGenJournalLine; var Reversing)` passes the new line and the recurring line. Inside the loop, `CopyFromGenJnlAllocation` assigns the account, dimensions, posting groups and amounts of each allocation field by field, then raises `OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAllocation; var GenJournalLine)`. The same journal line variable is reused for every allocation. The batch also calls `PostAllocations` for reversing lines, with `Reversing` set to true.

This is separate from the Allocation Account feature, which generates journal lines with `TransferFields`; see [carry fields through allocation account lines](carry-fields-through-allocation-account-lines.md).

## Best Practice

For a value that comes from the recurring line, set it in `OnPostAllocationsOnBeforeCopyFromGenJnlAlloc` from `AllocateGenJournalLine`. It then stays on the reused line for every allocation. For a value that differs per allocation, add the field to `Gen. Jnl. Allocation` and set it in `OnAfterCopyGenJnlLineFromGenJnlAllocation`. Assign it on every call, including blank values, so one allocation's value does not carry over to the next. From the journal line, the standard events take the value to the entries; see [carry general journal line fields to G/L, VAT and bank entries](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md).

See sample: [`carry-fields-through-recurring-journal-allocations.good.al`](carry-fields-through-recurring-journal-allocations.good.al).

## Anti Pattern

Assume the allocation postings inherit the recurring line because both come from the same journal. The recurring line's own entries get the value and the allocation entries stay blank. Setting a per-allocation value only when it is not blank is also wrong. The next allocation keeps the previous value, because the line variable is reused.

See sample: [`carry-fields-through-recurring-journal-allocations.bad.al`](carry-fields-through-recurring-journal-allocations.bad.al).

## References

- [Gen. Jnl.-Post Batch, PostAllocations](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al).
- [Gen. Journal Line, CopyFromGenJnlAllocation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al).
- [Gen. Jnl. Allocation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJnlAllocation.Table.al).
