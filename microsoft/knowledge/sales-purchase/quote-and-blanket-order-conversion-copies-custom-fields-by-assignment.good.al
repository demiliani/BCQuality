// Demonstration only; independently authored, not copied from BaseApp.
// Assumes Sales Header field 50130 "Delivery Window" Code[20]
// and field 50131 "Committed Qty." Decimal on Sales Line and Purchase Line, in table extensions.
codeunit 50130 "Delivery Window Conversion"
{
    // Default only when empty: a converted order keeps the quote's value.
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitRecord', '', false, false)]
    local procedure DefaultDeliveryWindow(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Delivery Window" = '' then
            SalesHeader."Delivery Window" := 'STANDARD';
    end;

    // Quantity-based custom field: reset like the standard quantity fields.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Sales Order to Order", 'OnAfterResetQuantityFields', '', false, false)]
    local procedure ResetCommittedQty(var SalesLine: Record "Sales Line")
    begin
        SalesLine."Committed Qty." := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Purch. Order to Order", 'OnAfterResetQuantityFields', '', false, false)]
    local procedure ResetCommittedQtyPurch(var TempPurchLine: Record "Purchase Line")
    begin
        TempPurchLine."Committed Qty." := 0;
    end;
}
