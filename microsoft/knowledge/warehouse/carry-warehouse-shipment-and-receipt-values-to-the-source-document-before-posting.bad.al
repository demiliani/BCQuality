// Demonstration only; independently authored, not copied from BaseApp.
// Expects warehouse fields to reach posted documents by field number, then patches history.
// Assumes "Inspection Lot" (50141) on Warehouse Receipt Line and Purch. Rcpt. Line, but not on Purchase Line.
codeunit 50141 "Whse. Post Source Values"
{
    // Purch. Rcpt. Line is a TransferFields of the Purchase Line, so the lot is blank here.
    // This subscriber patches the posted receipt lines after posting instead.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure PatchReceiptLines(var PurchaseHeader: Record "Purchase Header"; PurchRcpHdrNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcpHdrNo);
        if PurchRcptLine.FindSet(true) then
            repeat
                // The warehouse receipt line may already be deleted after a full receipt.
                WarehouseReceiptLine.SetRange("Source No.", PurchRcptLine."Order No.");
                WarehouseReceiptLine.SetRange("Source Line No.", PurchRcptLine."Order Line No.");
                if WarehouseReceiptLine.FindFirst() then begin
                    PurchRcptLine."Inspection Lot" := WarehouseReceiptLine."Inspection Lot";
                    PurchRcptLine.Modify();
                end;
            until PurchRcptLine.Next() = 0;
        // The item ledger entries never get the lot.
    end;
}
