---
bc-version: [all]
domain: service
keywords: [service-item, service-item-line, service-line, onaftersetserviteminfo, setserviteminfo, service-item-line-no, serv-posting-journals-mgt, onaftercopytoitemjnlline, onaftercopytoresjournalline, service-post]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry service item fields through service item lines and service posting

## Description

A service order has two kinds of lines. `Service Item Line` (table 5901) says which `Service Item` (table 5940) is being serviced. `Service Line` (table 5902) holds the items, resources, costs and G/L accounts used or charged, and points to its item line through `Service Item Line No.`. Each hop is a field-by-field copy with its own event:

| Hop | Where | Event |
| --- | --- | --- |
| Service item to service item line | `Service Item Line`.`SetServItemInfo`, called when `Service Item No.` is validated | `OnAfterSetServItemInfo(var ServiceItemLine; xServiceItemLine; ServiceItem)` |
| Service item line to service line | `Service Line`, validation of `Service Item Line No.` | `OnValidateServiceItemLineNoOnBeforeValidateContractNo(var ServiceLine; ServItemLine)` |

On orders, validating `Service Item No.` on a service line finds the item line and validates `Service Item Line No.`, so the second event covers both fields. On service invoices and credit memos there is no item line step: the `Service Item No.` validation on the service line returns before any item line lookup.

At posting, `Serv-Posting Journals Mgt.` splits each service line by type, and each ledger gets its own journal line:

- items: `Service Header`.`CopyToItemJnlLine` and `Service Line`.`CopyToItemJnlLine` (event `OnAfterCopyToItemJnlLine` on each table), then `Item Jnl.-Post Line`;
- resources: `CopyToResJournalLine` on both tables (event `OnAfterCopyToResJournalLine`), then `Res. Jnl.-Post Line`. Shipping and consuming post a `Usage` entry, invoicing posts a `Sale` entry;
- customer: `Service Post Invoice`.`PostLedgerEntry` builds the customer line with `Service Header`.`CopyToGenJournalLine` (event `OnAfterCopyToGenJnlLine`), then `Gen. Jnl.-Post Line`.

None of these copies sets the service item number. Only `Service Ledger Entry` records which service item was serviced; see [carry service fields to service and warranty ledger entries](carry-service-fields-to-service-and-warranty-ledger-entries.md).

## Best Practice

Decide which records must show the service item value, then extend each hop on that path. Add the field to `Service Item Line` and copy it in `OnAfterSetServItemInfo`. Add it to `Service Line` and copy it in `OnValidateServiceItemLineNoOnBeforeValidateContractNo`. For invoices and credit memos without item lines, copy from `Service Item` when `Service Line`.`Service Item No.` is validated.

From the service line, follow the ledger the plan names. For item ledger entries, copy to `Item Journal Line` in `OnAfterCopyToItemJnlLine` on `Service Line`, then to the entry in `OnAfterInitItemLedgEntry`; see [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md). For resource ledger entries, copy in `OnAfterCopyToResJournalLine` on `Service Line`, then in `OnAfterCopyFromResJnlLine` on `Res. Ledger Entry`. Posted service documents take the value by `TransferFields`; see [mirror service fields on posted service documents](mirror-service-fields-and-follow-up-after-service-posting.md).

See sample: [`carry-service-item-fields-through-service-item-lines-and-posting.good.al`](carry-service-item-fields-through-service-item-lines-and-posting.good.al).

## Anti Pattern

Add the field to `Service Item` and `Item Ledger Entry` with the same number and expect posting to fill it. No step copies the service item to the journal lines, so the entry stays empty. Or read the service item again in `OnAfterInitItemLedgEntry`: the item journal line has no service item number, and one service order can service several items.

See sample: [`carry-service-item-fields-through-service-item-lines-and-posting.bad.al`](carry-service-item-fields-through-service-item-lines-and-posting.bad.al).

## References

- [Service Item Line, Service Item No. validation and SetServItemInfo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Document/ServiceItemLine.Table.al).
- [Service Line, Service Item Line No. validation, CopyToItemJnlLine and CopyToResJournalLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Document/ServiceLine.Table.al).
- [Serv-Posting Journals Mgt., item and resource journal lines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServPostingJournalsMgt.Codeunit.al).
- [Service Post Invoice, PostLedgerEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServicePostInvoice.Codeunit.al).
- [Service Header, CopyToGenJournalLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Document/ServiceHeader.Table.al).
