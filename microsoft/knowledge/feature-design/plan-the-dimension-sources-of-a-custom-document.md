---
bc-version: [all]
domain: feature-design
keywords: [feature-design, dimension-set-id, adddimsource, getdefaultdimid, getrecdefaultdimid, createdimfromdefaultdim, onafterinitdefaultdimensionsources, default-dimension-priority, service-contract-header]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan the dimension sources of a custom document

## Description

A custom document often needs a `Dimension Set ID` built from several records: a customer, an item, a custom master and a contract. `DimensionManagement` does this from a list of sources, not from one record. `AddDimSource(DefaultDimSource, TableId, No, FirstPos)` adds a table and key to a `List of [Dictionary of [Integer, Code[20]]]`. `GetDefaultDimID(DefaultDimSource, SourceCode, GlobalDim1Code, GlobalDim2Code, InheritFromDimSetID, InheritFromTableNo)` reads the `Default Dimension` rows of every source and returns one set ID.

When two sources give a value for the same dimension, the first source in the list wins. A `Default Dimension Priority` row for the source code changes that: the table with the lower priority number wins, and a table with a priority beats one without. `FirstPos = true` puts a source at the front of the list.

Standard documents wrap this in one pattern. `Sales Header` has a local `InitDefaultDimensionSources(DefaultDimSource, FieldNo)` that adds every source and passes `FieldNo = Rec.FieldNo(...)` as `FirstPos`. So the field the user just changed goes first. It then raises `OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo)`. `CreateDimFromDefaultDim(FieldNo)` builds the list and calls `CreateDim`, which calls `GetRecDefaultDimID` with `InheritFromDimSetID` 0. Each source field calls `CreateDimFromDefaultDim` in its `OnValidate`. Sales lines inherit the header set: `Sales Line.CreateDim` passes the header's `Dimension Set ID` as `InheritFromDimSetID`.

`Service Contract Header` follows the same pattern. Its sources are bill-to customer, salesperson, responsibility center, contract template and service order type. It raises `OnAfterInitDefaultDimensionSources(var ServiceContractHeader, var DefaultDimSource, FieldNo)`, so an extension can add a source to a standard contract. Its `CreateDim` exits when `Change Status` is not `Open`.

## Best Practice

Settle these decisions before you build:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Sources | Every record that gives defaults: customer, item, custom master, contract. One `AddDimSource` call for each | This article |
| Custom master | It must own its `Default Dimension` rows (insert, rename, delete, global dimension sync) | [give a new master table default dimensions](../finance-extensions/give-a-new-master-table-default-dimensions.md) |
| Conflicts | Which source wins for a shared dimension. Pass a source code and ask for `Default Dimension Priority` rows; never rely on list order alone | This article |
| Recalculation | Each source field calls `CreateDimFromDefaultDim(FieldNo)` in `OnValidate`. Recalculation replaces manual changes, so decide whether to confirm as `Sales Header` does | [dimension management wiring](../data-modeling/dimension-management-wiring.md) |
| Lines | Lines pass the header set as `InheritFromDimSetID` and add their own sources, such as the item | This article |
| Extensibility | Publish `OnAfterInitDefaultDimensionSources` on your own table, so other apps can add sources without changing your code | This article |
| Transfer | Copy the whole set ID to journals and posted records, never only the shortcut codes | [write dimensions as dimension set entries](../finance/write-dimensions-as-dimension-set-entries.md), [do not edit shared dimension sets](../finance/do-not-edit-shared-dimension-sets.md) |

To add a custom master as a source to a standard document, subscribe to that table's `OnAfterInitDefaultDimensionSources` and call `AddDimSource` with your table and key. Pass `FieldNo = Rec.FieldNo(<your field>)` as `FirstPos`. Then call `CreateDimFromDefaultDim(Rec.FieldNo(<your field>))` from your field's `OnValidate`. For a standard service contract, the event is on `Service Contract Header`.

See sample: [`plan-the-dimension-sources-of-a-custom-document.good.al`](plan-the-dimension-sources-of-a-custom-document.good.al).

## Anti Pattern

Call `GetDefaultDimID` in each source field's `OnValidate` with only that field's source, and store the result. The last field validated decides the whole set, and dimensions from the other sources disappear. Passing the document's current `Dimension Set ID` as `InheritFromDimSetID` instead keeps values from a source that was cleared or replaced.

See sample: [`plan-the-dimension-sources-of-a-custom-document.bad.al`](plan-the-dimension-sources-of-a-custom-document.bad.al).

## References

- [DimensionManagement: AddDimSource, GetDefaultDimID, GetRecDefaultDimID](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Dimension/DimensionManagement.Codeunit.al).
- [Sales Header: InitDefaultDimensionSources, CreateDimFromDefaultDim, CreateDim](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesHeader.Table.al).
- [Sales Line: CreateDim inherits the header set](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
- [Service Contract Header: InitDefaultDimensionSources and OnAfterInitDefaultDimensionSources](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Contract/ServiceContractHeader.Table.al).
