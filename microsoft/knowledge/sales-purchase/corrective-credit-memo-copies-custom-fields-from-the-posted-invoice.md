---
bc-version: [all]
domain: sales-purchase
keywords: [correct-posted-sales-invoice, cancel-posted-invoice, corrective-credit-memo, copy-document-mgt, onaftercopysalesheaderdone, onaftercopypurchheaderdone, sales-cr-memo-header, sales-invoice-header, transferfields, tableextension]
technologies: [al]
countries: [w1]
application-area: [all]
---

# A corrective credit memo copies custom fields from the posted invoice

## Description

`Correct Posted Sales Invoice` builds the credit memo for the Cancel and Correct actions with `Copy Document Mgt.`. It inserts an empty credit memo, sets `SetPropertiesForCorrectiveCreditMemo`, and calls `CopySalesDocForInvoiceCancelling`, which copies from the posted invoice. Those properties include the header and do not recalculate lines.

The header is copied with `TransferFields` from `Sales Invoice Header`, and each line with `TransferFields` from `Sales Invoice Line` followed by a record assignment. So every custom field mirrored on the posted invoice comes back on the credit memo, and posting then copies it to `Sales Cr.Memo Header` and its lines. That is right for business data. It is wrong for state that belongs to one document only, such as an export status, an external transmission ID or an approval stamp.

Cancel also posts the credit memo in the same run, normally after a `Commit`. If a custom posting check rejects the copied values, the cancellation fails and the user is offered the unposted credit memo. Correct then creates a new invoice from the same posted invoice, again with the header included and lines not recalculated.

`Correct Posted Purch. Invoice` follows the same pattern for purchases.

## Best Practice

Classify every custom field that is mirrored on the posted invoice. Business data stays mirrored and needs no code; see [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md). Per-document state is cleared in a subscriber to `OnAfterCopySalesHeaderDone` on `Copy Document Mgt.`, which runs after the header copy and before the header is modified. Use `OnAfterCopyPurchHeaderDone` for purchases. Clearing it there covers Cancel, Correct, creating a corrective credit memo without posting, and a manual Copy Document from a posted invoice.

Make custom posting checks valid for a credit memo created this way. Test Cancel on an invoice that has the custom fields filled, and read the posted credit memo back.

See sample: [`corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.good.al`](corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.good.al).

## Anti Pattern

Mirror an export status field on the posted tables and do nothing else. The corrective credit memo is created already marked as exported and is never sent. Or clear the field in `OnAfterCreateCopyDocument` on `Correct Posted Sales Invoice` and call `Modify`. That adds a write, and a manual Copy Document from the posted invoice and purchase corrections still copy the status.

See sample: [`corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.bad.al`](corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.bad.al).

## References

- [Correct Posted Sales Invoice, CreateCopyDocument and the cancel posting](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/CorrectPostedSalesInvoice.Codeunit.al).
- [Correct Posted Purch. Invoice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/History/CorrectPostedPurchInvoice.Codeunit.al).
- [Copy Document Mgt., SetPropertiesForCorrectiveCreditMemo and OnAfterCopySalesHeaderDone](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al).
