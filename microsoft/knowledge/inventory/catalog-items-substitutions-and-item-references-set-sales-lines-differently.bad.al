// Demonstration only; independently authored, not copied from BaseApp.
// Item default in the OnInsert trigger and line default on the page.
// Items created from catalog items are inserted without the trigger, and substitutions
// and item references validate the table field from code, so the page trigger never runs.
// Assumes a Sales Line table extension with field 50140 "Brand Code" Code[20].
tableextension 50140 "Item Brand" extends Item
{
    fields
    {
        field(50140; "Brand Code"; Code[20])
        {
            Caption = 'Brand Code';
            DataClassification = CustomerContent;
        }
    }

    trigger OnInsert()
    begin
        if "Brand Code" = '' then
            "Brand Code" := 'HOUSE';
    end;
}

pageextension 50140 "Sales Order Subform Brand" extends "Sales Order Subform"
{
    layout
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                Item: Record Item;
            begin
                if (Rec.Type = Rec.Type::Item) and Item.Get(Rec."No.") then
                    Rec."Brand Code" := Item."Brand Code";
            end;
        }
    }
}
