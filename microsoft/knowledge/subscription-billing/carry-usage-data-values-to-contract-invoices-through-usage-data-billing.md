---
bc-version: [all]
domain: subscription-billing
keywords: [subscription-billing, usage-based-billing, usage-data-import, usage-data-generic-import, usage-data-billing, onbeforinsertusagedatabilling, data-exchange-definition, onbeforeinsertsaleslinefromcontractline, usage-data-processing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry usage data values to contract invoices through Usage Data Billing

## Description

Usage-based billing in the `Subscription Billing` app runs in four steps on a `Usage Data Import` (table 8013). Each step is started by `Usage Data Import.ProcessUsageDataImport`, which commits before the step and raises `OnBeforeProcessUsageDataImport` and `OnAfterProcessUsageDataImport`. The supplier's `Type` (enum `Usage Data Supplier Type`, extensible, implements the interface `Usage Data Processing`) picks the code. The standard value is `Generic`, implemented by `Generic Connector Processing` (codeunit 8033).

1. Create Imported Lines: the file in `Usage Data Blob` is read with the supplier's `Data Exchange Definition`. Its column mapping writes `Usage Data Generic Import` (table 8018) rows. That table has spare fields `Text1` to `Text3` and `Decimal1` to `Decimal3` for extra columns.
2. Process Imported Lines: links each row to a subscription and its usage-based `Subscription Line`.
3. Create Usage Data Billing: `Create Usage Data Billing` (codeunit 8023) creates one `Usage Data Billing` (table 8006) per imported row and per usage-based subscription line of that subscription. That includes customer and vendor lines. Fields are set one by one with `InitFrom` and assignments, not with `TransferFields`. Just before `Insert(true)` it raises `OnBeforInsertUsageDataBilling(var UsageDataBilling, UsageDataGenericImportGlobal)`. The name is spelled `OnBefor`.
4. Process Usage Data Billing: updates prices and quantities on the subscription lines.

When contract invoices are created, `Create Billing Documents` sets the sales line price and quantity from the open usage data billing rows of the contract line. Then it raises `OnBeforeInsertSalesLineFromContractLine` and inserts the line. Only after the insert does it link those rows to the document with `SaveDocumentValues`, which sets `Document Type`, `Document No.`, `Document Line No.` and `Billing Line Entry No.`.

## Best Practice

Carry an extra usage value in three hops:

- Import: map the column to a spare field such as `Text1` in the `Data Exch. Field Mapping` of the supplier's definition. A field you add to `Usage Data Generic Import` can be mapped the same way.
- Usage Data Billing: add the field and copy it in `OnBeforInsertUsageDataBilling` from `UsageDataGenericImportGlobal`. No `Modify` is needed. If the value is only for the customer side, check `UsageDataBilling.Partner`.
- Invoice line: in `OnBeforeInsertSalesLineFromContractLine`, read `Usage Data Billing` with the filters the app uses. These are `Partner` Customer, the contract number and line number from `TempBillingLine`, `Document Type` None and an empty `Document No.`. Copy the value to the sales line. Vendor invoices use `OnBeforeInsertPurchaseLineFromContractLine`.

One invoice line can cover many usage data billing rows, from several imported lines or periods. The design must say which value wins, or how values are combined. Mirror the sales line field on the posted tables; see [carry contract line fields to billing lines and contract invoices](carry-contract-line-fields-to-billing-lines-and-contract-invoices.md). To support a new supplier format rather than a new column, add a value to `Usage Data Supplier Type` with its own `Usage Data Processing` implementation.

See sample: [`carry-usage-data-values-to-contract-invoices-through-usage-data-billing.good.al`](carry-usage-data-values-to-contract-invoices-through-usage-data-billing.good.al).

## Anti Pattern

Give the field the same number on `Usage Data Generic Import` and `Usage Data Billing` and expect it to be copied. Nothing copies by field number in this path. Or assign the value in `OnAfterCreateUsageDataBillingFromTempSubscriptionLine`, where the row is already inserted, without `Modify`. Reading the usage rows by the sales line's `Document No.` in the pre-insert event finds nothing, because the link is written after the insert. Changing the invoice line afterwards runs into the locks described in [contract invoices are locked once created](contract-invoice-documents-are-locked-set-values-before-insert.md).

See sample: [`carry-usage-data-values-to-contract-invoices-through-usage-data-billing.bad.al`](carry-usage-data-values-to-contract-invoices-through-usage-data-billing.bad.al).

## References

- [Create Usage Data Billing, OnBeforInsertUsageDataBilling](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Usage%20Based%20Billing/Codeunits/CreateUsageDataBilling.Codeunit.al).
- [Generic Connector Processing, data exchange import](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Usage%20Based%20Billing/Codeunits/GenericConnectorProcessing.Codeunit.al).
- [Usage Data Generic Import table, spare fields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Usage%20Based%20Billing/Tables/UsageDataGenericImport.Table.al).
- [Usage Data Import table, processing steps](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Usage%20Based%20Billing/Tables/UsageDataImport.Table.al).
- [Create Billing Documents, usage price and SaveDocumentValues](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Subscription%20Billing/App/Billing/Codeunits/CreateBillingDocuments.Codeunit.al).
