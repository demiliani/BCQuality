# Feature design

> Quality wants an Inspection Certificate printed from our custom Inspection document and emailed to the customer. Some customers want their own certificate layout, and the certificate must show the item's GTIN as a barcode.

**Result:** Complete design. **Business process:** Print and email an Inspection Certificate from the custom Inspection document to the customer, through the standard Report Selections / Document Layouts printing and the Email module, with the item's GTIN as a barcode. **Knowledge used:** 18 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Which field on the Inspection identifies the customer the certificate is sent to (and whose Document Layouts apply)? If the Inspection has no customer, a field must be added and classified. _(affects: certificate-dispatch, certificate-report, inspection-page-actions)_
2. Is the Inspection document posted? Should the certificate print from the open Inspection, the posted Inspection, or both (and should a posted inspection support Post and Send via Document Sending Profile)? _(affects: certificate-report, certificate-dispatch, inspection-page-actions)_
3. Which barcode symbology should encode the GTIN (for example EAN-13, Code 128, or a 2D code such as QR), and what should happen when the item has no GTIN or a GTIN invalid for that symbology: error, or print without a barcode? _(affects: certificate-report, gtin-barcode-column-encoded, invalid-gtin-rejected)_
4. Which layout is the company default, and will customer-specific layouts be supplied by us as additional rendering layouts in the report or designed by users on Report Layouts and assigned in Document Layouts? _(affects: certificate-report, report-selection-subscribers)_
5. Should the email use a report-based email body (Report Selections 'Use for Email Body') and a dedicated email account/Email Scenario for certificates, or the default scenario? _(affects: certificate-dispatch, email-sends-through-report-selections)_
6. Must the certificate email carry the Inspection's attachments, print in the customer's language, or also be sent as an electronic document? _(affects: certificate-dispatch, certificate-report)_
7. Does the Inspection have lines (several items per inspection, each with a GTIN), and should the Inspection list page also get the Print/Email actions? _(affects: certificate-report, inspection-page-actions)_
8. Which Business Central version and runtime does the Inspection app target? The rendering-section layout declaration applies from BC20. _(affects: certificate-report)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | enumextension | Report Selection Usage | Add an 'Inspection Certificate' usage value so the certificate is registered in Report Selections like every standard document, instead of a hardcoded report. |  | [3] [4] [1] |
| 2 | create | enumextension | Custom Report Selection Sales | Add the same 'Inspection Certificate' value to the customer-side page enum so the usage can be shown and picked on Document Layouts (Customer Report Selections) for customers who want their own certificate layout. Customer side only: the certificate goes to customers, so the vendor-side enum 'Report Selection Usage Vendor' is deliberately not extended. |  | [3] [1] |
| 3 | create | report | Inspection Certificate | Document report built on the custom Inspection header (and lines, if the Inspection has lines). Includes the item's GTIN as a column and a barcode-encoded GTIN column produced through the Barcode module (1D: ValidateInput then EncodeFont; 2D: EncodeFont only). Layouts declared in a rendering section with DefaultRenderingLayout set by name, each with Caption and Summary; the default is a Word layout. The 1D barcode text box in the layout names the purchased IDAutomation font (never a 'Demo' font name); a 2D barcode uses IDAutomation2D. Fields read only in triggers (for example the Item GTIN when it is looked up from the Inspection's item in OnAfterGetRecord rather than via an Item dataitem column) are added with AddLoadFields in OnPreDataItem. Dataset column names are a contract for customer-designed layouts once released. | GTIN (column (Code)): Item.GTIN of the inspected item, human-readable.; GTINBarcode (column (Text)): Barcode Font Provider encoded GTIN; symbology is an open question. | [1] [6] [7] [8] [9] [10] |
| 4 | create | codeunit | Inspection Cert. Rep. Sel. Subscribers | Subscribers on page Customer Report Selections that map, validate and filter the new usage so it is visible, selectable and copyable in Document Layouts; the filter subscriber appends to the existing Usage filter, never overwrites it. |  | [3] |
| 5 | create | codeunit | Inspection Certificate Mgt. | Print and Email procedures for the certificate. Inspection-specific checks (for example that the inspection has a customer and is in a printable state) run before the call, then dispatch goes through Report Selections: PrintWithDialogForCust for Print and SendEmailToCust for Email, with the new usage, the filtered Inspection record and the customer number. No hardcoded Report.Run/RunModal and no hand-built email; email sending is therefore done by the Email module through Report Selections, never Codeunit Mail. The customer's assigned Document Sending Profile is not read (no Get/GetDefaultForCustomer + Send). |  | [4] [5] [11] [1] |
| 6 | modify | page | Inspection Card | Add 'Print Certificate' and 'Email Certificate' actions to the custom Inspection document page(s) in the caller's app; each action sets the selection filter and calls the dispatch codeunit. Whether the Inspection list page also gets the actions is an open question. |  | [5] [4] |
| 7 | create | codeunit | Inspection Certificate Install | Subtype = Install. OnInstallAppPerCompany registers the tenant-wide default with ReportSelections.InsertRecord(usage, sequence, Report::"Inspection Certificate") and seeds the certificate upgrade tag with SetUpgradeTag so the upgrade step does not run again. Reuse the app's existing install codeunit if it has one. |  | [14] [15] [3] |
| 8 | create | codeunit | Inspection Certificate Upgrade | Subtype = Upgrade. Because the Inspection app is already installed at customers, OnUpgradePerCompany registers the default Report Selections row for existing companies, guarded by HasUpgradeTag and ending with SetUpgradeTag; never a DataVersion check. Reuse the app's existing upgrade codeunit if it has one. |  | [14] [16] [15] |
| 9 | create | codeunit | Inspection Upgrade Tag Definitions | Holds the certificate upgrade tag value shared by install and upgrade code and registers it in OnGetPerCompanyUpgradeTags so new companies get it marked complete by SetAllUpgradeTags. |  | [15] [16] |
| 10 | modify | permissionset | Inspection permission set | Grant execute (X) on the Inspection Certificate report and the dispatch codeunit, plus read on any tabledata the report reads that the set does not yet cover, in the app's focused non-assignable building-block set so every role set that includes it inherits the grant; no wildcards, no reliance on SUPER. |  | [17] [18] |

