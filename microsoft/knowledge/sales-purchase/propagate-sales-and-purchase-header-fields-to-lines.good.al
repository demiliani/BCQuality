// Demonstration only; independently authored, not copied from BaseApp.
// Assumes a Sales Line and a Purchase Line extension with field 50180 "Handling Class" Code[10].
tableextension 50180 "Sales Header Handling Class" extends "Sales Header"
{
    fields
    {
        field(50180; "Handling Class"; Code[10])
        {
            Caption = 'Handling Class';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Handling Class"), CurrFieldNo <> 0);
            end;
        }
    }
}

tableextension 50181 "Purch. Header Handling Class" extends "Purchase Header"
{
    fields
    {
        field(50180; "Handling Class"; Code[10])
        {
            Caption = 'Handling Class';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo("Handling Class"), CurrFieldNo <> 0);
            end;
        }
    }
}

codeunit 50180 "Handling Class Line Update"
{
    // Sales: singular "Line" in the event name.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnUpdateSalesLineByChangedFieldName', '', false, false)]
    local procedure UpdateSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer)
    begin
        if ChangedFieldNo = SalesHeader.FieldNo("Handling Class") then
            SalesLine.Validate("Handling Class", SalesHeader."Handling Class");
    end;

    // Purchases: plural "Lines" in the event name.
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnUpdatePurchLinesByChangedFieldName', '', false, false)]
    local procedure UpdatePurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ChangedFieldNo: Integer)
    begin
        if ChangedFieldNo = PurchHeader.FieldNo("Handling Class") then
            PurchLine.Validate("Handling Class", PurchHeader."Handling Class");
    end;
}
