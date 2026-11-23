// Demonstration only; independently authored, not copied from BaseApp.
// Creates an active customer price list with one item price.
codeunit 50106 "Create Customer Price List"
{
    procedure CreateActivePriceList(CustomerNo: Code[20]; ItemNo: Code[20]; UnitPrice: Decimal; StartingDate: Date): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.Init();
        // Source Type sets Price Type Sale and Source Group Customer.
        PriceListHeader.Validate("Source Type", "Price Source Type"::Customer);
        PriceListHeader.Validate("Source No.", CustomerNo);
        PriceListHeader.Validate("Starting Date", StartingDate);
        // Blank Code: the number series in Sales & Receivables Setup supplies it.
        PriceListHeader.Insert(true);

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.SetNextLineNo();
        // Price Type, Status Draft, source, dates, currency and discount defaults from the header.
        PriceListLine.CopyFrom(PriceListHeader);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Unit Price", UnitPrice);
        PriceListLine.Insert(true);

        // Verifies source and lines, resolves duplicates and activates every line.
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);
        exit(PriceListHeader.Code);
    end;

    procedure UpdatePriceInActiveList(var PriceListLine: Record "Price List Line"; NewUnitPrice: Decimal)
    var
        PriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
    begin
        // Requires Allow Editing Active Price; Modify(true) turns the line back to Draft.
        PriceListLine.Validate("Unit Price", NewUnitPrice);
        PriceListLine.Modify(true);
        PriceListHeader.Get(PriceListLine."Price List Code");
        PriceListManagement.ActivateDraftLines(PriceListHeader, true);
    end;
}
