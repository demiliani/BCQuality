# Feature design

> Add an Activity Code that consultants pick on each time sheet line and that is carried, when approved hours are suggested into the project journal and posted, to the project journal line, the project ledger entries and the resource ledger entries, and kept when time sheets are moved to the archive.

**Result:** Complete design. **Business process:** Project time sheets: Suggest Lines from Time Sheets into the project journal, project journal posting (Job Jnl.-Post Line and Res. Jnl.-Post Line), and Move Time Sheets to Archive. **Knowledge used:** 14 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Where do valid Activity Codes come from: an existing table (which one), a new Activity Code master table that this feature must also create (with its pages, permissions and setup), or free text? This sets the field's type, length and TableRelation. _(affects: ts-line-ext, ts-line-archive-ext, job-jnl-line-ext, job-ledger-entry-ext, res-jnl-line-ext, res-ledger-entry-ext, time-sheet-page-ext)_
2. Is an Activity Code mandatory on a time sheet line of type Job, and if so, when must it be checked: at submit, at approval, or at posting? _(affects: ts-line-ext, time-sheet-page-ext)_
3. Should the Activity Code also be available on time sheet lines of type Resource or Service, which are posted through the resource journal or service documents rather than the project journal? _(affects: ts-line-ext, res-jnl-line-ext, activity-code-flow)_
4. Must project usage that does not come from time sheets carry an Activity Code: lines typed manually in the project journal, purchase lines posted to a project, project planning lines, or general journal lines with a project? Each requires its own Job Transfer Line subscriber. _(affects: job-jnl-line-ext, activity-code-flow, job-journal-page-ext)_
5. May users change the Activity Code on a suggested project journal line before posting, or must it always equal the time sheet value? _(affects: job-jnl-line-ext, job-journal-page-ext)_
6. Must the Activity Code appear as a column and filter on the Project Ledger Entries and Resource Ledger Entries pages and on the time sheet archive pages? A stored field is justified when it is shown as a native list column. _(affects: job-ledger-entry-ext, res-ledger-entry-ext, ts-line-archive-ext)_
7. Which Business Central version does the app target, and which object and field ID range should be used? _(affects: ts-line-ext, ts-line-archive-ext, job-jnl-line-ext, job-ledger-entry-ext, res-jnl-line-ext, res-ledger-entry-ext, activity-code-flow)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Time Sheet Line | Holds the Activity Code the consultant picks on each time sheet line. It is the source of the value for every later stage, and its field number and type define the archive mirror. | Activity Code (Code[20]): Field number from the app's ID range, reused unchanged on Time Sheet Line Archive. Type and length are provisional until the source of valid codes is settled; if a TableRelation is added, the type and length must exactly match the related key field. DataClassification = CustomerContent, set on the field because a tableextension has no table-level value. | [1] [4] [8] [10] |
| 2 | extend | tableextension | Time Sheet Line Archive | Keeps the Activity Code when time sheets are archived. MoveTimeSheetToArchive copies Time Sheet Line to Time Sheet Line Archive with TransferFields and then deletes the original, so the field must have the same number, type and length as on Time Sheet Line. No code is needed. | Activity Code (Code[20]): Same field number, type and length as the Time Sheet Line field. Editable = false. DataClassification = CustomerContent. | [4] [7] [10] |
| 3 | extend | tableextension | Job Journal Line | Carries the Activity Code on the suggested project journal line, where users review it before posting. From here it is copied to both the project ledger and the resource journal line. Other sources of project journal lines (purchase lines, planning lines, general journal lines) are left out because the request covers only time sheets; see the open question. | Activity Code (Code[20]): Same type and length as the Time Sheet Line field. The value is copied by event, so the field number does not need to match. DataClassification = CustomerContent. | [1] [2] [6] [10] |
| 4 | extend | tableextension | Job Ledger Entry | Stores the Activity Code on project ledger entries. It is a stored field rather than a related table because the value is on every time entry, which the request requires. The related-table guidance (from BC23) applies to optional or sparse attributes. | Activity Code (Code[20]): Editable = false. DataClassification = CustomerContent. | [2] [9] [10] |
| 5 | extend | tableextension | Res. Journal Line | Intermediate carrier needed to reach the resource ledger. Job Jnl.-Post Line.PostResource builds the resource journal line field by field with CopyFromJobJnlLine, so without this field the value is lost before Res. Jnl.-Post Line. | Activity Code (Code[20]): DataClassification = CustomerContent. | [3] [10] |
| 6 | extend | tableextension | Res. Ledger Entry | Stores the Activity Code on resource ledger entries. It is stored for the same reason as on Job Ledger Entry. | Activity Code (Code[20]): Editable = false. DataClassification = CustomerContent. | [3] [9] [10] |
| 7 | create | codeunit | Activity Code Time Sheet Flow | Event subscriber codeunit that holds the four copy subscribers: time sheet to project journal, project journal to project ledger, project journal to resource journal, and resource journal to resource ledger. It assigns the value only and never calls Modify. |  | [1] [2] [3] |
| 8 | extend | pageextension | Time Sheet (line part used by consultants to enter hours; confirm the exact page in symbols) | Lets the consultant pick the Activity Code on each time sheet line. |  | agent judgment |
| 9 | extend | pageextension | Job Journal | Shows the Activity Code on suggested project journal lines so users can review it before posting. |  | agent judgment |

