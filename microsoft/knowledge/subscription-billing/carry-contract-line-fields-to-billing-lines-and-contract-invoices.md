---
bc-version: [all]
domain: subscription-billing
keywords: [subscription-billing, billing-line, cust-sub-contract-line, subscription-line, onafterupdatebillinglinefromsubscriptionline, onbeforeinserttempbillingline, onbeforeinsertsaleslinefromcontractline, create-billing-documents, billing-line-archive, recurring-billing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry contract line fields to billing lines and contract invoices

## Description

Subscription Billing is the `Subscription Billing` app, publisher `Microsoft`, id `3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c`. A design that extends it needs that dependency. The app bills `Subscription Line` records. Each one is linked to a `Cust. Sub. Contract Line` through `Subscription Contract No.` and `Subscription Contract Line No.`. At each stage a value has to be copied by code:

1. `Billing Proposal` (codeunit 8062) creates `Billing Line` records field by field in `UpdateBillingLineFromServiceCommitment`, then raises `OnAfterUpdateBillingLineFromSubscriptionLine(var BillingLine, SubscriptionLine)`.
2. `Create Billing Documents` (codeunit 8060) does not read billing lines directly. It first groups them into a temporary `Billing Line` per subscription line and rebilling flag. It copies named fields only, and raises `OnBeforeInsertTempBillingLine(var TempBillingLine, var BillingLine)` before the insert.
3. Each `Sales Line` is built from that temporary line and inserted with `Insert(false)`. Just before the insert, `OnBeforeInsertSalesLineFromContractLine(var SalesLine, var TempBillingLine)` is raised.

After that, the standard rules apply. Posting copies the sales line to `Sales Invoice Line` with `TransferFields`. When the invoice is posted, the app moves the billing lines to `Billing Line Archive` with `TransferFields`.

## Best Practice

Add the field to `Cust. Sub. Contract Line`, `Billing Line`, `Sales Line` and `Sales Invoice Line`. Also add it to `Billing Line Archive` if users need it on archived billing lines. Use the same number and type on `Billing Line` and `Billing Line Archive`, and on the sales and posted line tables. Then subscribe to three events:

- `OnAfterUpdateBillingLineFromSubscriptionLine`: get the contract line through the subscription line's contract number and line number, and copy the value to the billing line.
- `OnBeforeInsertTempBillingLine`: copy the value from the billing line to the temporary line.
- `OnBeforeInsertSalesLineFromContractLine`: copy it from the temporary line to the sales line.

No `Modify` is needed, because each event runs before its insert. Credit memos follow the same path. Vendor contracts follow it with `OnBeforeInsertPurchaseLineFromContractLine`. Mirror the field on the posted tables as [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md) describes. Header values follow their own path: see [carry customer contract header fields to contract invoices](carry-customer-contract-header-fields-to-contract-invoices.md).

The temporary line groups every billing line of one subscription line. If the value can differ between billing periods, decide which one wins. Otherwise the last billing line read silently wins.

See sample: [`carry-contract-line-fields-to-billing-lines-and-contract-invoices.good.al`](carry-contract-line-fields-to-billing-lines-and-contract-invoices.good.al).

## Anti Pattern

Copy the value from the billing line to the sales line in `OnBeforeInsertSalesLineFromContractLine` without also filling the temporary line. Or look up `Billing Line` by the sales line's document number inside that event. The temporary line does not carry custom fields, and the billing line gets its `Document No.` only after the sales line is inserted. Either way the invoice line stays blank. Patching the sales line later with `Modify(true)` adds a write per line. It also runs into the app's change checks on contract invoices; see [contract invoice lines are locked once created](contract-invoice-documents-are-locked-set-values-before-insert.md).

See sample: [`carry-contract-line-fields-to-billing-lines-and-contract-invoices.bad.al`](carry-contract-line-fields-to-billing-lines-and-contract-invoices.bad.al).

## References

- [Subscription Billing app.json](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/app.json).
- [Billing Proposal, billing lines built from subscription lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/BillingProposal.Codeunit.al).
- [Create Billing Documents, temporary billing lines and sales lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/CreateBillingDocuments.Codeunit.al).
- [Sales Documents, billing line archive by TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/SalesDocuments.Codeunit.al).
- [Recurring billing](https://learn.microsoft.com/en-us/dynamics365/business-central/srb/recurring-billing).
