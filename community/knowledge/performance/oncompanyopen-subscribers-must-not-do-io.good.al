codeunit 50100 "Login Subscriber IO Good"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterLogin, '', false, false)]
    local procedure OnAfterLogin()
    begin
        // Defer HTTP and heavy SQL to a job; session open must return immediately.
        TaskScheduler.CreateTask(Codeunit::"Login Subscriber IO Work", Codeunit::"Login Subscriber IO Work", true, CompanyName(), CurrentDateTime());
    end;
}

codeunit 50101 "Login Subscriber IO Work"
{
    trigger OnRun()
    begin
        // Isolated from session creation: outbound I/O is safe here.
    end;
}
