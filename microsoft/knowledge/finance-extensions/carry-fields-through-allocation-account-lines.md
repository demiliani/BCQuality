---
bc-version: [all]
domain: finance-extensions
keywords: [allocation-account, allocation-line, gen-journal-alloc-acc-mgt, sales-alloc-acc-mgt, purchase-alloc-acc-mgt, onbeforecreategeneraljournalline, onbeforecreatesalesline, onbeforecreatepurchaseline, transferfields]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry fields through allocation account lines

## Description

An allocation account line is replaced by generated lines when it is posted. `"Gen. Journal Alloc. Acc. Mgt."` (2677) does this for journals from `OnBeforeCode` of `Gen. Jnl.-Post Batch`. `"Sales Alloc. Acc. Mgt."` (2678) and `"Purchase Alloc. Acc. Mgt."` (2679) do it from `OnBeforePostSalesDoc` and `OnBeforePostPurchaseDoc`. The source line is deleted and the generated lines are posted instead. A journal line with an allocation account posted directly through `Gen. Jnl.-Post Line` raises an error.

Each generated line starts as a `TransferFields` copy of the source line, re-read from the database. What happens next differs by side:

- **Journal.** `CreateGLLine` assigns the account and validates `Amount`. A custom `Gen. Journal Line` field stays on every generated line.
- **Sales and purchase.** `CreateSalesLine` and `CreatePurchaseLine` call `Validate("No.")` with the destination G/L account. The `No.` trigger of `Sales Line` and `Purchase Line` runs `Init()` and restores only standard fields. A custom line field copied by `TransferFields` is cleared.

Before each insert, the codeunits raise `OnBeforeCreateGeneralJournalLine`, `OnBeforeCreateSalesLine` or `OnBeforeCreatePurchaseLine`. Each passes the new line, the `Allocation Line` and the source line.

## Best Practice

For journals, rely on `TransferFields` for values that are the same on every allocated line. The value must be saved on the source line, because the codeunit reads the line again by `SystemId`. For sales and purchase lines, copy the field from the source line in `OnBeforeCreateSalesLine` or `OnBeforeCreatePurchaseLine`. When the value depends on the destination, set it from the `AllocationLine` parameter in the same events. The generated lines then post like any other line; see [carry sales and purchase line fields through the invoice posting buffer](../sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md).

Recurring journal allocations are a different feature; see [carry fields through recurring journal allocations](carry-fields-through-recurring-journal-allocations.md).

See sample: [`carry-fields-through-allocation-account-lines.good.al`](carry-fields-through-allocation-account-lines.good.al).

## Anti Pattern

Expect a custom sales line field to reach the generated lines because they are copied with `TransferFields`. `Validate("No.")` clears it before insert. Patching the generated lines from `OnAfterPostSalesDoc` is also too late, because the lines are already posted.

See sample: [`carry-fields-through-allocation-account-lines.bad.al`](carry-fields-through-allocation-account-lines.bad.al).

## References

- [Gen. Journal Alloc. Acc. Mgt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/AllocationAccount/GenJournalAllocAccMgt.Codeunit.al).
- [Sales Alloc. Acc. Mgt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/AllocationAccount/Sales/SalesAllocAccMgt.Codeunit.al).
- [Purchase Alloc. Acc. Mgt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/AllocationAccount/Purchase/PurchaseAllocAccMgt.Codeunit.al).
- [Sales Line, No. trigger](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
