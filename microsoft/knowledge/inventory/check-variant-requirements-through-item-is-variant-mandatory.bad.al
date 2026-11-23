// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: rebuilds the variant rule from one setup field and assigns the variant directly.
codeunit 50171 "Import Item Adjustment Bad"
{
    procedure CreateLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Ignores the item's own Default/No/Yes option and whether the item has variants.
        InventorySetup.Get();
        if InventorySetup."Variant Mandatory if Exists" and (VariantCode = '') then
            Error('Variant required.');

        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        // Skips the Blocked, Sales Blocked and Purchasing Blocked checks on Item Variant.
        ItemJournalLine."Variant Code" := VariantCode;
        ItemJournalLine.Validate(Quantity, Qty);
    end;
}
