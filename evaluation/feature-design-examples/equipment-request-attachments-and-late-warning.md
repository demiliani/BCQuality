# Feature design

> Our app has an Equipment Request table with a card page, and posting creates a Posted Equipment Request with the same No. Users must attach photos and supplier quotes to a request, see them in a factbox, and still find them on the posted request after posting. When the Needed-By date is before the work date, warn the user on the card without blocking them, and let each user turn that warning off.

**Result:** Complete design. **Business process:** Adds standard Document Attachment support (factbox, delete, rename and copy on posting) to the app's own Equipment Request document and its posting routine, and an advisory Needed-By Date notification on the Equipment Request Card that each user can switch off through the standard My Notifications page. **Knowledge used:** 15 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Are Equipment Request and Posted Equipment Request keyed by a single Code[20] No. field, and which field number holds it? Document Attachment Mgmt can map only such a key. _(affects: equipment-request-attachments, equipment-request-table, posted-equipment-request-table)_
2. Does the posting codeunit delete the open Equipment Request after posting, and with or without its OnDelete trigger? The attachment copy must run before that delete, and a delete without the trigger would leave the open request's attachments orphaned. _(affects: equipment-request-posting, equipment-request-table)_
3. Can users delete posted equipment requests? If not, the OnDelete call on Posted Equipment Request only covers code paths, and attachments on posted requests could also be made read-only. _(affects: posted-equipment-request-table, posted-equipment-request-card)_
4. Which page shows a posted equipment request (a card, or only a list), so the attachment factbox is added there? _(affects: posted-equipment-request-card)_
5. Which permission set will users who attach files and post requests hold, and does it already grant Document Attachment rights, or must the app's permission set include them? _(affects: app-permission-set, posting-copies-attachments-with-app-permissions)_
6. Should the late Needed-By Date warning appear only when the card opens and the date is changed on it, or also on the list page, on release or on posting? _(affects: equipment-request-card, equipment-request-late-notification)_
7. Should a blank Needed-By Date raise no warning (as designed), or a different one? _(affects: equipment-request-late-notification)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | codeunit | Equipment Request Attachments | Static event subscriber codeunit that teaches Document Attachment Mgmt the key of Equipment Request and Posted Equipment Request (number field, record resolution, entity flag, copy from/to filters), plus a CopyToPosted procedure the posting codeunit calls. Static binding because the mapping must apply in every session. |  | [2] [8] |
| 2 | modify | table | Equipment Request | Call DocumentAttachmentMgmt.DeleteAttachedDocuments from OnDelete and MoveAttachmentsWithinSameRecordType from OnRename, so deleting or renaming one request touches only that request's files. Requires the key to be a Code[20] No. field (see open question). |  | [2] [7] |
| 3 | modify | table | Posted Equipment Request | Call DocumentAttachmentMgmt.DeleteAttachedDocuments from OnDelete so a deleted posted request does not leave orphaned attachments; its number field is mapped by the subscriber codeunit. |  | [2] [7] |
| 4 | modify | page | Equipment Request Card | Add part Doc. Attachment List Factbox in area(FactBoxes) with SubPageLink Table ID = const(Database::Equipment Request), No. = field(No.). In OnAfterGetCurrRecord, and after Needed-By Date is validated on the page, call the late-warning codeunit to recall and, when needed, send the notification. |  | [2] [5] [4] [3] |
| 5 | modify | page | Posted Equipment Request | Add part Doc. Attachment List Factbox with SubPageLink Table ID = const(Database::Posted Equipment Request), No. = field(No.) so users find the copied photos and quotes on the posted request. |  | [2] [5] |
| 6 | modify | codeunit | Equipment Request Posting | After the Posted Equipment Request is inserted, call Equipment Request Attachments.CopyToPosted (DocumentAttachmentMgmt.CopyAttachments(FromRecRef, ToRecRef)); do this before the open request is deleted, because its OnDelete removes the open request's attachments. Do not use CopyAttachmentsForPostedDocs, which fits sales and purchase headers only. |  | [2] [1] |
| 7 | create | codeunit | Equipment Request Late Notification | Owns the fixed notification Guid; ShowIfLate exits when My Notifications.IsEnabled(Id) is false, sets the fixed Id, recalls, and sends a LocalScope notification with a Don't show again action only when Needed-By Date is not blank and earlier than WorkDate() (read only, never set). DontShowAgain calls MyNotifications.Disable(Id) and InsertDefault(..., false) when no row exists. Subscribes to OnInitializingNotificationWithDefaultState to register the notification, enabled by default. |  | [3] [4] [6] |
| 8 | modify | permissionset | Equipment Request permission set | Grant execute on the two new codeunits; keep posted-table and Document Attachment rights limited to what posting and attaching require, using indirect letters where users should write only through the posting codeunit. |  | [9] |

