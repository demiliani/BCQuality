// Demonstration only; independently authored, not copied from BaseApp.
// Relies on matching field numbers and expects resource purchase lines to post project usage.
tableextension 50120 "Purch. Line Cost Reason" extends "Purchase Line"
{
    fields
    {
        field(50120; "Cost Reason"; Code[20])
        {
            Caption = 'Cost Reason';
            DataClassification = CustomerContent;
        }
    }
}

// Same number on the project ledger, but no step copies it: the field stays empty.
tableextension 50121 "Job Ledg. Cost Reason" extends "Job Ledger Entry"
{
    fields
    {
        field(50120; "Cost Reason"; Code[20])
        {
            Caption = 'Cost Reason';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50120 "Purchase Cost Reason"
{
    // Resource purchase lines never reach Job Transfer Line, so no project entry is created.
    procedure AddSubcontractorHours(var PurchaseHeader: Record "Purchase Header"; ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]; Hours: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Insert(true);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Resource);
        PurchaseLine.Validate("No.", ResourceNo);
        PurchaseLine.Validate(Quantity, Hours);
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Modify(true);
    end;
}