## 3. How the data flows

- **Consultant** → **Time Sheet Line.Activity Code**: entered by the user. Picked on each time sheet line before submission and approval. agent judgment
- **Time Sheet Line.Activity Code (temporary buffer in report Suggest Job Jnl. Lines)** → **Job Journal Line.Activity Code**: copied in an event subscriber. Report 952 creates one project journal line per Time Sheet Detail (one day) of an Approved, unposted line. A line-level value is copied from the temporary time sheet line, which holds every field of the real line. Each journal line from the same time sheet line gets the same code. [1] [5]
- **Job Journal Line.Activity Code** → **Job Ledger Entry.Activity Code**: copied in an event subscriber. Job Jnl.-Post Line.CreateJobLedgEntry calls Job Transfer Line.FromJnlLineToLedgEntry, which copies fields one by one and then raises OnAfterFromJnlLineToLedgEntry. [2]
- **Job Journal Line.Activity Code** → **Res. Journal Line.Activity Code**: copied in an event subscriber. Job Jnl.-Post Line.PostResource calls Res. Journal Line.CopyFromJobJnlLine, which raises OnAfterCopyResJnlLineFromJobJnlLine. The time sheet fields stay on the line, so Res. Jnl.-Post Line still marks the detail as posted. [3]
- **Res. Journal Line.Activity Code** → **Res. Ledger Entry.Activity Code**: copied in an event subscriber. Res. Ledger Entry.CopyFromResJnlLine raises OnAfterCopyFromResJnlLine. [3]
- **Time Sheet Line.Activity Code** → **Time Sheet Line Archive.Activity Code**: standard TransferFields copy. Report 953 Move Time Sheets to Archive calls Time Sheet Management.MoveTimeSheetToArchive, which uses TransferFields and then deletes the original. Only time sheets whose lines are all Approved and Posted can be archived. [4] [7]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Report "Suggest Job Jnl. Lines" | `OnAfterTransferTimeSheetDetailToJobJnlLine` | Copy Activity Code from the temporary time sheet line to the project journal line before it is inserted. | Assign the field without calling Modify; the journal line is not inserted yet. · Read the line-level value from the temporary Time Sheet Line parameter, not from Time Sheet Detail and not by re-reading the database. | [1] |
| Codeunit "Job Transfer Line" | `OnAfterFromJnlLineToLedgEntry` | Copy Activity Code from the project journal line to the project ledger entry while the entry is built. | Do not use OnAfterJobLedgEntryInsert with Modify on the inserted entry. | [2] |
| Table "Res. Journal Line" | `OnAfterCopyResJnlLineFromJobJnlLine` | Copy Activity Code from the project journal line to the resource journal line built during project journal posting. | Do not touch the Time Sheet No., Time Sheet Line No. or Time Sheet Date fields, and do not update Time Sheet Detail or insert Time Sheet Posting Entry yourself. | [3] |
| Table "Res. Ledger Entry" | `OnAfterCopyFromResJnlLine` | Copy Activity Code from the resource journal line to the resource ledger entry. |  | [3] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on every Activity Code field in the six table extensions. A tableextension has no table-level value to inherit. Use CustomerContent unless the codes identify a person, and leave no field at ToBeClassified at release. [10] [11]

