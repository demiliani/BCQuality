# Feature design

> Capital expenditure requests are a new custom document with an amount in a foreign currency. They must go through an approval workflow where each approver can approve up to their own capex limit in local currency, and above that the request goes to the next approver in the chain. Approvers must see the request number and amount in Requests to Approve, and administrators want a ready-made workflow template they can enable in every company where the app is installed.

**Result:** Complete design. **Business process:** Adds a new custom Capex Request document with a foreign-currency amount that goes through the standard approval workflow engine (Approvals Mgmt., Workflow Event/Response Handling, Workflow Setup), with per-approver capex limits in LCY escalating along the Approver Chain, approval entries shown in Requests to Approve, and a shipped workflow template. **Knowledge used:** 29 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Which exchange rate converts the foreign-currency Amount to Amount (LCY) for the limit check: the rate on the request date, on the send date, or a rate entered on the request? Is Amount (LCY) frozen when the request is sent, or recalculated if rates change? _(affects: capex-request-table, amount-lcy-from-currency)_
2. Does a Capex Approval Limit of 0 mean the approver cannot approve any amount (only escalate), or no limit? Is the comparison inclusive (amount equal to the limit is approvable)? _(affects: user-setup-tableext, approve-within-limit-releases, approve-above-limit-escalates)_
3. What should happen when the last approver in the chain is still below the amount (no further Approver ID): is an approver with Unlimited Capex Approval required at the top of every chain? _(affects: user-setup-tableext, approve-above-limit-escalates)_
4. Should the template and design support only Approver Chain on the User Setup approver hierarchy, or also First Qualified Approver, Approver Limit Type Direct Approver, Salesperson/Purchaser (which needs a purchaser code on the request) or workflow user groups? _(affects: capex-workflow-template-codeunit, capex-request-table)_
5. Is a capex request a header-only document, or does it need lines (assets, amounts per line) with the total amount on the header? _(affects: capex-request-table, capex-request-card-page)_
6. What happens after a request is released: is it posted, converted into a purchase order or fixed asset, printed, archived, given attachments or dimensions? None of these is designed because the request does not ask for them. _(affects: capex-request-table, capex-request-card-page)_
7. May a user release or reopen a request without a workflow (Release/Reopen actions), and may a released request be reopened and resent? _(affects: capex-request-card-page, capex-approval-mgt-codeunit)_
8. Which fields stay editable in Pending Approval and Released status (proposed: none except Description)? _(affects: capex-request-table, capex-request-card-page)_
9. Should the capex limit fields appear on the Approval User Setup page only, or also on User Setup? _(affects: user-setup-pageext)_
10. Should the shipped template carry a default condition (for example only requests above a threshold), or apply to all Capex Requests? _(affects: capex-workflow-template-codeunit)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Capex Request | Header of the custom capital expenditure document. Document table type: primary key No. Code[20] assigned from the Capex Request Nos. series in OnInsert through codeunit "No. Series" when blank, then InitRecord sets the remaining defaults for every creation path. Holds the amount in a foreign currency, its LCY equivalent for the limit check, and the approval Status. OnRename raises OnRenameRecordInApprovalRequest and OnDelete raises OnDeleteRecordInApprovalRequest on "Approvals Mgmt." so approval entries follow a renamed request and go away with a deleted one. Status changes go through one procedure on the table (or the management codeunit) shared by page actions and workflow responses. The conversion of Amount to Amount (LCY) rests on judgment: no opened article covers currency conversion. Table-level DataClassification = CustomerContent. | No. (Code[20]): Primary key; from Capex Setup."Capex Request Nos." in OnInsert via "No. Series".GetNextNo when blank; OnValidate guards manual entry with "No. Series".TestManual/IsManual.; No. Series (Code[20]): Non-editable; records the series that produced No.; TableRelation "No. Series".; Description (Text[100]): In DataCaptionFields.; Request Date (Date): Default set in InitRecord; candidate date for the exchange rate (open question).; Currency Code (Code[10]): TableRelation Currency; same type and exact length as Currency.Code. Blank means LCY.; Amount (Decimal): Requested amount in Currency Code; AutoFormatType/AutoFormatExpression on Currency Code. OnValidate recalculates Amount (LCY).; Amount (LCY) (Decimal): Non-editable; Amount converted to local currency; the value compared with approver capex limits.; Currency Factor (Decimal): Non-editable; exchange factor used for Amount (LCY); kept so the LCY value is reproducible.; Status (Enum "Capex Request Status"): Open, Pending Approval, Released; non-editable; changed only by the status procedure and the workflow responses.; Requested By (Code[50]): User ID of the requester, default in InitRecord; field-level DataClassification EndUserIdentifiableInformation. | [5] [6] [7] [8] [9] [12] [13] [14] [15] [16] [1] [2] |
| 2 | create | enum | Capex Request Status | Open, Pending Approval and Released status values set by the page actions and by the standard workflow responses through the status subscribers. |  | [1] [2] |
| 3 | create | table | Capex Setup | Singleton setup table (Primary Key Code[10], blank) holding the Capex Request Nos. number series; TestField on the series before a request number is assigned. | Primary Key (Code[10]): Always blank.; Capex Request Nos. (Code[20]): TableRelation "No. Series"; TestField before use in Capex Request OnInsert. | [10] [11] [8] [15] |
| 4 | create | page | Capex Setup | Card page over Capex Setup with InsertAllowed = false and DeleteAllowed = false; OnOpenPage inserts the blank singleton row when missing. |  | [10] [21] [17] |
| 5 | create | page | Capex Request | Card page for one request (Document page with a lines subpage only if lines are confirmed). Actions: Send Approval Request and Cancel Approval Request in the Request Approval promoted group, Approve/Reject/Delegate/Comment in the Approve group when the current user has an open approval entry, Approvals in the entity group; enabled from "Approvals Mgmt." HasOpenApprovalEntries, CanCancelApprovalForRecord and HasOpenApprovalEntriesForCurrentUser. Promoted with area(Promoted)/actionref. Actions call the management codeunit; no business logic on the page. Fields are not editable unless Status is Open. |  | [21] [17] [18] [20] [22] [19] [1] |
| 6 | create | page | Capex Requests | List page over Capex Request with CardPageID = Capex Request, primary key left-most, showing No., Description, Currency Code, Amount, Amount (LCY) and Status; searchable entry point (UsageCategory = Lists). |  | [21] [17] [19] |
| 7 | create | codeunit | Capex Approval Mgt. | Owns the workflow integration: registers the Send and Cancel workflow events and their predecessors, links the standard responses after them, registers the Capex Request to Approval Entry table relation, exposes RunWorkflowOnSendCapexForApprovalCode and RunWorkflowOnCancelCapexApprovalRequestCode, and implements Send/Cancel (check an enabled workflow with "Workflow Management".CanExecuteWorkflow, error if none, then HandleEvent). Hosts the status-response subscribers (each exits unless RecRef.Number is Capex Request) and the approval entry argument and capex limit subscribers. |  | [1] [2] [3] [18] |
| 8 | create | codeunit | Capex Workflow Template | Ships a disabled Capex Request approval workflow template and its CAPEX workflow category so it appears in new companies and in every company where the app is installed later. Builds it from OnAfterInitWorkflowTemplates only when Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(code)) finds nothing, using InsertWorkflowTemplate, InitWorkflowStepArgument (Approver Type Approver, Approver Limit Type Approver Chain), InsertDocApprovalWorkflowSteps with the app's own send and cancel event codes and Capex Request conditions built with StrSubstNo of the request-page XML and Encode(CapexRequest.GetView(false)), then MarkWorkflowAsTemplate. |  | [4] [1] |
| 9 | extend | tableextension | User Setup | Adds each approver's own capex approval limit in local currency, plus an unlimited flag, read by the OnSufficientApproverElseCase subscriber. Every added Normal field declares its own DataClassification. | Capex Approval Limit (Decimal): In LCY; AutoFormatType = 1; DataClassification = CustomerContent. Meaning of 0 is an open question.; Unlimited Capex Approval (Boolean): DataClassification = CustomerContent; approver is sufficient for any amount. | [3] [15] [16] |
| 10 | extend | pageextension | Approval User Setup | Shows Capex Approval Limit and Unlimited Capex Approval next to the standard approval limits so administrators maintain the chain in one place. The choice of page rests on judgment (open question whether User Setup is also extended). |  | [19] |
| 11 | create | permissionset | Capex - Objects | Non-assignable building block: explicit entries for the Capex tables, pages and codeunits, no wildcards. |  | [23] [24] |
| 12 | create | permissionset | Capex - Request | Assignable set for requesters and approvers: includes Capex - Objects; RIM on Capex Request, R on Capex Setup; approvers act through the standard approval permission sets. |  | [23] [24] [1] |
| 13 | create | permissionset | Capex - Admin | Assignable set for workflow administrators: includes Capex - Request plus RIMD on Capex Request and RIM on Capex Setup. |  | [23] [24] [1] |

