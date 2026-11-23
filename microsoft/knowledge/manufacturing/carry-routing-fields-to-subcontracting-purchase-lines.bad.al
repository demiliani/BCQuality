// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: depends on the obsolete base report and on a requisition-line field that
// the Subcontracting app's direct "create from routing line" path never fills.
// Assumes Requisition Line and Purchase Line table extensions with field 50140 "Coating Spec".
codeunit 50142 "Subcontract Coating Spec Bad"
{
    [EventSubscriber(ObjectType::Report, Report::"Calculate Subcontracts", 'OnAfterTransferProdOrderRoutingLine', '', false, false)]
    local procedure CopyToReqLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        RequisitionLine."Coating Spec" := ProdOrderRoutingLine."Coating Spec";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnBeforePurchOrderLineInsert', '', false, false)]
    local procedure CopyToPurchLine(var PurchOrderHeader: Record "Purchase Header"; var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
        // Empty for orders created without the base report.
        PurchOrderLine."Coating Spec" := ReqLine."Coating Spec";
    end;
}