## 3. How the data flows

- **User upload on Equipment Request Card factbox** → **Document Attachment (Table ID = Equipment Request, No. = request No.)**: entered by the user. InitFieldsFromRecRef fills No. only because OnAfterTableHasNumberFieldPrimaryKey returns the number field. [2]
- **Document Attachment of Equipment Request** → **Document Attachment of Posted Equipment Request**: other. DocumentAttachmentMgmt.CopyAttachments called by the posting codeunit after the posted record is inserted; From filter on source No. and ToNo set by the copy subscribers. [2] [1]
- **Document Attachment of renamed Equipment Request** → **Document Attachment with the new request No.**: other. MoveAttachmentsWithinSameRecordType from OnRename; filters on No. because OnAfterTableIsEntity returns true. [2]
- **Equipment Request Needed-By Date compared with WorkDate()** → **Notification on Equipment Request Card**: other. Fixed Id recalled before every send, so the warning clears when the date is corrected. [3] [4] [6]
- **Don't show again action / My Notifications page toggle** → **My Notifications row for the current user**: other. Disable(Id), or InsertDefault(..., false) when the user has no row yet. [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Document Attachment Mgmt | `OnAfterTableHasNumberFieldPrimaryKey` | Return the No. field number for Equipment Request and Posted Equipment Request so filters, InitFieldsFromRecRef and delete use the record key. | Act only when TableNo is Equipment Request or Posted Equipment Request | [2] |
| Document Attachment Mgmt | `OnAfterGetRefTable` | Get the Equipment Request or Posted Equipment Request from DocumentAttachment.No. so the factbox can resolve the source record and upload works. | Case on DocumentAttachment.Table ID · Use Get as a Boolean so a missing record leaves RecRef empty | [2] |
| Document Attachment Mgmt | `OnAfterTableIsEntity` | Mark Equipment Request as an entity so a rename moves only that record's files. | Act only when TableNo is Equipment Request | [2] |
| Document Attachment Mgmt | `OnCopyAttachmentsOnAfterSetFromParameters` | Filter the source attachments on the Equipment Request No. during CopyAttachments. | Act only when FromRecRef.Number is Equipment Request | [2] |
| Document Attachment Mgmt | `OnCopyAttachmentsOnAfterSetToParameters` | Set ToFieldRef and ToNo to the Posted Equipment Request No. so copies are stored under the posted record. | Act only when ToRecRef.Number is Posted Equipment Request | [2] |
| My Notifications | `OnInitializingNotificationWithDefaultState` | Register the late Needed-By Date notification with name, description and default state enabled, so each user can turn it off on My Notifications. | Use the same fixed notification Guid as ShowIfLate | [3] |

## 5. Setup, permissions and lifecycle

- **setup**: No install code: the notification row is created by the My Notifications subscriber or by Don't show again; gate sending with My Notifications.IsEnabled (true when no row exists), never with Instruction Mgt.IsMyNotificationEnabled alone. [3]
- **permissions**: Add execute on Equipment Request Attachments and Equipment Request Late Notification to the app's permission set; grant only the table letters users need, indirect where writes must go through the posting codeunit, and confirm users who post hold insert rights on Document Attachment. [9]

