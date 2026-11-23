---
bc-version: [all]
domain: finance-extensions
keywords: [reminder-issue, finchrgmemo-issue, issued-reminder-header, issued-fin-charge-memo-header, transferfields, onafterinitgenjnlline, onafterissuereminder, onafterissuefinchargememo]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry reminder and finance charge memo fields when issuing

## Description

Issuing a reminder (`"Reminder-Issue"`, 393) or a finance charge memo (`"FinChrgMemo-Issue"`, 395) creates three kinds of output, each by its own mechanism:

- **Issued documents.** `Issued Reminder Header` and `Issued Reminder Line` are filled with `TransferFields` from `Reminder Header` and `Reminder Line`; the issued finance charge memo tables are filled the same way. Before the header and reminder line inserts, `OnBeforeIssuedReminderHeaderInsert`, `OnBeforeIssuedReminderLineInsert` and `OnBeforeIssuedFinChrgMemoHeaderInsert` run.
- **Ledger entries.** Interest, fees and the customer total are posted through temporary `Gen. Journal Line` rows built field by field in each codeunit's `InitGenJnlLine`. They are not built with the sales `CopyFromSalesHeader`, so `OnAfterCopyGenJnlLineFromSalesHeader` never fires for them. The hook is each codeunit's `OnAfterInitGenJnlLine`: on `"Reminder-Issue"` with `(var GenJournalLine; ReminderHeader; var SrcCode; AccNo)`, on `"FinChrgMemo-Issue"` with `(var GenJnlLine; FinChargeMemoHeader; var SrcCode)`.
- **Follow-up.** `OnAfterIssueReminder` and `OnAfterIssueFinChargeMemo` run at the end of issuing. Neither codeunit commits after posting, so these subscribers run inside the issuing transaction. Each codeunit commits earlier only to keep a newly assigned issuing number.

## Best Practice

To show a custom field on issued documents, give it the same field number and type on the source and issued tables; no subscriber is needed. To carry it to customer and G/L entries, add it to `Gen. Journal Line` and set it in the matching `OnAfterInitGenJnlLine`. The standard journal-line events then take it further; see [carry sales fields to the customer ledger](../sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md) for the customer-entry hop. A design that already carries a field from sales documents must add these subscribers separately for reminders and finance charge memos.

An error raised in `OnAfterIssueReminder` or `OnAfterIssueFinChargeMemo` undoes the issued document and its entries, unlike `OnAfterPostSalesDoc`, which runs after the commit. Keep external calls out of these subscribers and queue them instead; see [OnAfterPostSalesDoc runs after the posting commit](../sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md) for the outbox approach.

See sample: [`carry-reminder-and-finance-charge-fields-when-issuing.good.al`](carry-reminder-and-finance-charge-fields-when-issuing.good.al).

## Anti Pattern

Rely on the sales journal-line subscriber to cover reminder fees and interest, or fill the issued header in `OnAfterIssueReminder` with `Modify`. The first leaves reminder entries blank; the second adds a write that `TransferFields` would have done for free.

See sample: [`carry-reminder-and-finance-charge-fields-when-issuing.bad.al`](carry-reminder-and-finance-charge-fields-when-issuing.bad.al).

## References

- [Reminder-Issue](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Reminder/ReminderIssue.Codeunit.al).
- [FinChrgMemo-Issue](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/FinanceCharge/FinChrgMemoIssue.Codeunit.al).
