// Demonstration only; independently authored, not copied from BaseApp.
// Same field number on source and IC outbox tables (TransferFields); events for the field-by-field hops.
// Assumes field 50180 "Project Ref." Code[20] on Sales Header, Sales Line, Sales Invoice Header, Sales Invoice Line,
// IC Outbox Sales Header/Line, IC Inbox Purchase Header/Line, Purchase Header and Purchase Line.
codeunit 50180 "IC Project Ref. Transfer"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnBeforeICInboxPurchHeaderInsert', '', false, false)]
    local procedure OutboxToInboxHeader(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
        // May run in the sending company: copy only, read no company setup.
        ICInboxPurchaseHeader."Project Ref." := ICOutboxSalesHeader."Project Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnBeforeICInboxPurchLineInsert', '', false, false)]
    local procedure OutboxToInboxLine(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
        ICInboxPurchaseLine."Project Ref." := ICOutboxSalesLine."Project Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnCreatePurchDocumentOnBeforePurchHeaderModify', '', false, false)]
    local procedure InboxToPurchaseHeader(var PurchHeader: Record "Purchase Header"; ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    begin
        PurchHeader."Project Ref." := ICInboxPurchHeader."Project Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnCreatePurchLinesOnBeforeModify', '', false, false)]
    local procedure InboxToPurchaseLine(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
        // After Validate("No."), which cleared the value copied by TransferFields.
        PurchaseLine."Project Ref." := ICInboxPurchLine."Project Ref.";
    end;
}
