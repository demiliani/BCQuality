// Demonstration only; independently authored, not copied from BaseApp.
// Skips preview and records an outbox row; a recurring job queue entry sends it later.
table 50130 "Delivery Notice Outbox"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
        }
        field(2; "Sales Invoice No."; Code[20])
        {
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}

codeunit 50130 "Delivery Notice Scheduler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure QueueDeliveryNotice(SalesInvHdrNo: Code[20]; PreviewMode: Boolean)
    var
        DeliveryNoticeOutbox: Record "Delivery Notice Outbox";
    begin
        if PreviewMode then
            exit;
        if SalesInvHdrNo = '' then
            exit;

        DeliveryNoticeOutbox.Init();
        DeliveryNoticeOutbox."Sales Invoice No." := SalesInvHdrNo;
        DeliveryNoticeOutbox.Insert();
    end;
}

codeunit 50131 "Send Delivery Notices"
{
    // Run by a recurring job queue entry. Send each row with its SystemId as the
    // idempotency key, then delete the row only after the call succeeds.
    trigger OnRun()
    var
        DeliveryNoticeOutbox: Record "Delivery Notice Outbox";
    begin
        if DeliveryNoticeOutbox.FindSet() then
            repeat
                // Call the external service here.
            until DeliveryNoticeOutbox.Next() = 0;
    end;
}
