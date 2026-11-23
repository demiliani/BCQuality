// Demonstration only; independently authored, not copied from BaseApp.
// Assumes the app's own "Service Request" table and "Service Request Mgt." codeunit with OnAfterApproveServiceRequest.
// Version 2 of the app: the payload gained a warehouse code, so 2.0 is added and 1.0 is obsoleted.
enumextension 50120 "Service Request Event Category" extends EventCategory
{
    value(50120; "Service Requests")
    {
        Caption = 'Service Requests';
    }
}

codeunit 50120 "Service Request Business Events"
{
    [ExternalBusinessEvent('ServiceRequestApproved', '[OBSOLETE] Service request approved', 'Raised when a service request is approved.', Enum::EventCategory::"Service Requests", '1.0')]
    [Obsolete('Replaced by version 2.0 of ServiceRequestApproved.', '2.0')]
    local procedure ServiceRequestApproved(ServiceRequestId: Guid; RequestNo: Code[20])
    begin
    end;

    [ExternalBusinessEvent('ServiceRequestApproved', 'Service request approved', 'Raised when a service request is approved.', Enum::EventCategory::"Service Requests", '2.0')]
    local procedure ServiceRequestApprovedV2(ServiceRequestId: Guid; RequestNo: Code[20]; WarehouseCode: Code[10])
    begin
    end;

    // Raised inside the approval transaction: the platform sends the notification only after commit.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Request Mgt.", 'OnAfterApproveServiceRequest', '', false, false)]
    local procedure RaiseOnApproval(var ServiceRequest: Record "Service Request")
    begin
        ServiceRequestApproved(ServiceRequest.SystemId, ServiceRequest."No.");
        ServiceRequestApprovedV2(ServiceRequest.SystemId, ServiceRequest."No.", ServiceRequest."Warehouse Code");
    end;
}
