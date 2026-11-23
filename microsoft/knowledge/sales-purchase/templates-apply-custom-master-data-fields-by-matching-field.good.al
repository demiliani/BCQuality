// Demonstration only; independently authored, not copied from BaseApp.
// The template field mirrors the customer field: same number, name, type and length.
tableextension 50120 "Customer Delivery Window" extends Customer
{
    fields
    {
        field(50120; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50121 "Customer Templ. Delivery Window" extends "Customer Templ."
{
    fields
    {
        field(50120; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

pageextension 50120 "Customer Templ. Card Delivery" extends "Customer Templ. Card"
{
    layout
    {
        addlast(General)
        {
            field("Delivery Window"; Rec."Delivery Window")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 50120 "Delivery Window Template"
{
    // Fallback only when neither the template nor an earlier step set a value.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnApplyTemplateOnBeforeCustomerModify', '', false, false)]
    local procedure DefaultWhenTemplateIsEmpty(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
        if Customer."Delivery Window" = '' then
            Customer."Delivery Window" := 'STANDARD';
    end;
}
