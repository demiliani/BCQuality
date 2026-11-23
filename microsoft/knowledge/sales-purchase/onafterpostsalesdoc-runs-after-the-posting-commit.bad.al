// Demonstration only; independently authored, not copied from BaseApp.
// Calls the service even in posting preview and errors after the posting is already committed.
codeunit 50130 "Delivery Notice Sender"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure SendDeliveryNotice(SalesInvHdrNo: Code[20])
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if not Client.Get('https://delivery.example.com/notify?invoice=' + SalesInvHdrNo, Response) then
            Error(NoticeFailedErr);
        if not Response.IsSuccessStatusCode() then
            Error(NoticeFailedErr);
    end;

    var
        NoticeFailedErr: Label 'The delivery notice could not be sent. Posting was cancelled.';
}
