// Demonstration only; independently authored, not copied from BaseApp.
// "Customer PO Ref." (field 50150, Code[35]) is on Sales Line, Requisition Line and Purchase Line.
codeunit 50150 "Customer PO Ref. Linking"
{
    // Purchase order route: Get Sales Order (drop shipment) and Get Special Order.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterTransfldsFromSalesToPurchLine', '', false, false)]
    local procedure SalesLineToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
        ToPurchaseLine."Customer PO Ref." := FromSalesLine."Customer PO Ref.";
    end;

    // Requisition route, step 1: sales line to requisition line.
    [EventSubscriber(ObjectType::Report, Report::"Get Sales Orders", 'OnBeforeInsertReqWkshLine', '', false, false)]
    local procedure SalesLineToReqLine(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    begin
        ReqLine."Customer PO Ref." := SalesLine."Customer PO Ref.";
    end;

    // Requisition route, step 2: requisition line to purchase line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnAfterInitPurchOrderLine', '', false, false)]
    local procedure ReqLineToPurchLine(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
        PurchaseLine."Customer PO Ref." := RequisitionLine."Customer PO Ref.";
    end;
}
