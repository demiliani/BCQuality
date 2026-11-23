// Demonstration only; independently authored, not copied from BaseApp.
// "Price Agreement No." lives on Price List Line and has a twin with the same field
// number on Price Worksheet Line, so the worksheet round trip keeps it.
tableextension 50108 "Price List Line Review" extends "Price List Line"
{
    fields
    {
        field(50108; "Price Review Date"; Date)
        {
            Caption = 'Price Review Date';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50109 "Price Wksh. Line Review" extends "Price Worksheet Line"
{
    fields
    {
        // Same number, name and type: TransferFields copies it in both directions.
        field(50108; "Price Review Date"; Date)
        {
            Caption = 'Price Review Date';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50108 "Price Review Date Defaults"
{
    // Suggest Lines builds lines from the item, so it cannot know a review date.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price List Management", 'OnAddLineOnAfterPopulatePriceListLineFields', '', false, false)]
    local procedure SetReviewDateOnSuggestedLine(var PriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header"; PriceAsset: Record "Price Asset"; PriceLineFilters: Record "Price Line Filters")
    begin
        PriceListLine."Price Review Date" := CalcDate('<+1Y>', WorkDate());
    end;

    // Copied lines keep the source value; a copy with new amounts gets a new review date.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price List Management", 'OnCopyLineOnAfterAdjustAmounts', '', false, false)]
    local procedure SetReviewDateOnCopiedLine(var ToPriceListLine: Record "Price List Line"; PriceLineFilters: Record "Price Line Filters"; var FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header")
    begin
        if PriceLineFilters."Adjustment Factor" <> 1 then
            ToPriceListLine."Price Review Date" := CalcDate('<+1Y>', WorkDate());
    end;
}
