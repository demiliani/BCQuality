// Demonstration only; independently authored, not copied from BaseApp.
// ModifyAll skips the line field's OnValidate and never asks the user.
tableextension 50180 "Sales Header Handling Class" extends "Sales Header"
{
    fields
    {
        field(50180; "Handling Class"; Code[10])
        {
            Caption = 'Handling Class';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
            begin
                SalesLine.SetRange("Document Type", "Document Type");
                SalesLine.SetRange("Document No.", "No.");
                SalesLine.ModifyAll("Handling Class", "Handling Class");
            end;
        }
    }
}
