// Demonstration only; "Loyalty Points Earned" is a Decimal extension field on Sales Invoice Line.
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Document;

codeunit 50196 "Invoice Loyalty Points"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesInvLineInsert', '', false, false)]
    local procedure SetLoyaltyPoints(var SalesInvLine: Record "Sales Invoice Line"; SalesLine: Record "Sales Line")
    begin
        if SalesInvLine.Type = SalesInvLine.Type::Item then
            SalesInvLine."Loyalty Points Earned" := 2 * SalesLine.Quantity;
    end;
}
