codeunit 50100 "Login Subscriber IO Good"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterLogin, '', false, false)]
    local procedure OnAfterLogin()
    begin
        // Guard to interactive sessions only; background task sessions also raise OnAfterLogin.
        if not (Session.GetCurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop, ClientType::Tablet, ClientType::Phone]) then
            exit;

        // Idempotent: skip if a task for this codeunit is already queued.
        if TaskScheduler.TaskExists(Codeunit::"Login Subscriber IO Work") then
            exit;

        // Defer the I/O work; CreateTask is the only write allowed on this path.
        TaskScheduler.CreateTask(Codeunit::"Login Subscriber IO Work", 0, true, CompanyName(), CurrentDateTime() + 60000);
    end;
}

codeunit 50101 "Login Subscriber IO Work"
{
    trigger OnRun()
    begin
        // Isolated from session creation: outbound I/O is safe here.
    end;
}
