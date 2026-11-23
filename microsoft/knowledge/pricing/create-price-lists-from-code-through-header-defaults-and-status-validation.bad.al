// Demonstration only; independently authored, not copied from BaseApp.
// The line keeps Price Type Any, Status Draft and a blank Source Group, and the header is
// marked Active without the Status validation, so its lines are never activated.
// No document finds this price.
codeunit 50106 "Create Customer Price List"
{
    procedure CreateActivePriceList(CustomerNo: Code[20]; ItemNo: Code[20]; UnitPrice: Decimal; StartingDate: Date): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.Code := CopyStr(CustomerNo, 1, MaxStrLen(PriceListHeader.Code));
        PriceListHeader."Source Type" := "Price Source Type"::Customer;
        PriceListHeader."Source No." := CustomerNo;
        PriceListHeader."Starting Date" := StartingDate;
        PriceListHeader.Insert();

        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 10000;
        PriceListLine."Source Type" := "Price Source Type"::Customer;
        PriceListLine."Source No." := CustomerNo;
        PriceListLine."Asset Type" := "Price Asset Type"::Item;
        PriceListLine."Asset No." := ItemNo;
        PriceListLine."Unit Price" := UnitPrice;
        PriceListLine.Insert();

        PriceListHeader.Status := "Price Status"::Active;
        PriceListHeader.Modify();
        exit(PriceListHeader.Code);
    end;
}
