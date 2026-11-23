// Demonstration only; independently authored, not copied from BaseApp.
// Copies a custom amount to G/L entries but ignores reversal: the reversing entry keeps the original sign.
codeunit 50180 "Contract G/L Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToGLEntry(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."Contract No." := GenJournalLine."Contract No.";
        GLEntry."Contract Amount" := GenJournalLine."Contract Amount";
    end;
}
