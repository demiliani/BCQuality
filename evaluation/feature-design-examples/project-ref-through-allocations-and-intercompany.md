# Feature design

> General journal lines, sales lines and purchase lines get a Project Ref. When a line uses an allocation account, every allocated line must keep the Project Ref., and recurring journal allocations must also post it from the recurring line. When we send an intercompany sales order to a partner company in the same database, the partner's purchase order header and lines must get the Project Ref.

**Result:** Complete design. **Business process:** General journal posting with Allocation Accounts and recurring allocations, sales and purchase document posting with Allocation Accounts, and intercompany sales order to partner purchase order (same database). **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is Project Ref.: free code, or a TableRelation to Job (Project) No. or another table? Its type and length must match the related field exactly for an unconditional relation, and the same definition is then used on every mirrored table. _(affects: tab-gen-journal-line, tab-gl-entry, tab-sales-header, tab-sales-line, tab-purchase-header, tab-purchase-line, tab-ic-outbox-sales-header, tab-ic-outbox-sales-line, tab-ic-inbox-purchase-header, tab-ic-inbox-purchase-line, tab-sales-shipment-header, tab-sales-invoice-header, tab-sales-cr-memo-header, tab-return-receipt-header, tab-sales-header-archive, tab-sales-shipment-line, tab-sales-invoice-line, tab-sales-cr-memo-line, tab-return-receipt-line, tab-sales-line-archive, tab-purch-rcpt-header, tab-purch-inv-header, tab-purch-cr-memo-hdr, tab-return-shipment-header, tab-purchase-header-archive, tab-purch-rcpt-line, tab-purch-inv-line, tab-purch-cr-memo-line, tab-return-shipment-line, tab-purchase-line-archive)_
2. How does the Sales Header Project Ref. get its value for an IC sales order (user entry, default from lines, or from somewhere else), and should a header value default to the lines? _(affects: tab-sales-header, tab-ic-outbox-sales-header, tab-purchase-header)_
3. The mirroring articles add Project Ref. to every posted and archive table. Can any document type (shipments, receipts, credit memos, return documents, archives) be excluded? _(affects: tab-sales-shipment-header, tab-sales-invoice-header, tab-sales-cr-memo-header, tab-return-receipt-header, tab-sales-header-archive, tab-sales-shipment-line, tab-sales-invoice-line, tab-sales-cr-memo-line, tab-return-receipt-line, tab-sales-line-archive, tab-purch-rcpt-header, tab-purch-inv-header, tab-purch-cr-memo-hdr, tab-return-shipment-header, tab-purchase-header-archive, tab-purch-rcpt-line, tab-purch-inv-line, tab-purch-cr-memo-line, tab-return-shipment-line, tab-purchase-line-archive)_
4. Must Project Ref. appear as a native column on G/L entries and be read on almost every access? If not, store it in a related table keyed by G/L Entry No. instead of a G/L Entry table extension. _(affects: tab-gl-entry)_
5. Must Project Ref. also reach G/L entries from sales and purchase posting (via the Invoice Posting Buffer, including Group ID), customer/vendor ledger entries, or VAT and bank entries? Not designed. _(affects: cu-project-ref-allocation)_
6. Do users need Project Ref. on the handled IC tables (history)? Are file-based or API IC partners in scope? A file partner cannot carry the value, because xmlport IC Outbox Imp/Exp has a fixed field list. _(affects: cu-ic-project-ref, tab-ic-inbox-purchase-header, tab-ic-inbox-purchase-line)_
7. Should Project Ref. flow back when a user copies a posted document (Copy Document uses TransferFields), or be cleared? _(affects: tab-sales-header, tab-purchase-header)_
8. On which journal, document, posted-document and IC pages must Project Ref. be shown? _(affects: pag-general-journal, pag-recurring-general-journal, pag-sales-order, pag-sales-order-subform, pag-purchase-order, pag-purchase-order-subform)_
9. Which field number and object ID range does the app use? The field number must be identical on every table in this design. _(affects: tab-gen-journal-line, tab-gl-entry, tab-sales-header, tab-sales-line, tab-purchase-header, tab-purchase-line, tab-ic-outbox-sales-header, tab-ic-outbox-sales-line, tab-ic-inbox-purchase-header, tab-ic-inbox-purchase-line, tab-sales-shipment-header, tab-sales-invoice-header, tab-sales-cr-memo-header, tab-return-receipt-header, tab-sales-header-archive, tab-sales-shipment-line, tab-sales-invoice-line, tab-sales-cr-memo-line, tab-return-receipt-line, tab-sales-line-archive, tab-purch-rcpt-header, tab-purch-inv-header, tab-purch-cr-memo-hdr, tab-return-shipment-header, tab-purchase-header-archive, tab-purch-rcpt-line, tab-purch-inv-line, tab-purch-cr-memo-line, tab-return-shipment-line, tab-purchase-line-archive, cu-project-ref-allocation, cu-ic-project-ref, pag-general-journal, pag-recurring-general-journal, pag-sales-order, pag-sales-order-subform, pag-purchase-order, pag-purchase-order-subform, ps-project-ref)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Gen. Journal Line | Holds Project Ref. on general and recurring journal lines. Allocation Account lines are copied with TransferFields, so the same field carries to every generated journal line. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. Must be saved on the source line before posting: Gen. Journal Alloc. Acc. Mgt. re-reads the line by SystemId. | [1] [2] [7] [8] [9] |
| 2 | extend | tableextension | G/L Entry | Receives Project Ref. from the posted journal lines, including Allocation Account lines and recurring allocation lines, so the posted allocations carry it. Stored field chosen because the request says the allocations must post the value; the hot-ledger article allows a stored field only when the value must appear as a native list column and is read on almost every access, otherwise a related table keyed by Entry No. is preferred (see open question gl-entry-storage). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [10] [11] [7] [8] |
| 3 | extend | tableextension | Sales Header | Source of the header-level Project Ref. for intercompany sales orders; copied to IC Outbox Sales Header by TransferFields. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [5] [7] [8] |
| 4 | extend | tableextension | Sales Line | Holds Project Ref. on sales lines; source for allocation-generated sales lines and for IC Outbox Sales Line. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [1] [3] [5] [7] [8] |
| 5 | extend | tableextension | Purchase Header | Receives Project Ref. on the partner's purchase order header created from the IC inbox. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [6] [7] [8] |
| 6 | extend | tableextension | Purchase Line | Holds Project Ref. on purchase lines; source for allocation-generated purchase lines and target for the partner's IC purchase order lines. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [1] [3] [6] [7] [8] |
| 7 | extend | tableextension | IC Outbox Sales Header | Receives Project Ref. from the sales document (or posted sales invoice/credit memo) by TransferFields; same field number required, no subscriber. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [7] [8] |
| 8 | extend | tableextension | IC Outbox Sales Line | Receives Project Ref. from the sales document (or posted sales invoice/credit memo) by TransferFields; same field number required, no subscriber. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [7] [8] |
| 9 | extend | tableextension | IC Inbox Purchase Header | Receives Project Ref. field by field from the IC outbox in an event subscriber; copied into the partner company by IC Data Exchange Database with TransferFields. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [7] [8] |
| 10 | extend | tableextension | IC Inbox Purchase Line | Receives Project Ref. field by field from the IC outbox in an event subscriber; copied into the partner company by IC Data Exchange Database with TransferFields. | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as on every other table in this design; DataClassification set on the field. | [3] [7] [8] |
| 11 | extend | tableextension | Sales Shipment Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 12 | extend | tableextension | Sales Invoice Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 13 | extend | tableextension | Sales Cr.Memo Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 14 | extend | tableextension | Return Receipt Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 15 | extend | tableextension | Sales Header Archive | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 16 | extend | tableextension | Sales Shipment Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 17 | extend | tableextension | Sales Invoice Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 18 | extend | tableextension | Sales Cr.Memo Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 19 | extend | tableextension | Return Receipt Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 20 | extend | tableextension | Sales Line Archive | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [5] [7] [8] |
| 21 | extend | tableextension | Purch. Rcpt. Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 22 | extend | tableextension | Purch. Inv. Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 23 | extend | tableextension | Purch. Cr. Memo Hdr. | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 24 | extend | tableextension | Return Shipment Header | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 25 | extend | tableextension | Purchase Header Archive | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 26 | extend | tableextension | Purch. Rcpt. Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 27 | extend | tableextension | Purch. Inv. Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 28 | extend | tableextension | Purch. Cr. Memo Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 29 | extend | tableextension | Return Shipment Line | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 30 | extend | tableextension | Purchase Line Archive | TransferFields target of posting or archiving; mirrors Project Ref. so the value survives posting. Chosen by the mirroring article, not by the request (see open question posted-and-archive-scope). | Project Ref. (Code[20] (provisional; see open question project-ref-type-and-relation)): Same field number, name, type and length as the source field; Editable = false; DataClassification set on the field. | [6] [7] [8] |
| 31 | create | codeunit | Project Ref. Allocation Subscribers | Event subscribers that copy Project Ref. to allocation-generated sales and purchase lines, to recurring-journal allocation lines, and from journal lines to G/L entries. |  | [1] [2] [10] |
| 32 | create | codeunit | IC Project Ref. Subscribers | Event subscribers for the field-by-field intercompany hops: IC outbox to IC inbox (header and line) and IC inbox to the partner's purchase document (header and line). |  | [3] |
| 33 | extend | pageextension | General Journal | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 34 | extend | pageextension | Recurring General Journal | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 35 | extend | pageextension | Sales Order | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 36 | extend | pageextension | Sales Order Subform | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 37 | extend | pageextension | Purchase Order | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 38 | extend | pageextension | Purchase Order Subform | Shows Project Ref. so users can enter or see it. The exact list of document and posted-document pages is an open question (pages-in-scope). |  | [4] |
| 39 | create | permissionset | Project Ref. | Grants execute on the new subscriber codeunits; extended base tables need no new table permissions. |  | [4] |

