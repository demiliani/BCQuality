// Demonstration only; independently authored, not copied from BaseApp.
// Sales prices can differ per sales channel. Lines without a channel stay generic.
tableextension 50104 "Price List Line Channel" extends "Price List Line"
{
    fields
    {
        field(50104; "Sales Channel Code"; Code[10])
        {
            Caption = 'Sales Channel Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50105 "Price Wksh. Line Channel" extends "Price Worksheet Line"
{
    fields
    {
        field(50104; "Sales Channel Code"; Code[10])
        {
            Caption = 'Sales Channel Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50106 "Price Calc. Buffer Channel" extends "Price Calculation Buffer"
{
    fields
    {
        field(50104; "Sales Channel Code"; Code[10])
        {
            Caption = 'Sales Channel Code';
            DataClassification = SystemMetadata;
        }
    }
}

tableextension 50107 "Sales Line Channel" extends "Sales Line"
{
    fields
    {
        field(50104; "Sales Channel Code"; Code[10])
        {
            Caption = 'Sales Channel Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                // Plans and runs the recalculation for this field.
                if (Type = Type::Item) and ("No." <> '') then
                    UpdateUnitPrice(FieldNo("Sales Channel Code"));
            end;
        }
    }
}

codeunit 50104 "Sales Channel Pricing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line - Price", 'OnAfterFillBuffer', '', false, false)]
    local procedure FillChannel(var PriceCalculationBuffer: Record "Price Calculation Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        PriceCalculationBuffer."Sales Channel Code" := SalesLine."Sales Channel Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Buffer Mgt.", 'OnAfterSetFilters', '', false, false)]
    local procedure FilterChannel(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var PriceCalculationBuffer: Record "Price Calculation Buffer"; ShowAll: Boolean)
    begin
        if PriceCalculationBuffer."Price Type" <> PriceCalculationBuffer."Price Type"::Sale then
            exit;
        // Specific channel or generic line, like currency and unit of measure.
        PriceListLine.SetFilter("Sales Channel Code", '%1|%2', PriceCalculationBuffer."Sales Channel Code", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V16", 'OnAfterIsImprovedLine', '', false, false)]
    local procedure PreferSpecificChannel(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
        Result := Result or ((BestPriceListLine."Sales Channel Code" = '') and (PriceListLine."Sales Channel Code" <> ''));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V16", 'OnAfterIsDegradedLine', '', false, false)]
    local procedure AvoidGenericChannel(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
        Result := Result or ((BestPriceListLine."Sales Channel Code" <> '') and (PriceListLine."Sales Channel Code" = ''));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price List Management", 'OnAfterSetAssetFilters', '', false, false)]
    local procedure ChannelIsPartOfDuplicateKey(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        DuplicatePriceListLine.SetRange("Sales Channel Code", PriceListLine."Sales Channel Code");
    end;
}
