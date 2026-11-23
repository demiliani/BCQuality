---
bc-version: [all]
domain: feature-design
keywords: [feature-design, document-report, report-layout, report-selections, document-layouts, email, document-sending-profile, report-extension, e-documents, barcode]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a printable document and its delivery

## Description

Requests such as "print a delivery note for our rental orders", "add the batch number to the invoice" or "email the inspection certificate to the customer" decide more than a report object. The dataset is a contract that user-defined layouts bind to. The layout has to be declared and selected. The document has to be found through Report Selections so that per-customer layouts, email bodies and the Post and Send action work. Delivery may also go through email, attachments or an electronic document format.

Each of these parts has a rule in BCQuality, spread across the reporting, data-modeling, e-documents and breaking-changes domains. Without a plan, an agent writes a report and an action that runs it, and the customer's own layouts, Document Layouts and email setup stop applying.

## Best Practice

Plan one decision per row, in this order, and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| New report or extension | A report extension adds columns and layouts to a standard report; its triggers run after the base triggers, and its dataitem trigger order is explicit | [report extension triggers run after base](../reporting/reportextension-report-triggers-run-after-base-triggers.md), [dataitem trigger order](../reporting/reportextension-dataitem-trigger-order-is-explicit.md) |
| Dataset | Treat shipped column names as a contract; load the fields the dataset uses; know that `SetTableView` only narrows the dataitem view | [do not rename dataset columns](../reporting/do-not-rename-or-remove-shipped-report-dataset-columns.md), [AddLoadFields in OnPreDataItem](../performance/addloadfields-in-report-onpredataitem.md), [SetTableView cannot broaden](../reporting/settableview-cannot-broaden-dataitemtableview.md) |
| Layouts | Declare every layout in `rendering` with a caption and summary; prefer Word for document reports | [rendering section](../reporting/declare-report-layouts-in-the-rendering-section.md), [Word layout for documents](../performance/document-report-word-layout.md) |
| Layout selection | A layout from a report extension is not used until someone selects it; decide whether that is a setup step | [extension layouts are not selected automatically](../reporting/reportextension-layouts-are-not-selected-automatically.md) |
| Report Selections | Register a custom document under its own `Report Selection Usage`; for a standard document, use the existing usage | [extend Report Selection Usage](../data-modeling/extend-report-selection-usage-for-new-document-types.md) |
| Print and email actions | Run the document through Report Selections, never a hardcoded report or a hand-built email | [do not bypass Report Selections](../data-modeling/custom-document-dispatch-must-not-bypass-report-selections.md) |
| Per-customer or per-vendor layouts | Whether the usage must appear in Document Layouts, which needs the page enum and its events | [extend Report Selection Usage](../data-modeling/extend-report-selection-usage-for-new-document-types.md) |
| Sending profile | Document Sending Profile serves Post and Send; ordinary Print and Email actions call Report Selections | [print and email actions call Report Selections](../data-modeling/document-print-and-email-actions-call-report-selections-directly.md) |
| Email | Use the Email module and an Email Scenario so documents can use different accounts | [Email module](../breaking-changes/prefer-email-module.md) |
| Running the report from code | Stop when the request page is cancelled; check request page input; one file per client request | [empty request page parameters](../reporting/stop-when-runrequestpage-returns-empty-parameters.md), [validate request page input](../ui/validate-request-page-input-in-onqueryclosepage.md), [one download per request](../reporting/report-output-in-a-loop-needs-one-client-download.md), [clear the report variable](../reporting/clear-report-variable-before-independent-runmodal.md) |
| Attachments | Files stored on a custom document need the attachment mapping; whether they travel with the email | storage: [document attachments on custom tables](../data-modeling/enable-document-attachments-on-custom-tables.md); sending attachments with the email: none yet; rests on judgment |
| Electronic documents | When the document must also leave as a structured file, add a format or carry fields through the existing one | [e-document format enum](../e-documents/add-an-e-document-format-through-the-format-enum.md), [carry custom fields](../e-documents/carry-custom-fields-through-e-document-export-and-import.md), [creation after the posting commit](../e-documents/e-document-creation-runs-after-the-posting-commit.md) |
| Barcodes | Encode through the Barcode module and name the production font | [barcode module and font](../data-modeling/report-barcodes-must-use-barcode-module-and-production-font-name.md) |
| Pictures | Logos and item pictures stored as Media, not BLOB | [Media not BLOB](../data-modeling/pictures-must-use-media-not-blob.md) |
| Document language | Printing in the customer's language and its formats | none yet; rests on judgment |
| Fields from posting | A value printed on a posted document must first reach the posted table | [mirror sales fields](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md), [plan the full path of a sales field](../sales-purchase/plan-the-full-path-of-a-custom-sales-field.md) |
| Tests | Handle the request page and every UI call the run raises | [UI handlers in tests](../testing/ui-handlers-in-tests.md), [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md) |

A custom document that is also posted follows [plan a custom document with posting](plan-a-custom-document-with-posting.md) for everything before printing.

Whether a new layout replaces the company default, whether customers get their own layouts, and whether the document must also be sent electronically are decisions for the requester. When the request does not settle them, raise open questions instead of choosing.

## Anti Pattern

Add an action that calls `Report.RunModal` on a new report with an RDLC layout, and build the email by hand with the PDF attached. Users cannot pick another layout in Report Selections or Document Layouts, the Post and Send action ignores the document, the email bypasses the configured account, and renaming a dataset column later breaks every layout a customer designed.

## References

- [Multiple report layouts](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-multiple-report-layouts).
- [Manage report layouts](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-manage-report-layouts#layout-sources).
- [Set the report layout](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-set-report-layout).
