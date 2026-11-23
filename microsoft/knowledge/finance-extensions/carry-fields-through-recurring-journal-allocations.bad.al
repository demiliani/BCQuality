// Demonstration only; independently authored, not copied from BaseApp.
// No recurring-line copy, and a conditional per-allocation copy that leaks between allocations.
codeunit 50170 "Recurring Allocation Fields"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromGenJnlAllocation', '', false, false)]
    local procedure CopyFromAllocation(GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        // A blank allocation keeps the previous allocation's value.
        if GenJnlAllocation."Cost Pool" <> '' then
            GenJournalLine."Cost Pool" := GenJnlAllocation."Cost Pool";
        // "Contract Ref." is never set: PostAllocations started the line with Init().
    end;
}