## 3. How the data flows

- **User (Capex Request page)** → **Capex Request.Currency Code, Capex Request.Amount**: entered by the user. Requester enters the amount in a foreign currency while Status is Open. [18]
- **Capex Request.Amount, Currency Code, Request Date** → **Capex Request.Amount (LCY), Currency Factor**: field validation. OnValidate of Amount and Currency Code recalculates the LCY value; the exchange rate source and date rest on judgment (no opened article). agent judgment
- **Capex Setup.Capex Request Nos.** → **Capex Request.No., No. Series**: other. OnInsert via "No. Series".GetNextNo after TestField of the series. [8] [9] [11]
- **Capex Request (Send Approval Request action)** → **Workflow engine (send event)**: other. CanExecuteWorkflow then HandleEvent with the app's send event code. [1]
- **Capex Request.No., Amount, Amount (LCY), Currency Code** → **ApprovalEntryArgument**: copied in an event subscriber. OnPopulateApprovalEntryArgument fills Document No., Amount, Amount (LCY) and Currency Code for Capex Request only. [3]
- **ApprovalEntryArgument** → **Approval Entry (shown in Requests to Approve)**: other. Standard MakeApprovalEntry copies Document No., Amount, Amount (LCY) and Currency Code to each approval entry, which approvers see in Requests to Approve. [3]
- **User Setup.Capex Approval Limit, Unlimited Capex Approval** → **Approver Chain sufficiency decision**: other. OnSufficientApproverElseCase compares ApprovalEntryArgument.Amount (LCY) with the approver's limit; insufficient sends the request to the next approver in the User Setup chain. [3]
- **Workflow responses (Set Status to Pending Approval, Release Document, Open Document)** → **Capex Request.Status**: copied in an event subscriber. Status subscribers set Pending Approval, Released or Open for Capex Request only and set Handled. [2]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Workflow Event Handling | `OnAddWorkflowEventsToLibrary` | Register the "approval of a capex request is requested" and "approval of a capex request is canceled" events with AddEventToLibrary. |  | [1] |
| Workflow Event Handling | `OnAddWorkflowEventPredecessorsToLibrary` | Order the capex events with AddEventPredecessor (cancel, and approve/reject/delegate of the approval request, after send). |  | [1] |
| Workflow Response Handling | `OnAddWorkflowResponsePredecessorsToLibrary` | Allow the standard responses SetStatusToPendingApprovalCode, CreateApprovalRequestsCode, SendApprovalRequestForApprovalCode, ReleaseDocumentCode, OpenDocumentCode and CancelAllApprovalRequestsCode after the capex events with AddResponsePredecessor. |  | [1] |
| Workflow Event Handling | `OnAddWorkflowTableRelationsToLibrary` | Link Capex Request to Approval Entry with "Workflow Setup".InsertTableRelation so the engine follows the record. |  | [1] |
| Approvals Mgmt. | `OnSetStatusToPendingApproval` | Set Capex Request Status to Pending Approval, modify, return the record in Variant and set IsHandled. | Exit unless RecRef.Number = Database::"Capex Request" | [2] |
| Workflow Response Handling | `OnReleaseDocument` | Set Capex Request Status to Released, modify and set Handled. | Exit unless RecRef.Number = Database::"Capex Request" | [2] |
| Workflow Response Handling | `OnOpenDocument` | Set Capex Request Status back to Open (reject and cancel), modify and set Handled. | Exit unless RecRef.Number = Database::"Capex Request" | [2] |
| Approvals Mgmt. | `OnPopulateApprovalEntryArgument` | Fill Document No., Amount, Amount (LCY) and Currency Code of the argument so approvers see the request number and amount in Requests to Approve and the limit check has the LCY amount. | Exit unless RecRef.Number = Database::"Capex Request" | [3] |
| Approvals Mgmt. | `OnSufficientApproverElseCase` | Decide whether the approver may approve: sufficient when Unlimited Capex Approval, or when Amount (LCY) <= Capex Approval Limit; otherwise the Approver Chain escalates to the next approver. | Exit unless ApprovalEntryArgument."Table ID" = Database::"Capex Request" · Treat a user who is their own approver (User ID = Approver ID) as sufficient, as the standard checks do | [3] |
| Workflow Setup | `OnAddWorkflowCategoriesToLibrary` | Insert the CAPEX workflow category with InsertWorkflowCategory. |  | [4] |
| Workflow Setup | `OnAfterInitWorkflowTemplates` | Insert the disabled Capex Request approval template in every company, on every Workflow Templates initialization. | Exit when Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(CapexTemplateCode)) finds the template, so steps are never added twice | [4] |

