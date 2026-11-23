---
bc-version: [all]
domain: finance-extensions
keywords: [gen-journal-line, gen-journal-batch, gen-jnl-post-batch, setupnewline, document-no, no-series, setsuppresscommit, journal-template, finance-feature]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Post finance journal lines from feature code in a dedicated batch

## Description

When a feature posts to the general ledger, it usually creates `Gen. Journal Line` records and runs `"Gen. Jnl.-Post Batch"`, as [create financial ledger entries through the owning posting engine](../finance/post-ledger-entries-through-posting-codeunits.md) requires. Three behaviors of the batch codeunit shape the design:

- It sets filters on the journal template and batch of the record it receives, so it posts every line in that batch that matches the record's remaining filters, including lines a user entered by hand.
- It checks document numbers against the batch's `No. Series`. A number equal to the next number is consumed; any other number must be allowed as a manual number by that series, or posting fails.
- It calls `Commit()` unless `SetSuppressCommit(true)` was called first.

`SetUpNewLine` on `Gen. Journal Line` fills posting date and document number from the batch, using `PeekNextNo` on the batch's series without consuming it.

## Best Practice

Give the feature its own journal template and batch, named in the feature's setup table, so batch posting can only reach the feature's lines. Check that the setup values exist with `TestField` before creating lines, as [TestField a required setup field](../data-modeling/testfield-required-setup-field.md) describes.

Create each line with `SetUpNewLine` from the previous line, so document numbers come from the batch series in the order posting expects. Then `Validate` the account fields rather than assigning them, so posting groups, VAT and default dimensions are filled. Keep each document balanced; see [preserve journal batch document balance](../finance/preserve-journal-batch-document-balance.md).

Decide the transaction boundary in the design. When the posting must commit or roll back together with the feature's own writes, call `SetSuppressCommit(true)` and let the caller own the transaction.

See sample: [`post-finance-journal-lines-from-code-in-a-dedicated-batch.good.al`](post-finance-journal-lines-from-code-in-a-dedicated-batch.good.al).

## Anti Pattern

Insert lines into a batch users also work in, with hard-coded document numbers, and run batch posting. The run posts the users' lines too, and fails when a hard-coded number is neither the next number nor allowed as a manual number. A feature that expects its own earlier writes to roll back with a failed posting also loses them, because batch posting committed.

See sample: [`post-finance-journal-lines-from-code-in-a-dedicated-batch.bad.al`](post-finance-journal-lines-from-code-in-a-dedicated-batch.bad.al).

## References

- [Gen. Jnl.-Post Batch: batch filter, document number check and commits](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al).
- [Gen. Journal Line: SetUpNewLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al).
