---
bc-version: [all]
domain: sales-purchase
keywords: [sales-quote-to-order, blanket-sales-order-to-order, purch-quote-to-order, blanket-purch-order-to-order, onafterinitrecord, onafterresetquantityfields, onafterinsertsalesorderline, record-assignment, quote-no]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Quote and blanket order conversion copies custom fields by record assignment

## Description

`Sales-Quote to Order` (86), `Blanket Sales Order to Order` (87), `Purch.-Quote to Order` (96) and `Blanket Purch. Order to Order` (97) create the order in the same `Sales Header`, `Sales Line`, `Purchase Header` or `Purchase Line` table. The new header and each new line start as a record assignment of the source, so every custom field on these tables is already on the order. No copy subscriber and no mirrored field is needed.

Three steps can still change or lose the value:

- **Header initialization.** After the assignment, the order header is inserted with `Insert(true)`, which runs `InitInsert` and `InitRecord`. The purchase routines also call `InitRecord` themselves before the insert. `OnAfterInitRecord` therefore runs on a record that already holds the quote's or blanket order's values.
- **Blanket quantities.** The blanket routines reset the standard quantity fields with `ResetQuantityFields`, then raise `OnAfterResetQuantityFields`. A custom quantity or amount field is copied in full to every order created from the same blanket line.
- **Source removal.** The quote routines delete the quote header and lines with `Delete()` and `DeleteAll()`, without triggers, after an optional archive. Data in your own tables, keyed by the quote number, is not moved. The order keeps the link in `Quote No.`. The blanket order stays and can feed several orders. Unless commit is suppressed, both blanket routines commit before they finish.

## Best Practice

Keep custom header and line fields on the document tables and let the assignment carry them. Make default logic in `OnAfterInitRecord` fill a field only when it is empty, so a converted order keeps the value from its source. This refines [initialize document defaults in InitRecord](../data-modeling/initialize-document-defaults-in-initrecord.md).

Reset custom quantity-based line fields in `OnAfterResetQuantityFields` on both blanket codeunits. Move records in your own tables in the line events that receive both lines: `OnAfterInsertSalesOrderLine` on codeunits 86 and 87, `OnAfterInsertPurchOrderLine` on codeunit 96 and `OnAfterPurchOrderLineInsert` on codeunit 97. Their parameters differ by codeunit, so take each signature from its publisher.

See sample: [`quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.good.al`](quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.good.al).

## Anti Pattern

Write a subscriber that copies the custom field from the quote to the order and calls `Modify`. It adds a write and hides the real defect: an `OnAfterInitRecord` subscriber that overwrites the field with a default for every new header. Another mistake is to leave a custom quantity field untouched on blanket conversion, so each partial order shows the blanket line's full quantity.

See sample: [`quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.bad.al`](quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.bad.al).

Copying documents with Copy Document follows other rules; see [Copy Document drops custom line fields when it recalculates lines](copy-document-recalculate-lines-drops-custom-line-fields.md).

## References

- [Sales-Quote to Order, CreateSalesHeader and TransferQuoteToOrderLines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesQuotetoOrder.Codeunit.al).
- [Blanket Sales Order to Order, CreateSalesOrderLines and ResetQuantityFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/BlanketSalesOrdertoOrder.Codeunit.al).
- [Purch.-Quote to Order, CreatePurchHeader calls InitRecord](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchQuotetoOrder.Codeunit.al).
- [Blanket Purch. Order to Order](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/BlanketPurchOrdertoOrder.Codeunit.al).
- [Sales Header, OnInsert, InitInsert and InitRecord](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesHeader.Table.al).
