// Demonstration only; independently authored, not copied from BaseApp.
// Mirrored field numbers carry the value; follow-up work runs after posting through an outbox.
// Assumes an outbox table "Visit Report Outbox" with an AutoIncrement key and a "Service Invoice No." field.
tableextension 50320 "Service Header Visit Ref." extends "Service Header"
{
    fields
    {
        field(50320; "Visit Reference"; Code[20])
        {
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50321 "Serv. Inv. Header Visit Ref." extends "Service Invoice Header"
{
    fields
    {
        field(50320; "Visit Reference"; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50320 "Visit Report Scheduler"
{
    // Never raised during posting preview, so no preview guard is needed here.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostServiceDoc', '', false, false)]
    local procedure QueueVisitReport(ServInvoiceNo: Code[20])
    var
        VisitReportOutbox: Record "Visit Report Outbox";
    begin
        if ServInvoiceNo = '' then
            exit;
        VisitReportOutbox.Init();
        VisitReportOutbox."Service Invoice No." := ServInvoiceNo;
        VisitReportOutbox.Insert();
    end;
}
