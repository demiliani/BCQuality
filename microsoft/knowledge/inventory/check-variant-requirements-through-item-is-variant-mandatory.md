---
bc-version: [all]
domain: inventory
keywords: [item-variant, variant-code, variant-mandatory-if-exists, isvariantmandatory, inventory-setup, item-jnl-check-line, release-sales-document, item-variant-blocked, validate]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Check variant requirements through Item.IsVariantMandatory

## Description

Whether a line needs a `Variant Code` is decided at two levels. `Inventory Setup` has the Boolean `Variant Mandatory if Exists`. Each `Item` has its own `Variant Mandatory if Exists` option with the values `Default`, `No` and `Yes`, and only `Default` falls back to the setup. The rule applies only when at least one `Item Variant` exists for the item; the check counts all variants, blocked ones included.

`Item.IsVariantMandatory()` combines the two levels and the variant check. It also raises `OnBeforeIsVariantMandatory`, so another extension can change the answer. Standard code relies on it in several places. `Release Sales Document` and `Release Purchase Document` test `Variant Code` on item lines when it returns true. `Item Jnl.-Check Line` applies the same rule when an item journal line is posted, and `"Whse. Jnl.-Register Line"` applies it to warehouse journal lines.

Validating `Variant Code` on a line runs further checks. On `Item Journal Line`, the trigger raises an error when the variant is `Blocked`, or `Sales Blocked` or `Purchasing Blocked` for the entry type. When the variant changes, it also clears `Bin Code`, fills the default bin where the location uses one, and replaces `Description` with the variant description.

## Best Practice

When a feature creates sales, purchase or journal lines from code, for example from an import or an API, decide the variant before the line is released or posted. Call `Item.IsVariantMandatory()` and stop with a clear error, or ask for the variant, when it returns true and no variant is known. Do not rebuild the rule from the setup fields.

Set the variant with `Validate("Variant Code", ...)` after `"No."` and before quantity, unit of measure and bin, so the blocked checks run and the variant cannot clear values set earlier. Base-quantity rules for the unit of measure are in [derive base quantities through the line's unit of measure](../scm/derive-base-quantities-through-the-line-unit-of-measure.md).

See sample: [`check-variant-requirements-through-item-is-variant-mandatory.good.al`](check-variant-requirements-through-item-is-variant-mandatory.good.al).

## Anti Pattern

Read only `InventorySetup."Variant Mandatory if Exists"`, or only test the item field for `Yes`. The first ignores items set to `No` or `Yes`; the second ignores `Default` items when the setup requires a variant. Either mistake lets the import pass until release or posting fails, or blocks items that do not need a variant. Assigning `"Variant Code" :=` directly skips the blocked checks, and a bin set before the variant is cleared when the variant is validated.

See sample: [`check-variant-requirements-through-item-is-variant-mandatory.bad.al`](check-variant-requirements-through-item-is-variant-mandatory.bad.al).

## References

- [Item, IsVariantMandatory and VariantMandatoryIfAvailable](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/Item.Table.al).
- [Item Jnl.-Check Line, CheckVariantMandatory](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Journal/ItemJnlCheckLine.Codeunit.al).
- [Release Sales Document, line checks](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/ReleaseSalesDocument.Codeunit.al).
- [Item Journal Line, Variant Code validation and DisplayErrorIfItemVariantIsBlocked](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Journal/ItemJournalLine.Table.al).
