// Demonstration only; independently authored, not copied from BaseApp.
// Copies a custom reference and a custom amount to G/L entries and negates the amount on reversal.
// Assumes "Contract No." Code[20] and "Contract Amount" Decimal on Gen. Journal Line and G/L Entry,
// with the same field numbers on both tables.
codeunit 50180 "Contract G/L Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToGLEntry(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."Contract No." := GenJournalLine."Contract No.";
        GLEntry."Contract Amount" := GenJournalLine."Contract Amount";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseGLEntryOnBeforeInsertGLEntry', '', false, false)]
    local procedure NegateOnReversal(var GLEntry: Record "G/L Entry"; GLEntry2: Record "G/L Entry")
    begin
        // The reversing entry was copied from the original; the reference stays, the amount is negated.
        GLEntry."Contract Amount" := -GLEntry2."Contract Amount";
    end;
}
