# Feature design

> We rent equipment to customers. Add a Rental Order document with a header and lines, numbered from its own series. When the rental ends the user posts it: the order becomes a Posted Rental Order with a number from a separate posting series, and the rental amount is posted to the G/L. Users must find posted rentals with Find entries, print and email them, and attach signed delivery forms.

**Result:** Complete design. **Business process:** Adds a custom Rental Order document (header and lines, own number series) to the customer-facing rental process, with a posting routine that creates a Posted Rental Order from a separate series and posts the rental amount to the general ledger through the standard general journal posting engine, plus Find Entries, Report Selections printing/email and document attachments. **Knowledge used:** 56 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What does a rental line rent: an Item, a Resource, a Fixed Asset, or a new Equipment master table that this feature must also create (with its own numbering, card, list and Blocked field)? _(affects: rental-line, posted-rental-line, check-reports-all-errors)_
2. How is a line's Rental Amount determined: typed by the user, or calculated from a rate and the rental period (and from which price source)? _(affects: rental-line)_
3. Which G/L account does the rental amount post to, and where does it come from: a Rental Revenue Account in Rental Setup, or the customer's and equipment's posting groups through General Posting Setup? _(affects: rental-setup, rental-gen-jnl-posting)_
4. What is the balancing side of the rental posting: the customer (creating a customer ledger entry / receivable), or a G/L balancing account? The request only says the amount is posted to the G/L. _(affects: rental-gen-jnl-posting, post-writes-rental-amount-to-gl)_
5. Does the rental posting carry VAT? If so, which VAT calculation type, and is Rental Amount VAT-inclusive or VAT-exclusive? _(affects: rental-line, rental-gen-jnl-posting)_
6. Should the G/L entries carry the Posted Rental Order No. as Document No. (so Find Entries shows them together with the posted rental)? That requires the dedicated batch's No. Series to allow it as a manual number; otherwise the batch series number is used. _(affects: rental-gen-jnl-posting, find-entries-finds-posted-rental)_
7. Should one journal document be posted per rental order (total amount) or one journal line per rental line? _(affects: rental-gen-jnl-posting)_
8. Must rental orders carry dimensions (from the customer, the equipment or both) and pass the complete Dimension Set ID to the journal lines and posted tables? Not designed until answered. _(affects: rental-header, rental-line, rental-gen-jnl-posting, posted-rental-header)_
9. Which Customer Blocked values (Ship, Invoice, All) must block creating and posting a rental order? _(affects: rental-header, rental-check)_
10. Is a separate bill-to customer needed, or is one Customer No. enough for posting, printing and emailing? _(affects: rental-header, posted-rental-order-page)_
11. Does the rental order need a status and a release step (Open/Released) before posting, and what does release check? No article covers a custom release routine. _(affects: rental-header, rental-post)_
12. Must rental orders be approved before release or posting? _(affects: rental-header, rental-post)_
13. Must the rental order support Preview Posting? No article covers preview for a custom posting routine. _(affects: rental-post)_
14. Must open rental orders be archived before change or deletion? _(affects: rental-header)_
15. Must the open Rental Order (before posting) also be printable, for example as a delivery note, which would need its own Report Selection Usage? _(affects: report-selection-usage-ext, posted-rental-order-report)_
16. Must customers get their own report or layout for posted rentals in Document Layouts? The design wires the customer-side enum and events; confirm or exclude. _(affects: custom-report-selection-sales-ext, rental-report-selection-subscribers, document-layouts-shows-usage)_
17. Must the signed delivery forms be sent as email attachments together with the posted rental, or only stored on it? _(affects: posted-rental-order-page, email-uses-report-selections)_
18. Should posted rentals be emailed from a dedicated email account (an Email Scenario of their own)? _(affects: posted-rental-order-page)_
19. Must posted rentals also be sent as electronic documents (E-Documents)? _(affects: posted-rental-order-report)_
20. Must the posted rental print in the customer's language? _(affects: posted-rental-order-report)_
21. How is a wrongly posted rental corrected: a reversal of its G/L transaction, or a credit/cancellation document of its own? _(affects: rental-post, rental-gen-jnl-posting)_
22. Should install create default number series and the dedicated journal template/batch, or does an administrator set them up? _(affects: rental-install, rental-setup)_
23. May users delete posted rentals, and if so, what checks apply? _(affects: posted-rental-header, rental-user-permissionset)_
24. Which standard permission sets must rental users also hold to post to the G/L (and customer ledger, if chosen)? _(affects: rental-user-permissionset, post-as-rental-user-without-super)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Rental Setup | Setup-type singleton (Primary Key Code[10], blank) holding the rental document series, the posted rental series, the dedicated general journal template and batch, and the G/L account(s) the rental amount posts to. Every value is checked with TestField before use. | Primary Key (Code[10]): Always blank; sole key.; Rental Order Nos. (Code[20]): TableRelation to No. Series; series for open Rental Orders.; Posted Rental Order Nos. (Code[20]): TableRelation to No. Series; separate series for Posted Rental Orders.; Rental Jnl. Template Name (Code[10]): General journal template reserved for rental posting.; Rental Jnl. Batch Name (Code[10]): General journal batch reserved for rental posting; users must not enter lines in it.; Rental Revenue Account (Code[20]): TableRelation to G/L Account; kept only if the open question on account source chooses a feature setup account. | [1] [2] [3] [4] [5] |
| 2 | create | page | Rental Setup | Card page over Rental Setup with InsertAllowed = false and DeleteAllowed = false; OnOpenPage inserts the blank row when it is missing. |  | [1] [6] |
| 3 | create | table | Rental Header | Document-type header. Primary key No. Code[20]. OnInsert assigns No. from Rental Setup."Rental Order Nos." through codeunit "No. Series" when No. is blank (TestField on the setup series first), stores the series in No. Series, then calls InitRecord, which sets the remaining defaults (Posting Date, Document Date). OnDelete deletes the Rental Lines of the order and calls DeleteAttachedDocuments; OnRename calls MoveAttachmentsWithinSameRecordType. The table declares Permissions = tabledata "Rental Line" = rd. Customer No. OnValidate gets the Customer and checks its Blocked value; the check is repeated before posting. Table-level DataClassification = CustomerContent. | No. (Code[20]): Primary key; from Rental Order Nos.; No. OnValidate guards manual entry with NoSeries.TestManual/IsManual.; Customer No. (Code[20]): TableRelation to Customer; Blocked checked at use.; Customer Name (Text[100]): Copied from the customer on validate; same length as Customer.Name.; Posting Date (Date): Default set in InitRecord.; Document Date (Date): Default set in InitRecord.; Rental Start Date (Date); Rental End Date (Date); No. Series (Code[20]): Non-editable; series that produced No. | [2] [7] [8] [9] [10] [11] [12] [3] [13] [14] |
| 4 | create | table | Rental Line | Document-type line owned by Rental Header. Primary key Document No. + Line No. Each line carries the rented equipment reference and the rental amount that is posted to the G/L. Table-level DataClassification = CustomerContent. | Document No. (Code[20]): TableRelation to Rental Header.No.; Line No. (Integer); Equipment No. (Code[20]): What table it relates to (Item, Resource, Fixed Asset or a new equipment master) is an open question; its length must match the related key field; Blocked of that master is checked at use and before posting.; Description (Text[100]); Rental Amount (Decimal): Amount posted to the G/L; how it is calculated (entered, or rate x period) is an open question. AutoFormatType = 1. | [2] [10] [12] [13] |
| 5 | create | table | Posted Rental Header | Document History table created only by the posting codeunit, never user-editable. Mirrors every Rental Header field with the same field number, data type and length so TransferFields copies them, plus Rental Order No. (the original order number) in a field number that the open header does not use. Primary key No. Code[20] from the posted series. OnDelete (if deletion is allowed at all) calls DeleteAttachedDocuments and deletes its posted lines. Table-level DataClassification = CustomerContent. | No. (Code[20]): From Rental Setup."Posted Rental Order Nos.", assigned by the posting codeunit, not copied from the order.; Rental Order No. (Code[20]): Original Rental Header No.; not mirrored on the open header.; Customer No. (Code[20]): Same field number/type/length as Rental Header.; Customer Name (Text[100]): Same field number/type/length as Rental Header.; Posting Date (Date): Same field number as Rental Header; used by Find Entries.; Document Date (Date); Rental Start Date (Date); Rental End Date (Date); No. Series (Code[20]): Holds the posted series. | [2] [15] [16] [8] [11] [10] [13] |
| 6 | create | table | Posted Rental Line | Document History lines; every Rental Line field mirrored with the same number, type and length; Document No. holds the posted header number. Table-level DataClassification = CustomerContent. | Document No. (Code[20]): Posted Rental Header No.; Line No. (Integer); Equipment No. (Code[20]); Description (Text[100]); Rental Amount (Decimal) | [2] [15] [16] [13] |
| 7 | create | page | Rental Order | Document page over Rental Header with a General FastTab, the lines subpage filtered to the header, the Doc. Attachment List Factbox (SubPageLink Table ID = const(Database::"Rental Header"), No. = field(No.)) and a Post action that calls the Rental-Post (Yes/No) codeunit. No business logic on the page. |  | [6] [11] [17] [18] [19] |
| 8 | create | page | Rental Order Subform | ListPart over Rental Line, SubPageLink to the header No., AutoSplitKey on Line No. |  | [6] [18] |
| 9 | create | page | Rental Orders | List page over Rental Header with CardPageID = Rental Order; the searchable entry point (UsageCategory = Lists). |  | [6] [20] |
| 10 | create | page | Posted Rental Order | Non-editable Document page over Posted Rental Header with a lines ListPart, the Doc. Attachment List Factbox for Posted Rental Header (users attach signed delivery forms here), and Print, Email and Find Entries actions. Print calls ReportSelections.PrintWithDialogForCust and Email calls ReportSelections.SendEmailToCust with the Posted Rental Order usage and the customer number field; neither loads the customer's Document Sending Profile. |  | [6] [11] [21] [22] [17] [18] |
| 11 | create | page | Posted Rental Order Subform | Non-editable ListPart over Posted Rental Line filtered to the posted header. |  | [6] |
| 12 | create | page | Posted Rental Orders | Read-only list over Posted Rental Header, CardPageID = Posted Rental Order, default descending sort so the newest posted rentals come first; also the page Find Entries opens when several posted rentals match. |  | [6] [23] [20] |
| 13 | create | codeunit | Rental-Post (Yes/No) | Called from the Post action. Asks for confirmation before any database write or lock, then runs Rental-Post. Pages never call Rental-Post directly, so Rental-Post can also run unattended. |  | [19] [24] |
| 14 | create | codeunit | Rental-Check | Checks a rental order before posting and reports every blocking problem at once: an [ErrorBehavior(ErrorBehavior::Collect)] procedure runs the checks (customer not blocked, each line's equipment not blocked, required header fields, at least one line with an amount, required Rental Setup fields via TestField) and, if errors were collected, retrieves and clears them with GetCollectedErrors(true) and fails with all messages. Shows no UI other than errors. |  | [25] [12] [3] [19] |
| 15 | create | codeunit | Rental-Post | Document posting routine with TableNo = Rental Header, run through Codeunit.Run so posting is atomic. Raises OnBeforePostRentalOrder(var RentalHeader, var IsHandled) and exits when handled; runs Rental-Check; gets the posted number from Rental Setup."Posted Rental Order Nos." through codeunit "No. Series"; inserts Posted Rental Header and Lines with TransferFields from the order; copies the order's attachments with Document Attachment Mgmt.CopyAttachments after the posted header is inserted; creates the G/L journal lines in the dedicated batch and posts them through Gen. Jnl.-Post Batch with SetSuppressCommit(true) so the posted document and the G/L entries commit or roll back together; deletes the open order and its lines; raises OnAfterPostRentalOrder(var RentalHeader, var PostedRentalHeader). No explicit Commit and no user prompts. Its Permissions property grants the direct rights on the posted tables. Publishers are empty [IntegrationEvent(false, false)] local procedures; events fired while uncommitted posting writes exist carry [CommitBehavior(CommitBehavior::Ignore)]. |  | [19] [26] [27] [28] [5] [8] [15] [11] [29] [30] [31] [32] [14] |
| 16 | create | codeunit | Rental Gen. Jnl. Posting | Called by Rental-Post. Gets Rental Setup and TestFields the journal template, the batch and every account the posting needs (including an account a posting setup getter returns, if posting groups are chosen). Errors if the dedicated batch already contains lines. Creates each Gen. Journal Line with SetUpNewLine from the previous line, Validates Account Type/No., Bal. Account Type/No. and Amount (never assigns them), keeps each document balanced, sets the description and the source posted rental number, and runs Gen. Jnl.-Post Batch after SetSuppressCommit(true). Never inserts G/L Entry rows itself. |  | [5] [28] [33] [3] [4] [34] |
| 17 | create | codeunit | Rental Navigate Subscribers | Adds Posted Rental Header to Find Entries: OnAfterFindRecords filters it by DocNoFilter and PostingDateFilter and calls InsertIntoDocEntry; OnBeforeShowRecords re-applies the filters, opens Posted Rental Order for one record or Posted Rental Orders for several, and sets IsHandled. Both are built as one unit. No extra key is needed because the filter is on the posted table's own No. |  | [35] |
| 18 | create | codeunit | Rental Attachment Subscribers | Maps Rental Header and Posted Rental Header to Document Attachment: returns field 1 (No. Code[20]) as the number field for both tables, resolves the record from DocumentAttachment.No., marks Rental Header as an entity so a rename moves only its files, and filters the copy source on the order No. and sets ToNo to the posted No. when the posting codeunit copies attachments. |  | [11] |
| 19 | create | enumextension | Report Selection Usage | Adds the value Posted Rental Order so the posted document is registered in Report Selections. |  | [36] [22] |
| 20 | create | enumextension | Custom Report Selection Sales | Adds the same Posted Rental Order value to the customer-side page enum so the usage can be used on Document Layouts. Customer side only: the rental is issued to customers, so Report Selection Usage Vendor is not extended. |  | [36] |
| 21 | create | codeunit | Rental Report Selection Subscribers | Customer Report Selections triad for the Posted Rental Order usage: map the table value to the page value, map the picked page value back on validate, and append (never overwrite) the usage to the Copy from Report Selection filter. |  | [36] |
| 22 | create | report | Posted Rental Order | Document report over Posted Rental Header and Posted Rental Line. Layouts declared in the rendering section with Caption and Summary, DefaultRenderingLayout set to a Word layout. Dataset column names are a contract from the first release: add columns later, never rename or remove them. |  | [37] [38] [39] [40] |
| 23 | create | codeunit | Rental Install | Subtype = Install. On first install or reinstall per company registers the tenant-wide default with ReportSelections.InsertRecord(Posted Rental Order usage, '1', Report::"Posted Rental Order") when no row exists. Does not hard-code G/L accounts. |  | [41] [36] [4] |
| 24 | create | codeunit | Rental Upgrade | Subtype = Upgrade, entered from OnUpgradePerCompany, for data changes in later versions; each step guarded with HasUpgradeTag and closed with SetUpgradeTag. |  | [41] [42] |
| 25 | create | permissionset | Rental - Objects | Assignable = false building block: execute on the rental codeunits, pages and report; tabledata Rental Setup and the open rental tables. Every object listed explicitly, no wildcards. |  | [43] [44] [45] |
| 26 | create | permissionset | Rental - Post | Assignable role that includes Rental - Objects. Grants RIMD on Rental Header and Rental Line, R on Rental Setup, and only indirect rights (r plus the letters posting needs, such as i and m) on Posted Rental Header and Posted Rental Line, so posted rentals are written only through Rental-Post. |  | [43] [32] [45] [44] |
| 27 | create | permissionset | Rental - Setup | Assignable role that includes Rental - Objects and grants RIM on Rental Setup so an administrator can complete setup without SUPER. |  | [43] [45] [44] |
| 28 | create | codeunit | Rental Posting Tests | Test codeunit (Subtype = Test) with [FEATURE] tag and [SCENARIO]/[GIVEN]/[WHEN]/[THEN] per test; fixtures from library codeunits; posted data created only by posting. |  | [46] [47] [48] [49] |

## 3. How the data flows

- **Rental Setup.Rental Order Nos.** → **Rental Header.No.**: other. Rental Header.OnInsert: TestField the series, NoSeries.GetNextNo, store No. Series, then InitRecord. [7] [8] [3] [9]
- **Customer** → **Rental Header.Customer No. / Customer Name**: field validation. User picks the customer; OnValidate gets the customer, checks Blocked and copies the name. [12]
- **User** → **Rental Line (Equipment No., Description, Rental Amount)**: entered by the user. Equipment reference and amount rule depend on open questions. [12]
- **Rental Setup.Posted Rental Order Nos.** → **Posted Rental Header.No.**: other. Rental-Post: TestField and NoSeries.GetNextNo on the posted series; the order number goes to Rental Order No. [8] [3] [14]
- **Rental Header** → **Posted Rental Header**: standard TransferFields copy. PostedRentalHeader.TransferFields(RentalHeader) then set No., No. Series and Rental Order No.; every mirrored field has the same number, type and length; SkipFieldsNotMatchingType is not used. [15] [16]
- **Rental Line** → **Posted Rental Line**: standard TransferFields copy. Per line, then Document No. := posted header No. [15] [16]
- **Rental Header / Rental Line** → **Gen. Journal Line (dedicated rental batch)**: field validation. SetUpNewLine from the previous line, then Validate account, balancing account and Amount; posting date and description from the order; amounts per open question on VAT and grouping. [5] [33] [34]
- **Gen. Journal Line** → **G/L Entry**: other. Gen. Jnl.-Post Batch with SetSuppressCommit(true); the posting engine creates the entries and the register. [28] [5] [50]
- **Document Attachment (Rental Header)** → **Document Attachment (Posted Rental Header)**: other. Rental-Post calls CopyAttachments(FromRecRef, ToRecRef) after inserting the posted header; subscribers filter the source No. and set ToNo. [11]
- **User** → **Document Attachment (Rental Header / Posted Rental Header)**: entered by the user. Signed delivery forms uploaded through the Doc. Attachment List Factbox on either page. [11]
- **Posted Rental Header** → **Find Entries (Document Entry)**: copied in an event subscriber. OnAfterFindRecords adds the count; OnBeforeShowRecords opens the posted pages. [35]
- **Posted Rental Header** → **Posted Rental Order report (print / email)**: other. Report Selections usage Posted Rental Order; PrintWithDialogForCust / SendEmailToCust. [36] [22] [21]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Navigate | `OnAfterFindRecords` | Count Posted Rental Header records matching the document number and posting date filters and add them with InsertIntoDocEntry. | Filter on DocNoFilter and PostingDateFilter before counting | [35] |
| Navigate | `OnBeforeShowRecords` | Open Posted Rental Order (one record) or Posted Rental Orders (several) for the rental row. | Exit unless TempDocumentEntry."Table ID" = Database::"Posted Rental Header" · Set IsHandled := true only for the rental row | [35] |
| Document Attachment Mgmt | `OnAfterTableHasNumberFieldPrimaryKey` | Return field 1 (No.) as the number field for Rental Header and Posted Rental Header. | Only for the two rental table IDs | [11] |
| Document Attachment Mgmt | `OnAfterGetRefTable` | Get the Rental Header or Posted Rental Header from DocumentAttachment.No. so the factbox can upload and open files. | Case on DocumentAttachment."Table ID"; RecRef only set when Get succeeds | [11] |
| Document Attachment Mgmt | `OnAfterTableIsEntity` | Mark Rental Header as an entity so a rename moves only that order's files. | Only for Rental Header | [11] |
| Document Attachment Mgmt | `OnCopyAttachmentsOnAfterSetFromParameters` | Filter the copy source on the order's No. so only that order's attachments are copied on posting. | Only when FromRecRef.Number() = Database::"Rental Header" | [11] |
| Document Attachment Mgmt | `OnCopyAttachmentsOnAfterSetToParameters` | Set ToFieldRef and ToNo to the Posted Rental Header No. | Only when ToRecRef.Number() = Database::"Posted Rental Header" | [11] |
| Customer Report Selections | `OnAfterOnMapTableUsageValueToPageValue` | Show the Posted Rental Order usage in the Usage column of Document Layouts. | Only for the Posted Rental Order usage | [36] |
| Customer Report Selections | `OnValidateUsage2OnCaseElse` | Map the picked Posted Rental Order page value back to the Report Selection Usage value. | Only for the Posted Rental Order page value | [36] |
| Customer Report Selections | `OnAfterFilterCustomerUsageReportSelections` | Append the Posted Rental Order usage to the Copy from Report Selection filter. | Append with StrSubstNo('%1\|%2', existing filter, usage); never overwrite | [36] |

## 5. Setup, permissions and lifecycle

- **setup**: Rental Setup card: users fill Rental Order Nos., Posted Rental Order Nos., the dedicated journal template and batch and the posting account(s); code TestFields each before use, and a test blanks each one to prove the error. [1] [3] [5] [4]
- **install**: Install codeunit registers the tenant-wide Report Selections default for the Posted Rental Order usage on first install/reinstall; it creates no G/L accounts or number series (see open question). [41] [36]
- **upgrade**: Separate upgrade codeunit for later data migrations, each step behind its own upgrade tag. [41] [42]
- **permissions**: Ship Rental - Objects (non-assignable), Rental - Post and Rental - Setup (assignable); posted tables granted indirectly to users, direct rights on Rental-Post's Permissions property; no wildcards; verify setup and posting as a non-SUPER user. [43] [32] [45] [44]
- **privacy**: Table-level DataClassification = CustomerContent on Rental Setup, Rental Header/Line and Posted Rental Header/Line; field-level overrides only where a field stores a different kind of data; no ToBeClassified at release. [13] [51]
- **other**: Group all rental objects in one feature folder (for example src/Rental/) consistent with the app's convention. [52]

## 6. Tests

1. **post-creates-posted-rental-with-posting-series** [47] [8] [15] [53] [46]
    - Given Rental Setup with distinct Rental Order Nos. and Posted Rental Order Nos. series, a customer from LibrarySales and a rental order with two lines
    - When The order is posted through Rental-Post
    - Then A Posted Rental Header exists whose No. is the next number of the posted series, Rental Order No. equals the order number, the header fields and both lines equal the order values, and the open order and its lines no longer exist
2. **post-writes-rental-amount-to-gl** [28] [5] [47]
    - Given A rental order with a known total Rental Amount and configured posting accounts
    - When The order is posted
    - Then G/L entries for the posting date and document number carry the rental amount on the revenue account and the balancing side, created by the posting engine (a G/L register exists)
3. **post-rolls-back-when-gl-posting-fails** [5] [27] [49]
    - Given A rental order and a blank posting account that makes journal posting fail after the posted header was inserted
    - When The order is posted
    - Then An error is raised and no Posted Rental Header, Posted Rental Line or G/L entry exists, and the open order is unchanged (SetSuppressCommit kept one transaction)
4. **post-does-not-post-user-lines-in-batch** [5]
    - Given A user line already exists in the dedicated rental journal batch
    - When A rental order is posted
    - Then Posting fails with the batch-not-empty error and the user's line is not posted
5. **blank-setup-series-errors** [3]
    - Given Rental Setup with a blank Posted Rental Order Nos.
    - When A rental order is posted
    - Then The error names the Posted Rental Order Nos. field; a separate test blanks Rental Order Nos. and inserts an order
6. **check-reports-all-errors** [25] [12]
    - Given A rental order with a blocked customer and a line without an amount
    - When Rental-Check runs
    - Then One error is raised whose text contains both problems, and nothing is posted
7. **find-entries-finds-posted-rental** [35] [54]
    - Given A posted rental created by posting
    - When Find Entries is run for its No. and Posting Date
    - Then The Document Entry list has a Posted Rental Header row with count 1, and Show Records opens Posted Rental Order on that record (page handler captures the No.)
8. **print-uses-report-selections** [36] [22] [21] [54]
    - Given A posted rental and the Posted Rental Order usage registered in Report Selections
    - When Print is invoked on the posted rental
    - Then The report registered for the usage runs for that record (request page handler captures it); changing the registered report changes what runs
9. **email-uses-report-selections** [21] [55] [54]
    - Given A posted rental for a customer with an email address
    - When Email is invoked on the posted rental
    - Then SendEmailToCust is used with the Posted Rental Order usage, independent of the customer's Document Sending Profile (email editor handled by a modal page handler)
10. **document-layouts-shows-usage** [36]
    - Given The Posted Rental Order usage and the customer page enum extension
    - When A user picks Posted Rental Order in Document Layouts for a customer
    - Then The Custom Report Selection row stores the Posted Rental Order Report Selection Usage and shows it in the Usage column
11. **attachments-copied-on-posting** [11]
    - Given Two rental orders, each with its own attachment
    - When One order is posted
    - Then The posted rental has exactly that order's attachment with No. = posted No., and the other order's attachment is untouched
12. **delete-order-deletes-only-its-lines-and-files** [10] [11]
    - Given Two rental orders with lines and attachments
    - When One order is deleted
    - Then Its lines and attachments are gone; the other order's lines and attachments remain
13. **post-as-rental-user-without-super** [56] [32] [45]
    - Given A rental order and the test user lowered to the Rental - Post role (plus the standard posting rights the open question settles)
    - When The user posts the order
    - Then Posting succeeds, and the user has no direct write permission on Posted Rental Header (WritePermission is false)
14. **new-order-gets-defaults-on-every-path** [9] [7]
    - Given Rental Setup with a series
    - When A Rental Header is inserted from code with Insert(true) and no page
    - Then No., No. Series, Posting Date and Document Date are set by OnInsert/InitRecord

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version is unknown: no repository or app.json; tooltip inheritance on table fields applies from BC24 (runtime 13.0) and the rendering section from runtime 9.0.
- Status and release of the rental order: no BCQuality article covers a custom release routine; rests on judgment (open question status-release).
- Posting preview for the custom Rental-Post routine: no BCQuality article covers it; not designed (open question posting-preview).
- Archive of open rental orders: no BCQuality article covers a custom archive; not designed (open question archive).
- Sending stored attachments with the email: no BCQuality article; rests on judgment (open question email-attachments).
- Document language of the printed posted rental: no BCQuality article; rests on judgment.
- Deleting the open Rental Order and its lines after posting follows the request ('the order becomes a Posted Rental Order'); no article states it for a custom document.
- The Rental Order No. field on the posted header (link to the original order) rests on agent judgment.

## Sources

[1] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Rental Setup singleton and its card.
    - Primary Key Code[10] blank is the sole key.
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard that inserts the missing row.
[2] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Table types: Setup for Rental Setup, Document for Rental Header/Line, Document History for the posted tables.
    - Document header key Code[20] No.; line key = header key renamed Document No. + Integer Line No.
    - Document History is a posted copy created during posting, mirrors the source fields and is never user-editable.
    - Setup has a blank Code[10] Primary Key and one record.
[3] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guarding every setup value the posting needs.
    - TestField a required setup field before use; never fall back to a default when it is blank.
    - Write a test that blanks the setup field and asserts the error.
[4] `microsoft/knowledge/feature-design/plan-gl-account-determination-for-a-finance-feature.md`: Map for how the rental amount reaches the G/L: account source, missing-account check, dedicated batch, balance, dimensions, VAT, corrections.
    - Choose posting groups or a feature setup account as the account source; never hard-code accounts.
    - Check every account before creating journal lines, including values a posting setup getter returns.
    - Which account the amount belongs to is an accounting decision for the requester.
[5] `microsoft/knowledge/finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md`: Dedicated rental journal batch and how lines are created and posted.
    - Give the feature its own journal template and batch named in setup; TestField them before creating lines.
    - Create lines with SetUpNewLine and Validate the account fields rather than assigning them.
    - Gen. Jnl.-Post Batch posts every line in the batch and commits unless SetSuppressCommit(true) was called; decide the transaction boundary in the design.
    - A document number must be the batch series' next number or allowed as a manual number by that series.
[6] `microsoft/knowledge/ui/page-design-must-match-bc-page-type-conventions.md`: Page types and links for the rental pages.
    - Document page has FastTabs plus a lines subpage filtered to the header.
    - List page sets CardPageID to its card when one exists.
    - ListPart subpage SubPageLink must filter to the host record.
[7] `microsoft/knowledge/data-modeling/master-table-no-from-number-series-in-oninsert.md`: Number assignment in Rental Header.OnInsert.
    - When No. is blank, OnInsert reads setup, TestFields the series, stores it in No. Series and assigns No. from the series.
    - No. Code[20] is the key; do not use AutoIncrement, GUID or SystemId as the business key.
[8] `microsoft/knowledge/data-modeling/use-no-series-codeunit-not-noseriesmanagement.md`: Codeunit "No. Series" for both the rental and the posted rental number.
    - Use codeunit "No. Series" (GetNextNo, IsManual/TestManual); never NoSeriesManagement.
[9] `microsoft/knowledge/data-modeling/initialize-document-defaults-in-initrecord.md`: Rental Header defaults set in InitRecord after the number is assigned.
    - Assign the document number, then call InitRecord, which holds the remaining defaults.
    - Do not set defaults in page triggers.
[10] `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`: Rental Header deletes its lines in OnDelete.
    - The owning table deletes its dependents in OnDelete, filtered on the foreign key.
    - Declare Permissions = tabledata <dependent> = rd on the owning table.
[11] `microsoft/knowledge/data-modeling/enable-document-attachments-on-custom-tables.md`: Attaching signed delivery forms to rental orders and posted rentals, and copying them on posting.
    - Subscribe OnAfterTableHasNumberFieldPrimaryKey, OnAfterGetRefTable and OnAfterTableIsEntity for the custom tables.
    - Add Doc. Attachment List Factbox with SubPageLink on Table ID and No.
    - Call DeleteAttachedDocuments in OnDelete and MoveAttachmentsWithinSameRecordType in OnRename.
    - After inserting the posted record call CopyAttachments and subscribe the copy From/To parameter events; CopyAttachmentsForPostedDocs is not an option for a custom table.
    - The key must be Code[20] No.
[12] `microsoft/knowledge/data-modeling/check-blocked-in-referencing-code-not-in-master.md`: Blocked checks for the customer and the rented equipment at use and before posting.
    - The referencing record checks the master's Blocked in OnValidate and again before posting.
    - An option-style Blocked needs the specific option compared at each path.
[13] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Data classification of the new tables.
    - A table-level DataClassification is the default for its Normal fields; override per field only where the data differs.
[14] `microsoft/knowledge/feature-design/plan-a-custom-document-with-posting.md`: Map for the custom posted document: which parts to plan (numbering, posting structure, posted tables, Navigate, printing, attachments, permissions, tests) and which rows rest on judgment.
    - Plan header and lines, numbering, posting structure, checks, ledger effects, posted tables, Navigate, printing, attachments and permissions before building.
    - Status/release, posting preview and archive have no article for a custom document and rest on judgment.
    - Whether the document needs an archive, a preview, approvals or ledger entries is for the requester; unsettled rows become open questions.
[15] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field mirroring between open and posted rental tables.
    - Every mirrored field has the same field number, data type and length on every table in the TransferFields cascade.
[16] `microsoft/knowledge/data-modeling/transferfields-skip-type-mismatch-can-drop-data.md`: TransferFields from the order to the posted tables.
    - Use TransferFields only when every required field shares number and type; do not use SkipFieldsNotMatchingType = true to hide mismatches.
    - Map fields the destination needs explicitly when they do not match.
[17] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Pages call codeunits.
    - Business operations (posting, checks) live in codeunits or the table, not in page triggers.
[18] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on rental pages.
    - Every user-facing field has an explicit or inherited non-empty tooltip; on runtime 13.0+ define it on the table field (applies from BC24).
[19] `microsoft/knowledge/data-modeling/check-post-line-batch-pattern.md`: Shape of the posting codeunits and the Post action.
    - A document posting routine calls line posting directly and skips batch posting.
    - A -Post document codeunit is never called directly from a page; the page calls a -Post (Yes/No) wrapper so -Post can run unattended.
    - Do not build one monolithic codeunit that validates, writes entries and shows dialogs.
[20] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Page names.
    - A page's name must match its source table's entity.
[21] `microsoft/knowledge/data-modeling/document-print-and-email-actions-call-report-selections-directly.md`: Print and Email actions on the posted rental.
    - Ordinary Print/Email actions call PrintWithDialogForCust/SendEmailToCust (or the TrySendTo helpers) directly.
    - Do not load the customer's assigned Document Sending Profile for a plain Email action; reserve it for Post and Send.
[22] `microsoft/knowledge/data-modeling/custom-document-dispatch-must-not-bypass-report-selections.md`: No hard-coded report or hand-built email.
    - Dispatch through Report Selections' Print/Email procedures; custom logic goes around the call, not instead of it.
[23] `microsoft/knowledge/ui/default-descending-sort-on-historical-pages.md`: Posted Rental Orders list sorting.
    - History pages default to a descending sort so the newest records come first.
[24] `microsoft/knowledge/performance/avoid-user-prompts-inside-transactions.md`: Confirmation before posting writes.
    - Ask the user before any database write that takes a lock; never prompt inside the write transaction.
[25] `microsoft/knowledge/error-handling/collect-validation-errors-with-errorbehavior.md`: Rental-Check reports all blocking problems at once.
    - Mark the orchestrating procedure [ErrorBehavior(ErrorBehavior::Collect)].
    - Retrieve and clear with GetCollectedErrors(true) and fail the operation with the collected messages; never replace failure with Message.
[26] `microsoft/knowledge/performance/understand-implicit-transaction-boundary.md`: No explicit Commit in rental posting.
    - Default to no explicit Commit(); the runtime commits when execution completes and rolls back on error.
    - Use Commit() only with a specific reason.
[27] `microsoft/knowledge/performance/codeunit-run-as-atomic-sub-operation.md`: Atomic posting.
    - Run work that must complete fully or not at all through Codeunit.Run and react to its return value; a caller already in a write transaction must commit first.
[28] `microsoft/knowledge/finance/post-ledger-entries-through-posting-codeunits.md`: G/L entries only through the posting engine.
    - Create G/L entries through the owning journal posting workflow, for a persisted batch through Gen. Jnl.-Post Batch.
    - Never insert G/L Entry or other Finance-owned ledger records directly.
[29] `microsoft/knowledge/events/publish-thin-onbefore-onafter-integration-events.md`: Events published by the rental posting routine.
    - Raise OnBeforeX(var Rec, var IsHandled) and OnAfterX(var Rec) at the routine's boundaries.
    - Publishers are [IntegrationEvent(false, false)] local procedures with empty bodies.
[30] `microsoft/knowledge/events/use-ishandled-to-make-base-behaviour-overridable.md`: Overridable posting entry.
    - Raise OnBefore(..., var IsHandled) first and exit if IsHandled before any default logic.
[31] `microsoft/knowledge/security/commitbehavior-attribute-scopes-explicit-commits.md`: Protecting the rental posting events from subscriber commits.
    - Annotate publishers fired while uncommitted atomic writes exist with [CommitBehavior(CommitBehavior::Ignore)]; not every publisher needs it.
    - The attribute does not suppress the implicit commit of a nested Codeunit.Run.
[32] `microsoft/knowledge/security/indirect-permissions-for-elevated-access.md`: Indirect rights on the posted rental tables.
    - Grant lowercase (indirect) rights when a role writes a table only through a specific codeunit; that codeunit supplies the direct rights.
    - Do not grant RIMD on posted/system-of-record tables to users.
[33] `microsoft/knowledge/finance/preserve-journal-batch-document-balance.md`: Balance of the rental journal documents.
    - Keep balancing lines in the same document/date group when the template forces document balance; post persisted batches through the batch workflow.
[34] `microsoft/knowledge/finance/normal-vat-journal-amount-includes-vat.md`: Open question on whether the rental posting carries VAT.
    - With Automatic VAT Entry and Normal VAT, journal Amount includes VAT; supply the VAT-inclusive total in that mode.
    - Other VAT calculation types need their own analysis.
[35] `microsoft/knowledge/data-modeling/extend-find-entries-navigate-for-new-document-types.md`: Find Entries support for posted rentals.
    - Subscribe to Navigate OnAfterFindRecords and OnBeforeShowRecords together.
    - In OnBeforeShowRecords check the Table ID, re-apply the filters, open the page and set IsHandled.
[36] `microsoft/knowledge/data-modeling/extend-report-selection-usage-for-new-document-types.md`: Report Selections registration and Document Layouts wiring for the posted rental.
    - Add a Report Selection Usage value and register the tenant-wide default with InsertRecord.
    - For each applicable counterparty side only, extend the page enum and subscribe the map, validate and filter events; append to filters, never overwrite.
[37] `microsoft/knowledge/reporting/declare-report-layouts-in-the-rendering-section.md`: Layout declaration of the Posted Rental Order report.
    - Declare every layout in rendering with Caption and Summary and set DefaultRenderingLayout; do not use the legacy layout properties.
[38] `microsoft/knowledge/performance/document-report-word-layout.md`: Default layout type.
    - Document reports prefer a Word layout over RDLC unless layout requirements favour RDLC.
[39] `microsoft/knowledge/reporting/do-not-rename-or-remove-shipped-report-dataset-columns.md`: Report dataset contract.
    - After release keep column names and columns; add new columns rather than renaming or removing.
[40] `microsoft/knowledge/feature-design/plan-a-printable-document-and-its-delivery.md`: Map for printing and emailing the posted rental: report, layouts, Report Selections, print/email actions, attachments and tests.
    - Register a custom document under its own Report Selection Usage and print/email through Report Selections.
    - Sending attachments with the email and document language have no article and rest on judgment.
    - Whether customers get their own layouts and whether the document must also be sent electronically are decisions for the requester.
[41] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Install vs upgrade code.
    - Install code runs on first install/reinstall only; version migration goes in an Upgrade codeunit.
[42] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Upgrade steps.
    - Guard each upgrade step with HasUpgradeTag and record SetUpgradeTag; no version checks.
[43] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Small non-assignable building blocks composed into assignable role sets with IncludedPermissionSets.
[44] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Explicit permission entries.
    - Enumerate each tabledata and object; no * grants; only the letters needed.
[45] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Coverage of setup and usage without SUPER.
    - Permission sets must cover setup and normal usage; validate as a user with only the app roles.
[46] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test codeunit structure.
    - [FEATURE] on the codeunit; [SCENARIO], [GIVEN], [WHEN], [THEN] in each test.
[47] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, G/L accounts and values with library codeunits; create parents before dependents and Validate foreign keys.
[48] `microsoft/knowledge/testing/triage-posted-table-license-failures-against-baseline.md`: Posted data in tests.
    - Create posted data by posting through the standard routine, not by inserting posted rows.
[49] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Transaction model of posting tests.
    - Do not declare AutoRollback on tests whose code under test calls Commit; use AutoCommit with a TestIsolation runner.
[50] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Corrections of posted rentals.
    - Correct posted financial effects by reversal or a new posting, never by editing or deleting entries.
[51] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of classifications.
    - No ToBeClassified in a released extension.
[52] `microsoft/knowledge/style/source-organized-by-feature-not-object-type.md`: Source layout.
    - Group the feature's files by feature folder, consistently with the project's convention.
[53] `microsoft/knowledge/testing/test-one-when-per-test.md`: Test shape.
    - One [WHEN] action per test; posting as a precondition belongs in [GIVEN].
[54] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Print, email and Find Entries tests.
    - Every UI call needs a listed handler and every nonoptional handler must run; handlers capture values the test asserts.
[55] `microsoft/knowledge/breaking-changes/prefer-email-module.md`: Email delivery of posted rentals.
    - Build on the Email module (Email, Email Message) and route through an Email Scenario; do not use Codeunit Mail.
[56] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: Permission test of rental posting.
    - Use TestPermissions Restrictive and lower the user with Permissions Mock/Library - Lower Permissions to a context containing the permission set or a role including it; for indirect grants assert WritePermission is false.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

