codeunit 50100 "Sales Review Agent Task"
{
    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    var
        AgentMessage: Codeunit "Agent Message";
        NotRelevantMsg: Label 'Message is not a sales order task.';
        NotRelevantDetailsTxt: Label 'Provide a message related to sales order review.';
    begin
        if AgentTaskMessage.Type = AgentTaskMessage.Type::Output then begin
            AgentMessage.UpdateText(AgentTaskMessage, AgentMessage.GetText(AgentTaskMessage) + '\n\nWritten with the help of AI');
            exit;
        end;
        if not IsRelevant(AgentMessage.GetText(AgentTaskMessage)) then begin
            Annotations.Code := 'RELEVANCE001';
            Annotations.Severity := Annotations.Severity::Warning;
            Annotations.Message := NotRelevantMsg;
            Annotations.Details := NotRelevantDetailsTxt;
            Annotations.Insert();
        end;
    end;

    local procedure IsRelevant(MessageText: Text): Boolean
    begin
        exit(MessageText <> '');
    end;
}
