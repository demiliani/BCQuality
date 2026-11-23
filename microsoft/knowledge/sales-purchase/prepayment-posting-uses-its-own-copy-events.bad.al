// Demonstration only; independently authored, not copied from BaseApp.
// Only the normal invoice copy event: prepayment invoices never raise it.
codeunit 50140 "Prepayment Field Flow"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', false, false)]
    local procedure HeaderToJnlLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Delivery Window" := SalesHeader."Delivery Window";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforeSalesInvLineInsert', '', false, false)]
    local procedure OrderLineToPostedLine(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        // With Compress Prepayment on, the buffer line number is 0 and this Get fails.
        if SalesLine.Get(SalesLine."Document Type"::Order, SalesInvHeader."Prepayment Order No.", PrepmtInvLineBuffer."Line No.") then
            SalesInvLine."Project Ref." := SalesLine."Project Ref.";
    end;
}
