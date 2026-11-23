---
bc-version: [all]
domain: service
keywords: [servcontractmanagement, service-contract, create-contract-invoices, createallservlines, service-ledger-entry, appl-to-service-entry, onservledgentrytoservicelineonbeforeservlineinsert, oncreateserviceledgerentryonbeforeservledgentryinsert, insertservledgerentrysale, combine-invoices]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Service contract invoices are built from contract service ledger entries

## Description

Contract invoices do not come from a service order. Codeunit `ServContractManagement` builds them in code. Report `Create Contract Invoices` calls `CreateServHeader` and then `CreateAllServLines` for each contract. `CreateInvoice`, used for a single contract, calls the same two procedures. Its events `OnBeforeCreateInvoice` and `OnAfterCreateInvoice` do not run from the report.

The order of work inside `CreateAllServLines` matters:

1. For each `Service Contract Line`, `CreateServiceLedgEntry` inserts open `Service Ledger Entry` rows of type `Service Contract`. Their document type is blank and their document number is the unposted invoice number. These rows are created now, not when the invoice is posted.
2. `CreateServiceLine` then turns each of those entries into one `Service Line` in `ServLedgEntryToServiceLine`. It assigns named fields one by one and sets `Appl.-to Service Entry` to the entry number. The contract line itself is not passed to this step.
3. Text lines come from `CreateHeadingServiceLine`, `CreateDetailedServiceLine` and `CreateLastServiceLines`.

The ledger entries have three insert points, each with its own event that passes the `Service Contract Line`:

- not prepaid: `OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert(var ServiceLedgerEntry; ServiceContractHeader; ServiceContractLine)`;
- prepaid, one entry per month: `OnInsertMultipleServLedgEntriesOnBeforeServLedgEntryInsert`. Its `ServiceContractHeader` is only filled for a partial month, so read the contract line;
- prepaid partial period: `OnPostPartialServLedgEntryOnBeforeServLedgEntryInsert(var ServLedgEntry; ServContractLine; ServiceHeader)`.

The service line event is `OnServLedgEntryToServiceLineOnBeforeServLineInsert`. It has two ledger entry parameters. The entry being converted is `ServiceLedgerEntryParm`. The parameter named `ServiceLedgerEntry` holds the codeunit's global entry: the last entry created for the contract line, not necessarily the one on this service line. Neither `Service Line` nor `Service Ledger Entry` stores the contract line number.

When the invoice is posted, `ServLedgEntries-Post.InsertServLedgerEntrySale` finds the line's `Appl.-to Service Entry`. For a `Service Contract` entry it closes the existing rows with `ModifyAll`, sets the posted document type and number, and exits. No new sale entry is inserted, so `OnBeforeServLedgerEntrySaleInsert` is not raised for contract invoice lines.

With `Combine Invoices`, the report creates one header for several contracts of the same bill-to customer. The header is filled from the first contract only.

## Best Practice

Put contract-line values on the contract service ledger entries when they are created. Add the field to `Service Ledger Entry` and `Service Line`. Subscribe to the three insert events above that the contracts in scope use, and copy from the contract line. Then subscribe to `OnServLedgEntryToServiceLineOnBeforeServLineInsert` and copy from `ServiceLedgerEntryParm` to the service line. From the service line the value reaches the posted invoice line by `TransferFields`; see [mirror service fields on posted service documents](mirror-service-fields-and-follow-up-after-service-posting.md).

Copy header values in `OnBeforeServHeaderModify`, as [carry service fields to service and warranty ledger entries](carry-service-fields-to-service-and-warranty-ledger-entries.md) describes. Keep values that differ per contract on the lines, because a combined invoice has one header.

Contract credit memos are a separate path. `CreateCreditLine` builds each credit line and raises `OnBeforeServLineInsert(var ServiceLine; ServiceHeader; ServiceContractHeader)` before its insert.

See sample: [`service-contract-invoices-are-built-from-contract-service-ledger-entries.good.al`](service-contract-invoices-are-built-from-contract-service-ledger-entries.good.al).

## Anti Pattern

Treat a contract invoice like an order invoice. Copy the value only in `OnBeforeServLedgerEntrySaleInsert`, which never runs for contract lines. Or look up the contract line from the finished service line. There is no contract line number to look it up by, so the code has to guess by service item number. Or read the event parameter named `ServiceLedgerEntry` instead of `ServiceLedgerEntryParm`, so every line gets the value of the last entry.

See sample: [`service-contract-invoices-are-built-from-contract-service-ledger-entries.bad.al`](service-contract-invoices-are-built-from-contract-service-ledger-entries.bad.al).

## References

- [ServContractManagement: CreateServHeader, CreateAllServLines, CreateServiceLedgEntry, ServLedgEntryToServiceLine, CreateCreditLine and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Contract/ServContractManagement.Codeunit.al).
- [Create Contract Invoices report, Combine Invoices](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Contract/CreateContractInvoices.Report.al).
- [ServLedgEntries-Post, InsertServLedgerEntrySale closes contract entries](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServLedgEntriesPost.Codeunit.al).
