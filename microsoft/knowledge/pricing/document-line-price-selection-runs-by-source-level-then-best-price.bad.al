// Demonstration only; independently authored, not copied from BaseApp.
// Replaces the price calculation with its own Price List Line query.
// Assumes the Customer table extension from the good sample.
// It ignores line status, ending dates, minimum quantity, source levels,
// currency, unit of measure and VAT conversion, and rounding.
codeunit 50100 "Parent Customer Price Source"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnUpdateUnitPriceOnBeforeFindPrice', '', false, false)]
    local procedure UseParentCustomerPrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean; xSalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
    begin
        if not Customer.Get(SalesHeader."Bill-to Customer No.") then
            exit;
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.SetRange("Source No.", Customer."Price Parent Customer No.");
        PriceListLine.SetRange("Asset No.", SalesLine."No.");
        if PriceListLine.FindFirst() then begin
            SalesLine."Unit Price" := PriceListLine."Unit Price";
            IsHandled := true;
        end;
    end;
}