## 6. Tests

1. **suggest-copies-activity-code-to-job-journal** [1] [5] [12] [13]
    - Given A resource that uses time sheets, a project with a task, and an approved time sheet line of type Job with Activity Code set and hours on two days, all created with the test Library codeunits
    - When Suggest Lines from Time Sheets runs (report Suggest Job Jnl. Lines) for a project journal batch
    - Then Two project journal lines are created, one per day, and each has the time sheet line's Activity Code
2. **posting-copies-activity-code-to-job-ledger** [2] [13] [14]
    - Given Project journal lines suggested from an approved time sheet line with Activity Code set, with the posting setup the project journal posting path reads
    - When The project journal is posted
    - Then Each new Job Ledger Entry for the time sheet has the Activity Code
3. **posting-copies-activity-code-to-res-ledger** [3] [13] [14]
    - Given Project journal lines suggested from an approved time sheet line with Activity Code set, with the full posting setup
    - When The project journal is posted
    - Then Each new Res. Ledger Entry for the time sheet has the Activity Code, and the time sheet line is marked Posted
4. **partly-posted-day-keeps-activity-code** [5] [14]
    - Given An approved time sheet line with Activity Code where part of a day's quantity has already been posted
    - When Suggest Lines from Time Sheets runs again and the resulting journal line is posted
    - Then The new journal line has the open quantity only, and the new Job Ledger Entry and Res. Ledger Entry both have the Activity Code
5. **rejected-line-is-not-suggested** [5] [13]
    - Given A time sheet with one approved line and one rejected line, each with a different Activity Code
    - When Suggest Lines from Time Sheets runs
    - Then Only journal lines for the approved line are created, carrying its Activity Code; no line carries the rejected line's code
6. **archive-keeps-activity-code** [4] [7]
    - Given A time sheet whose lines are all approved and posted, with Activity Code set on each line
    - When Move Time Sheets to Archive runs for that time sheet
    - Then Each Time Sheet Line Archive record has the Activity Code of its original line, and the original lines are deleted
7. **archive-keeps-maximum-length-activity-code** [7]
    - Given A posted time sheet line whose Activity Code uses the full declared field length
    - When Move Time Sheets to Archive runs for that time sheet
    - Then The archived line holds the complete Activity Code without a length error

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown; prefer-related-table-over-extension-on-hot-ledgers applies only from BC23.
- Page extensions time-sheet-page-ext and job-journal-page-ext and the user-entry hop are not covered by BCQuality knowledge; they rest on the agent's judgment, and the exact time sheet page must be confirmed in symbols.
- Permission sets: the design adds no new tables or pages, and no opened article states whether a permission set is needed for the subscriber codeunit and table extensions; this rests on the agent's judgment.

## Sources

[1] `microsoft/knowledge/projects/carry-time-sheet-fields-to-job-journal-through-suggest-lines.md`: Time sheet to project journal hop, its subscriber, and the Job Journal Line and Job Ledger Entry fields
    - Suggest Job Jnl. Lines fills named fields one by one; a custom time sheet field is not copied, and matching field numbers do not help.
    - Subscribe to OnAfterTransferTimeSheetDetailToJobJnlLine on report Suggest Job Jnl. Lines; copy a line-level value from the temporary time sheet line and a per-day value from Time Sheet Detail.
    - Assign without Modify because the line is not inserted yet.
    - Job Transfer Line events for purchase and planning lines are not raised on this path.
    - Do not subscribe to OnAfterJobLedgEntryInsert, re-read the time sheet line and Modify the ledger entry.