## 6. Tests

1. **factbox-shows-only-own-attachments** [2] [5] [11]
    - Given Two Equipment Requests, each with one attachment added through the attachment flow
    - When The Equipment Request Card is opened for the first request
    - Then The Doc. Attachment List Factbox lists only the first request's attachment (TestPage test kept in a UI-layer codeunit)
2. **new-attachment-stores-request-no** [2] [12]
    - Given An Equipment Request created through library or app helpers
    - When An attachment is added for the request through Document Attachment InitFieldsFromRecRef
    - Then The Document Attachment row has Table ID = Equipment Request and No. = the request No.
3. **posting-copies-attachments** [2] [1] [14]
    - Given An Equipment Request with two attachments and a second request with one attachment
    - When The first request is posted through the posting codeunit
    - Then Document Attachment rows exist for Posted Equipment Request with the same No., exactly two, and none for the second request
4. **delete-removes-only-own-attachments** [2] [7]
    - Given Two Equipment Requests each with an attachment
    - When The first request is deleted with its OnDelete trigger
    - Then Only the first request's attachments are gone; the second request keeps its attachment
5. **rename-moves-only-own-attachments** [2]
    - Given Two Equipment Requests each with an attachment
    - When The first request is renamed
    - Then Its attachment carries the new No.; the second request's attachment is unchanged
6. **late-needed-by-date-sends-notification** [10] [3] [6] [13]
    - Given WorkDate set deliberately by the test and an Equipment Request with Needed-By Date one day earlier
    - When The Equipment Request Card is opened
    - Then The SendNotificationHandler captures the late-date notification with the fixed Id, and the card stays editable (no error or Confirm)
7. **on-time-needed-by-date-sends-nothing** [10] [13]
    - Given WorkDate set by the test and a request whose Needed-By Date equals WorkDate
    - When The Equipment Request Card is opened
    - Then No late-date notification is captured; the handler is listed as optional
8. **disabled-notification-is-not-sent** [3] [10]
    - Given A late request and a My Notifications row for the user with the notification disabled
    - When ShowIfLate runs for the request
    - Then No notification is sent
9. **dont-show-again-creates-disabled-row** [3]
    - Given A user with no My Notifications row for the notification
    - When The DontShowAgain handler runs
    - Then A My Notifications row exists for the user with Enabled = false
