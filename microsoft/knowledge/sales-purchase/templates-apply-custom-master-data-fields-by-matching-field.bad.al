// Demonstration only; independently authored, not copied from BaseApp.
// Default set on insert: it runs before the template, so the template value is ignored.
// The template field also has a different name and length, so it is never copied.
tableextension 50121 "Customer Templ. Delivery Window" extends "Customer Templ."
{
    fields
    {
        field(50120; "Default Delivery Window"; Code[10])
        {
            Caption = 'Default Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50120 "Delivery Window Template"
{
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeInsertEvent', '', false, false)]
    local procedure SetDefaultOnInsert(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        Rec."Delivery Window" := 'STANDARD';
    end;
}
