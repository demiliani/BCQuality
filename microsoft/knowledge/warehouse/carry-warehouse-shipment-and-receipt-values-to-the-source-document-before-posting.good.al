// Demonstration only; independently authored, not copied from BaseApp.
// Values move warehouse document -> source document -> posted document and item ledger.
// Assumes table extensions with the same field numbers on:
//   Warehouse Shipment Header, Sales Header, Sales Shipment Header: 50140 "Carrier Seal No." Code[20]
//   Warehouse Receipt Line, Purchase Line, Purch. Rcpt. Line: 50141 "Inspection Lot" Code[20]
//   Item Journal Line, Item Ledger Entry: both fields.
codeunit 50140 "Whse. Post Source Values"
{
    // Shipment header -> sales header. Sales-Post copies it to Sales Shipment Header by TransferFields.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Whse. Post Shipment", 'OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify', '', false, false)]
    local procedure CopySealToSalesHeader(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
        if SalesHeader."Carrier Seal No." = WarehouseShipmentHeader."Carrier Seal No." then
            exit;
        SalesHeader."Carrier Seal No." := WarehouseShipmentHeader."Carrier Seal No.";
        ModifyHeader := true;
    end;

    // Receipt line -> purchase line. Runs only when a receipt line matches the purchase line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnInitSourceDocumentLinesOnAfterSourcePurchLineFound', '', false, false)]
    local procedure CopyLotToPurchLine(var PurchaseLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
        if PurchaseLine."Inspection Lot" = WhseRcptLine."Inspection Lot" then
            exit;
        PurchaseLine."Inspection Lot" := WhseRcptLine."Inspection Lot";
        ModifyLine := true;
    end;

    // From here on, the normal posting path: source document -> item journal line -> item ledger entry.
    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromSalesHeader', '', false, false)]
    local procedure SealToItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header")
    begin
        ItemJnlLine."Carrier Seal No." := SalesHeader."Carrier Seal No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromPurchLine', '', false, false)]
    local procedure LotToItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
        ItemJnlLine."Inspection Lot" := PurchLine."Inspection Lot";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure ValuesToItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."Carrier Seal No." := ItemJournalLine."Carrier Seal No.";
        NewItemLedgEntry."Inspection Lot" := ItemJournalLine."Inspection Lot";
    end;
}
