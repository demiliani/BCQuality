// Demonstration only. Shows the wrong pattern: generated text is used without checking whether the call succeeded.

codeunit 50208 "Email Draft Generator Bad"
{
    Access = Internal;

    procedure DraftReminder(var ReminderDraft: Record "Reminder Draft Demo"; CustomerName: Text; Endpoint: Text; Deployment: Text; ApiKey: SecretText)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
    begin
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Endpoint, Deployment, ApiKey);
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Draft Payment Reminder");
        AOAIChatMessages.SetPrimarySystemMessage('Write a polite payment reminder email.');
        AOAIChatMessages.AddUserMessage(CustomerName);
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIOperationResponse);

        // BAD: a failed call does not raise an error; whatever GetLastMessage returns is stored as the draft.
        ReminderDraft."Body Text" := CopyStr(AOAIChatMessages.GetLastMessage(), 1, MaxStrLen(ReminderDraft."Body Text"));
        ReminderDraft.Modify(true);
    end;
}
