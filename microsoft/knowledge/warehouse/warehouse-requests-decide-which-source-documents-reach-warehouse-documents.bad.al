// Demonstration only; independently authored, not copied from BaseApp.
// Filters on the sales header inside the report, after the warehouse requests were chosen.
// The filter card cannot offer it, the Source Documents list ignores it,
// and inventory picks created from Warehouse Request ignore it too.
codeunit 50130 "Delivery Route Whse. Request"
{
    SingleInstance = true;

    var
        RouteFilter: Code[10];

    procedure SetRouteFilter(NewRouteFilter: Code[10])
    begin
        RouteFilter := NewRouteFilter;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Source Documents", 'OnAfterSalesHeaderOnAfterGetRecord', '', false, false)]
    local procedure SkipOtherRoutes(SalesHeader: Record "Sales Header"; var SkipRecord: Boolean)
    begin
        if (RouteFilter <> '') and (SalesHeader."Delivery Route" <> RouteFilter) then
            SkipRecord := true;
    end;
}