## 3. How the data flows

- **User** → **Gen. Journal Line (general and recurring)**: entered by the user. User enters Project Ref. on the journal line. [4]
- **User** → **Sales Header**: entered by the user. User enters the header Project Ref. on the sales order (source rule is an open question: header-source). [3]
- **User** → **Sales Line**: entered by the user. User enters Project Ref. on the sales line. [4]
- **User** → **Purchase Line**: entered by the user. User enters Project Ref. on the purchase line. [4]
- **Gen. Journal Line (Allocation Account line)** → **Generated Gen. Journal Lines**: standard TransferFields copy. Gen. Journal Alloc. Acc. Mgt. copies the saved source line with TransferFields from OnBeforeCode of Gen. Jnl.-Post Batch; no subscriber. [1]
- **Sales Line (Allocation Account line)** → **Generated Sales Lines**: copied in an event subscriber. Validate("No.") clears the TransferFields copy; restored in OnBeforeCreateSalesLine. [1]
- **Purchase Line (Allocation Account line)** → **Generated Purchase Lines**: copied in an event subscriber. Validate("No.") clears the TransferFields copy; restored in OnBeforeCreatePurchaseLine. [1]
- **Recurring Gen. Journal Line** → **Recurring allocation Gen. Journal Line**: copied in an event subscriber. PostAllocations starts the line with Init(); value set from AllocateGenJournalLine in OnPostAllocationsOnBeforeCopyFromGenJnlAlloc, also for reversing allocations. [2]
- **Gen. Journal Line** → **G/L Entry**: copied in an event subscriber. Copied in OnAfterCopyGLEntryFromGenJnlLine; covers direct, allocation-account and recurring-allocation journal postings. Reversal copies the reference unchanged. [10]
- **Sales Header / Sales Line** → **Sales and Return posted headers/lines and archives**: standard TransferFields copy. Standard posting and archiving TransferFields; same field number on all targets. [5] [7]
- **Purchase Header / Purchase Line** → **Purchase posted headers/lines and archives**: standard TransferFields copy. Standard posting and archiving TransferFields; same field number on all targets. [6] [7]
- **Sales Header / Sales Line** → **IC Outbox Sales Header / IC Outbox Sales Line**: standard TransferFields copy. ICInboxOutboxMgt hop 1; same field number, no subscriber. [3]
- **IC Outbox Sales Header** → **IC Inbox Purchase Header**: copied in an event subscriber. Built field by field; copy in OnBeforeICInboxPurchHeaderInsert (may run in the sending company). [3]
- **IC Outbox Sales Line** → **IC Inbox Purchase Line**: copied in an event subscriber. Built field by field; copy in OnBeforeICInboxPurchLineInsert. [3]
- **IC Inbox Purchase Header/Line (sending company)** → **IC Inbox Purchase Header/Line (partner company, same database)**: standard TransferFields copy. Move IC Trans. to Partner Comp builds the inbox rows; IC Data Exchange Database copies them with TransferFields. [3]
- **IC Inbox Purchase Header** → **Partner Purchase Header**: copied in an event subscriber. Header built field by field; copy in OnCreatePurchDocumentOnBeforePurchHeaderModify. [3]
- **IC Inbox Purchase Line** → **Partner Purchase Line**: copied in an event subscriber. Line TransferFields is cleared by Validate("No."); copy in OnCreatePurchLinesOnBeforeModify. [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Sales Alloc. Acc. Mgt." | `OnBeforeCreateSalesLine` | SalesLine."Project Ref." := AllocationSalesLine."Project Ref." on each generated sales line. | Copy from the source line parameter; do not rely on TransferFields, which Validate("No.") clears · Do not patch posted lines from OnAfterPostSalesDoc | [1] |
| Codeunit "Purchase Alloc. Acc. Mgt." | `OnBeforeCreatePurchaseLine` | PurchaseLine."Project Ref." := AllocationPurchaseLine."Project Ref." on each generated purchase line. | Copy from the source line parameter; do not rely on TransferFields, which Validate("No.") clears | [1] |
| Codeunit "Gen. Jnl.-Post Batch" | `OnPostAllocationsOnBeforeCopyFromGenJnlAlloc` | GenJournalLine."Project Ref." := AllocateGenJournalLine."Project Ref." once before the allocation loop; the reused line keeps it for every allocation, including reversing allocations. | Set from the recurring line, not from Gen. Jnl. Allocation · Do not use OnAfterCopyGenJnlLineFromGenJnlAllocation for a recurring-line value | [2] |
| Table "G/L Entry" | `OnAfterCopyGLEntryFromGenJnlLine` | GLEntry."Project Ref." := GenJournalLine."Project Ref.". | Do not modify posted G/L entries after posting · No reversal handling needed: a reference is copied unchanged by Gen. Jnl.-Post Reverse | [10] |
| Codeunit ICInboxOutboxMgt | `OnBeforeICInboxPurchHeaderInsert` | ICInboxPurchaseHeader."Project Ref." := ICOutboxSalesHeader."Project Ref.". | May run in the sending company: copy only, read no company setup | [3] |
| Codeunit ICInboxOutboxMgt | `OnBeforeICInboxPurchLineInsert` | ICInboxPurchaseLine."Project Ref." := ICOutboxSalesLine."Project Ref.". | May run in the sending company: copy only, read no company setup | [3] |
| Codeunit ICInboxOutboxMgt | `OnCreatePurchDocumentOnBeforePurchHeaderModify` | PurchHeader."Project Ref." := ICInboxPurchHeader."Project Ref." on the partner's purchase order header. |  | [3] |
| Codeunit ICInboxOutboxMgt | `OnCreatePurchLinesOnBeforeModify` | PurchaseLine."Project Ref." := ICInboxPurchLine."Project Ref." on each partner purchase order line. | Do not use OnCreatePurchLinesOnAfterTransferFields: Validate("No.") runs after it and clears the value | [3] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification explicitly on every Project Ref. field in every table extension (a tableextension has no table-level value to inherit); choose the value that matches what the reference holds, such as CustomerContent for a business reference. Never leave ToBeClassified. [8]
- **permissions**: Add the two new subscriber codeunits to the app's Project Ref. permission set; name the page extensions in the plan. [4]

## 6. Tests

1. **journal-allocation-account-keeps-project-ref** [1] [10] [12] [13]
    - Given A general journal line with an Allocation Account with two allocation lines and a Project Ref. saved on the line, created with LibraryERM
    - When The journal batch is posted
    - Then Every G/L entry created for the allocated lines carries the Project Ref.
2. **sales-allocation-account-keeps-project-ref** [1] [5] [12] [13]
    - Given A sales invoice line with an Allocation Account and a Project Ref., created with LibrarySales
    - When The sales invoice is posted
    - Then Every posted Sales Invoice Line generated from the allocation carries the Project Ref.
3. **purchase-allocation-account-keeps-project-ref** [1] [6] [12] [13]
    - Given A purchase invoice line with an Allocation Account and a Project Ref., created with LibraryPurchase
    - When The purchase invoice is posted
    - Then Every posted Purch. Inv. Line generated from the allocation carries the Project Ref.
4. **recurring-allocation-posts-project-ref** [2] [10] [12]
    - Given A recurring general journal line with Project Ref. and two Gen. Jnl. Allocation lines
    - When The recurring journal is posted
    - Then The recurring line's G/L entry and every allocation G/L entry carry the recurring line's Project Ref.
5. **recurring-reversing-allocation-posts-project-ref** [2] [10]
    - Given A recurring journal line with a reversing recurring method, Project Ref. and allocations
    - When The recurring journal is posted
    - Then The reversing allocation G/L entries also carry the Project Ref.
6. **gl-reversal-keeps-project-ref** [10]
    - Given A posted journal transaction whose G/L entries carry Project Ref.
    - When The transaction is reversed
    - Then The reversing G/L entries carry the same Project Ref.
7. **ic-sales-order-to-partner-po** [3] [12] [13]
    - Given An IC partner with database inbox, a sales order to the IC customer with header and line Project Ref.
    - When The IC sales order is sent, moved to the partner and the partner creates the purchase order from the IC inbox
    - Then The partner Purchase Header and every Purchase Line carry the same Project Ref. as the sending sales header and lines
8. **ic-line-value-survives-validate-no** [3]
    - Given An IC inbox purchase line with Project Ref.
    - When The partner purchase line is created (TransferFields then Validate("No."))
    - Then The purchase line still carries the Project Ref.
9. **ic-inbox-header-subscriber-reads-no-setup** [3]
    - Given An IC outbox sales header with Project Ref.
    - When The transaction is moved to the partner company in the same database
    - Then The partner IC Inbox Purchase Header carries Project Ref. and the subscriber reads no setup of either company
10. **posting-mirrors-project-ref** [5] [6] [7] [12]
    - Given A sales order and a purchase order with header and line Project Ref.
    - When Each is shipped/received and invoiced, and archived
    - Then Shipment, receipt, invoice headers and lines and the archive tables carry the same Project Ref.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined (no repository)
- Page names in the page extensions rest on the agent's judgment; BCQuality names no specific pages
- Running the IC test in a single test company (partner pointing to the same company) rests on the agent's judgment

## Sources

[1] `microsoft/knowledge/finance-extensions/carry-fields-through-allocation-account-lines.md`: Allocation Account behavior for journals, sales and purchase lines
    - Journal: rely on TransferFields; the value must be saved on the source line because it is re-read by SystemId
    - Sales/purchase: copy the field in OnBeforeCreateSalesLine / OnBeforeCreatePurchaseLine, because Validate("No.") clears the TransferFields copy
    - Do not patch generated lines from OnAfterPostSalesDoc; they are already posted
[2] `microsoft/knowledge/finance-extensions/carry-fields-through-recurring-journal-allocations.md`: Recurring journal allocation posting
    - Set a recurring-line value in OnPostAllocationsOnBeforeCopyFromGenJnlAlloc from AllocateGenJournalLine
    - Do not assume allocation postings inherit the recurring line; PostAllocations starts with Init()
    - A per-allocation value must be assigned on every call, including blanks, because the line variable is reused
[3] `microsoft/knowledge/finance-extensions/carry-intercompany-document-fields-to-the-partner-document.md`: Intercompany sales document to partner purchase document
    - Add the field with the same number to the source document, IC outbox and IC inbox tables
    - Subscribe to the inbox insert events and to the purchase document modify events
    - Write code that works in either company; do not read the partner's setup in OnBeforeICInboxPurchHeaderInsert
    - Do not copy the line value in OnCreatePurchLinesOnAfterTransferFields
    - A file partner cannot carry the value
[4] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage planning, page extensions, permission set and read-back tests
    - Plan one extension step per stage the field must reach
    - Name page extensions and permission set entries for new objects
    - Test by posting and reading the value back from every target
    - Do not fill ledger entries after posting by modifying them
[5] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Sales Header/Line fields on posted and archive tables
    - Same field number, name, type and length on every TransferFields target unless the plan excludes a document type
    - No subscriber for these stages; keep mirrored fields non-editable on posted tables
[6] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirroring Purchase Header/Line fields on posted and archive tables
    - Same field number, name, type and length on every TransferFields target unless the plan excludes a document type
    - No subscriber for these stages; keep mirrored fields non-editable on posted tables
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition across the TransferFields cascade
    - Mirrored fields must have the same field number, data type and length on every table in the cascade
[8] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new fields
    - Every Normal field in a tableextension must set its own DataClassification
    - Choose the value matching the stored data; ToBeClassified and SystemMetadata for customer data are under-classifications
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Project Ref. if it gets a TableRelation
    - Applies only if Project Ref. has a TableRelation
    - For an unconditional relation, use the exact type and length of the related field
[10] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Carrying the journal value to G/L entries and reversal
    - A Gen. Journal Line field reaches G/L Entry only through OnAfterCopyGLEntryFromGenJnlLine
    - Decide per entry; VAT and bank entries only if their reports need it
    - State reversal behavior: a reference is copied unchanged; add a reversal test
[11] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Storage choice on G/L Entry
    - Use a stored tableextension field on a hot ledger only when the value must appear as a native list column and is read on almost every access; otherwise use a related table keyed by Entry No.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures
    - Build fixtures with LibrarySales, LibraryPurchase, LibraryERM and LibraryRandom; create parents before dependents
[13] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test data
    - Create the records the test owns; do not assume existing records
    - Fill every mandatory field; keep scenario-defining values explicit

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
