// Demonstration only; independently authored, not copied from BaseApp.
// The line is already inserted and linked to its billing line. Modify(true)
// fires the app's Sales Line OnBeforeModifyEvent check and billing fails.
// Assumes the "Region Code" field on "Cust. Sub. Contract Line".
codeunit 50112 "Region Dimension Billing"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnAfterInsertSalesLineFromBillingLine, '', false, false)]
    local procedure SetRegionAfterInsert(CustomerContractLine: Record "Cust. Sub. Contract Line"; SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Shortcut Dimension 2 Code", CustomerContractLine."Region Code");
        SalesLine.Modify(true); // error: dimensions of a contract-linked line cannot change
    end;
}
