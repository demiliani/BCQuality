---
bc-version: [all]
domain: subscription-billing
keywords: [subscription-billing, document-change-management, recurring-billing, sales-header, sales-line, dimensions, onbeforeinsertsaleslinefromcontractline, auto-contract-billing, job-queue, billing-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Contract invoices are locked once created: set values before insert

## Description

Sales documents created by `Create Billing Documents` have `Recurring Billing` set on the header. Each line is linked to its contract through `Billing Line`: `Document Type`, `Document No.` and `Document Line No.` are written with `ModifyAll` only after the sales line is inserted. The app's `Document Change Management` codeunit then protects these documents.

- Its `Sales Header` `OnBeforeModifyEvent` subscriber raises an error on `Modify(true)` when any of these change: dimensions, sell-to or bill-to customer, contact or address fields, currency, `Prices Including VAT`, `VAT Bus. Posting Group`, invoice discount or `Recurring Billing`.
- Its `Sales Line` `OnBeforeModifyEvent` subscriber does the same for a line that has a billing line. It checks dimensions, type, number, quantity, unit of measure, prices, amounts, discounts and the billing period.
- `OnBeforeValidateEvent` subscribers on the same fields stop a user from changing them on the page.

The app turns these checks off only while it builds the header, around `OnAfterCreateSalesHeaderFromContract` and `OnAfterCreateSalesHeaderForCustomerNo`.

Billing can also run without a user. `Auto Contract Billing` (codeunit 8014) runs from a job queue entry for a billing template. When the documents are not posted directly, `Create Billing Documents` commits after each finished document.

## Best Practice

Decide every locked value before the document exists. Header values go in `OnAfterCreateSalesHeaderFromContract` or `OnAfterCreateSalesHeaderForCustomerNo`, without `Modify`. Line values go in `OnBeforeInsertSalesLineFromContractLine`, read from `TempBillingLine`. Dimensions come from the subscription line's `Dimension Set ID`, which the app combines into the sales line. To change them, set them on the subscription or contract line before billing, as the app's own error message tells the user, or set them on the sales line in that same pre-insert event. Fields that the app does not check, such as your own extension fields, can still be changed later.

Subscribers in this path must not need UI, because billing can run in a job queue; see [job queue handlers must not require UI](../performance/job-queue-handlers-must-not-require-ui.md). An error in a subscriber stops the run, but the documents committed before it stay.

See sample: [`contract-invoice-documents-are-locked-set-values-before-insert.good.al`](contract-invoice-documents-are-locked-set-values-before-insert.good.al).

## Anti Pattern

Adjust the line dimension or unit price on the created invoice afterwards. For example, a subscriber to `OnAfterInsertSalesLineFromBillingLine` that validates a field and calls `Modify(true)`. The billing line is already linked, so `Document Change Management` raises an error and billing fails for the contract. Calling `Modify(false)` to get around the check is no better. It makes the invoice disagree with the contract and the billing lines that are later moved to `Billing Line Archive`.

See sample: [`contract-invoice-documents-are-locked-set-values-before-insert.bad.al`](contract-invoice-documents-are-locked-set-values-before-insert.bad.al).

## References

- [Document Change Management, checks on contract-linked documents](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/DocumentChangeManagement.Codeunit.al).
- [Create Billing Documents, line insert, billing line link and commit checkpoint](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/CreateBillingDocuments.Codeunit.al).
- [Auto Contract Billing, job queue entry point](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/AutoContractBilling.Codeunit.al).
- [Posting documents](https://learn.microsoft.com/en-us/dynamics365/business-central/srb/posting-documents).
