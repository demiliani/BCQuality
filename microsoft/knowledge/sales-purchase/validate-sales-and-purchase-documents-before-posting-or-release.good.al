// Demonstration only; independently authored, not copied from BaseApp.
// Assumes Sales Header and Purchase Header extensions with "Delivery Window" and "Supplier Contract Ref." fields.
codeunit 50190 "Document Rules"
{
    // Must stop every posting, preview included: check phase, before any entry is written.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckSalesDoc', '', false, false)]
    local procedure CheckSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesHeader.TestField("Delivery Window");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckPurchDoc', '', false, false)]
    local procedure CheckPurchDoc(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice then
            PurchHeader.TestField("Supplier Contract Ref.");
    end;

    // A rule about releasing the order: the header is passed as Sender.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCheckSalesReleaseRestrictions', '', false, false)]
    local procedure CheckSalesRelease(var Sender: Record "Sales Header")
    begin
        if Sender."Document Type" = Sender."Document Type"::Order then
            Sender.TestField("Delivery Window");
    end;
}
