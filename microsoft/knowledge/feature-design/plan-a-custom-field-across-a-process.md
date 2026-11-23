---
bc-version: [all]
domain: feature-design
keywords: [feature-design, custom-field, transferfields, posting, ledger-entry, copy-document, archive, upgrade, field-path, tableextension]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a custom field across a business process

## Description

Requests such as "add a delivery route and show it on the posted shipment" or "carry the cost center reference to the ledger" add a field to one record and expect it on many others. Each Business Central process moves data along its own mechanisms: some copy by field number with `TransferFields`, some copy field by field through a journal line and expose an event, some create records on several entry points. A field reaches only the stages the plan names.

This map is the index of field paths in BCQuality. Pick the processes the field touches, open every article of those rows, then settle the cross-cutting rows. For a sales field the detailed walk-through is [plan the full path of a custom sales field](../sales-purchase/plan-the-full-path-of-a-custom-sales-field.md).

## Best Practice

Plan one row group per process the request touches. Open every linked article for the stages chosen:

| Process | Stage the field must reach | Knowledge |
| --- | --- | --- |
| Sales | Whole path, posted documents and archives | [full path of a sales field](../sales-purchase/plan-the-full-path-of-a-custom-sales-field.md), [mirror sales fields](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md) |
| Sales | Customer, item and G/L entries | [customer ledger](../sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md), [item ledger](../sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md), [invoice posting buffer](../sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md) |
| Sales | Prepayments, drop shipment and special order | [prepayment copy events](../sales-purchase/prepayment-posting-uses-its-own-copy-events.md), [drop shipment and special order](../sales-purchase/carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines.md) |
| Purchase | Posted documents, archives, vendor ledger | [mirror purchase fields](../sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md), [vendor ledger](../sales-purchase/carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md) |
| Returns | Return receipts and corrective credit memos | [Get Return Receipt Lines](../sales-purchase/get-return-receipt-lines-copies-custom-fields-from-the-return-order-line.md), [corrective credit memo](../sales-purchase/corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.md) |
| Quotes, blanket orders | Order created from a quote or blanket order | [conversion copies by assignment](../sales-purchase/quote-and-blanket-order-conversion-copies-custom-fields-by-assignment.md) |
| Transfer | Posted transfer documents and item ledger | [posted transfers copy one by one](../warehouse/posted-transfer-documents-copy-fields-one-by-one.md), [transfer line to item ledger](../warehouse/carry-transfer-line-fields-to-item-ledger.md), [post transfers through codeunits](../scm/post-transfers-through-shipment-and-receipt-codeunits.md) |
| Warehouse | Which source documents reach warehouse documents | [warehouse requests](../warehouse/warehouse-requests-decide-which-source-documents-reach-warehouse-documents.md) |
| Warehouse | Receipts, shipments and their posted documents | [source line to receipt and shipment lines](../warehouse/carry-source-line-fields-to-warehouse-receipt-and-shipment-lines.md), [posted warehouse documents](../warehouse/carry-warehouse-document-fields-to-posted-warehouse-documents.md), [warehouse values to the source document before posting](../warehouse/carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.md), [commits per source document](../warehouse/warehouse-shipment-and-receipt-posting-commits-per-source-document.md) |
| Warehouse | Picks, put-aways, movements, warehouse entries | [picks and put-aways](../warehouse/carry-fields-to-warehouse-picks-put-aways-and-registered-activities.md), [inventory picks post through the source](../warehouse/inventory-picks-and-put-aways-post-through-the-source-document.md), [movements](../warehouse/carry-fields-through-warehouse-movements-and-internal-movements.md), [warehouse entries](../warehouse/carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.md) |
| Inventory | Item journals, physical inventory, item tracking | [item journal to ledgers](../inventory/carry-item-journal-fields-to-item-and-phys-inventory-ledger.md), [item tracking lines](../inventory/carry-item-tracking-line-fields-to-item-ledger-entries.md), [post through item journals](../scm/post-item-ledger-changes-through-item-journals.md) |
| Inventory | Reclassification | [two entries from one line](../inventory/item-reclassification-posts-two-entries-from-one-journal-line.md) |
| Inventory | Planning to supply orders | [demand fields through planning lines](../inventory/carry-demand-fields-through-planning-lines-to-supply-orders.md), [carry out requisition actions](../scm/carry-out-requisition-actions-through-the-standard-workflow.md) |
| Production | Order status change, output and consumption, journal posting | [status change copies whole records](../manufacturing/production-order-status-change-copies-whole-records.md), [output and consumption lines](../manufacturing/carry-production-order-fields-to-output-and-consumption-journal-lines.md), [capacity and item ledger](../manufacturing/carry-production-journal-fields-to-capacity-and-item-ledger.md) |
| Production | Routing lines and subcontracting | [refresh and planning paths](../manufacturing/copy-routing-line-fields-on-refresh-and-planning-paths.md), [subcontracting purchase lines](../manufacturing/carry-routing-fields-to-subcontracting-purchase-lines.md) |
| Assembly | Assembly posting and assemble-to-order | [assembly posting](../manufacturing/carry-assembly-fields-through-assembly-posting.md), [assemble-to-order headers](../manufacturing/carry-sales-line-fields-to-assemble-to-order-assembly-headers.md) |
| Projects | Job journal from every source, job ledger | [every source path](../projects/carry-document-fields-to-job-journal-line-on-every-source-path.md), [Job Transfer Line](../projects/carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md), [project purchases](../projects/project-purchases-post-usage-only-for-item-and-gl-account-lines.md) |
| Projects | Project invoices and time sheets | [planning line to invoice lines](../projects/carry-job-planning-line-fields-to-project-sales-invoice-lines.md), [Suggest Job Jnl. Lines](../projects/carry-time-sheet-fields-to-job-journal-through-suggest-lines.md), [Res. Jnl.-Post Line](../projects/time-sheet-posting-runs-in-res-jnl-post-line.md), [time sheet archive](../projects/time-sheet-archive-copies-fields-by-field-number.md) |
| Service | Service items, posted documents, ledger entries, contracts | [service item lines](../service/carry-service-item-fields-through-service-item-lines-and-posting.md), [mirror service fields](../service/mirror-service-fields-and-follow-up-after-service-posting.md), [service and warranty ledger](../service/carry-service-fields-to-service-and-warranty-ledger-entries.md), [contract invoices](../service/service-contract-invoices-are-built-from-contract-service-ledger-entries.md) |
| Finance | General journal to G/L, VAT and bank entries; allocations | [G/L, VAT and bank entries](../finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md), [allocation accounts](../finance-extensions/carry-fields-through-allocation-account-lines.md), [recurring allocations](../finance-extensions/carry-fields-through-recurring-journal-allocations.md), [deferrals](../finance-extensions/carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.md) |
| Finance | Payments and bank reconciliation | [cash receipts](../finance-extensions/carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.md), [suggested payments](../finance-extensions/carry-vendor-ledger-fields-to-suggested-payment-lines.md), [bank reconciliation](../finance-extensions/carry-bank-reconciliation-line-fields-to-payment-postings.md), [payment export](../finance-extensions/add-custom-data-to-payment-export-files.md) |
| Finance | Reminders and finance charge memos | [default from customer](../finance-extensions/default-customer-fields-on-reminder-and-finance-charge-headers.md), [carry when issuing](../finance-extensions/carry-reminder-and-finance-charge-fields-when-issuing.md) |
| Finance | Fixed assets | [FA and general journal lines](../finance-extensions/carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.md), [purchase and depreciation](../finance-extensions/carry-purchase-and-depreciation-fields-to-fixed-asset-entries.md) |
| Finance | Intercompany | [partner document](../finance-extensions/carry-intercompany-document-fields-to-the-partner-document.md), [IC outbox journals](../finance-extensions/send-intercompany-journals-through-the-ic-outbox-not-changecompany.md) |
| E-Documents | Export and import | [export and import](../e-documents/carry-custom-fields-through-e-document-export-and-import.md), [created after the posting commit](../e-documents/e-document-creation-runs-after-the-posting-commit.md) |
| Shopify | Orders in, items out | [order values to sales document](../shopify/carry-shopify-order-values-to-the-created-sales-document.md), [item data as metafields](../shopify/send-custom-item-data-to-shopify-as-metafields.md) |
| Subscription Billing | Contracts to billing lines and invoices | [contract lines](../subscription-billing/carry-contract-line-fields-to-billing-lines-and-contract-invoices.md), [contract header](../subscription-billing/carry-customer-contract-header-fields-to-contract-invoices.md), [usage data](../subscription-billing/carry-usage-data-values-to-contract-invoices-through-usage-data-billing.md), [set before insert](../subscription-billing/contract-invoice-documents-are-locked-set-values-before-insert.md), [renewal](../subscription-billing/contract-renewal-updates-subscription-lines-through-planned-lines.md) |

