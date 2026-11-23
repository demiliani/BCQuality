---
bc-version: [all]
domain: finance-extensions
keywords: [default-dimension, dimension-management, global-dimension, defaultdimobjectnolist, savedefaultdim, deletedefaultdim, renamedefaultdim, getdefaultdimid, adddimsource, dimension-set-id]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Give a new master table default dimensions, and a custom document a Dimension Set ID

## Description

`DimensionManagement.DefaultDimObjectNoList` decides which tables appear in the Default Dimensions lookup. It includes a table automatically when the table has `Code[20]` fields named like `Global Dimension 1 Code`, has no field related to `Dimension Set Entry`, and has a primary key made of one `Code` field. A typical new master table qualifies without any subscriber.

What is not automatic: the `Default Dimension` table writes global dimension values back only to the standard tables it knows. For any other table it raises `OnAfterUpdateGlobalDimCode`. The master table also owns its default dimensions on insert, rename and delete, as `Customer` does with `UpdateDefaultDim`, `RenameDefaultDim` and `DeleteDefaultDim`.

A document that should carry dimensions stores a `Dimension Set ID`. `DimensionManagement.GetDefaultDimID` computes it from a list of default dimension sources built with `AddDimSource`.

## Best Practice

For a new master table, follow the `Customer` pattern:

- Add `Global Dimension 1 Code` and `Global Dimension 2 Code` with `CaptionClass` `'1,1,1'` and `'1,1,2'`.
- Validate them through a `ValidateShortcutDimCode` procedure that calls `ValidateDimValueCode` and `SaveDefaultDim`.
- Call `UpdateDefaultDim` in `OnInsert`, `RenameDefaultDim` in `OnRename` and `DeleteDefaultDim` in `OnDelete`.
- Subscribe to `OnAfterUpdateGlobalDimCode` on `Default Dimension` and update the record's global dimension field when its table ID matches, so editing defaults on the Default Dimensions page stays in sync.

For a custom document, keep `Dimension Set ID` and the shortcut dimension fields on the header. When a master record is validated, build the sources with `AddDimSource` for each master record that contributes defaults and set the ID with `GetDefaultDimID`. Write dimensions only as dimension sets; see [write dimensions as dimension set entries](../finance/write-dimensions-as-dimension-set-entries.md) and [do not edit shared dimension sets](../finance/do-not-edit-shared-dimension-sets.md).

See sample: [`give-a-new-master-table-default-dimensions.good.al`](give-a-new-master-table-default-dimensions.good.al).

For designing dimensions for a feature end to end, start from [plan the dimension sources of a custom document](../feature-design/plan-the-dimension-sources-of-a-custom-document.md).

## Anti Pattern

Add global dimension fields to a new master table and stop there. Users can set default dimensions on the Default Dimensions page, but the record's global dimension fields never update. Renaming or deleting the record leaves orphaned `Default Dimension` rows. Copying dimension codes into a custom document's own code fields, without a `Dimension Set ID`, gives posting nothing to transfer.

See sample: [`give-a-new-master-table-default-dimensions.bad.al`](give-a-new-master-table-default-dimensions.bad.al).

## References

- [DimensionManagement: DefaultDimObjectNoList, SaveDefaultDim, GetDefaultDimID](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Dimension/DimensionManagement.Codeunit.al).
- [Default Dimension: UpdateGlobalDimCode and OnAfterUpdateGlobalDimCode](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Dimension/DefaultDimension.Table.al).
- [Customer: the master-table dimension pattern](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Customer/Customer.Table.al).
