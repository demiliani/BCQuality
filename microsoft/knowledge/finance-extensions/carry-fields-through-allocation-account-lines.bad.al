// Demonstration only; independently authored, not copied from BaseApp.
// Relies on TransferFields alone, then tries to repair posted results.
codeunit 50160 "Cost Driver Allocation"
{
    // No create-event subscriber: Validate("No.") on each generated line clears "Cost Driver Code".

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure RepairAfterPosting(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Runs after the commit and edits posted documents; the ledger entries stay blank.
        SalesInvoiceLine.SetRange("Document No.", SalesInvHdrNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.ModifyAll("Cost Driver Code", SalesHeader."Cost Driver Code");
    end;
}
