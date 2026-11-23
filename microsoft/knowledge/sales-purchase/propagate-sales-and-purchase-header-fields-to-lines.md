---
bc-version: [all]
domain: sales-purchase
keywords: [updatesaleslinesbyfieldno, updatepurchlinesbyfieldno, onupdatesaleslinebychangedfieldname, onupdatepurchlinesbychangedfieldname, header-to-line, modifyall, sales-header, purchase-header, confirm-dialog]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Propagate sales and purchase header fields to lines the standard way

## Description

`Sales Header` and `Purchase Header` have a routine for pushing a changed header field to the existing lines: `UpdateSalesLinesByFieldNo` and `UpdatePurchLinesByFieldNo`. Standard fields call it from their `OnValidate`, for example `UpdateSalesLinesByFieldNo(FieldNo("Shipment Date"), CurrFieldNo <> 0)`. The routine asks the user to confirm when its second parameter is true, modifies the header, loops over the lines, validates the standard fields it knows, and calls `Modify(true)` on each line.

For a field it does not know, such as a table extension field, the routine raises an event per line with the field's name and number. The event names are not symmetric: sales raises `OnUpdateSalesLineByChangedFieldName` (singular "Line"), purchases raise `OnUpdatePurchLinesByChangedFieldName` (plural "Lines"). Both pass the header, the line as `var`, the field name, the field number and the header's previous version.

## Best Practice

In the `OnValidate` of the custom header field, call `UpdateSalesLinesByFieldNo(FieldNo("<field>"), CurrFieldNo <> 0)` or the purchase equivalent. Subscribe to the event of that side and, when `ChangedFieldNo` is your field, `Validate` the line field from the header. The standard routine then gives you the user confirmation, skips documents with no lines and modifies each line with its triggers.

That routine only touches lines that already exist. A line added later takes its header values in `InitHeaderDefaults`, which runs when the line's `No.` is validated and ends with `OnAfterInitHeaderDefaults` on `Sales Line` (`var SalesLine`, `SalesHeader`, `xSalesLine`) and on `Purchase Line` (`var PurchLine`, `PurchHeader`, `var TempPurchLine`). Subscribe to it as well, so new and existing lines get the same value.

Spell the event name exactly as each publisher declares it; a sales subscriber copied to purchases with the name adjusted by analogy does not bind.

See sample: [`propagate-sales-and-purchase-header-fields-to-lines.good.al`](propagate-sales-and-purchase-header-fields-to-lines.good.al).

## Anti Pattern

Update the lines with `SalesLine.ModifyAll("<field>", Rec."<field>")` in the header field's `OnValidate`. `ModifyAll` skips the line field's `OnValidate`, so anything that depends on it is not recalculated. It also gives the user no confirmation and runs even when the change came from code that should not touch the lines.

See sample: [`propagate-sales-and-purchase-header-fields-to-lines.bad.al`](propagate-sales-and-purchase-header-fields-to-lines.bad.al).

## References

- [Sales Header, UpdateSalesLinesByFieldNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesHeader.Table.al).
- [Purchase Header, UpdatePurchLinesByFieldNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchaseHeader.Table.al).