## 3. How the data flows

- **Inspection header (Item No.)** → **Item.GTIN**: other. Report reads the inspected item's GTIN (dataitem link or lookup in OnAfterGetRecord; trigger-only reads use AddLoadFields). [10]
- **Item.GTIN** → **Inspection Certificate dataset column GTINBarcode**: other. Barcode Font Provider ValidateInput + EncodeFont (1D) or Barcode Font Provider 2D EncodeFont (2D); layout names the production font. [6]
- **Install / upgrade code** → **Report Selections (Inspection Certificate usage)**: other. ReportSelections.InsertRecord registers the tenant-wide default report. [3] [14] [16]
- **Customer card > Document Layouts** → **Custom Report Selection (Inspection Certificate usage, per customer)**: entered by the user. Users pick the usage and a customer-specific report/layout; enabled by the customer-side page enum and the map/validate/filter subscribers. [3] [4]
- **Inspection Card Print Certificate action** → **Report Selections.PrintWithDialogForCust**: other. Resolves the report and layout for the inspection's customer, honoring Custom Report Selection overrides. [5] [4]
- **Inspection Card Email Certificate action** → **Report Selections.SendEmailToCust -> Email module**: other. Report Selections renders the certificate per the customer's selection and sends it through the Email module to the customer. [5] [4] [11]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Customer Report Selections | `OnAfterOnMapTableUsageValueToPageValue` | Map the Inspection Certificate table usage to the page enum value so existing rows display in the Usage column. | Act only when CustomReportSelection.Usage is the Inspection Certificate usage. | [3] |
| Customer Report Selections | `OnValidateUsage2OnCaseElse` | Set CustomReportSelection.Usage to the Inspection Certificate usage when the user picks it from the Usage dropdown. | Act only when ReportUsage equals the page enum value's ordinal. | [3] |
| Customer Report Selections | `OnAfterFilterCustomerUsageReportSelections` | Include the Inspection Certificate usage in the filter used by 'Copy from Report Selection'. | Append with StrSubstNo('%1\|%2', ReportSelections.GetFilter(Usage), UsageFilter); never overwrite the existing filter. | [3] |
| Upgrade Tag | `OnGetPerCompanyUpgradeTags` | Register the certificate upgrade tag so SetAllUpgradeTags marks it complete for new companies. |  | [15] |

