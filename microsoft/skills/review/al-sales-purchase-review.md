---
kind: action-skill
id: al-sales-purchase-review
version: 1
title: AL sales and purchase review
description: Reviews AL extensions of sales and purchase document processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL sales and purchase review

Reviews AL source changes against the `sales-purchase` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain sales-purchase`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of `Sales Header`, `Sales Line`, `Purchase Header`, `Purchase Line`, their posted and archive tables, `Invoice Posting Buffer`, `Gen. Journal Line`, `Cust. Ledger Entry`, `Vendor Ledger Entry`, `Item Journal Line` or `Item Ledger Entry`, or event subscribers to `Sales-Post`, `Purch.-Post`, `Sales Post Invoice Events`, `Purch. Post Invoice Events`, `Release Sales Document`, `Release Purchase Document`, or to events on those tables; code or subscribers touching `Copy Document Mgt.`, `ArchiveManagement`, `Sales-Post Prepayments`, `Purchase-Post Prepayments`, `Purch.-Get Drop Shpt.`, `Dist. Integration`, `Req. Wksh.-Make Order`, `Correct Posted Sales Invoice`, `Correct Posted Purch. Invoice`, the archive tables or `Prepayment Inv. Line Buffer`. Also review inputs that extend `Customer`, `Vendor`, `Item` together with their templates (`Customer Templ.`, `Vendor Templ.`, `Item Templ.`), subscribe to `Sales-Quote to Order`, `Blanket Sales Order to Order`, `Purch.-Quote to Order`, `Blanket Purch. Order to Order`, `Sales-Get Return Receipts`, `Purch.-Get Return Shipments` or `Bank Acc. Reconciliation Post`, or extend `Return Receipt Line` or `Return Shipment Line`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `sales-purchase` articles:

- A field added to `Sales Header`, `Sales Line`, `Purchase Header` or `Purchase Line` has a field with the same name but a different number on a posted or archive table in the same app, or a subscriber copies it to a posted table and calls `Modify` — `mirror-sales-fields-on-every-transferfields-target` or `mirror-purchase-fields-on-every-transferfields-target`, by document side. Do not match a posted table that simply lacks the field; that is a design decision unless the input states the field must reach it.
- A page extension copies master-data values into a sales or purchase header or line in a field trigger, or a payment or posting default is copied on the sell-to or buy-from event instead of the bill-to or pay-to event — `default-sales-and-purchase-fields-from-master-data`.
- A header field trigger updates lines with `ModifyAll` or a loop of plain assignments instead of `UpdateSalesLinesByFieldNo` or `UpdatePurchLinesByFieldNo`, or a purchase subscriber uses the sales-style name `OnUpdatePurchLineByChangedFieldName` — `propagate-sales-and-purchase-header-fields-to-lines`.
- A "cannot post" rule sits in a page action trigger or in an after-posting subscriber, or a rule meant to block posting preview sits only in a post or release restriction event — `validate-sales-and-purchase-documents-before-posting-or-release`.
- A subscriber to `OnPrepareLineOnAfterFillInvoicePostingBuffer` targets `"Sales Post Invoice"` or `"Purch. Post Invoice"` instead of the matching `... Post Invoice Events` codeunit, a value copied into `Invoice Posting Buffer` must split G/L entries but has no `OnAfterBuildPrimaryKey` subscriber, or a purchase subscriber sets `IsHandled` without updating the buffer itself — `carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer`.
- A subscriber to `OnAfterPostSalesDoc` performs an external call, sends a message or raises an error expecting the posting to roll back, without exiting on `PreviewMode`, or calls `Commit` — `onafterpostsalesdoc-runs-after-the-posting-commit`.
- A subscriber to `OnAfterPostPurchaseDoc` declares a `PreviewMode` parameter, or performs an external call or sends a message without exiting when `"Gen. Jnl.-Post Preview".IsActive()` is true — `onafterpostpurchasedoc-has-no-previewmode-parameter`.
- A subscriber to an after-posting event finds `Cust. Ledger Entry`, `Vendor Ledger Entry` or `Item Ledger Entry` rows and modifies them — `carry-sales-fields-to-customer-ledger-through-the-journal-line`, `carry-purchase-fields-to-vendor-ledger-through-the-journal-line` or `carry-sales-line-fields-to-item-ledger-through-the-item-journal-line`, by the table modified.
- An `OnAfterInsertToSalesLine` or `OnAfterInsertToPurchLine` subscriber assigns a custom field and calls `Modify`, or a line field that must survive Copy Document has no `OnAfterRecalculateSalesLine` or `OnAfterRecalculatePurchLine` subscriber — `copy-document-recalculate-lines-drops-custom-line-fields`.
- A custom field defaulted from master data and mirrored on `Sales Header Archive` or `Sales Line Archive` has no `OnAfterTransferFromArchToSalesHeader` or `OnAfterTransferFromArchToSalesLine` subscriber, or an `OnAfterRestoreSalesDocument` subscriber loops the restored lines and calls `Modify` — `restore-archived-sales-document-revalidates-custom-fields`.
- An `OnAfterCopyGenJnlLineFromSalesHeader` or `OnAfterCopyGenJnlLineFromPurchHeader` subscriber has no matching `...PrepmtPost` subscriber, or a per-line value is read from the prepayment buffer's line number or assigned in `OnAfterCopyGenJnlLineFromPrepmtInvBuffer` — `prepayment-posting-uses-its-own-copy-events`.
- A field is copied from sales to purchase lines only in `OnAfterPurchaseLineInsert` with `Modify` or by matching field numbers alone, or `OnAfterTransfldsFromSalesToPurchLine` is handled without the requisition worksheet route (`Requisition Line` and `OnAfterInitPurchOrderLine`) — `carry-sales-line-fields-to-drop-shipment-and-special-order-purchase-lines`.
- A per-document status or ID field mirrored on `Sales Invoice Header` or `Purch. Inv. Header` is not reset in `OnAfterCopySalesHeaderDone` or `OnAfterCopyPurchHeaderDone`, or an `OnAfterCreateCopyDocument` subscriber on `Correct Posted Sales Invoice` modifies the header — `corrective-credit-memo-copies-custom-fields-from-the-posted-invoice`.

`plan-the-full-path-of-a-custom-sales-field` is design guidance for planning skills and produces no review finding on its own.
- A `Customer`, `Vendor` or `Item` field default is set only on the card page or in an insert trigger or insert-event subscriber with no matching field on the template table, or a template table-extension field has the master field's number but a different name, type or length — `templates-apply-custom-master-data-fields-by-matching-field`.
- A `Sales Header` or `Purchase Header` `OnAfterInitRecord` subscriber assigns a custom field without checking that it is empty, a quote or blanket order conversion subscriber copies a custom field from the source and calls `Modify`, or a custom quantity field on lines is not reset in `OnAfterResetQuantityFields` when blanket orders are in scope — `quote-and-blanket-order-conversion-copies-custom-fields-by-assignment`.
- A custom field mirrored on `Return Receipt Line` or `Return Shipment Line` is expected on credit memo lines created by Get Return Receipt/Shipment Lines with no `OnAfterCopyFieldsFromReturnReceiptLine` or `OnAfterCopyFieldsFromReturnShipmentLine` subscriber, or is set by a line insert-event subscriber plus `Modify` — `get-return-receipt-lines-copies-custom-fields-from-the-return-order-line`.
- An after-posting subscriber applies another routine's commit or preview rule: `PreviewMode` declared on `OnAfterPostPurchaseDoc` or `OnAfterPostServiceDoc`, an external call or an assumption that posting is committed in `Bank Acc. Reconciliation Post` `OnAfterFinalizePost`, or a read of `Bank Acc. Reconciliation Line` there — `choose-the-after-posting-hook-per-posting-routine`.

Resolve layer conflicts per READ. When no sales-purchase knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Sales and purchase"`.