## 5. Setup, permissions and lifecycle

- **setup**: Capex Setup singleton created on first open of the Capex Setup page; administrator assigns the Capex Request Nos. series before the first request (TestField enforces it). [10] [11] [8]
- **setup**: Administrators maintain Approver ID chains and the new Capex Approval Limit / Unlimited Capex Approval on the approval user setup, then create a workflow from the shipped template and enable it. [3] [4]
- **install**: No install code inserts workflow, step, event, response or table-relation rows: events, responses and table relations are registered only through the library events (recreated on upgrade), and the template comes from OnAfterInitWorkflowTemplates, so it appears in new and existing companies without install code and is shipped disabled. [1] [4]
- **permissions**: Ship Capex - Objects (non-assignable), Capex - Request and Capex - Admin (assignable) composed with IncludedPermissionSets, explicit entries, no wildcards. [23] [24] [1]
- **privacy**: Table-level DataClassification = CustomerContent on Capex Request and Capex Setup, field-level override EndUserIdentifiableInformation on Requested By, explicit classification on every User Setup extension field; no ToBeClassified at release. [15] [16]

## 6. Tests

1. **template-inserted-once-and-disabled** [4] [27]
    - Given A company where Microsoft templates already exist and the app is installed
    - When The Workflow Templates initialization (InitWorkflow) runs twice
    - Then Exactly one Capex Request approval template exists, marked as template, not enabled, in the CAPEX category, with one set of steps
