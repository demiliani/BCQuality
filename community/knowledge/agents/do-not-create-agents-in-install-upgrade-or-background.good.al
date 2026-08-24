page 50100 "Sales Review Agent Setup"
{
    PageType = ConfigurationDialog;
    ApplicationArea = All;
    SourceTable = "Sales Review Agent Setup";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Agent: Codeunit Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        AgentUserSecurityId: Guid;
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        AgentUserSecurityId := Agent.Create(
            Enum::"Agent Metadata Provider"::"Sales Review Agent",
            'SALESREVIEW',
            'Sales Review Agent',
            TempAgentAccessControl);
        Agent.SetInstructions(AgentUserSecurityId, GetInstructions());
        Agent.Activate(AgentUserSecurityId);
        exit(true);
    end;

    local procedure GetInstructions() Instructions: SecretText
    var
        InstructionsNameTxt: Label 'Instructions.txt', Locked = true;
    begin
        Instructions := NavApp.GetResourceAsText(InstructionsNameTxt);
    end;
}