Then settle the rows every field shares, whatever the process:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Mirrored definitions | Same number, type and length on every `TransferFields` target; no skipping mismatches | [match type and length](../data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md), [SkipFieldsNotMatchingType](../data-modeling/transferfields-skip-type-mismatch-can-drop-data.md) |
| Default from master data | Customer, vendor and item defaults, templates, catalog items and substitutions | [default from master data](../sales-purchase/default-sales-and-purchase-fields-from-master-data.md), [templates by matching field](../sales-purchase/templates-apply-custom-master-data-fields-by-matching-field.md), [catalog items and substitutions](../inventory/catalog-items-substitutions-and-item-references-set-sales-lines-differently.md) |
| Header to lines | Existing lines and lines added later | [propagate header fields](../sales-purchase/propagate-sales-and-purchase-header-fields-to-lines.md) |
| Copy document | Whether the field flows back, and recalculated lines | [recalculate drops line fields](../sales-purchase/copy-document-recalculate-lines-drops-custom-line-fields.md), [full path of a sales field](../sales-purchase/plan-the-full-path-of-a-custom-sales-field.md) |
| Archive and restore | Archive tables mirror the field; restore revalidates it | [restore revalidates](../sales-purchase/restore-archived-sales-document-revalidates-custom-fields.md), [mirror sales fields](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md) |
| Price list lines | Fields of the applied price line, worksheets and copied lines | [plan a custom pricing rule](plan-a-custom-pricing-rule.md), [OnAfterSetPrice](../pricing/copy-applied-price-list-line-fields-in-onaftersetprice.md), [worksheet and copy lines](../pricing/price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.md) |
| Checks before posting | Where a required value is enforced | [validate before posting or release](../sales-purchase/validate-sales-and-purchase-documents-before-posting-or-release.md) |
| After-posting hook | One rule per posting routine: commit, preview and parameters | [choose the after-posting hook](../sales-purchase/choose-the-after-posting-hook-per-posting-routine.md), [OnAfterPostSalesDoc](../sales-purchase/onafterpostsalesdoc-runs-after-the-posting-commit.md), [OnAfterPostPurchaseDoc](../sales-purchase/onafterpostpurchasedoc-has-no-previewmode-parameter.md) |
| Posted entries | Fill entries during posting, never by modifying them afterwards | [do not modify posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md) |
| API exposure | Whether the field appears on an API page, and in which version | [plan API exposure](plan-api-exposure-and-background-sync.md), [version by adding](../web-services/version-apis-by-adding-not-mutating-published-versions.md) |
| Upgrade back-fill | Existing rows and posted history keep blank unless upgrade code fills them | [InitValue does not back-fill](../upgrade/initvalue-does-not-update-existing-rows.md), [DataTransfer](../upgrade/datatransfer-for-bulk-init.md), [DataTransfer skips triggers](../upgrade/datatransfer-skips-triggers-and-subscribers.md), [upgrade tags](../upgrade/use-upgrade-tags-not-version-checks.md) |
| Privacy | Classification on every table that holds the field | [classification on sensitive fields](../privacy/data-classification-required-on-pii-fields.md) |
| Tests | Post through each chosen entry point and read the value back from every target | [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md) |

Whether a field should reach a stage the request does not name, such as archives or ledger entries, is a question for the requester. Raise one question per group of stages.

## Anti Pattern

Plan only the source table and the one target the requester named, then fill the other records with subscribers that find and modify them after posting. The other entry points leave the field blank, posted entries are changed outside posting, and the gap appears only in production.

## References

- [Sales-Post](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Copy Document Mgt.](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al).
