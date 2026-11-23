// Demonstration only; independently authored, not copied from BaseApp.
// Copies a routing-line value to the subcontracting purchase line where every creation path meets.
tableextension 50140 "Prod. Rtng. Line Coating" extends "Prod. Order Routing Line"
{
    fields
    {
        field(50140; "Coating Spec"; Code[20])
        {
            Caption = 'Coating Spec';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50141 "Purch. Line Coating" extends "Purchase Line"
{
    fields
    {
        field(50140; "Coating Spec"; Code[20])
        {
            Caption = 'Coating Spec';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50140 "Subcontract Coating Spec"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine', '', false, false)]
    local procedure CopyCoatingSpec(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Ordinary purchase proposals use the same code path.
        if (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Operation No." = '') then
            exit;
        ProdOrderRoutingLine.SetLoadFields("Coating Spec");
        if ProdOrderRoutingLine.Get(
             ProdOrderRoutingLine.Status::Released, RequisitionLine."Prod. Order No.",
             RequisitionLine."Routing Reference No.", RequisitionLine."Routing No.", RequisitionLine."Operation No.")
        then
            PurchOrderLine."Coating Spec" := ProdOrderRoutingLine."Coating Spec"; // Set before PurchOrderLine.Insert().
    end;
}
