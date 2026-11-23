---
bc-version: [all]
domain: inventory
keywords: [nonstock-item, catalog-item-management, item-subst, item-reference-management, createnewitem, oncreatenewitemonbeforeitemmodify, onitemsubstgetonaftersubstsaleslineitem, onaftervalidatesalesreferenceno, onafterassignitemvalues, item-templ]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Catalog items, substitutions and item references set sales lines differently

## Description

A sales line can get its item in three ways besides typing `No.`. Each one still validates `No.`, so `OnAfterAssignItemValues` on `Sales Line` runs. Each one also does something around that validation that a custom default can miss.

- Catalog item. `ShowNonstock` on `Sales Line` calls `Catalog Item Management.NonStockSales` (codeunit 5703), then `Validate("No.")`, then overwrites the unit price from the catalog item. When the item does not exist yet, `CreateNewItem` creates it. It inserts the `Item` with `Insert()` without running the trigger, so the item's `OnInsert` code and table extension `OnInsert` triggers do not run. It then applies the item template by copying `Item Templ.` fields to `Item` by field number, and assigns the catalog fields one by one. The same `CreateNewItem` runs from `NonstockAutoItem` and when a substitute is a catalog item.
- Substitution. `ShowItemSub` calls `Item Subst.ItemSubstGet` (codeunit 5701). The substitute is validated on a temporary copy of the line: `No.`, `Variant Code`, `Quantity` and `Unit of Measure Code`. The copy then replaces the real line by record assignment. A subscriber that exits on `IsTemporary`, or that writes records keyed to the line, behaves differently here. Reservations on the line are deleted.
- Item reference. Validating `Item Reference No.` runs `Item Reference Management.ValidateSalesReferenceNo` (codeunit 5720). It validates `No.` only when the item differs from the current one. Afterwards it overwrites `Description` and `Description 2` when the reference has them. `OnAfterValidateSalesReferenceNo` passes the reference that was found.

## Best Practice

Keep the general item default in `OnAfterAssignItemValues`; see [default sales and purchase fields from customer, vendor and item](../sales-purchase/default-sales-and-purchase-fields-from-master-data.md). Do not guard it with `IsTemporary`, or substitutes never get the value. Then add only what each route needs:

- A value on the new item from the catalog item: subscribe to `OnCreateNewItemOnBeforeItemModify` on `Catalog Item Management` and assign it to `Item`. For a value every new item should get, add the field to `Item Templ.` with the same number as on `Item`; the template copy carries it.
- A value on the line from the catalog item: subscribe to `OnAfterShowNonStock` on `Sales Line`, which passes the `Nonstock Item`.
- A value from the original item to the substitute line, such as the requested brand: subscribe to `OnItemSubstGetOnAfterSubstSalesLineItem` on `Item Subst.`. The first parameter is the new line, the second is the line before substitution.
- A value from the customer's item reference: subscribe to `OnAfterValidateSalesReferenceNo` and read `ReturnedItemReference`. This runs even when the item did not change.

See sample: [`catalog-items-substitutions-and-item-references-set-sales-lines-differently.good.al`](catalog-items-substitutions-and-item-references-set-sales-lines-differently.good.al).

## Anti Pattern

Default an item field in a table extension `OnInsert` trigger on `Item`, or in an `OnAfterInsertEvent` subscriber that exits when `RunTrigger` is false. Items created from catalog items stay blank. Default a line field in `OnAfterValidateEvent` of `No.` on the sales order page. Substitutions and item references validate the table field from code, so the page event never runs.

See sample: [`catalog-items-substitutions-and-item-references-set-sales-lines-differently.bad.al`](catalog-items-substitutions-and-item-references-set-sales-lines-differently.bad.al).

## References

- [Catalog Item Management, NonStockSales and CreateNewItem](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/Catalog/CatalogItemManagement.Codeunit.al).
- [Item Subst., ItemSubstGet](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/Substitution/ItemSubst.Codeunit.al).
- [Item Reference Management, ValidateSalesReferenceNo](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/Catalog/ItemReferenceManagement.Codeunit.al).
- [Item Templ. Mgt., InitFromTemplate](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/ItemTemplMgt.Codeunit.al).
- [Sales Line, ShowNonstock and ShowItemSub](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