[2] `microsoft/knowledge/projects/carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md`: Project journal to project ledger hop and its subscriber
    - Job Transfer Line.FromJnlLineToLedgEntry copies field by field; matching field numbers do nothing.
    - Subscribe to OnAfterFromJnlLineToLedgEntry on codeunit Job Transfer Line to copy the value while the entry is built; OnBeforeJobLedgEntryInsert is an alternative only for computed values.
    - Do not subscribe to OnAfterJobLedgEntryInsert and Modify the inserted entry.
[3] `microsoft/knowledge/projects/time-sheet-posting-runs-in-res-jnl-post-line.md`: Resource ledger path: Res. Journal Line and Res. Ledger Entry fields and their two subscribers
    - Extending only Job Journal Line and Res. Ledger Entry leaves the field empty; the resource journal line in between is built field by field.
    - Add the field to Res. Journal Line and Res. Ledger Entry, copy it with the event of each source path the design needs (OnAfterCopyResJnlLineFromJobJnlLine for the project journal), then to the ledger with OnAfterCopyFromResJnlLine.
    - Do not write code that updates Time Sheet Detail or inserts Time Sheet Posting Entry; keep the three time sheet fields on the line.
[4] `microsoft/knowledge/projects/time-sheet-archive-copies-fields-by-field-number.md`: Archive stage: Time Sheet Line Archive field mirrored by number and type
    - MoveTimeSheetToArchive uses TransferFields and then deletes the originals.
    - Give the archive table the same field, with the same number and type, as the live table; use the OnBefore...ArchiveInsert events only for computed values or values with no matching field.
    - Only time sheets whose lines are all Approved and Posted can be archived.
    - A different field number or type on the archive leaves the archived value empty, and it cannot be recovered.
[5] `microsoft/knowledge/projects/time-sheet-hours-post-per-day-only-when-approved.md`: Per-day granularity of the suggested lines and the partly posted and rejected test scenarios
    - Suggest creates one journal line per Time Sheet Detail, only for Approved and unposted lines, with quantity GetMaxQtyToPost.
    - Expect several journal lines, and several ledger entries, for one time sheet line.
    - Tests should cover a partly posted day and a rejected line.
[6] `microsoft/knowledge/projects/carry-document-fields-to-job-journal-line-on-every-source-path.md`: Scoping which project journal line sources carry the Activity Code
    - Job Transfer Line builds project journal lines from purchase lines, planning lines, planning sales lines and general journal lines, field by field, each with its own OnAfterFrom...ToJnlLine event.
    - Decide in the design which sources must carry the value, and subscribe to the matching Job Transfer Line events for each.
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Time Sheet Line to Time Sheet Line Archive mirror and the maximum-length archive test
    - A field mirrored across a TransferFields cascade must have the same field number, data type and length on every table in the cascade, from the start.
    - A shorter length on one side compiles and fails only when a real value exceeds it.
[8] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing the Activity Code field if it is related to a table of valid codes
    - With an unconditional TableRelation, the field must have the same type and exact length as the related field.
    - Read the related field's declared type and length from its table definition; do not assume Code[10] or Code[20].
[9] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing stored tableextension fields on Job Ledger Entry and Res. Ledger Entry (applies from BC23)
    - Put optional, sparse or integration attributes on hot ledgers in a related table keyed by the entry number.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[10] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every Activity Code field
    - A tableextension has no table-level classification to inherit; every Normal field it adds must set its own DataClassification.
    - Choose the classification that matches the stored data when the field is defined; do not use SystemMetadata for customer data.
[11] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release check on the new fields
    - No field may ship with DataClassification = ToBeClassified.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for resources, projects and time sheets in the tests
    - Create prerequisite records with the test Library codeunits, parents first, and Validate foreign keys; do not hand-roll Init/Insert.
[13] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Preconditions for the suggest and posting tests
    - A posting test's GIVEN must set up every posting setup and date the path reads, not just the primary record.
    - A test that claims filtering logic must include a record that should be excluded.
[14] `microsoft/knowledge/testing/test-one-when-per-test.md`: Splitting the posting assertions into separate tests
    - Each test has exactly one WHEN; preconditions such as suggesting the journal belong in GIVEN.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
