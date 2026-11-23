// Demonstration only; independently authored, not copied from BaseApp.
// Price Type stays Any, so lines copy Price Type Any and no calculation finds them,
// and the cost is written to Unit Price, which neither the purchase nor the project
// cost calculation reads.
codeunit 50110 "Project Cost Prices"
{
    procedure CreateProjectResourceCostList(JobNo: Code[20]; ResourceNo: Code[20]; UnitCost: Decimal): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.Init();
        PriceListHeader.Validate("Source Type", "Price Source Type"::Job);
        PriceListHeader.Validate("Source No.", JobNo);
        PriceListHeader.Insert(true);

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.SetNextLineNo();
        PriceListLine.CopyFrom(PriceListHeader);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.Validate("Asset No.", ResourceNo);
        PriceListLine.Validate("Unit Price", UnitCost);
        PriceListLine.Insert(true);

        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);
        exit(PriceListHeader.Code);
    end;
}
