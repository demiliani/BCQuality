---
bc-version: [all]
domain: sales-purchase
keywords: [transferfields, tableextension, purchase-header, purch-inv-header, purch-rcpt-header, purch-cr-memo-hdr, return-shipment-header, purchase-header-archive, initfrompurchline, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Mirror custom purchase fields on every TransferFields target

## Description

Purchase posting creates posted headers with `TransferFields(PurchHeader, true, true)` into `Purch. Rcpt. Header`, `Purch. Inv. Header`, `Purch. Cr. Memo Hdr.` and `Return Shipment Header`. Archiving copies the header into `Purchase Header Archive` the same way. Posted lines are created by `InitFromPurchLine`, which calls `TransferFields(PurchLine)` on `Purch. Rcpt. Line`, `Purch. Inv. Line`, `Purch. Cr. Memo Line` and `Return Shipment Line`. Archiving copies lines into `Purchase Line Archive`.

`TransferFields` matches fields by number. A table extension field reaches a target only if the target has a field with the same number and a compatible type. A different number is skipped without any error.

## Best Practice

Give the custom field the same field number, name, type and length on `Purchase Header` or `Purchase Line` and on every target table the plan needs. Unless the plan states that a document type never needs the field, that means all four posted tables and the archive. Type and length must match, as [TransferFields mirrored fields must match type and length](../data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md) explains.

No subscriber is needed for these stages; the standard `TransferFields` call does the copy. Keep the mirrored fields non-editable on the posted tables. Sales documents follow the same rule; see [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md).

See sample: [`mirror-purchase-fields-on-every-transferfields-target.good.al`](mirror-purchase-fields-on-every-transferfields-target.good.al).

## Anti Pattern

Extend only `Purchase Header` and `Purch. Inv. Header`, or use a different field number on the posted table, then patch the posted header in a subscriber with `Modify`. Receipts, credit memos, return shipments and archives stay blank, and every posted invoice costs an extra write.

See sample: [`mirror-purchase-fields-on-every-transferfields-target.bad.al`](mirror-purchase-fields-on-every-transferfields-target.bad.al).

## References

- [Purch.-Post, posted headers created with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPost.Codeunit.al).
- [Purch. Inv. Line, InitFromPurchLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/History/PurchInvLine.Table.al).
- [ArchiveManagement, purchase header and line archive with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/ArchiveManagement.Codeunit.al).
