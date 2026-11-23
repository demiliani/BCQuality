---
bc-version: [all]
domain: projects
keywords: [job-journal-line, job-transfer-line, frompurchaselinetojnlline, onafterfrompurchaselinetojnlline, onafterfromplanninglinetojnlline, onafterfromplanningsaleslinetojnlline, onafterfromgenjnllinetojnlline, job-post-line, project]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry document fields to the project journal line on every source path

## Description

Project ledger entries are posted from `Job Journal Line`, but most of those lines are not typed by a user in a project journal. Codeunit `Job Transfer Line` builds them from other records, field by field, and raises an event at the end of each copy:

| Source | Procedure | Event |
| --- | --- | --- |
| Purchase line posted with a project (`Job Post-Line`.`PostJobOnPurchaseLine`) | `FromPurchaseLineToJnlLine` | `OnAfterFromPurchaseLineToJnlLine` |
| Project planning line | `FromPlanningLineToJnlLine` | `OnAfterFromPlanningLineToJnlLine` |
| Planning line invoiced through a sales document | `FromPlanningSalesLineToJnlLine` | `OnAfterFromPlanningSalesLineToJnlLine` |
| General journal line with a project | `FromGenJnlLineToJnlLine` | `OnAfterFromGenJnlLineToJnlLine` |

A field that exists only on the project journal is therefore empty for usage posted from a purchase invoice, and for every other generated line.

## Best Practice

Decide in the design which sources must carry the value, then subscribe to the matching `Job Transfer Line` events to copy it onto the project journal line. From there one subscriber to `OnAfterFromJnlLineToLedgEntry` carries it to the ledger; see [carry project journal fields to the project ledger](carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md).

Purchase lines charged to a project are the most common miss: the purchase invoice posts the vendor and item side, and `Job Post-Line` then builds a separate project journal line for the project usage. For the purchase side of the same document, see [carry purchase fields to the vendor ledger](../sales-purchase/carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md).

See sample: [`carry-document-fields-to-job-journal-line-on-every-source-path.good.al`](carry-document-fields-to-job-journal-line-on-every-source-path.good.al).

## Anti Pattern

Design the field only on the project journal page and the project ledger, assuming all project usage is entered in project journals. Usage posted from purchase invoices or invoiced from planning lines then reaches the ledger without the value, and nobody notices until a report filters on it.

See sample: [`carry-document-fields-to-job-journal-line-on-every-source-path.bad.al`](carry-document-fields-to-job-journal-line-on-every-source-path.bad.al).

## References

- [Job Transfer Line, From... procedures and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Journal/JobTransferLine.Codeunit.al).
- [Job Post-Line, PostJobOnPurchaseLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Posting/JobPostLine.Codeunit.al).
- [Purch. Post Invoice, project usage posted per purchase line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPostInvoice.Codeunit.al).