## 5. Setup, permissions and lifecycle

- **install**: On first install per company, insert the default Report Selections row for the Inspection Certificate usage and seed the certificate upgrade tag. [14] [15] [3]
- **upgrade**: In the upgrade codeunit, register the default Report Selections row for companies that already run the Inspection app, guarded by HasUpgradeTag/SetUpgradeTag; register the tag with OnGetPerCompanyUpgradeTags. [14] [16] [15]
- **setup**: Customer-specific certificate layouts are configured by users on the customer's Document Layouts page (Custom Report Selection); additional layouts are added on Report Layouts. No new setup table. [3] [4] [7]
- **setup**: Barcode fonts need no setup on Business Central online; on-premises the IDAutomation fonts must be purchased and installed. The layout must name the production font. [6]
- **permissions**: Add X on the report and dispatch codeunit to the app's focused building-block permission set; verify print and email as a user holding only the app's roles. [17] [18]
- **privacy**: No new table fields are designed, so no new DataClassification decisions; if an open question adds a field to the Inspection (for example a customer number), classify it then. agent judgment

## 6. Tests

1. **print-uses-registered-report** [5] [12] [13]
    - Given A customer, an item with a GTIN and an Inspection for that customer and item, created with Library codeunits and the app's own fixture helpers, and the default Report Selections row installed
    - When The Print Certificate action runs
    - Then The Inspection Certificate report runs through Report Selections; a request-page handler captures the run and the saved dataset contains the inspection number and the item's GTIN
2. **gtin-barcode-column-encoded** [6] [13]
    - Given An item whose GTIN is valid for the chosen symbology and an Inspection for it
    - When The certificate report is run and its dataset is read
    - Then GTINBarcode equals the Barcode Font Provider EncodeFont result for that GTIN and symbology
3. **invalid-gtin-rejected** [6]
    - Given An item whose GTIN contains characters outside the chosen 1D symbology's character set
    - When The certificate report is run
    - Then ValidateInput raises its error (or the agreed handling for an invalid/blank GTIN applies) instead of an unscannable barcode being printed
4. **customer-specific-selection-wins** [4] [3] [12]
    - Given A Custom Report Selection row for customer A with the Inspection Certificate usage pointing to a different report or layout, and Inspections for customers A and B
    - When The certificate is printed for each inspection
    - Then Customer A's inspection uses the customer-specific selection and customer B's uses the tenant default
5. **document-layouts-map-and-validate** [3]
    - Given A customer and the Customer Report Selections test page opened for it
    - When The user picks Inspection Certificate in Usage and the page is reopened
    - Then The stored Custom Report Selection.Usage is the Inspection Certificate usage (validate subscriber) and the row shows Inspection Certificate in the Usage column (map subscriber)
6. **copy-from-report-selection-appends** [3]
    - Given The default Report Selections row for the Inspection Certificate usage and the existing standard customer usages
    - When Copy from Report Selection runs on Customer Report Selections
    - Then The Inspection Certificate row is copied and the standard customer usages are still copied (filter appended, not overwritten)
7. **email-sends-through-report-selections** [5] [11] [12]
    - Given A customer with an e-mail address, an Inspection for that customer and an email account set up for the test
    - When The Email Certificate action runs
    - Then An email message addressed to the customer is created through the Email module with the certificate attached; the email editor modal page is handled by a handler that captures the recipient and the test asserts it
