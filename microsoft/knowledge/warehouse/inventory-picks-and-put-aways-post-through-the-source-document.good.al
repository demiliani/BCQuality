// Demonstration only; independently authored, not copied from BaseApp.
// The source line carries the value to the item ledger; the activity line only shows it.
// Assumes field 50150 "Export Ref." Code[20] on Sales Line, Purchase Line, Item Journal Line and Item Ledger Entry,
// copied to the ledger through the item journal line as in the sales and purchase posting articles.
tableextension 50150 "Whse. Act. Line Export Ref." extends "Warehouse Activity Line"
{
    fields
    {
        field(50150; "Export Ref."; Code[20])
        {
            Caption = 'Export Ref.';
            DataClassification = CustomerContent;
        }
    }
}

// Same field number on posted inventory pick and put-away lines: TransferFields copies it.
tableextension 50151 "Posted Invt. Pick Export Ref." extends "Posted Invt. Pick Line"
{
    fields
    {
        field(50150; "Export Ref."; Code[20])
        {
            Caption = 'Export Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50152 "Posted Invt. Put Export Ref." extends "Posted Invt. Put-away Line"
{
    fields
    {
        field(50150; "Export Ref."; Code[20])
        {
            Caption = 'Export Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50150 "Export Ref. Invt. Activities"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnBeforeNewWhseActivLineInsertFromSales', '', false, false)]
    local procedure PickFromSalesLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
        WarehouseActivityLine."Export Ref." := SalesLine."Export Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnBeforeNewWhseActivLineInsertFromPurchase', '', false, false)]
    local procedure PutAwayFromPurchaseLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PurchaseLine: Record "Purchase Line")
    begin
        WarehouseActivityLine."Export Ref." := PurchaseLine."Export Ref.";
    end;

    // Put-away template bin policy: no source record is passed, so read it by the source fields.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnAfterInitWarehouseActivityLine', '', false, false)]
    local procedure PutAwayFromTemplatePolicy(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if WarehouseActivityLine."Source Type" <> Database::"Purchase Line" then
            exit;
        PurchaseLine.SetLoadFields("Export Ref.");
        if PurchaseLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then
            WarehouseActivityLine."Export Ref." := PurchaseLine."Export Ref.";
    end;
}
