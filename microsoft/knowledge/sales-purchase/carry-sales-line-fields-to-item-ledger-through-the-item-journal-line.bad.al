// Demonstration only; independently authored, not copied from BaseApp.
// Patches posted item ledger entries after the posting commit.
codeunit 50120 "Batch Ref. Item Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PatchItemEntries(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                ItemLedgerEntry.SetRange("Document No.", SalesShptHdrNo);
                ItemLedgerEntry.SetRange("Document Line No.", SalesLine."Line No.");
                ItemLedgerEntry.ModifyAll("Customer Batch Ref.", SalesLine."Customer Batch Ref.");
            until SalesLine.Next() = 0;
    end;
}