10. **posting-copies-attachments-with-app-permissions** [15] [9]
    - Given A request with an attachment and the test user lowered to the app's permission set (TestPermissions Restrictive)
    - When The request is posted
    - Then Posting succeeds and the posted request has the attachment

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined: there is no repository or app.json; all cited articles apply to [all] versions and w1.
- Creating Document Attachment rows in tests (without the file upload dialog) is not covered by BCQuality knowledge; the fixture approach rests on judgment.
- Names of the existing posting codeunit, posted page and permission set are assumed from the request; confirm against the app.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-document-with-posting.md`: Map for the custom posted document: selects the Attachments, Permissions and Tests decisions this request touches.
    - Map the custom key for the open and posted tables and copy attachments on posting.
    - Tests post through the routine, not by inserting posted rows; one action per test.
    - A row the request does not settle is raised as an open question, not built or left out silently.
[2] `microsoft/knowledge/data-modeling/enable-document-attachments-on-custom-tables.md`: Document Attachment wiring for Equipment Request and Posted Equipment Request: subscribers, factbox, delete, rename and copy on posting.
    - Subscribe to OnAfterTableHasNumberFieldPrimaryKey for the table and its posted counterpart, OnAfterGetRefTable, and OnAfterTableIsEntity.
    - Add Doc. Attachment List Factbox with SubPageLink Table ID = const(Database::<table>), No. = field(No.).
    - Call DeleteAttachedDocuments from OnDelete and MoveAttachmentsWithinSameRecordType from OnRename.
    - After the posted record is inserted, call CopyAttachments(FromRecRef, ToRecRef) and subscribe to OnCopyAttachmentsOnAfterSetFromParameters and OnCopyAttachmentsOnAfterSetToParameters.
    - CopyAttachmentsForPostedDocs is not an option for a custom table.
    - A key wider than Code[20], or not a code, cannot use No. directly; decide before choosing this mechanism.
    - Do not build a custom attachment table with its own BLOB field, and do not wire the factbox without the subscribers.
[3] `microsoft/knowledge/ui/register-user-notifications-in-my-notifications.md`: Advisory late Needed-By Date warning as a notification that each user can switch off in My Notifications.
    - A warning that does not stop the user is a Notification, not Message or Confirm.
    - Keep a fixed notification Guid; subscribe to OnInitializingNotificationWithDefaultState and call InsertDefault with name, description and default state.
    - Exit before sending when My Notifications.IsEnabled(Id) is false; do not gate on Instruction Mgt.IsMyNotificationEnabled alone.
    - Set the Id, Recall() the previous one, set the message, then Send().
    - Add a Don't show again action that calls Disable(Id) and InsertDefault(..., false) when Disable returns false.
[4] `microsoft/knowledge/ui/notification-recall-needs-known-id.md`: Recall of the late warning when the Needed-By Date is corrected or another record is shown.
    - Keep the identity of every notification the code will recall and recall with that identity, such as a fixed Id recalled before re-sending.
    - Do not recall with a fresh Notification or a new CreateGuid() that cannot carry the sent Id.
[5] `microsoft/knowledge/ui/factbox-design.md`: Attachment factboxes on the open and posted request pages.
    - Every ListPart FactBox has a SubPageLink to the host record; without it the part loads the whole source table.
    - Keep FactBox count modest and avoid heavy OnAfterGetRecord logic in the part.
[6] `microsoft/knowledge/data-modeling/code-must-not-change-workdate.md`: Comparison of Needed-By Date with the work date, and the date context of tests.
    - Read the work date to compare or default a value; business logic must never set WorkDate as a side effect.
    - A test may set WorkDate deliberately to establish its date context.
[7] `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`: Removing a request's attachments when the open or posted request is deleted.
    - The owning table implements OnDelete and deletes its dependents filtered on the foreign key; AL has no cascading delete.
    - Declare the rights the trigger needs on the dependent table so it does not fail for a non-SUPER user.
[8] `microsoft/knowledge/events/choose-static-vs-manual-subscribers-deliberately.md`: Binding of the attachment and notification subscriber codeunits.
    - Use a static subscriber for behaviour that applies all the time; use Manual binding only for scoped behaviour.
    - Keep subscriber methods local.
[9] `microsoft/knowledge/security/indirect-permissions-for-elevated-access.md`: Permission set changes for the new codeunits and attachment rights.
    - Use lowercase indirect letters when a role may write a table only through a specific codeunit, and grant only the letters the role needs.
    - Do not grant direct RIMD on posted tables when users only reach them through the posting routine.
[10] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Notification tests.
    - Every UI call on the executed path needs a matching handler listed in HandlerFunctions.
    - A notification the scenario may or may not raise uses an optional SendNotificationHandler(true).
    - Each executed handler must contribute evidence the test asserts.
[11] `microsoft/knowledge/testing/ui-test-codeunit-naming.md`: Split between factbox (TestPage) tests and logic tests.
    - Keep TestPage-driven tests and logic-layer tests in separate codeunits.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for requests and related master data.
    - Use the standard Library codeunits for prerequisite data and create parents before dependents.
    - Validate foreign-key fields so table relations and validation run as in production.
[13] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Dates in the late-warning tests.
    - Create the records the test owns rather than looking up existing data.
    - Keep values that define the scenario, such as dates around the work-date boundary, explicit and deliberately chosen.
[14] `microsoft/knowledge/testing/test-one-when-per-test.md`: Shape of every test.
    - Each test has one WHEN; precondition actions such as posting to get a posted record belong in GIVEN.
[15] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test for posting with attachments.
    - Use TestPermissions Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

