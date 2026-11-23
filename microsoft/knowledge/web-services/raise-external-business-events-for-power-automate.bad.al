// Demonstration only; independently authored, not copied from BaseApp.
// Version 2 of the app edits the shipped 1.0 event in place and also calls a flow URL from the transaction.
codeunit 50120 "Service Request Business Events"
{
    // Was ('ServiceRequestApproved', ..., '1.0') with (ServiceRequestId; RequestNo) in version 1.
    [ExternalBusinessEvent('ServiceRequestApproved', 'Service request approved', 'Raised when a service request is approved.', Enum::EventCategory::"Service Requests", '2.0')]
    local procedure ServiceRequestApproved(ServiceRequestId: Guid; WarehouseCode: Code[10])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Request Mgt.", 'OnAfterApproveServiceRequest', '', false, false)]
    local procedure RaiseOnApproval(var ServiceRequest: Record "Service Request")
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
    begin
        ServiceRequestApproved(ServiceRequest.SystemId, ServiceRequest."Warehouse Code");

        // Runs before commit: a later error still leaves the flow triggered.
        Content.WriteFrom(StrSubstNo('{"no":"%1"}', ServiceRequest."No."));
        Client.Post('https://prod-00.westeurope.logic.azure.com/workflows/example/triggers/manual/paths/invoke', Content, Response);
    end;
}
