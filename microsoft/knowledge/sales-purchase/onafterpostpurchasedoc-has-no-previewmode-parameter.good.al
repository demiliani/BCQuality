// Demonstration only; independently authored, not copied from BaseApp.
// Detects preview through Gen. Jnl.-Post Preview and records an outbox row for a recurring job.
// Assumes an outbox table "Supplier Notice Outbox" with an AutoIncrement key and a "Purch. Invoice No." field.
codeunit 50160 "Supplier Notice Scheduler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure QueueSupplierNotice(PurchInvHdrNo: Code[20])
    var
        SupplierNoticeOutbox: Record "Supplier Notice Outbox";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if GenJnlPostPreview.IsActive() then
            exit;
        if PurchInvHdrNo = '' then
            exit;

        SupplierNoticeOutbox.Init();
        SupplierNoticeOutbox."Purch. Invoice No." := PurchInvHdrNo;
        SupplierNoticeOutbox.Insert();
    end;
}
