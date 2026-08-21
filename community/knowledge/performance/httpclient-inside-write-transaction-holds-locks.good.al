codeunit 50100 "HttpClient Holds Locks Good"
{
    // Write completes inside the caller's transaction; HTTP deferred so locks are released with it.
    procedure SyncCustomerLastName(var Customer: Record Customer)
    begin
        Customer."Search Name" := Customer.Name;
        Customer.Modify(false);
        TaskScheduler.CreateTask(Codeunit::"Customer Sync Task", 0, true, CompanyName(), CurrentDateTime());
    end;
}

codeunit 50101 "Customer Sync Task"
{
    trigger OnRun()
    var
        Client: HttpClient;
        Customer: Record Customer;
        Response: HttpResponseMessage;
    begin
        // Separate session: no write-transaction lock is held during the HTTP call.
        if Customer.FindSet() then
            repeat
                Client.Get(StrSubstNo('https://example.local/sync/%1', Customer."No."), Response);
            until Customer.Next() = 0;
    end;
}
