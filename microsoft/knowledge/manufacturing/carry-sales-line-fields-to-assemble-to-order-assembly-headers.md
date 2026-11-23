---
bc-version: [all]
domain: manufacturing
keywords: [assemble-to-order, assemble-to-order-link, assembly-header, sales-line, autoasmtoorder, onbeforeasmheadermodify, onbeforeneedssynchronization, synchronizeasmfromsalesline]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry sales line fields to assemble-to-order assembly headers

## Description

An assemble-to-order sales line owns an `Assembly Header` through table `"Assemble-to-Order Link"`. When standard sales line fields change, `Sales Line` calls its public `AutoAsmToOrder`, which calls `UpdateAsmFromSalesLine` on the link. For a new link, the link inserts the assembly header and synchronizes it. For an existing one, it first asks `NeedsSynchronization`, which compares only standard fields: item, location, shipment date, variant, bin, dimensions, quantity, unit of measure, planning flexibility and reservation. If none differ, it exits without touching the assembly header.

Synchronization (`SynchronizeAsmFromSalesLine`) copies the standard values field by field and raises `OnBeforeAsmHeaderModify(var AssemblyHeader; var SalesLine)` just before `Modify(true)`.

## Best Practice

Add the field to `Assembly Header` and copy it from the sales line in `OnBeforeAsmHeaderModify` on table `"Assemble-to-Order Link"`. That covers the first creation and every later synchronization.

If a change to the custom field alone must reach an existing assembly order, two more steps are needed. In the sales line field's `OnValidate`, call `AutoAsmToOrder()`. Then subscribe to `OnBeforeNeedsSynchronization(AssemblyHeader; SalesLine; var Result; var IsHandled)` on the same table and, only when your field differs, set `Result := true` and `IsHandled := true`. Leave both untouched otherwise, so the standard comparison still decides for standard fields.

See sample: [`carry-sales-line-fields-to-assemble-to-order-assembly-headers.good.al`](carry-sales-line-fields-to-assemble-to-order-assembly-headers.good.al).

## Anti Pattern

Copy the field only in `OnBeforeAsmHeaderModify` and expect later changes to flow: an edit to the custom field alone leaves the assembly order with the old value, because `NeedsSynchronization` sees no standard difference. The opposite mistake is to answer `OnBeforeNeedsSynchronization` with `IsHandled := true` on every call, which replaces the standard comparison and stops item, quantity and date changes from reaching the assembly order.

See sample: [`carry-sales-line-fields-to-assemble-to-order-assembly-headers.bad.al`](carry-sales-line-fields-to-assemble-to-order-assembly-headers.bad.al).

## References

- [Assemble-to-Order Link, UpdateAsm, NeedsSynchronization and SynchronizeAsmFromSalesLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Assembly/Document/AssembletoOrderLink.Table.al).
- [Sales Line, AutoAsmToOrder](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
