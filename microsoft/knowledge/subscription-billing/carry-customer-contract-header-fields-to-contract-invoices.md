---
bc-version: [all]
domain: subscription-billing
keywords: [subscription-billing, customer-subscription-contract, sales-header, transferfields, onaftercreatesalesheaderfromcontract, onaftercreatesalesheaderforcustomerno, collective-invoice, create-billing-documents, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry customer contract header fields to contract invoices

## Description

`Create Billing Documents` (codeunit 8060) in the `Subscription Billing` app creates the sales header in one of two ways. The way depends on the `Documents per` grouping chosen when documents are created.

- Per contract: `CreateSalesHeaderFromContract` inserts the header, validates the customers, and then runs `SalesHeader.TransferFields(CustomerContract, false)`. Every field of `Customer Subscription Contract` is copied to the `Sales Header` field with the same number and a compatible type, extension fields included. Then it raises `OnAfterCreateSalesHeaderFromContract(CustomerContract, var SalesHeader)` and calls `SalesHeader.Modify(false)`.
- Per sell-to or bill-to customer (a collective invoice): `CreateSalesHeaderForCustomerNo` does not copy from any contract. It only copies `External Document No.`. Then it raises `OnAfterCreateSalesHeaderForCustomerNo(var SalesHeader, ContractNo)` and calls `Modify(false)`. `ContractNo` is the contract of the first billing line that opened the header. Lines from other contracts can follow on the same invoice.

So a contract header field with a matching number appears on per-contract invoices and is silently missing from collective invoices.

## Best Practice

Give the field the same number and type on `Customer Subscription Contract` and `Sales Header`, and mirror it on the posted header tables; see [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md). That covers per-contract invoices without a subscriber. For collective invoices, the design must choose a rule. One option is to take the value from the contract passed to `OnAfterCreateSalesHeaderForCustomerNo`. Another is to keep contracts with different values apart with `OnAfterIsNewSalesHeaderNeeded`. A third is to leave the header blank and carry the value per line; see [carry contract line fields to billing lines and contract invoices](carry-contract-line-fields-to-billing-lines-and-contract-invoices.md). Assign values in these events without calling `Modify`, because the app modifies the header right after the event. Vendor contracts work the same way with `OnAfterCreatePurchaseHeaderFromContract` and `OnAfterCreatePurchaseHeaderForVendorNo`.

Because the copy is by field number, check that no other contract field number collides with an unrelated `Sales Header` extension field of a compatible type.

See sample: [`carry-customer-contract-header-fields-to-contract-invoices.good.al`](carry-customer-contract-header-fields-to-contract-invoices.good.al).

## Anti Pattern

Give the contract and sales header fields different numbers and copy the value in `OnAfterCreateSalesHeaderFromContract` only. Or rely on matching numbers alone. Either design forgets the collective-invoice path, where no `TransferFields` runs and the per-contract event is not raised. The field then depends on the grouping the user picks when they create documents.

See sample: [`carry-customer-contract-header-fields-to-contract-invoices.bad.al`](carry-customer-contract-header-fields-to-contract-invoices.bad.al).

## References

- [Create Billing Documents, CreateSalesHeaderFromContract and CreateSalesHeaderForCustomerNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/CreateBillingDocuments.Codeunit.al).
- [Customer Subscription Contract table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Customer%20Contracts/Tables/CustomerSubscriptionContract.Table.al).
- [Recurring billing, create posting documents](https://learn.microsoft.com/en-us/dynamics365/business-central/srb/recurring-billing).
- [Posting documents](https://learn.microsoft.com/en-us/dynamics365/business-central/srb/posting-documents).
