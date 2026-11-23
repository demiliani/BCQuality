// Demonstration only; independently authored, not copied from BaseApp.
// Patches the posted customer entry after the posting commit.
codeunit 50110 "Delivery Window Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PatchCustomerEntry(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvHdrNo);
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry."Delivery Window" := SalesHeader."Delivery Window";
            CustLedgerEntry.Modify();
        end;
    end;
}
