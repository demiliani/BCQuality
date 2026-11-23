// Demonstration only; independently authored, not copied from BaseApp.
// Assumes field 50140 "Inspection Result" Code[10] on Sales Line, Return Receipt Line,
// Purchase Line and Return Shipment Line, with the same number and type.
codeunit 50140 "Inspection Result Returns"
{
    // The credit memo line must carry the value recorded at receipt, not the order line's current value.
    [EventSubscriber(ObjectType::Table, Database::"Return Receipt Line", 'OnAfterCopyFieldsFromReturnReceiptLine', '', false, false)]
    local procedure CopyFromReturnReceipt(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
        SalesLine."Inspection Result" := ReturnReceiptLine."Inspection Result";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Line", 'OnAfterCopyFieldsFromReturnShipmentLine', '', false, false)]
    local procedure CopyFromReturnShipment(var ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Inspection Result" := ReturnShipmentLine."Inspection Result";
    end;
}
