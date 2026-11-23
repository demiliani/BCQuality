---
bc-version: [all]
domain: finance-extensions
keywords: [payment-export, payment-export-data, data-exchange, exp-pre-mapping-gen-jnl, onbeforeinsertpaymentexoprtdata, pmt-export-mgt-gen-jnl-line, payment-journal, bank-file]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Add custom data to payment export files through Payment Export Data

## Description

Payment export through the data exchange framework does not read `Gen. Journal Line` while it writes the file. The pre-mapping codeunit `"Exp. Pre-Mapping Gen. Jnl."` (1273) first fills one `Payment Export Data` row per journal line, field by field, from the journal line, the vendor or employee, and the bank accounts. The data exchange definition's field mapping then maps columns to fields of `Payment Export Data`.

Just before inserting each row, the codeunit raises `OnBeforeInsertPaymentExoprtData(var PaymentExportData; GenJournalLine; GeneralLedgerSetup)`. The event name really is misspelled ("Exoprt"). The older path in `"Pmt Export Mgt Gen. Jnl Line"` (1206) fills the same table and raises `OnBeforeInsertPmtExportDataJnlFromGenJnlLine` with the same parameters, but that event is declared `[Scope('OnPrem')]`: an extension for Business Central online cannot subscribe to it.

## Best Practice

Add the custom field to `Payment Export Data`, set it from the journal line in a subscriber to `OnBeforeInsertPaymentExoprtData`, and map it in the data exchange definition's field mapping like any standard column. Subscribe to `OnBeforeInsertPmtExportDataJnlFromGenJnlLine` only in an on-premises app that must also support the older path. The value usually starts on the payment journal line; see [carry vendor ledger fields to suggested payment lines](carry-vendor-ledger-fields-to-suggested-payment-lines.md).

Copy the publisher's event name exactly. A subscriber that "corrects" the spelling names an event that does not exist, and the app does not compile. Fixed formats with their own XMLport, such as SEPA credit transfer, do not use this mapping; check which export the bank account's setup uses before relying on it.

See sample: [`add-custom-data-to-payment-export-files.good.al`](add-custom-data-to-payment-export-files.good.al).

## Anti Pattern

Rewrite the exported file afterwards, or replace the whole pre-mapping codeunit with a copy to add one value. A copy stops receiving the standard fixes and bypasses the extension point that exists for exactly this.

See sample: [`add-custom-data-to-payment-export-files.bad.al`](add-custom-data-to-payment-export-files.bad.al).

## References

- [Exp. Pre-Mapping Gen. Jnl., Payment Export Data rows and their event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/DataExchange/ExpPreMappingGenJnl.Codeunit.al).
- [Pmt Export Mgt Gen. Jnl Line, older export path](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Payment/PmtExportMgtGenJnlLine.Codeunit.al).
- [Set up data exchange definitions](https://learn.microsoft.com/en-us/dynamics365/business-central/across-how-to-set-up-data-exchange-definitions).
