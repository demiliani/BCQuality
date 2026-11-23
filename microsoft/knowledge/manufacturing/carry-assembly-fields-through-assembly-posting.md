---
bc-version: [all]
domain: manufacturing
keywords: [assembly-header, assembly-line, posted-assembly-header, posted-assembly-line, assembly-post, transferfields, item-journal-line, onbeforepostitemconsumption, onaftercreateitemjnllinefromassemblyheader]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry assembly fields through assembly posting

## Description

`"Assembly-Post"` uses two different mechanisms. It creates `Posted Assembly Header` with `TransferFields(AssemblyHeader)` and each `Posted Assembly Line` with `TransferFields(AssemblyLine)`, so fields with the same number and type are copied. The undo of a posted assembly copies back the same way.

The item journal lines it posts are built field by field, with a separate event per kind of line:

- **Output of the assembled item:** `OnAfterCreateItemJnlLineFromAssemblyHeader(var ItemJournalLine; AssemblyHeader)`.
- **Item components:** `OnBeforePostItemConsumption(var AssemblyHeader; var AssemblyLine; var ItemJournalLine)`, raised just before the line is posted.
- **Resource lines:** `OnAfterCreateItemJnlLineFromAssemblyLine(var ItemJournalLine; AssemblyLine)`. Despite its name, this event is raised only in `PostResourceConsumption`, for lines of type Resource; item component lines never reach it.

## Best Practice

For posted assembly documents, give the field the same number, type and length on `Assembly Header` and `Posted Assembly Header`, or on `Assembly Line` and `Posted Assembly Line`, as for sales and purchase documents; see [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md).

For item ledger entries, add the field to `Item Journal Line` and copy it in the event of the line kind that must carry it, then from the journal line to the entry with `OnAfterInitItemLedgEntry`, as in [carry sales line fields to the item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md). Use `OnBeforePostItemConsumption` for component items.

See sample: [`carry-assembly-fields-through-assembly-posting.good.al`](carry-assembly-fields-through-assembly-posting.good.al).

## Anti Pattern

Subscribe to `OnAfterCreateItemJnlLineFromAssemblyLine` to carry a field from each component line to its consumption entry. Item components never raise it, so the consumption entries stay empty, and only resource lines get the value.

See sample: [`carry-assembly-fields-through-assembly-posting.bad.al`](carry-assembly-fields-through-assembly-posting.bad.al).

## References

- [Assembly-Post, posted documents with TransferFields and the item journal line events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Assembly/Posting/AssemblyPost.Codeunit.al).