2. **send-sets-pending-and-fills-approval-entry** [2] [3] [25] [27]
    - Given An enabled workflow created from the capex template with "Library - Workflow" (codeunit 131101), a Capex Setup with a number series, a currency with an exchange rate, and a Capex Request in that currency created through the table (Insert(true))
    - When The requester sends the request for approval
    - Then Status is Pending Approval and the open approval entry carries the request No. as Document No., Amount, Amount (LCY) and Currency Code equal to the request values
3. **amount-lcy-from-currency** agent judgment
    - Given A currency with an exchange rate valid on the request date
    - When Amount and Currency Code are validated on a Capex Request
    - Then Amount (LCY) equals Amount converted at that rate (expected value per the answered exchange-rate question)
4. **approve-within-limit-releases** [3] [2] [25]
    - Given An enabled capex workflow with Approver Chain; first approver Capex Approval Limit above the request Amount (LCY)
    - When The first approver approves
    - Then No further approval entry is created and Status is Released
5. **approve-above-limit-escalates** [3] [25]
    - Given An enabled capex workflow with Approver Chain; first approver limit below the request Amount (LCY) and the next approver in the chain with Unlimited Capex Approval
    - When The first approver approves
    - Then An open approval entry is created for the next approver, Status stays Pending Approval; after that approver approves Status is Released
6. **reject-reopens** [2]
    - Given A Capex Request pending approval
    - When The approver rejects it
    - Then Status is Open and approval entries are Rejected
7. **cancel-reopens** [2] [29]
    - Given A Capex Request pending approval
    - When The requester cancels the approval request (confirmation message handled by a MessageHandler that captures the text)
    - Then Status is Open and the approval entries are Canceled
8. **other-tables-unaffected** [2] [3]
    - Given An enabled standard purchase order approval workflow with Approver Chain and User Setup purchase limits, and the capex subscribers active
    - When A purchase order is sent for approval
    - Then The purchase approval entries and sufficiency follow the standard purchase limits and the capex subscribers change nothing
9. **send-without-workflow-fails** [1] [28]
    - Given No enabled capex workflow
    - When The requester sends a Capex Request for approval
    - Then The expected "no approval workflow" error is raised, pinned with Assert.ExpectedError on the full label text, and Status stays Open
10. **missing-number-series-fails** [11] [28]
    - Given Capex Setup with a blank Capex Request Nos.
    - When A Capex Request is inserted with a blank No.
    - Then The TestField error is raised, verified with Assert.ExpectedTestFieldError
