---
bc-version: [all]
domain: finance-extensions
keywords: [fa-ledger-entry, maintenance-ledger-entry, fa-journal-line, make-fa-ledger-entry, make-maintenance-ledger-entry, oncopyfromfajnlline, fa-jnl-post-line, fa-insert-ledger-entry, fixed-asset]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry custom fields to FA ledger entries from both FA and general journal lines

## Description

`FA Ledger Entry` and `Maintenance Ledger Entry` rows are built in codeunits `Make FA Ledger Entry` and `Make Maintenance Ledger Entry`, called by `FA Jnl.-Post Line`. Each has two copy procedures, one per source: `CopyFromFAJnlLine` for an FA journal line, used for posting types the depreciation book does not integrate with G/L, and `CopyFromGenJnlLine` for a general journal line with account type Fixed Asset (FA G/L journals and fixed asset lines posted from purchase documents). Both start with `Init()`, assign named fields one by one and end with an integration event.

The events have the same names on both codeunits and differ only by publisher: `OnAfterCopyFromFAJnlLine(var FALedgerEntry; FAJournalLine)` and `OnAfterCopyFromGenJnlLine(var FALedgerEntry; GenJournalLine)` on `Make FA Ledger Entry`, and the same pair with `var MaintenanceLedgerEntry` on `Make Maintenance Ledger Entry`. `OnAfterCopyFromGenJnlLine` is also the name of copy events on `VAT Entry` and `Bank Account Ledger Entry`, so the publisher must be named exactly.

`FA Insert Ledger Entry`.`InsertFA` then copies the whole prepared record, raises `OnBeforeInsertFA(var FALedgerEntry)` and inserts it, so a value set in the copy events survives.

## Best Practice

Add the field to `FA Journal Line`, `Gen. Journal Line`, `FA Ledger Entry` and, when maintenance is in scope, `Maintenance Ledger Entry`. Subscribe to both copy events of each Make codeunit the plan needs. Which source is used depends on the depreciation book's G/L integration settings, so a design that covers one source covers only some companies. How the field gets onto `Gen. Journal Line` and on to `G/L Entry` is described in [carry Gen. Journal Line fields to G/L, VAT and bank entries](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md).

See sample: [`carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.good.al`](carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.good.al).

## Anti Pattern

Subscribe only to the FA journal event because the FA journal is where users type, so postings from FA G/L journals and purchase invoices leave the field blank. Or find FA ledger entries after posting and `Modify` them; posted ledger entries are outputs of posting, see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.bad.al`](carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.bad.al).

## References

- [Make FA Ledger Entry, copy procedures and events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/FixedAssets/FixedAsset/MakeFALedgerEntry.Codeunit.al).
- [Make Maintenance Ledger Entry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/FixedAssets/Maintenance/MakeMaintenanceLedgerEntry.Codeunit.al).
- [FA Jnl.-Post Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al).
- [FA Insert Ledger Entry, InsertFA](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al).
