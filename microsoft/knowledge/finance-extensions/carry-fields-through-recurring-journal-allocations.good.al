// Demonstration only; independently authored, not copied from BaseApp.
// The recurring line's value is set once per allocation run; the per-allocation value is set on every allocation.
// Assumes Gen. Journal Line fields 50170 "Contract Ref." Code[20] and 50171 "Cost Pool" Code[20],
// and a Gen. Jnl. Allocation extension with field 50171 "Cost Pool" Code[20].
codeunit 50170 "Recurring Allocation Fields"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnPostAllocationsOnBeforeCopyFromGenJnlAlloc', '', false, false)]
    local procedure CopyFromRecurringLine(var GenJournalLine: Record "Gen. Journal Line"; var AllocateGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Contract Ref." := AllocateGenJournalLine."Contract Ref.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromGenJnlAllocation', '', false, false)]
    local procedure CopyFromAllocation(GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        // Unconditional, because the same journal line variable is reused for each allocation.
        GenJournalLine."Cost Pool" := GenJnlAllocation."Cost Pool";
    end;
}