11. **rename-and-delete-follow-approval-entries** [1] [13]
    - Given A Capex Request with open approval entries
    - When The request is renamed, and in a second test deleted with Delete(true)
    - Then The approval entries point to the new record ID, and after delete no approval entries for the request remain
12. **requester-permissions** [26] [23]
    - Given A test user lowered to Capex - Request with TestPermissions Restrictive
    - When The user creates a Capex Request and sends it for approval
    - Then The request is created and pending approval without a permission error

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Currency conversion of Amount to Amount (LCY) (exchange rate lookup, currency factor, rounding) is not covered by BCQuality knowledge; the field design and the amount-lcy-from-currency test rest on judgment.
- The choice of Approval User Setup as the page to extend with the capex limit fields is not covered by BCQuality knowledge; it rests on judgment.
- Status-based editability of Capex Request fields and the custom release routine rest on judgment (no article for a custom release routine).
- Context dimensions bc-version, countries and application-area are unknown: no repository or app.json was supplied. Tooltip inheritance on table fields applies from BC24 (runtime 13.0).

## Sources

[1] `microsoft/knowledge/feature-design/plan-an-approval-workflow-for-a-custom-record.md`: Map for the whole approval design: status, events, responses, status responses, approval entry details, table relation, rename/delete, template, page actions, permissions and tests.
    - Register events with AddEventToLibrary in OnAddWorkflowEventsToLibrary and order them with OnAddWorkflowEventPredecessorsToLibrary.
    - Send and Cancel actions check an enabled workflow with "Workflow Management".CanExecuteWorkflow, then raise the event with HandleEvent.
    - Reuse the standard responses after the custom events through OnAddWorkflowResponsePredecessorsToLibrary.
    - Link the table to Approval Entry through OnAddWorkflowTableRelationsToLibrary and InsertTableRelation.
    - Raise OnRenameRecordInApprovalRequest and OnDeleteRecordInApprovalRequest on "Approvals Mgmt." from the table triggers.
    - Register events, responses and table relations only through the library events; never insert those rows from install code, because the libraries are recreated on upgrade.
    - Do not handle only the Release response.
[2] `microsoft/knowledge/feature-design/custom-approval-records-must-handle-status-responses.md`: Status subscribers and the Status enum.
    - Subscribe to OnSetStatusToPendingApproval ("Approvals Mgmt."), OnReleaseDocument and OnOpenDocument ("Workflow Response Handling") for the custom table.
    - Check RecRef.Number first and exit for any other table; set the Handled/IsHandled flag only for the own table.
    - Keep the status change in a procedure on the table or a codeunit used by both page actions and the workflow.
[3] `microsoft/knowledge/feature-design/fill-the-approval-entry-argument-for-a-custom-record.md`: Showing request number and amount on approval entries and the per-approver capex limit with Approver Chain escalation.
    - Subscribe to OnPopulateApprovalEntryArgument, exit unless RecRef.Number is the custom table, and fill Document No., Amount, Amount (LCY) and Currency Code.
    - For Approver Chain or First Qualified Approver, subscribe to OnSufficientApproverElseCase, check ApprovalEntryArgument."Table ID", and compare Amount (LCY) with the chosen limit (an existing or new User Setup field, optionally with an unlimited flag).
    - Treat a user who is their own approver as sufficient.
    - Without these subscribers the first approver is always sufficient and an Approver Chain never escalates.
    - Do not write the amount into Approval Entry from its OnBeforeInsertEvent; use OnAfterPopulateApprovalEntryArgument only to adjust standard values.
[4] `microsoft/knowledge/feature-design/ship-a-workflow-template-for-a-custom-record-approval.md`: Ready-made workflow template available in every company where the app is installed.
    - Subscribe to OnAfterInitWorkflowTemplates and exit when Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(code)) finds the template.
    - Build it with InsertWorkflowTemplate, InitWorkflowStepArgument, InsertDocApprovalWorkflowSteps and MarkWorkflowAsTemplate; add the category in OnAddWorkflowCategoriesToLibrary.
    - Build conditions as StrSubstNo of the request-page XML with Encode(Record.GetView(false)); condition text must not be empty.
    - Use the app's own event codes; ship the template disabled.
    - Do not insert the template only from OnInsertWorkflowTemplates, and do not insert Workflow/Workflow Step rows from install code.
[5] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions the new Capex Request record needs: table type, numbering, setup, privacy, pages, permissions, tests.
    - Plan table type, numbering, setup, data rules, privacy, pages, permissions, install/upgrade and tests, not only the table and its page.
    - A row the request does not settle is a question for the requester, not a default.
