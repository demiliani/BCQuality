---
bc-version: [all]
domain: subscription-billing
keywords: [subscription-billing, contract-renewal, planned-subscription-line, sales-subscription-line, subscription-line, post-sub-contract-renewal, onbeforeupdatesubscriptionlinefromplannedsubscriptionline, onaftercopyfromsalessubscriptionline, onafterinsertsubscriptionline]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Contract renewal updates subscription lines through planned lines, field by field

## Description

A contract renewal in the `Subscription Billing` app does not create a new contract or new subscription lines. It extends the existing `Subscription Line` records. The path is:

1. `Create Sub. Contract Renewal` (codeunit 8002) turns `Sub. Contract Renewal Line` records into a sales quote. For each line it inserts a `Sales Subscription Line` with process `Contract Renewal` and copies values from the current subscription line one by one. Then it raises `OnAfterInsertSubscriptionLine(var SalesLine, var SubContractRenewalLine, var SalesSubscriptionLine)`. The line is already inserted and modified at that point.
2. The quote can only become an order; the app blocks quote-to-invoice. When the order is posted, a `Sales-Post` subscriber runs `Post Sub. Contract Renewal` (codeunit 8004). For renewal lines no shipment and no invoice are posted.
3. For each sales subscription line it fills a temporary `Subscription Line` with `CopyFromSalesServiceCommitment`, field by field. That procedure raises `OnAfterCopyFromSalesSubscriptionLine(var SubscriptionLine, SalesSubscriptionLine)` on the `Subscription Line` table. Then it copies the temporary line into a `Planned Subscription Line` (table 8002) with `TransferFields`, so fields with the same number are copied.
4. `ProcessPlannedServiceCommitment` applies the planned line to the real subscription line field by field: end date, prices, discounts, unit cost, billing rhythm and terms. It raises `OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine(var SubscriptionLine, var PlannedSubscriptionLine)`. Then it archives the old values, calls `Modify(false)` and deletes the planned line.

Step 4 runs at once only when the subscription line is billed up to its end date, or when price, discount, calculation base and billing rhythm are unchanged. Otherwise the planned line waits. It is checked again each time a contract invoice for that subscription line is posted. While it waits, the subscription line cannot be selected for another renewal.

## Best Practice

For a value that must be renewed, such as a support level:

- Add the field to `Subscription Line`, `Sales Subscription Line` and `Planned Subscription Line`, with the same number and type on the subscription line and the planned line.
- Fill the quote in `OnAfterInsertSubscriptionLine`. Read the current subscription line by `SalesSubscriptionLine."Subscription Line Entry No."`, assign the value and call `Modify`.
- Copy it to the temporary subscription line in `OnAfterCopyFromSalesSubscriptionLine`. `TransferFields` then carries it to the planned line.
- Apply it in `OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine`, without `Modify`.

The design must state that the new value takes effect when the planned line is applied, not when the order is posted. To change the update rule, subscribe to `OnCheckPerformSubscriptionLineUpdate` on codeunit `"Post Sub. Contract Renewal"`; it passes the subscription line, the planned subscription line and `var PerformUpdate`. Billing of renewed periods then follows [carry contract line fields to billing lines and contract invoices](carry-contract-line-fields-to-billing-lines-and-contract-invoices.md).

See sample: [`contract-renewal-updates-subscription-lines-through-planned-lines.good.al`](contract-renewal-updates-subscription-lines-through-planned-lines.good.al).

## Anti Pattern

Add the field only to `Subscription Line` and `Sales Subscription Line`, and expect posting to copy it. The planned line and the final update are field by field, so the value is dropped. Writing the subscription line directly in `OnAfterInsertPlannedSubscriptionLineFromSalesSubscriptionLine` is also wrong. It applies the value while the old term may still be unbilled, even when the app keeps the planned line waiting. Subscribing to sales invoice posting events for renewals finds nothing, because renewal lines post no invoice.

See sample: [`contract-renewal-updates-subscription-lines-through-planned-lines.bad.al`](contract-renewal-updates-subscription-lines-through-planned-lines.bad.al).

## References

- [Create Sub. Contract Renewal, sales subscription lines for the quote](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Contract%20Renewal/Codeunits/CreateSubContractRenewal.Codeunit.al).
- [Post Sub. Contract Renewal, planned lines and the update rule](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Contract%20Renewal/Codeunits/PostSubContractRenewal.Codeunit.al).
- [Sub. Contr. Renewal Subcribers, posting hooks](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Contract%20Renewal/Codeunits/SubContrRenewalSubcribers.Codeunit.al).
- [Subscription Line table, CopyFromSalesServiceCommitment](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Service%20Commitments/Tables/SubscriptionLine.Table.al).
- [Planned Subscription Line table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Contract%20Renewal/Tables/PlannedSubscriptionLine.Table.al).
