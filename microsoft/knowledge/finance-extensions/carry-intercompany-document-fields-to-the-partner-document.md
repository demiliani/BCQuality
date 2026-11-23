---
bc-version: [all]
domain: finance-extensions
keywords: [intercompany, icinboxoutboxmgt, ic-outbox-sales-header, ic-inbox-purchase-header, onbeforeicinboxpurchheaderinsert, oncreatepurchdocumentonbeforepurchheadermodify, oncreatepurchlinesonbeforemodify, ic-outbox-imp-exp, transferfields]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry intercompany document fields to the partner document

## Description

An intercompany sales document reaches the partner's purchase document in three hops, each with its own copy mechanism. All hops are in `ICInboxOutboxMgt` (427).

| Hop | Mechanism | Header event | Line event |
| --- | --- | --- | --- |
| Sales document to IC outbox | `TransferFields` | `OnAfterICOutBoxSalesHeaderTransferFields` | `OnAfterICOutBoxSalesLineInsert` |
| IC outbox to partner IC inbox | field by field | `OnBeforeICInboxPurchHeaderInsert` | `OnBeforeICInboxPurchLineInsert` |
| IC inbox to purchase document | field by field; lines `TransferFields`, then `Validate("No.")` | `OnCreatePurchDocumentOnBeforePurchHeaderModify` | `OnCreatePurchLinesOnBeforeModify` |

The first hop also runs from posted invoices and credit memos, with `TransferFields` from `Sales Invoice Header` or `Sales Cr.Memo Header`. A field with the same number on the IC outbox tables needs no subscriber. In the third hop, the `No.` trigger of `Purchase Line` runs `Init()`, which clears any custom field that `TransferFields` copied. The purchase-to-sales direction has matching events, such as `OnBeforeICInboxSalesHeaderInsert`, `OnCreateSalesDocumentOnBeforeSalesHeaderModify` and `OnAfterCreateSalesLines`.

How the second hop runs depends on the partner's inbox type. For a partner in the same database, report `Move IC Trans. to Partner Comp` (513) builds the inbox rows in the sending company. `IC Data Exchange Database` then copies them into the partner company with `TransferFields`. For a file partner, `IC Outbox Export` writes xmlport `IC Outbox Imp/Exp` (12), which has a fixed field list and cannot be extended. `IC Inbox Import` reads it back, so a custom field is blank when the second hop runs. Partners connected by API copy the rows to `Buffer IC Inbox` tables first; that transport is not covered here.

The IC general journal follows the same shape with field-by-field copies: `OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert`, `OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert` and `OnCreateJournalLinesOnBeforeModify`.

## Best Practice

Add the field with the same number to the source document, the IC outbox and the IC inbox tables. The handled IC tables are filled with `TransferFields`, so add it there too if users need the history. Subscribe to the inbox insert event and to the purchase document modify events. Write code that works in either company, because the inbox event can run in the sender's company. If file partners are in scope, state that the value cannot travel in the file.

See sample: [`carry-intercompany-document-fields-to-the-partner-document.good.al`](carry-intercompany-document-fields-to-the-partner-document.good.al).

## Anti Pattern

Rely on equal field numbers end to end, or copy the line value in `OnCreatePurchLinesOnAfterTransferFields`. The inbox hop and the partner header are built field by field, and `Validate("No.")` clears the line value after that event. Reading the partner's setup tables inside `OnBeforeICInboxPurchHeaderInsert` is also wrong, because it may run in the sending company.

See sample: [`carry-intercompany-document-fields-to-the-partner-document.bad.al`](carry-intercompany-document-fields-to-the-partner-document.bad.al).

## References

- [ICInboxOutboxMgt](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/ICInboxOutboxMgt.Codeunit.al).
- [IC Data Exchange Database](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/DataExchange/ICDataExchangeDatabase.Codeunit.al).
- [IC Inbox Import](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/Inbox/ICInboxImport.Codeunit.al).
- [IC Outbox Export](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/Intercompany/Outbox/ICOutboxExport.Codeunit.al).