[6] `microsoft/knowledge/feature-design/plan-a-custom-document-with-posting.md`: Stages a custom document may need (lines, posting, printing, attachments, archive, dimensions) raised as open questions because the request does not ask for them.
    - Whether the document needs an archive, a preview, approvals or ledger entries is for the requester to say; raise unsettled rows as open questions.
    - Status and release for a custom release routine rest on judgment; approval-driven status changes follow the status-responses article.
[7] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Capex Request as a Document-type header and Capex Setup as a Setup table.
    - Document header primary key Code[20] No.; Setup table key Code[10] Primary Key, always blank.
[8] `microsoft/knowledge/data-modeling/master-table-no-from-number-series-in-oninsert.md`: Numbering of Capex Request.
    - No. Code[20] sole primary key with a non-editable No. Series Code[20] field.
    - OnInsert checks No. is blank, reads setup, TestFields the series, stores it in No. Series and assigns No.
[9] `microsoft/knowledge/data-modeling/use-no-series-codeunit-not-noseriesmanagement.md`: Number assignment API.
    - Use codeunit "No. Series" (GetNextNo, IsManual/TestManual); never NoSeriesManagement.
[10] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Capex Setup table and page.
    - Single blank Primary Key Code[10] row; Card page with InsertAllowed = false, DeleteAllowed = false and an open-time insert of the missing row.
[11] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guard on the request number series.
    - TestField the required setup field before use; test that a blank value raises the error.
[12] `microsoft/knowledge/data-modeling/initialize-document-defaults-in-initrecord.md`: Defaults of a new Capex Request (Request Date, Requested By).
    - Assign the document number, then call InitRecord, which holds the defaults; do not set defaults in page triggers.
[13] `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`: Capex Request OnDelete cleans up what it owns, including approval entries through OnDeleteRecordInApprovalRequest.
    - The owning table deletes its dependents in OnDelete; there is no cascading delete.
[14] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Currency Code field length.
    - A field with an unconditional TableRelation has the same type and exact length as the related field (Currency.Code).
[15] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of new tables and the User Setup extension fields.
    - Use table-level classification where accurate, field-level overrides where different.
    - Every Normal field added by a tableextension needs an explicit DataClassification.
[16] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of classification.
    - No ToBeClassified in shipped fields.
[17] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Page names.
    - Page names describe the source table.
[18] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Page actions delegate to the codeunit; status changes not implemented in page triggers.
    - Business operations and cross-entry-point rules live in a codeunit or the table, not only in a page trigger.
[19] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on new and extended page fields.
    - Every user-facing field has an explicit or inherited tooltip; on runtime 13.0 (BC24) or later define it on the table field (condition: applies from BC24 for inheritance).
[20] `microsoft/knowledge/ui/promoted-action-groups.md`: Placement of approval actions.
    - Use the standard Request Approval and Approve groups for approval actions, Home for card actions, entity-named group for record navigation such as Approvals.
[21] `microsoft/knowledge/ui/page-design-must-match-bc-page-type-conventions.md`: Card, list and setup page shapes.
    - Card named after the table with General first FastTab; List with CardPageID to the card and key fields left-most; Document page only with a lines subpage.
[22] `microsoft/knowledge/ui/prefer-actionref-syntax-for-promoted-actions.md`: Promotion syntax of the approval actions.
    - Promote with area(Promoted) and actionref; never Promoted properties in new pages.
[23] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Non-assignable building blocks composed into assignable role sets with IncludedPermissionSets.
[24] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set entries.
    - Enumerate each tabledata and object explicitly with only the letters needed; no wildcards.
[25] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures (currency, users, requests, workflows).
    - Build fixtures with the Library codeunits, parents first, validating foreign keys; no hand-rolled Init/Insert with invented keys.
[26] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Requester permission test.
    - Use TestPermissions Restrictive and lower the user with the test libraries before the protected operation.
[27] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunits.
    - [FEATURE] on the codeunit, [SCENARIO], [GIVEN], [WHEN], [THEN] in every test.
[28] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative tests (no workflow, missing number series).
    - Follow every asserterror with ExpectedError on the full label text or ExpectedTestFieldError, not a bare asserterror or error code alone.
[29] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Cancel test, where the document chain shows a confirmation message.
    - Every UI call on the path needs a listed handler, every listed nonoptional handler must run, and handlers contribute an assertion.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