8. **email-ignores-sending-profile** [5]
    - Given A customer whose assigned Document Sending Profile has E-Mail = No
    - When The Email Certificate action runs
    - Then The certificate email is still created, because the action does not read the assigned profile
9. **install-registers-default** [14] [15] [3]
    - Given A company without a Report Selections row for the Inspection Certificate usage
    - When The install code runs
    - Then A Report Selections row for the usage points to the Inspection Certificate report and the certificate upgrade tag is set
10. **upgrade-runs-once** [16] [14]
    - Given A company upgraded from the previous app version without the certificate upgrade tag
    - When The upgrade codeunit runs twice
    - Then Exactly one default Report Selections row exists and the tag is set after the first run
11. **non-super-user-can-print** [17]
    - Given A user with only the app's assignable permission sets
    - When The certificate is printed and emailed
    - Then Both succeed without SUPER

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- No repository was supplied: the Inspection table, page, existing install/upgrade codeunits and permission sets are named generically and must be mapped to the caller's app.
- bc-version is unknown; the rendering-section rule applies from BC20.
- Sending the Inspection's attachments with the certificate email is not covered by BCQuality knowledge; rests on judgment.
- Printing the certificate in the customer's language is not covered by BCQuality knowledge; rests on judgment.
- Mapping the Inspection Certificate usage to a dedicated Email Scenario when sending through Report Selections.SendEmailToCust is not covered by an opened article; no event for it is designed.
- Privacy lifecycle step rests on judgment (no new fields designed).
- Email test infrastructure (email account fixture and email editor handler) is not covered by an opened article beyond the general UI-handler rule.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-printable-document-and-its-delivery.md`: Process map for the printable, emailed certificate: decides the report, layouts, Report Selections usage, Document Layouts, email and barcode rows, and the open questions for requester decisions.
    - Plan one decision per row and open the linked articles before designing that part.
    - Whether a new layout replaces the company default, whether customers get their own layouts and whether the document is also sent electronically are requester decisions; raise open questions when not settled.
    - Do not add an action that calls Report.RunModal on a new report with an RDLC layout and builds the email by hand.
    - Sending attachments with the email and printing in the customer's language have no BCQuality article and rest on judgment.
[2] `microsoft/knowledge/feature-design/plan-a-custom-document-with-posting.md`: Followed for the Printing row of the custom Inspection document and to raise whether the Inspection is posted (which decides whether the certificate prints from the open or the posted Inspection).
    - A custom document is registered in Report Selections and printed and emailed through it.
    - Whether the document needs posting, archive, approvals or ledger entries is for the requester; raise open questions instead of building or omitting silently.
[3] `microsoft/knowledge/data-modeling/extend-report-selection-usage-for-new-document-types.md`: Registering the Inspection Certificate usage, its tenant-wide default and the customer-side Document Layouts wiring.
    - Add the usage via enumextension of 'Report Selection Usage' and register the default with ReportSelections.InsertRecord(Usage, Sequence, ReportID).
    - For each applicable counterparty, extend the page enum ('Custom Report Selection Sales' for customers) and subscribe to the map, validate and filter events of that page.
    - Append to the Usage filter with StrSubstNo('%1\|%2', ReportSelections.GetFilter(Usage), UsageFilter); never overwrite.
    - Do not subscribe the vendor side for a customer-only document.
[4] `microsoft/knowledge/data-modeling/custom-document-dispatch-must-not-bypass-report-selections.md`: Dispatch codeunit and the requirement that per-customer layouts work through Custom Report Selection.
    - Dispatch through Report Selections' own Print/Email procedures; custom logic goes around the call, not instead of it.
    - A hardcoded report ID is a defect on its own; a hand-built email is a defect on its own.
[5] `microsoft/knowledge/data-modeling/document-print-and-email-actions-call-report-selections-directly.md`: Print and Email actions on the Inspection page and the Post-and-Send boundary.
    - Ordinary Print/Email actions call PrintForCust/PrintWithDialogForCust/SendEmailToCust for a customer-facing document, or Document Sending Profile's stateless TrySendToPrinter/TrySendToEMail helpers.
    - Never Get/GetDefaultForCustomer the assigned profile and call Send from a plain Email button; reserve that for Post and Send.
[6] `microsoft/knowledge/data-modeling/report-barcodes-must-use-barcode-module-and-production-font-name.md`: GTIN barcode on the certificate.
    - Encode through the Barcode module: 1D declares Interface 'Barcode Font Provider' and calls ValidateInput and EncodeFont; 2D declares 'Barcode Font Provider 2D' and calls EncodeFont only.
    - Name the purchased production font in the layout (e.g. IDAutomationHC39M for Code 39; IDAutomation2D for 2D other than Maxicode), never a name containing 'Demo'.
    - On-premises the fonts must be purchased and installed; online they are available automatically.
[7] `microsoft/knowledge/reporting/declare-report-layouts-in-the-rendering-section.md`: Layout declaration of the new report. Applies from BC20 (runtime 9.0).
    - Declare every layout in a rendering section, set DefaultRenderingLayout by name, give each layout a Caption and Summary.
    - Do not use DefaultLayout/RDLCLayout/WordLayout/ExcelLayout in a new report.
[8] `microsoft/knowledge/performance/document-report-word-layout.md`: Default layout type of the certificate.
    - Prefer a Word layout over RDLC for a document report unless specific layout requirements favor RDLC.
[9] `microsoft/knowledge/reporting/do-not-rename-or-remove-shipped-report-dataset-columns.md`: Dataset naming, because customers will build their own certificate layouts on it.
    - Once released, keep existing column names and columns layouts may use; add new columns instead of renaming.
[10] `microsoft/knowledge/performance/addloadfields-in-report-onpredataitem.md`: Fields read only in report triggers, such as the item GTIN looked up for encoding.
    - Add trigger-only fields with AddLoadFields in OnPreDataItem; do not list every dataset column.
[11] `microsoft/knowledge/breaking-changes/prefer-email-module.md`: Email delivery of the certificate.
    - Send through Codeunit Email / 'Email Message' and an Email Scenario so documents can use different accounts; never Codeunit Mail.
[12] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Request-page and email-editor handling in tests.
    - Every UI call on the executed path needs a listed handler; every nonoptional listed handler must execute.
    - Handlers contribute meaningful evidence; assert a captured value after the action.
[13] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers and items.
    - Build prerequisite records with Library codeunits (LibrarySales.CreateCustomer, LibraryInventory.CreateItem), parents first, validating foreign keys.
[14] `microsoft/knowledge/upgrade/install-code-does-not-run-on-version-upgrade.md`: Install versus upgrade path for registering the default Report Selections row.
    - Install code runs only on first install or reinstall, not on version upgrade; put version migration in a Subtype = Upgrade codeunit.
[15] `microsoft/knowledge/upgrade/register-upgrade-tags-with-subscribers.md`: Seeding and registering the certificate upgrade tag.
    - Guard upgrade work with HasUpgradeTag and SetUpgradeTag after completion; seed the tag explicitly from OnInstallAppPerCompany; register it in OnGetPerCompanyUpgradeTags for new companies; share one tag definition.
[16] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Run-once control of the upgrade step.
    - Every upgrade procedure starts with HasUpgradeTag and ends with SetUpgradeTag; never branch on DataVersion; one tag per feature.
[17] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: Permission coverage for the new report and codeunits.
    - Cover every page, report, codeunit and tabledata the feature uses through assignable roles composed from non-assignable sets; validate as a non-SUPER user; no wildcards.
[18] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Where to add the new grants.
    - Add the objects to a focused Assignable = false building block that role sets include via IncludedPermissionSets; do not re-enumerate objects in several role sets.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

