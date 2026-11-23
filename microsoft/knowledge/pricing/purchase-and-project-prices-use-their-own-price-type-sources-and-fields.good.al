// Demonstration only; independently authored, not copied from BaseApp.
// Assumes "Price Agreement No." on Price List Line, Purchase Line and Job Planning Line.
codeunit 50110 "Project Cost Prices"
{
    procedure CreateProjectResourceCostList(JobNo: Code[20]; ResourceNo: Code[20]; UnitCost: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.Init();
        // The project source group does not derive the price type: set it first.
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Purchase;
        PriceListHeader.Validate("Source Type", "Price Source Type"::Job);
        PriceListHeader.Validate("Source No.", JobNo);
        PriceListHeader.Insert(true); // number series from Jobs Setup

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine.SetNextLineNo();
        PriceListLine.CopyFrom(PriceListHeader);
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.Validate("Asset No.", ResourceNo);
        // Project cost of a resource: Unit Cost and Direct Unit Cost, not Unit Price.
        PriceListLine.Validate("Unit Cost", UnitCost);
        PriceListLine.Validate("Direct Unit Cost", DirectUnitCost);
        PriceListLine.Insert(true);

        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);
        exit(PriceListHeader.Code);
    end;

    // Each document type publishes its own OnAfterSetPrice with its own parameters.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase Line - Price", 'OnAfterSetPrice', '', false, false)]
    local procedure CopyAgreementToPurchaseLine(var PurchaseLine: Record "Purchase Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; CurrPriceType: Enum "Price Type"; var PurchaseHeader: Record "Purchase Header")
    begin
        if (AmountType <> AmountType::Price) or (CurrPriceType <> CurrPriceType::Purchase) then
            exit;
        if PriceListLine.IsRealLine() then
            PurchaseLine."Price Agreement No." := PriceListLine."Price Agreement No."
        else
            PurchaseLine."Price Agreement No." := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Planning Line - Price", 'OnAfterSetPrice', '', false, false)]
    local procedure CopyAgreementToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; CurrPriceType: Enum "Price Type")
    begin
        // The planning line is priced twice: Sale for the price, Purchase for the cost.
        if (AmountType <> AmountType::Price) or (CurrPriceType <> CurrPriceType::Sale) then
            exit;
        if PriceListLine.IsRealLine() then
            JobPlanningLine."Price Agreement No." := PriceListLine."Price Agreement No."
        else
            JobPlanningLine."Price Agreement No." := '';
    end;
}
