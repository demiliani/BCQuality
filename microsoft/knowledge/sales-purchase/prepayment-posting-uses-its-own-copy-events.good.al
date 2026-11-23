// Demonstration only; independently authored, not copied from BaseApp.
// "Delivery Window" (field 50100) is on Sales Header, Gen. Journal Line and Cust. Ledger Entry.
// "Project Ref." (field 50140, Code[20]) is on Sales Line, Prepayment Inv. Line Buffer and Sales Invoice Line.
codeunit 50140 "Prepayment Field Flow"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost', '', false, false)]
    local procedure HeaderToCustomerJnlLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Delivery Window" := SalesHeader."Delivery Window";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prepayment Inv. Line Buffer", 'OnAfterCopyFromSalesLine', '', false, false)]
    local procedure LineToBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line")
    begin
        PrepaymentInvLineBuffer."Project Ref." := SalesLine."Project Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforeSalesInvLineInsert', '', false, false)]
    local procedure BufferToPostedLine(var SalesInvLine: Record "Sales Invoice Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
        SalesInvLine."Project Ref." := PrepmtInvLineBuffer."Project Ref.";
    end;
}
