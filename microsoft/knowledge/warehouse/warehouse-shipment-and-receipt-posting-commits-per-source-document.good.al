// Demonstration only; independently authored, not copied from BaseApp.
// Per-document follow-up after warehouse-driven sales posting.
// Assumes table 50146 "Seal Notification Queue" (Entry No. autoincrement, Shipment No., Seal No.).
// "Carrier Seal No." already reached the Sales Header before posting (see the source-document article).
codeunit 50145 "Seal Follow-up"
{
    // Raised once per source document, after that document's commit, with WhseShip = true
    // when Whse.-Post Shipment posted it.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure QueueSealNotification(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20]; CommitIsSuppressed: Boolean; WhseShip: Boolean; PreviewMode: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SealNotificationQueue: Record "Seal Notification Queue";
    begin
        if PreviewMode or not WhseShip or (SalesShptHdrNo = '') then
            exit;
        if not SalesShipmentHeader.Get(SalesShptHdrNo) then
            exit;
        if SalesShipmentHeader."Carrier Seal No." = '' then
            exit;

        // Outbox row only; a job queue entry sends it later. No Commit here, even when commit is suppressed.
        SealNotificationQueue.Init();
        SealNotificationQueue."Shipment No." := SalesShipmentHeader."No.";
        SealNotificationQueue."Seal No." := SalesShipmentHeader."Carrier Seal No.";
        SealNotificationQueue.Insert(true);
    end;
}
