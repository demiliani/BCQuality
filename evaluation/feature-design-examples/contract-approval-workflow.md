# Feature design

> Maintenance contracts must be approved by a service manager before they can be used. The person who creates a contract sends it for approval, the approver approves or rejects it, and a rejected or canceled request puts the contract back to open so it can be changed.

**Result:** Complete design. **Business process:** Approval workflow (standard workflow engine and Approvals Mgmt.) for a custom Maintenance Contract record: Open -> Pending Approval -> Released, with reject and cancel returning the contract to Open. **Knowledge used:** 18 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is 'Maintenance Contract' a custom table in this app, a table in another app (then the Status field goes in a tableextension), or the standard Service Contract of Service Management? The design assumes a custom table in this app. _(affects: maintenance-contract-table, maintenance-contract-card, contract-status-enum)_
2. Do contracts already exist in production? If so, should they start Open (and need approval before use) or be set to Released by an upgrade step? _(affects: status-upgrade-codeunit, maintenance-contract-table)_
3. Where is a contract 'used' (for example service orders, invoicing, a contract lookup)? Each point of use must call TestStatusReleased; which ones are in scope? _(affects: maintenance-contract-table)_
4. Which fields stay editable while Pending Approval and when Released, and can a Released contract be reopened manually (a Reopen action) to change it? _(affects: maintenance-contract-table, maintenance-contract-card, fields-locked-outside-open)_
5. How is the service manager identified as approver: Approval User Setup approver, a workflow user group, or a specific user? Are there approval limits? _(affects: approval-permissionset)_
6. Should the app ship a ready workflow template (OnInsertWorkflowTemplates, OnAddWorkflowCategoriesToLibrary) that wires send, approve, reject-to-Open and cancel-to-Open, or will administrators build the workflow themselves? _(affects: workflow-events-codeunit, reject-reopens-contract)_
7. Should approvers see an amount, customer or other contract values on the approval entry (OnPopulateApprovalEntryArgument)? _(affects: workflow-events-codeunit)_
8. May a contract be deleted or renamed while its approval is pending or after it is released? _(affects: maintenance-contract-table, delete-and-rename-follow-approval-entries)_
9. Should the send and cancel actions also appear on the Maintenance Contracts list page? _(affects: maintenance-contract-card)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | enum | Maint. Contract Status | Named approval states of a maintenance contract: Open, Pending Approval, Released. A fixed set of named states, so an enum rather than an integer. |  | [1] [8] |
| 2 | extend | table | Maintenance Contract (assumed to be the app's own custom table; see open question q-contract-table) | Add the Status field and the status logic both the page actions and the workflow responses call: procedures to set Pending Approval, Released and Open, a TestStatusOpen check called from the OnValidate of each business field that must not change outside Open, and a TestStatusReleased check for the points of use. OnRename raises Approvals Mgmt. OnRenameRecordInApprovalRequest and OnDelete raises OnDeleteRecordInApprovalRequest so approval entries follow a renamed contract and go away with a deleted one. Status changes are not blocked in OnModify, because the workflow responses modify the record. | Status (Enum "Maint. Contract Status"): Not editable by the user; changed only through the status procedures. Classified explicitly unless the table-level DataClassification describes it; never ToBeClassified. Existing rows get ordinal 0 (Open); see q-existing-status. | [1] [2] [7] [5] [14] [15] |
| 3 | create | codeunit | Maint. Contract Wf. Events | Defines the event codes for 'approval of a maintenance contract is requested' and 'approval request for a maintenance contract is canceled', registers them, their predecessors, the response predecessors and the table relation through the workflow library events, and exposes Send and Cancel procedures that check Workflow Management.CanExecuteWorkflow and then call HandleEvent. Page actions call these procedures; the page holds no workflow logic. |  | [1] [3] |
| 4 | create | codeunit | Maint. Contract Appr. Resp. | Handles the three status responses for the Maintenance Contract table only: OnSetStatusToPendingApproval, OnReleaseDocument and OnOpenDocument, each calling the table's status procedure, modifying the record and setting the handled flag. |  | [2] [9] |
| 5 | extend | page | Maintenance Contract (card page of the table) | Show Status; make the business fields editable only while Status is Open; add a 'Request Approval' promoted group with Send Approval Request and Cancel Approval Request, enabled from Approvals Mgmt. HasOpenApprovalEntries and CanCancelApprovalForRecord, and an Approvals action that opens the contract's approval entries. Actions call the workflow-events codeunit. |  | [1] [4] [3] |
| 6 | create | permissionset | MAINT CONTR APPROVAL | Non-assignable building block granting execute on the two new codeunits, listed explicitly without wildcards, included through IncludedPermissionSets in the app's existing role-shaped maintenance-contract sets for requesters and approvers. |  | [1] [10] [11] |
| 7 | create | codeunit | Maint. Contract Status Upgrade | Only if existing contracts must keep being usable after the upgrade (q-existing-status): Subtype = Upgrade codeunit that sets Status to Released on existing rows with DataTransfer, guarded by its own registered upgrade tag. Not needed if existing contracts should start Open or the table is new. |  | [12] [13] |

## 3. How the data flows

- **Maintenance Contract (Send Approval Request action)** → **Workflow engine (Workflow Management.HandleEvent with the send event code)**: entered by the user. Raised only after CanExecuteWorkflow confirms an enabled workflow for the contract. [1]
- **Workflow response SetStatusToPendingApproval** → **Maintenance Contract.Status = Pending Approval**: field validation. Through the OnSetStatusToPendingApproval subscriber. [2]
- **Maintenance Contract** → **Approval Entry (Record ID to Approve)**: other. Created by the standard CreateApprovalRequests and SendApprovalRequestForApproval responses; the table relation registered through OnAddWorkflowTableRelationsToLibrary lets the engine follow the record. [1]
- **Approval Entry approved (last approver)** → **Maintenance Contract.Status = Released**: field validation. Standard ReleaseDocument response, handled by the OnReleaseDocument subscriber. [2]
- **Approval Entry rejected, or approval request canceled** → **Maintenance Contract.Status = Open**: field validation. Standard OpenDocument response (after CancelAllApprovalRequests on cancel), handled by the OnOpenDocument subscriber. Linking reject to OpenDocument is done in the workflow definition; see q-template. [1] [2]
- **Maintenance Contract (rename or delete)** → **Approval Entry**: other. OnRename raises OnRenameRecordInApprovalRequest; OnDelete raises OnDeleteRecordInApprovalRequest. Code that deletes contracts uses Delete(true) so OnDelete runs. [1] [5] [6]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Workflow Event Handling (codeunit 1520) | `OnAddWorkflowEventsToLibrary` | Register the send and cancel events for maintenance contracts with AddEventToLibrary. |  | [1] |
| Workflow Event Handling (codeunit 1520) | `OnAddWorkflowEventPredecessorsToLibrary` | Order the contract events with AddEventPredecessor so the cancel event follows the send event. |  | [1] |
| Workflow Response Handling (codeunit 1521) | `OnAddWorkflowResponsePredecessorsToLibrary` | Link SetStatusToPendingApprovalCode, CreateApprovalRequestsCode and SendApprovalRequestForApprovalCode after the send event, and CancelAllApprovalRequestsCode and OpenDocumentCode after the cancel event, with AddResponsePredecessor. |  | [1] |
| Workflow Event Handling (codeunit 1520); confirm in symbols | `OnAddWorkflowTableRelationsToLibrary` | Relate Maintenance Contract to Approval Entry with Workflow Setup.InsertTableRelation. |  | [1] |
| Approvals Mgmt. (codeunit 1535) | `OnSetStatusToPendingApproval` | Set the contract to Pending Approval, modify it, return it in Variant and set IsHandled. | Exit unless RecRef.Number = Database::"Maintenance Contract", before any database call · Set IsHandled only for the own table | [2] [9] |
| Workflow Response Handling (codeunit 1521) | `OnReleaseDocument` | Set the contract to Released after final approval, modify it and set Handled. | Exit unless RecRef.Number = Database::"Maintenance Contract", before any database call · Set Handled only for the own table | [2] [9] |
| Workflow Response Handling (codeunit 1521) | `OnOpenDocument` | Set the contract back to Open on rejection or cancellation, modify it and set Handled. | Exit unless RecRef.Number = Database::"Maintenance Contract", before any database call · Set Handled only for the own table | [2] [9] |

## 5. Setup, permissions and lifecycle

- **install**: Register workflow events, responses and the table relation only through the library events; insert nothing into the workflow event, response or table relation tables from install code, because the libraries are rebuilt on upgrade. [1]
- **setup**: An administrator creates and enables an approval workflow for maintenance contracts that uses the new events, with the service manager as approver (see q-approver and q-template). [1]
- **upgrade**: If the Maintenance Contract table already holds data, existing rows get Status = Open (ordinal 0), not any InitValue. If they must stay usable, back-fill Released with DataTransfer in an upgrade codeunit guarded by an upgrade tag (status-upgrade-codeunit). [12] [13]
- **permissions**: Add the MAINT CONTR APPROVAL building block (Assignable = false, explicit entries, no wildcards) to the app's requester and approver role sets through IncludedPermissionSets. [10] [11]
- **privacy**: Give the Status field a real DataClassification, inherited from the table level only if that value describes it; no ToBeClassified ships. If the field is added through a tableextension, classify it explicitly. [14] [15]

## 6. Tests

1. **send-sets-pending-approval** [1] [16]
    - Given An enabled maintenance-contract approval workflow created with Library - Workflow, an approver set up, and an Open contract
    - When The requester sends the contract for approval
    - Then Status is Pending Approval and an open Approval Entry exists for the contract's record ID and the approver
2. **approve-releases-contract** [1] [2]
    - Given A contract pending approval
    - When The approver approves the request
    - Then Status is Released and the approval entry is Approved
3. **reject-reopens-contract** [1] [2]
    - Given A contract pending approval
    - When The approver rejects the request
    - Then Status is Open and the business fields can be validated again
4. **cancel-reopens-contract** [1] [2]
    - Given A contract pending approval
    - When The requester cancels the approval request
    - Then Status is Open and the contract's approval entries are Canceled
5. **send-without-workflow-fails** [1]
    - Given No enabled maintenance-contract approval workflow
    - When The requester sends the contract for approval
    - Then An error states that no approval workflow is enabled, and Status stays Open
6. **fields-locked-outside-open** [18] [7]
    - Given A contract pending approval, and the same contract after release
    - When The card page is opened with OpenEdit, and a business field is validated in code
    - Then The business fields report Editable() = false on the page, and validating them raises the TestField error on Status; after reopening they are editable again
7. **other-tables-not-claimed** [2]
    - Given The maintenance-contract subscribers installed and a standard purchase or sales document approval workflow enabled
    - When A standard document is sent and approved
    - Then The standard document's status changes as without this app; the contract subscribers did not set Handled
8. **delete-and-rename-follow-approval-entries** [1] [5] [6]
    - Given A contract with approval entries
    - When The contract is renamed, and later deleted with Delete(true)
    - Then The approval entries point to the new record ID after rename and are removed after delete
9. **requester-permissions-suffice** [17] [10]
    - Given A test user lowered with Permissions Mock or Library - Lower Permissions to the requester role that includes MAINT CONTR APPROVAL, under TestPermissions Restrictive
    - When The user sends and cancels an approval request
    - Then Both succeed without SUPER

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no repository or app.json was supplied. promoted-action-groups applies from BC21.
- The opened article names OnAddWorkflowTableRelationsToLibrary without its publisher codeunit; confirm the publisher in symbols before implementing.
- Workflow template and approval entry details: the approval map lists the extension points but states that no BCQuality article covers them yet; they rest on judgment (q-template, q-approval-entry-details).
- Enforcing Released at points of use (TestStatusReleased) rests on judgment beyond the TestField choice; the points of use are not known (q-use-points).

## Sources

[1] `microsoft/knowledge/feature-design/plan-an-approval-workflow-for-a-custom-record.md`: Decision map for the whole design: status, events, raising, responses, table relation, rename/delete, page actions, permissions and tests.
    - Reuse the standard workflow engine and responses; the extension supplies events, response links, status changes and rename/delete cleanup.
    - Register events with OnAddWorkflowEventsToLibrary/AddEventToLibrary, order them with OnAddWorkflowEventPredecessorsToLibrary/AddEventPredecessor, link responses with OnAddWorkflowResponsePredecessorsToLibrary/AddResponsePredecessor, and relate the table with OnAddWorkflowTableRelationsToLibrary and Workflow Setup.InsertTableRelation.
    - Send and Cancel check CanExecuteWorkflow, then call HandleEvent.
    - Raise OnRenameRecordInApprovalRequest and OnDeleteRecordInApprovalRequest on Approvals Mgmt. from the table triggers.
    - Do not insert workflow event, response or table relation rows from install code, and do not handle only the Release response.
    - Test enable, send, approve, reject and cancel with Library - Workflow, checking the status each time.
[2] `microsoft/knowledge/feature-design/custom-approval-records-must-handle-status-responses.md`: The three status-response subscribers and their table guard.
    - Subscribe to OnSetStatusToPendingApproval (Approvals Mgmt.), OnReleaseDocument and OnOpenDocument (Workflow Response Handling), set the status, modify and set the handled flag.
    - Check RecRef.Number first and exit for any other table.
    - Keep the status change in a table or codeunit procedure shared by page actions and the workflow.
    - Leaving any response unhandled fails with 'Record type %1 is not supported by this workflow response.' on the first approval step.
[3] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Send/Cancel actions and status changes live in codeunits and the table, not in the card page.
    - A business operation that must hold regardless of entry point belongs in a codeunit or the table, not only in a page trigger.
    - Page actions call codeunit procedures instead of computing or persisting inline.
[4] `microsoft/knowledge/ui/promoted-action-groups.md`: Placement of the approval actions on the card; applies from BC21 (bc-version unknown).
    - Use the standard workflow group caption 'Request Approval' for send and cancel approval actions.
    - Do not invent custom group captions or fragment the ribbon into one-action groups.
[5] `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`: Approval entries must be cleaned up from the contract's OnDelete.
    - AL has no cascading delete; the owning table removes dependents in OnDelete.
    - Rename propagates through TableRelation, delete does not.
[6] `microsoft/knowledge/data-modeling/delete-master-data-with-trigger.md`: Contracts are deleted with Delete(true) so the OnDelete cleanup runs.
    - Outside the owning table's own triggers, delete master and reference records with Delete(true)/DeleteAll(true).
[7] `microsoft/knowledge/error-handling/fielderror-vs-testfield.md`: TestStatusOpen and TestStatusReleased checks on the contract.
    - Use TestField for a simple presence or equality check on one field.
    - Rely on the built-in field and record context rather than restating the field name in a custom message.
[8] `microsoft/knowledge/style/fixed-choice-set-must-use-enum-not-integer.md`: Status typed as an enum.
    - A fixed set of named states is declared as an Enum and branched on by name, not stored as an Integer.
[9] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Status-response subscribers exit on the table check before any database call.
    - Open the subscriber with an in-memory predicate such as the record type; only then issue database calls.
[10] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the approval permission set.
    - Small building blocks with Assignable = false, included into role-shaped assignable sets through IncludedPermissionSets.
[11] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Explicit object entries in the approval permission set.
    - Enumerate each table, tabledata and object explicitly; no '*' grants.
    - Grant only the letters the role needs.
[12] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Status of contracts that exist before the feature is installed.
    - A new field on an existing table leaves existing rows at the datatype default, not the InitValue.
    - If existing rows need another value, ship an upgrade procedure, typically DataTransfer, guarded by an upgrade tag.
    - No upgrade code is needed for a field on a brand-new table.
[13] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Guard for the optional status back-fill.
    - Start each upgrade procedure with HasUpgradeTag and end with SetUpgradeTag; one tag per feature.
    - Do not branch on DataVersion to decide which upgrade step runs.
[14] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the new Status field.
    - A field inherits the table-level DataClassification of its own table; a tableextension field inherits nothing and must classify itself.
[15] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the new field.
    - No field ships with DataClassification = ToBeClassified.
[16] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for the workflow and contract tests.
    - Build prerequisite data with the test Library codeunits instead of hand-rolled Init/Insert, parents first.
[17] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test for requesters.
    - Use TestPermissions Restrictive and lower the user with Permissions Mock or Library - Lower Permissions before the protected operation.
    - A role that includes the set under test is an adequate context.
[18] `microsoft/knowledge/testing/use-testpage-editable-to-verify-field-editability.md`: Test that fields are locked outside Open.
    - Open the TestPage with OpenEdit and assert Editable(), not Enabled().

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
