// Demonstration only; independently authored, not copied from BaseApp.
// The field is copied on every path that creates production order routing lines, before each insert.
tableextension 50150 "Routing Line Inspection" extends "Routing Line"
{
    fields
    {
        field(50150; "Inspection Plan"; Code[20])
        {
            Caption = 'Inspection Plan';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50151 "Plan. Rtng. Line Inspection" extends "Planning Routing Line"
{
    fields
    {
        field(50150; "Inspection Plan"; Code[20])
        {
            Caption = 'Inspection Plan';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50152 "Prod. Rtng. Line Inspection" extends "Prod. Order Routing Line"
{
    fields
    {
        field(50150; "Inspection Plan"; Code[20])
        {
            Caption = 'Inspection Plan';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50150 "Routing Inspection Copy"
{
    // Refresh Production Order -> Calculate Prod. Order.InitProdOrderRoutingLine.
    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", 'OnAfterCopyFromRoutingLine', '', false, false)]
    local procedure FromRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    begin
        ProdOrderRoutingLine."Inspection Plan" := RoutingLine."Inspection Plan";
    end;

    // Planning: Routing Line -> Planning Routing Line.
    [EventSubscriber(ObjectType::Table, Database::"Planning Routing Line", 'OnAfterTransferFromRoutingLine', '', false, false)]
    local procedure ToPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; var RoutingLine: Record "Routing Line")
    begin
        PlanningRoutingLine."Inspection Plan" := RoutingLine."Inspection Plan";
    end;

    // Carry out: Planning Routing Line -> Prod. Order Routing Line (Mfg. Carry Out Action.TransferRouting).
    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", 'OnAfterCopyFromPlanningRoutingLine', '', false, false)]
    local procedure FromPlanningRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PlanningRoutingLine: Record "Planning Routing Line")
    begin
        ProdOrderRoutingLine."Inspection Plan" := PlanningRoutingLine."Inspection Plan";
    end;
}
