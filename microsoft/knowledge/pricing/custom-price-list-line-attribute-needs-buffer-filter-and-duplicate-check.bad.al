// Demonstration only; independently authored, not copied from BaseApp.
// Assumes the table extensions from the good sample.
// SetRange removes every generic price list line (blank channel) from the calculation,
// and the channel is missing from the duplicate filters, so two channel prices for the
// same item are reported as duplicates when the price list is activated.
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
        PriceListLine.SetRange("Sales Channel Code", PriceCalculationBuffer."Sales Channel Code");
    end;
}
