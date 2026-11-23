---
bc-version: [all]
domain: ui
keywords: [notification, my-notifications, oninitializingnotificationwithdefaultstate, insertdefault, isenabled, disable, dont-show-again, message, confirm, instruction-mgt]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Register advisory notifications in My Notifications so users can turn them off

## Description

A warning that does not stop the user belongs in a `Notification`, not in `Message` or `Confirm`. `Message` and `Confirm` block the page and cannot be turned off by the user. In a background or web service session, `Confirm` raises a callback error. A notification shows in the bar on top of the page and does not block.

A notification the user cannot switch off becomes noise. Table 1518 `My Notifications` is the standard per-user switch. The `My Notifications` page raises `OnInitializingNotificationWithDefaultState` when it opens. Each feature subscribes to it and calls `MyNotifications.InsertDefault(Id, Name, Description, DefaultState)`. That creates the row the user sees and can toggle. A notification that is never registered there does not appear on the page, so it cannot be turned off.

Two checks with the same purpose return different results when the user has no row yet:

- `"My Notifications".IsEnabled(Id)` returns `true` when no row exists, and `Enabled` otherwise.
- `"Instruction Mgt.".IsMyNotificationEnabled(Id)` returns `false` when no row exists. A notification gated only by it stays silent until the row is created, for example by opening the page.

## Best Practice

Follow the pattern of `DimensionManagement` for its default dimension priorities notification:

- Keep a fixed notification `Guid` in a procedure.
- Subscribe to `OnInitializingNotificationWithDefaultState` on page `My Notifications` and call `InsertDefault` with a name, a description and the default state.
- Before sending, exit when `"My Notifications".IsEnabled(Id)` is false. Use `IsEnabledForRecord` when the user may filter by record.
- Set the `Id`, `Recall()` the previous one, set the message, then `Send()`.
- Add a "Don't show again" action. Its handler calls `MyNotifications.Disable(Id)`, and when that returns `false` (no row yet) calls `InsertDefault(..., false)`.

Keep `Error` for conditions that must stop the transaction, and `Confirm` for a real decision that changes what the code does next. Recalling and tracking per-record notifications is covered in [a notification that must be recalled needs a known Id](notification-recall-needs-known-id.md).

To send a document by email, do not build the email by hand. Use `Report Selections`; see [custom document dispatch must not bypass Report Selections](../data-modeling/custom-document-dispatch-must-not-bypass-report-selections.md) and [document print and email actions call Report Selections directly](../data-modeling/document-print-and-email-actions-call-report-selections-directly.md).

See sample: [`register-user-notifications-in-my-notifications.good.al`](register-user-notifications-in-my-notifications.good.al).

## Anti Pattern

A `Message` for an advisory check that runs on every validation, or a notification sent with a new `CreateGuid()` each time, with no `My Notifications` registration and no "Don't show again" action. Users cannot silence it, and the message pops up again for every record a user validates in a batch from the UI. A second form registers the notification but checks `IsMyNotificationEnabled` alone, so it never appears for a user who has not opened `My Notifications`.

See sample: [`register-user-notifications-in-my-notifications.bad.al`](register-user-notifications-in-my-notifications.bad.al).

## References

- [My Notifications table: InsertDefault, IsEnabled, IsEnabledForRecord, Disable](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Modules/System/Notifications/MyNotifications.Table.al).
- [My Notifications page: OnInitializingNotificationWithDefaultState](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Modules/System/Notifications/MyNotifications.Page.al).
- [Instruction Mgt.: IsMyNotificationEnabled, CreateMissingMyNotificationsWithDefaultState](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/InstructionMgt.Codeunit.al).
- [DimensionManagement: default dimension priorities notification and DontNotifyCurrentUserAgain](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Dimension/DimensionManagement.Codeunit.al).
- [Handling UI interaction in web services and background sessions](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/webservices/handling-ui-interaction-when-working-with-web-services).
- [Using nonintrusive notifications](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-notifications-developing).
