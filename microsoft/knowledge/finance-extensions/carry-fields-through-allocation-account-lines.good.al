// Demonstration only; independently authored, not copied from BaseApp.
// Generated sales and purchase lines lose custom fields in Validate("No."), so copy them in the create events.
// Assumes Sales Line and Purchase Line extensions with field 50160 "Cost Driver Code" Code[20].
codeunit 50160 "Cost Driver Allocation"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Alloc. Acc. Mgt.", 'OnBeforeCreateSalesLine', '', false, false)]
    local procedure CopyToAllocatedSalesLine(var SalesLine: Record "Sales Line"; var AllocationSalesLine: Record "Sales Line")
    begin
        SalesLine."Cost Driver Code" := AllocationSalesLine."Cost Driver Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase Alloc. Acc. Mgt.", 'OnBeforeCreatePurchaseLine', '', false, false)]
    local procedure CopyToAllocatedPurchaseLine(var PurchaseLine: Record "Purchase Line"; var AllocationPurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Cost Driver Code" := AllocationPurchaseLine."Cost Driver Code";
    end;
}
