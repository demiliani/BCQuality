---
bc-version: [all]
domain: sales-purchase
keywords: [copy-document-mgt, copysalesdocline, recalculate-lines, onafterrecalculatesalesline, onafterrecalculatepurchline, sales-line, purchase-line, copy-sales-document, get-posted-document-lines, tableextension]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Copy Document drops custom line fields when it recalculates lines

## Description

`Copy Document Mgt.` copies headers and lines in two different ways. The header is copied with `TransferFields`, so a mirrored custom header field arrives. A line is copied in `CopySalesDocLine` or `CopyPurchDocLine`, and the method depends on the `RecalculateLines` property.

When `RecalculateLines` is false, the target line is a record assignment of the source line, so every field is kept, custom ones included. When it is true, the target line is created with `Init`. `RecalculateSalesLine` or `RecalculatePurchLine` then validates a fixed list of standard fields such as `Type`, `No.`, `Variant Code`, `Location Code`, `Unit of Measure Code` and `Quantity`. A custom line field is not copied from the source line. It keeps only what validation sets, such as a default from the item.

Recalculation is common. The `Copy Sales Document` report turns `Recalculate Lines` on when `Include Header` is off, and always for posted shipments and posted return receipts. Lines copied from an archive go through the same recalculation.

Lines copied from posted documents or archives are first built with `TransferFields` from the posted or archive line, so the custom field must also exist with the same number on that table.

## Best Practice

Decide per field whether it must survive a copy. If it must, subscribe to `OnAfterRecalculateSalesLine` on `Copy Document Mgt.` and copy the value from `FromSalesLine` to `ToSalesLine`. For purchases, use `OnAfterRecalculatePurchLine`. The event runs only on the recalculation path, and the target line is not inserted yet, so assign the value without `Modify`.

Mirror the line field on the posted and archive line tables with the same number; see [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md). Header fields that must not be copied are cleared in `OnAfterCopySalesHeaderDone`, as [plan the full path of a custom sales field](plan-the-full-path-of-a-custom-sales-field.md) explains.

Test both copy modes: copy an open order with `Include Header` on and off, and copy a posted shipment.

See sample: [`copy-document-recalculate-lines-drops-custom-line-fields.good.al`](copy-document-recalculate-lines-drops-custom-line-fields.good.al).

## Anti Pattern

Test Copy Document once with `Include Header` on, see the field copied, and conclude that line copies are covered. Or subscribe to `OnAfterInsertToSalesLine` and patch the inserted line with `Modify`. The first misses the recalculation path. The second adds a write per copied line, and purchase copies stay uncovered unless a second subscriber is written.

See sample: [`copy-document-recalculate-lines-drops-custom-line-fields.bad.al`](copy-document-recalculate-lines-drops-custom-line-fields.bad.al).

## References

- [Copy Document Mgt., CopySalesDocLine, RecalculateSalesLine and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al).
- [Copy Sales Document report, Recalculate Lines forced for posted shipments and without header](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/CopySalesDocument.Report.al).
- [Posted Sales Document Lines, copies posted lines with RecalculateLines off](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/PostedSalesDocumentLines.Page.al).
