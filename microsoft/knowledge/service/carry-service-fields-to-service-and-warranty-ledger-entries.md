---
bc-version: [all]
domain: service
keywords: [service-ledger-entry, warranty-ledger-entry, servledgentries-post, onbeforeservledgerentryinsert, onbeforewarrantyledgerentryinsert, servcontractmanagement, service-contract, onbeforeservheadermodify, service-line]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry service fields to service and warranty ledger entries on every insert path

## Description

Codeunit `"ServLedgEntries-Post"` builds `Service Ledger Entry` rows field by field from the service header, service line and service item line. It has several insert paths, each with its own event raised just before the `Insert`:

- usage on posting: `OnBeforeServLedgerEntryInsert(var ServiceLedgerEntry; ServiceLine; ServiceItemLine; ServiceHeader)`;
- sale on invoicing: `OnBeforeServLedgerEntrySaleInsert(var ServiceLedgerEntry; ServiceLine; ServiceItemLine; ServiceHeader)`;
- credit memo: `OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert(var ServiceLedgerEntry; ServiceHeader; ServiceLine)`;
- credit memo usage: `OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert(var ServiceLedgerEntry; ServiceHeader; ServiceLine)`.

`Warranty Ledger Entry` rows are built in the same codeunit and raise `OnBeforeWarrantyLedgerEntryInsert(var WarrantyLedgerEntry; ServiceLine)`. The parameter order differs between the events, so a subscriber written for one does not match another.

Service contract invoices are ordinary service documents created by codeunit `ServContractManagement`. `CreateServHeader` fills the new `Service Header` field by field from the contract and raises `OnBeforeServHeaderModify(var ServiceHeader; ServiceContractHeader)` before its `Modify`.

## Best Practice

Add the field to `Service Ledger Entry` and subscribe to every insert event whose entry type the plan needs, not only the first one found. A field that must appear on all service ledger entries needs all four subscribers. Add the field to `Warranty Ledger Entry` and subscribe to `OnBeforeWarrantyLedgerEntryInsert` only when warranty analysis needs it.

For a value that comes from the service contract, copy it to the invoice header in `OnBeforeServHeaderModify` on `ServContractManagement`. From there it follows the normal service document path; see [mirror service fields on posted service documents](mirror-service-fields-and-follow-up-after-service-posting.md).

See sample: [`carry-service-fields-to-service-and-warranty-ledger-entries.good.al`](carry-service-fields-to-service-and-warranty-ledger-entries.good.al).

## Anti Pattern

Subscribe only to `OnBeforeServLedgerEntryInsert`, so sale entries and credit memo entries stay blank. Or find the service ledger entries after posting and `Modify` them; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-service-fields-to-service-and-warranty-ledger-entries.bad.al`](carry-service-fields-to-service-and-warranty-ledger-entries.bad.al).

## References

- [ServLedgEntries-Post, service and warranty ledger inserts](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServLedgEntriesPost.Codeunit.al).
- [ServContractManagement, CreateServHeader](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Contract/ServContractManagement.Codeunit.al).
