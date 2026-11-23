---
bc-version: [all]
domain: finance-extensions
keywords: [g-l-entry, vat-entry, bank-account-ledger-entry, gen-journal-line, onaftercopyglentryfromgenjnlline, onaftercopyfromgenjnlline, gen-jnl-post-reverse, reversal, reverse-entries]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry Gen. Journal Line fields to G/L, VAT and bank entries, and plan their reversal

## Description

`Gen. Jnl.-Post Line` initializes each entry it creates from the journal line with a field-by-field copy method that ends with an integration event:

- `G/L Entry.CopyFromGenJnlLine` raises `OnAfterCopyGLEntryFromGenJnlLine` on `G/L Entry`.
- `VAT Entry.CopyFromGenJnlLine` raises `OnAfterCopyFromGenJnlLine` on `VAT Entry`.
- `Bank Account Ledger Entry.CopyFromGenJnlLine` raises `OnAfterCopyFromGenJnlLine` on `Bank Account Ledger Entry`.

A custom `Gen. Journal Line` field reaches none of these entries unless an extension copies it in the matching event.

Reversal works differently. `Gen. Jnl.-Post Reverse` builds each reversing G/L, VAT, customer, vendor and bank entry by assigning the original record, for example `GLEntry := GLEntry2`, and then negating the standard amount fields one by one. Custom fields are therefore copied unchanged to the reversing entry. A custom amount or quantity keeps its original sign.

## Best Practice

Add the field to `Gen. Journal Line` and to each entry table the design needs, and subscribe to that table's copy event. Decide per entry: the G/L entry usually needs the value, while VAT and bank entries need it only if their reports or reconciliations use it. Do not store the field on a ledger entry only because it exists on the journal line; see [prefer a related table over stored fields on hot ledgers](../performance/prefer-related-table-over-extension-on-hot-ledgers.md).

For every custom field on an entry, state what reversal must do. A reference or code can stay as copied. A custom amount or quantity must be negated in the reversal events, such as `OnReverseGLEntryOnBeforeInsertGLEntry`, `OnReverseVATEntryOnBeforeInsert` and `OnReverseBankAccLedgEntryOnBeforeInsert` on `Gen. Jnl.-Post Reverse`. Add a test that reverses a posted transaction and checks the custom values.

See sample: [`carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.good.al`](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.good.al).

## Anti Pattern

Copy a custom amount to `G/L Entry` and assume reversal handles it like the standard amounts. The reversing entry carries the same positive amount, so any report that sums the custom field counts the reversed transaction twice. Patching entries after posting instead edits posted ledger entries; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.bad.al`](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.bad.al).

## References

- [G/L Entry: CopyFromGenJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Ledger/GLEntry.Table.al).
- [VAT Entry: CopyFromGenJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/VAT/Ledger/VATEntry.Table.al).
- [Bank Account Ledger Entry: CopyFromGenJnlLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Ledger/BankAccountLedgerEntry.Table.al).
- [Gen. Jnl.-Post Reverse: reversing entries copied from the originals](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Reversal/GenJnlPostReverse.Codeunit.al).
