// Demonstration only; independently authored, not copied from BaseApp.
// "Customer Project" travels Sales Line -> Inventory Profile / Unplanned Demand -> Requisition Line
// -> Purchase Line or Prod. Order Line. Every hop copies before the insert, so no Modify is needed.
tableextension 50120 "Sales Line Cust. Project" extends "Sales Line"
{
    fields
    {
        field(50120; "Customer Project"; Code[20])
        {
            Caption = 'Customer Project';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50121 "Invt. Profile Cust. Project" extends "Inventory Profile"
{
    fields
    {
        field(50120; "Customer Project"; Code[20])
        {
            Caption = 'Customer Project';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50122 "Req. Line Cust. Project" extends "Requisition Line"
{
    fields
    {
        field(50120; "Customer Project"; Code[20])
        {
            Caption = 'Customer Project';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50123 "Purch. Line Cust. Project" extends "Purchase Line"
{
    fields
    {
        field(50120; "Customer Project"; Code[20])
        {
            Caption = 'Customer Project';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50124 "Prod. Line Cust. Project" extends "Prod. Order Line"
{
    fields
    {
        field(50120; "Customer Project"; Code[20])
        {
            Caption = 'Customer Project';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50120 "Cust. Project Planning"
{
    // Calculate Plan: sales demand -> inventory profile.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line Invt. Profile", 'OnAfterTransferInventoryProfileFromSalesLine', '', false, false)]
    local procedure ProfileFromSalesLine(var InventoryProfile: Record "Inventory Profile"; var SalesLine: Record "Sales Line")
    begin
        InventoryProfile."Customer Project" := SalesLine."Customer Project";
    end;

    // Calculate Plan: demand profile -> new planning line. Guard: the parameter is not always a sales demand.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnMaintainPlanningLineOnBeforeReqLineInsert', '', false, false)]
    local procedure PlanningLineFromDemand(var RequisitionLine: Record "Requisition Line"; var DemandInvtProfile: Record "Inventory Profile")
    begin
        if DemandInvtProfile."Source Type" <> Database::"Sales Line" then
            exit;
        RequisitionLine."Customer Project" := DemandInvtProfile."Customer Project";
    end;

    // Order Planning: the unplanned demand still identifies the sales line.
    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterTransferFromUnplannedDemand', '', false, false)]
    local procedure OrderPlanningLineFromDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        SalesLine: Record "Sales Line";
    begin
        if UnplannedDemand."Demand Type" <> UnplannedDemand."Demand Type"::Sales then
            exit;
        SalesLine.SetLoadFields("Customer Project");
        if SalesLine.Get(Enum::"Sales Document Type".FromInteger(UnplannedDemand."Demand SubType"), UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.") then
            RequisitionLine."Customer Project" := SalesLine."Customer Project";
    end;

    // Carry-out to purchase (requisition worksheet, planning worksheet, Order Planning).
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnAfterInitPurchOrderLine', '', false, false)]
    local procedure PurchaseLineFromReqLine(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
        PurchaseLine."Customer Project" := RequisitionLine."Customer Project";
    end;

    // Carry-out to production.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Carry Out Action", 'OnInsertProdOrderLineWithReqLine', '', false, false)]
    local procedure ProdOrderLineFromReqLine(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
        ProdOrderLine."Customer Project" := RequisitionLine."Customer Project";
    end;
}
