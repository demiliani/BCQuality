// Demonstration only; independently authored, not copied from BaseApp.
// Copied from a sales subscriber: the purchase event has no PreviewMode parameter, so this does not match the publisher.
codeunit 50160 "Supplier Notice Sender"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure SendSupplierNotice(PurchInvHdrNo: Code[20]; PreviewMode: Boolean)
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if PreviewMode then
            exit;
        Client.Get('https://supplier.example.com/notify?invoice=' + PurchInvHdrNo, Response);
    end;
}
