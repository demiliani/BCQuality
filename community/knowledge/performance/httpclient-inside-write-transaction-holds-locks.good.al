codeunit 50100 "HttpClient Holds Locks Good"
{
    procedure SyncCustomerLastName(var Customer: Record Customer)
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        Customer."Search Name" := Customer.Name;
        Customer.Modify(false);
        Commit();
        Client.Get(StrSubstNo('https://example.local/sync/%1', Customer."No."), Response);
    end;
}
