// Demonstration only; independently authored, not copied from BaseApp.
// Looks the price list line up again after the price was applied.
// The lookup ignores source levels, minimum quantity, currency, line status and the
// best-price choice, so it can return a line other than the one that set the price.
// Assumes the table extensions from the good sample.
codeunit 50101 "Price Agreement Copy"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterApplyPrice', '', false, false)]
    local procedure FindAgreementAgain(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallFieldNo: Integer; CurrentFieldNo: Integer)
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", SalesLine."No.");
        PriceListLine.SetRange("Unit Price", SalesLine."Unit Price");
        if PriceListLine.FindFirst() then
            SalesLine."Price Agreement No." := PriceListLine."Price Agreement No.";
    end;
}
