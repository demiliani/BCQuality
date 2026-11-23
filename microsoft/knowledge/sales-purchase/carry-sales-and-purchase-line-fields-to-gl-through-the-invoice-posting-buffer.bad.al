// Demonstration only; independently authored, not copied from BaseApp.
// Wrong publisher, and the field is not part of the Group ID.
codeunit 50200 "Product Line G/L Posting"
{
    // The event is published by "Sales Post Invoice Events", not by "Sales Post Invoice".
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice", 'OnPrepareLineOnAfterFillInvoicePostingBuffer', '', false, false)]
    local procedure FillFromSalesLine(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        InvoicePostingBuffer."Product Line Code" := SalesLine."Product Line Code";
    end;

    // No OnAfterBuildPrimaryKey subscriber: lines with different product lines merge,
    // and the G/L entry keeps only the first line's value.
    [EventSubscriber(ObjectType::Table, Database::"Invoice Posting Buffer", 'OnAfterCopyToGenJnlLine', '', false, false)]
    local procedure CopyToJournalLine(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        GenJnlLine."Product Line Code" := InvoicePostingBuffer."Product Line Code";
    end;
}
