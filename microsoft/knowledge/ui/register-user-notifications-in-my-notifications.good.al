// Demonstration only; independently authored, not copied from BaseApp.
// Advisory warning on the sales order when the requested delivery date is in the past.
codeunit 50110 "Late Delivery Notification"
{
    var
        NotificationNameTxt: Label 'Requested delivery date is in the past';
        NotificationDescriptionTxt: Label 'Show a warning when a sales order has a requested delivery date before the work date.';
        LateDeliveryMsg: Label 'The requested delivery date of order %1 is in the past.', Comment = '%1 = order number';
        DontShowAgainTxt: Label 'Don''t show again';

    procedure GetNotificationId(): Guid
    begin
        exit('6a1f0c52-3d7e-4b8a-9f21-5c0d7e3a4b10');
    end;

    procedure ShowIfLate(SalesHeader: Record "Sales Header")
    var
        MyNotifications: Record "My Notifications";
        LateNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetNotificationId()) then
            exit;

        LateNotification.Id := GetNotificationId();
        LateNotification.Recall();
        if (SalesHeader."Requested Delivery Date" = 0D) or (SalesHeader."Requested Delivery Date" >= WorkDate()) then
            exit;

        LateNotification.Message(StrSubstNo(LateDeliveryMsg, SalesHeader."No."));
        LateNotification.Scope := NotificationScope::LocalScope;
        LateNotification.AddAction(DontShowAgainTxt, Codeunit::"Late Delivery Notification", 'DontShowAgain');
        LateNotification.Send();
    end;

    procedure DontShowAgain(LateNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationId()) then
            MyNotifications.InsertDefault(GetNotificationId(), NotificationNameTxt, NotificationDescriptionTxt, false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure RegisterDefault()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetNotificationId(), NotificationNameTxt, NotificationDescriptionTxt, true);
    end;
}
