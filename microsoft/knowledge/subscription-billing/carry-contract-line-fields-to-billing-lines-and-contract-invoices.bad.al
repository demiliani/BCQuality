// Demonstration only; independently authored, not copied from BaseApp.
// The billing line gets its Document No. only after the sales line is inserted,
// so this filter finds nothing and the invoice line stays blank.
codeunit 50110 "CC Ref Billing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnBeforeInsertSalesLineFromContractLine, '', false, false)]
    local procedure TempLineToSalesLine(var SalesLine: Record "Sales Line"; var TempBillingLine: Record "Billing Line" temporary)
    var
        BillingLine: Record "Billing Line";
    begin
        BillingLine.SetRange("Document No.", SalesLine."Document No.");
        BillingLine.SetRange("Document Line No.", SalesLine."Line No.");
        if BillingLine.FindFirst() then
            SalesLine."Cost Center Ref." := BillingLine."Cost Center Ref.";
    end;
}
