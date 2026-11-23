// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: covers only the refresh path. Orders created by carrying out the
// planning worksheet build their routing lines from Planning Routing Line and never raise this event.
// Assumes Routing Line and Prod. Order Routing Line table extensions with field 50150 "Inspection Plan".
codeunit 50153 "Routing Inspection Copy Bad"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Prod. Order", 'OnAfterTransferRoutingLine', '', false, false)]
    local procedure FromRoutingLineOnly(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderRoutingLine."Inspection Plan" := RoutingLine."Inspection Plan";
    end;
}
