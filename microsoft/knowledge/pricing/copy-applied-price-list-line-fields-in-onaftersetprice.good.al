// Demonstration only; independently authored, not copied from BaseApp.
// A price list line carries a "Price Agreement No." that must appear on the sales line
// whose unit price came from that price list line.
tableextension 50101 "Price List Line Agreement" extends "Price List Line"
{
    fields
    {
        field(50101; "Price Agreement No."; Code[20])
        {
            Caption = 'Price Agreement No.';
            DataClassification = CustomerContent;
        }
    }
}

// Same field number, so the price worksheet keeps the value (TransferFields).
tableextension 50102 "Price Wksh. Line Agreement" extends "Price Worksheet Line"
{
    fields
    {
        field(50101; "Price Agreement No."; Code[20])
        {
            Caption = 'Price Agreement No.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50103 "Sales Line Agreement" extends "Sales Line"
{
    fields
    {
        field(50101; "Price Agreement No."; Code[20])
        {
            Caption = 'Price Agreement No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50101 "Price Agreement Copy"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line - Price", 'OnAfterSetPrice', '', false, false)]
    local procedure CopyAgreementToSalesLine(var SalesLine: Record "Sales Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var SalesHeader: Record "Sales Header")
    begin
        // The discount pass passes its own price list line.
        if AmountType <> AmountType::Price then
            exit;
        // Resource lines also run this codeunit with the Purchase price type for the unit cost.
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if PriceListLine.IsRealLine() then
            SalesLine."Price Agreement No." := PriceListLine."Price Agreement No."
        else
            // Fallback to the item card price: no agreement applies.
            SalesLine."Price Agreement No." := '';
    end;
}
