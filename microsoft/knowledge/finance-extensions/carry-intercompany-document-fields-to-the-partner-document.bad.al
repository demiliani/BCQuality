// Demonstration only; independently authored, not copied from BaseApp.
// Trusts equal field numbers for every hop and copies the line value too early.
codeunit 50180 "IC Project Ref. Transfer"
{
    // No OnBeforeICInboxPurchHeaderInsert subscriber: the inbox header is built field by field,
    // so "Project Ref." is blank in the partner's inbox and on the partner's purchase header.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnCreatePurchLinesOnAfterTransferFields', '', false, false)]
    local procedure InboxToPurchaseLine(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
        // Validate("No.") runs after this event and clears the value again.
        PurchaseLine."Project Ref." := ICInboxPurchLine."Project Ref.";
    end;
}
