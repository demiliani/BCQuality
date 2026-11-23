// Demonstration only; independently authored, not copied from BaseApp.
// Looks up the sales line at carry-out time and patches the inserted purchase line.
// Planning-engine lines have no Demand Order No., so most planned orders stay blank,
// and production orders are not covered at all.
codeunit 50120 "Cust. Project Planning"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnAfterPurchOrderLineInsert', '', false, false)]
    local procedure PatchPurchaseLine(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesLine.Get(SalesLine."Document Type"::Order, RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.") then begin
            PurchOrderLine."Customer Project" := SalesLine."Customer Project";
            PurchOrderLine.Modify();
        end;
    end;
}
