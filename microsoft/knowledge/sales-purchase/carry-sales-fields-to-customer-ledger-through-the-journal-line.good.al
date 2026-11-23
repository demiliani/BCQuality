// Demonstration only; independently authored, not copied from BaseApp.
// The value travels Sales Header -> Gen. Journal Line -> Cust. Ledger Entry during posting.
// Assumes the Sales Header table extension with field 50100 "Delivery Window" Code[20].
tableextension 50110 "Gen. Jnl. Line Delivery Window" extends "Gen. Journal Line"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50111 "Cust. Ledg. Delivery Window" extends "Cust. Ledger Entry"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50110 "Delivery Window Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', false, false)]
    local procedure CopyToJournalLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Delivery Window" := SalesHeader."Delivery Window";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Delivery Window" := GenJournalLine."Delivery Window";
    end;
}
