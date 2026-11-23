// Demonstration only; independently authored, not copied from BaseApp.
// A delivery route on the sales header becomes a Get Source Documents filter.
// The value is copied to Warehouse Request at release, then filtered on Warehouse Request.
// Assumes a Sales Header table extension with field 50130 "Delivery Route" Code[10].
tableextension 50130 "Whse. Request Delivery Route" extends "Warehouse Request"
{
    fields
    {
        field(50130; "Delivery Route"; Code[10])
        {
            Caption = 'Delivery Route';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50131 "Whse. Src. Filter Route" extends "Warehouse Source Filter"
{
    fields
    {
        field(50130; "Delivery Route Filter"; Code[100])
        {
            Caption = 'Delivery Route Filter';
            DataClassification = CustomerContent;
        }
    }
}

pageextension 50130 "Src. Doc. Filter Card Route" extends "Source Document Filter Card"
{
    layout
    {
        addlast(General)
        {
            field("Delivery Route Filter"; Rec."Delivery Route Filter")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies which delivery routes to include when getting source documents.';
            }
        }
    }
}

codeunit 50130 "Delivery Route Whse. Request"
{
    // Runs on every release, before the request is inserted or modified.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Sales Release", 'OnBeforeCreateWhseRequest', '', false, false)]
    local procedure CopyRouteOnRelease(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header")
    begin
        WhseRqst."Delivery Route" := SalesHeader."Delivery Route";
    end;

    // Filter card path: Warehouse Source Filter.SetFilters builds the request filter here.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure ApplyRouteFilter(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request")
    begin
        if WarehouseSourceFilter."Delivery Route Filter" <> '' then
            WarehouseRequest.SetFilter("Delivery Route", WarehouseSourceFilter."Delivery Route Filter");
    end;
}
