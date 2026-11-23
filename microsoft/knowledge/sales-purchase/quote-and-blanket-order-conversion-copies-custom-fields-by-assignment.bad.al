// Demonstration only; independently authored, not copied from BaseApp.
// The default overwrites the quote's value; a second subscriber patches it back with Modify.
codeunit 50130 "Delivery Window Conversion"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitRecord', '', false, false)]
    local procedure DefaultDeliveryWindow(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Delivery Window" := 'STANDARD';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnAfterOnRun', '', false, false)]
    local procedure CopyFromQuote(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
        SalesOrderHeader."Delivery Window" := SalesHeader."Delivery Window";
        SalesOrderHeader.Modify();
    end;
}
