// Demonstration only; independently authored, not copied from BaseApp.
// Copied from a sales subscriber: the service event has no PreviewMode parameter,
// and the external call runs after the posting commit with no way to retry.
codeunit 50320 "Visit Report Sender"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostServiceDoc', '', false, false)]
    local procedure SendVisitReport(ServInvoiceNo: Code[20]; PreviewMode: Boolean)
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if PreviewMode then
            exit;
        Client.Get('https://visits.example.com/report?invoice=' + ServInvoiceNo, Response);
    end;
}
