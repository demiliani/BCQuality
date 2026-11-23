---
bc-version: [all]
domain: finance-extensions
keywords: [deferral, deferral-posting-buffer, deferral-header, deferral-line, deferral-utilities, g-l-entry, onpostdeferralpostbufferonbeforeinsertglentryforglaccount, onaftercopyfromdeferralpostbuffer, createdeferralschedule, updatedeferralamounts]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields to deferral G/L entries and maintain deferral schedules from code

## Description

Deferral G/L entries are not copies of the main G/L entry. `Gen. Jnl.-Post Line` (12) creates them in two places:

- For sales and purchase documents, `PostDeferralPostBuffer` reads the `Deferral Posting Buffer` (1706) rows that `Sales Post Invoice` or `Purch. Post Invoice` wrote for the same `Document No.` and `Deferral Line No.`.
- For general journal lines, `PostDeferral` reads `Deferral Header` (1701) and `Deferral Line` (1702) of the journal line.

Each deferral entry starts with `InitGLEntry`, so `CopyFromGenJnlLine` runs and `OnAfterCopyGLEntryFromGenJnlLine` fires with the journal line being posted. A value already on that `Gen. Journal Line` therefore reaches the deferral entries too. But `InitGLEntry` sets `G/L Account No.` and `Amount` after that event, and `PostDeferralPostBuffer` and `PostDeferral` then overwrite `Posting Date`, `Description` and `Source Code` with the period values. At `OnAfterCopyGLEntryFromGenJnlLine`, the G/L entry still shows the document's posting date and no final account.

Per-period data has its own events, raised after the period posting date is set:

| Source | G/L account side | Deferral account side |
| --- | --- | --- |
| Sales or purchase document | `OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount` | `OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount` |
| General journal, per period | `OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount` | `OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount` |

`G/L Entry.CopyFromDeferralPostBuffer` and its event `OnAfterCopyFromDeferralPostBuffer` run only on the G/L account side of the document path, not on the deferral account side.

The `Deferral Posting Buffer` is filled field by field. `PrepareSales` and `PreparePurch` copy a fixed list from the line, then raise `OnAfterPrepareSales` and `OnAfterPreparePurch`. `InitFromDeferralLine` copies only amounts, date and description. `Update` merges rows with the same accounts, posting groups, dimensions, deferral code, posting date and deferral line number, and raises `OnUpdateOnAfterSetFilters` so an extension can add its field to that grouping.

Schedules have their own trap. `Deferral Utilities` (1720) rebuilds the lines whenever the schedule is set again: `SetDeferralRecords` deletes all `Deferral Line` rows and the calculation method creates them again. `Sales Line` calls `UpdateDeferralAmounts` when the line amount changes. That calls `RemoveOrSetDeferralSchedule`, which keeps the header's `Calc. Method`, `No. of Periods` and start date. Validating `Deferral Code` calls `DeferralCodeOnValidate`, which uses the template's method and period count. A change of the header `Posting Date` validates `Deferral Code` again on every line, without a dialog when `GuiAllowed` is false. At posting, `CheckDeferralAmount` stops with an error when the schedule's line total differs from `Amount to Defer`.

## Best Practice

For a document-level value, carry it to the `Gen. Journal Line` as in [the Invoice Posting Buffer article](../sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md), and copy it in `OnAfterCopyGLEntryFromGenJnlLine`. Do not read the entry's account, amount or posting date there.

For a value that depends on the period, set it in the four events in the table above. Write it on both sides if reports read the deferral account. When the value comes from the line or the deferral line, copy it into the buffer in `OnAfterPrepareSales` or `OnAfterPreparePurch`, or in `OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate` (`Sales Post Invoice Events`) and `OnPrepareDeferralLineOnAfterInitFromDeferralLine` (`Purch. Post Invoice Events`). Add it to the grouping in `OnUpdateOnAfterSetFilters` when rows with different values must stay apart.

To create a schedule from code, validate `Deferral Code` on the line. For custom periods or a custom start date, call `DeferralUtilities.CreateDeferralSchedule` afterwards with the line's `GetDeferralAmount()`, as `Returns Deferral Start Date` does. After that, change amounts only through `Validate`, so `UpdateDeferralAmounts` recalculates the lines. A user-defined schedule must be set again after each amount change.

See sample: [`carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.good.al`](carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.good.al).

## Anti Pattern

Derive a period value in `OnAfterCopyGLEntryFromGenJnlLine` from `GLEntry."Posting Date"` or filter there on `GLEntry."G/L Account No."`. Every deferral entry gets the document's period, and the account check reads a blank or stale value. Patching entries after posting through the entry number returned by `RunGenJnlPostLine` misses the deferral entries, and it edits posted entries; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

Insert or modify `Deferral Line` rows directly to set a custom split. The next amount change or posting date change deletes them, and a total that differs from `Amount to Defer` stops posting.

See sample: [`carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.bad.al`](carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.bad.al).

## References

- [Gen. Jnl.-Post Line: InitGLEntry, PostDeferral and PostDeferralPostBuffer](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al).
- [Deferral Posting Buffer](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Deferral/DeferralPostingBuffer.Table.al).
- [Deferral Utilities](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Deferral/DeferralUtilities.Codeunit.al).
- [Sales Post Invoice: PrepareDeferralLine and CheckDeferralAmount](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPostInvoice.Codeunit.al).
- [Sales Line: Deferral Code and UpdateDeferralAmounts](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
