---
bc-version: [all]
domain: finance-extensions
keywords: [intercompany, ic-outbox-jnl-line, ic-inbox-jnl-line, icinboxoutboxmgt, createoutboxjnltransaction, complete-ic-inbox-action, createjournallines, changecompany, gen-jnl-post-batch, ic-data-exchange-database]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Send intercompany journals through the IC outbox, not by writing the partner company

## Description

Intercompany data moves in three steps, and each step runs in a defined company:

1. The sending company creates an IC outbox transaction. For general journals, `Gen. Jnl.-Post Batch` does this only when the batch belongs to a template of type `Intercompany`. `ProcessICLines` calls `ICInboxOutboxMgt.CreateOutboxJnlTransaction`, and after each posted line `PostGenJournalLine` calls `CreateOutboxJnlLine`. Posting a line with an `IC Partner Code` through `Gen. Jnl.-Post Line` directly, or from another template type, creates no outbox transaction. Documents use `SendSalesDoc` and `SendPurchDoc` on `ICInboxOutboxMgt` (427).
2. The transaction is sent: by the `Send to IC Partner` line action and report `Move IC Trans. to Partner Comp` (513), or automatically when `IC Setup` has `Auto. Send Transactions`. For a partner in the same database, `IC Data Exchange Database` (532) writes only the partner's IC inbox tables, such as `IC Inbox Transaction` and `IC Inbox Jnl. Line`. It uses `ChangeCompany`, `TransferFields` and `Insert` with no trigger. For partners with auto-accept, it inserts a `Job Queue Entry` in the partner company that runs `IC Inbox Outbox Subs. Runner` there.
3. The partner company processes its inbox. Report `Complete IC Inbox Action` (511) runs the chosen `Line Action`: `Accept` calls `CreateJournalLines`, `CreateSalesDocument` or `CreatePurchDocument`; `Return to IC Partner` calls `ForwardToOutBox`; `Cancel` moves the rows to the handled tables. `CreateJournalLines` validates `Account No.` after translating the IC account, customer, vendor or bank account, then builds dimensions from the IC dimensions. All of this reads the partner's own setup.

So the standard flow writes across companies only into inbox tables. The partner's journal lines and documents are always created by code running in the partner company. Microsoft Learn states that after `ChangeCompany`, triggers still run in the current company, not in the company passed to `ChangeCompany`.

A custom journal field travels field by field through `OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert`, `OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert` and `OnCreateJournalLinesOnBeforeModify` on `ICInboxOutboxMgt`. `CreateJournalLines` fills `Handled IC Inbox Jnl. Line` with `TransferFields`. Document fields are covered in [carry intercompany document fields to the partner document](carry-intercompany-document-fields-to-the-partner-document.md).

## Best Practice

To post an intercompany journal from code, create the lines in a batch of an `Intercompany` template, set `IC Partner Code`, `IC Account Type` and `IC Account No.` through `Validate`, and post the batch with `Gen. Jnl.-Post Batch`. See [post finance journal lines from code in a dedicated batch](post-finance-journal-lines-from-code-in-a-dedicated-batch.md). Let the partner accept the inbox transaction, by hand, through `Complete IC Inbox Action`, or by auto-accept.

To carry a custom field, add it to `Gen. Journal Line`, `IC Outbox Jnl. Line`, `IC Inbox Jnl. Line` and `Handled IC Inbox Jnl. Line` with the same field number. Then subscribe to the three journal events above. The inbox event may run in the sending company, so it must only copy. Read the partner's setup only in `OnCreateJournalLinesOnBeforeModify`, which runs in the partner company.

When data must reach another company and no IC transaction fits, follow [ChangeCompany runs triggers in the calling company](../events/changecompany-runs-triggers-in-the-calling-company.md): run the code in that company, or write a hand-off row that the target processes itself.

See sample: [`send-intercompany-journals-through-the-ic-outbox-not-changecompany.good.al`](send-intercompany-journals-through-the-ic-outbox-not-changecompany.good.al).

## Anti Pattern

Create the partner's `Gen. Journal Line` or `Purchase Header` directly with `ChangeCompany` and then `Validate`, `Insert(true)` or a posting codeunit. The triggers run in the sending company, so account checks, number series, dimensions and posting groups come from the wrong company. No IC transaction exists, so nothing appears in the IC inbox, cannot be returned or cancelled, and cannot be matched to the sender's posting.

Posting an IC line with `Gen. Jnl.-Post Line` from a general template also skips the outbox, and the partner never receives the transaction.

See sample: [`send-intercompany-journals-through-the-ic-outbox-not-changecompany.bad.al`](send-intercompany-journals-through-the-ic-outbox-not-changecompany.bad.al).

## References

- [ICInboxOutboxMgt: CreateOutboxJnlTransaction, OutboxJnlLineToInbox and CreateJournalLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/ICInboxOutboxMgt.Codeunit.al).
- [Gen. Jnl.-Post Batch: ProcessICLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al).
- [IC Data Exchange Database](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/DataExchange/ICDataExchangeDatabase.Codeunit.al).
- [Complete IC Inbox Action](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/Inbox/CompleteICInboxAction.Report.al).
- [Record.ChangeCompany method, Remarks](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-changecompany-method).
