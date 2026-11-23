---
bc-version: [all]
domain: manufacturing
keywords: [production-order, output-journal, consumption-journal, production-journal-mgt, output-jnl-expl-route, calc-consumption, copyfromprodorderline, copyfromprodordercomp, item-journal-line, manufacturing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry production order fields to output and consumption lines on every path

## Description

Output and consumption are posted from `Item Journal Line` rows with `Order Type` Production. Those rows are built field by field, never with `TransferFields`, and four standard paths build them, each with its own event:

- **Typed in the output or consumption journal.** Validating `Item No.` calls `CopyFromProdOrderLine` or `CopyFromProdOrderComp` on the `"Mfg. Item Journal Line"` table extension, which end with `OnAfterCopyFromProdOrderLine` and `OnAfterCopyFromProdOrderComp`. Subscribe with `ObjectType::Table` and `Database::"Item Journal Line"`.
- **Production Journal page** (`"Production Journal Mgt"`): `OnBeforeInsertOutputJnlLine(var ItemJournalLine; ProdOrderRtngLine; ProdOrderLine)` and `OnBeforeInsertConsumptionJnlLine(var ItemJournalLine; ProdOrderComp; ProdOrderLine; Level)`.
- **Explode Routing in the output journal** (`"Output Jnl.-Expl. Route"`): `OnBeforeOutputItemJnlLineInsert(var ItemJournalLine; LastOperation)`. It passes no production order line; read it with the line's `Order No.` and `Order Line No.`.
- **Calc. Consumption report**: `OnBeforeInsertItemJnlLine(var ItemJournalLine; ProdOrderComponent)`.

## Best Practice

Add the field to `Item Journal Line` and decide which paths the users of the feature run. Cover each of them with its event, reading the value from the production order line or component the event passes. Keep the copy in one procedure that all subscribers call, so the paths cannot drift apart. From the journal line, carry the value to the entries as described in [carry production journal fields to capacity and item ledger entries](carry-production-journal-fields-to-capacity-and-item-ledger.md).

A path the request does not mention is a question for the requester, not one to skip silently: a value that appears only when users work from the Production Journal page is a defect the first time someone explodes a routing instead.

See sample: [`carry-production-order-fields-to-output-and-consumption-journal-lines.good.al`](carry-production-order-fields-to-output-and-consumption-journal-lines.good.al).

## Anti Pattern

Subscribe to only one path, usually the Production Journal page, and assume all output and consumption lines pass through it. Or give the journal line field the same number as the production order field and expect it to be copied: no path uses `TransferFields`, so the value stays empty without any error.

See sample: [`carry-production-order-fields-to-output-and-consumption-journal-lines.bad.al`](carry-production-order-fields-to-output-and-consumption-journal-lines.bad.al).

## References

- [Mfg. Item Journal Line, CopyFromProdOrderLine and CopyFromProdOrderComp](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Journal/MfgItemJournalLine.TableExt.al).
- [Mfg. Item Journal Mgt., the Item No. validation that calls them](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Journal/MfgItemJournalMgt.Codeunit.al).
- [Production Journal Mgt](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Journal/ProductionJournalMgt.Codeunit.al).
- [Output Jnl.-Expl. Route](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Journal/OutputJnlExplRoute.Codeunit.al).
- [Calc. Consumption report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Document/CalcConsumption.Report.al).
