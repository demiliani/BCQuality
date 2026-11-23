// Demonstration only; independently authored, not copied from BaseApp.
// Builds an item journal line from imported data and decides the variant before posting.
codeunit 50170 "Import Item Adjustment"
{
    procedure CreateLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        Item: Record Item;
        VariantRequiredErr: Label 'Item %1 requires a variant code.', Comment = '%1 = item number';
    begin
        Item.Get(ItemNo);
        // Combines Inventory Setup, the item's own option, and whether variants exist.
        if (VariantCode = '') and Item.IsVariantMandatory() then
            Error(VariantRequiredErr, ItemNo);

        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Variant Code", VariantCode); // blocked checks run here
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode); // after the variant, so it is not cleared
        ItemJournalLine.Validate(Quantity, Qty);
    end;
}
