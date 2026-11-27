---
bc-version: [all]
domain: manufacturing
keywords: [partial-output, backward-flushing, routing-link-code, production-order-component, consumption-journal, operation-output, onpostflushedconsumponaftercopyprodorderfieldstoitemjnlline]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Let standard flushing post consumption for partial production output

## Description

An output posting and a component consumption posting are distinct. For a released production order, a component with **Backward** flushing and a routing link code is flushed when output for the linked operation is posted; successive partial outputs can each post a share of the consumption. Without a routing link code, standard backward flushing takes place when the order is changed to **Finished**. A **Manual** component instead needs an explicit consumption posting.

## Best Practice

When building a shop-floor integration, post output through the standard output journal path. If the integration also stages actual manual consumption, select only `Prod. Order Component` lines with `Flushing Method = Manual` for that step. Use the method on the order component, not the current default on the item card. Do not stage a second consumption line for components BC is configured to flush. Link each operation-flushed component to the intended operation; reusing the same routing link code on different operations can cause each operation to flush the component.

To add metadata to the automatic consumption generated during operation output, subscribe to `OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine` on `Mfg. Item Jnl.-Post Line`. It exposes the generated consumption `Item Journal Line` by `var`, the original output line, and the `Prod. Order Component`, after the standard quantity has been calculated and before tracking is transferred and the consumption is posted. Set extension fields on the generated line; let BC post it. This event is for operation flushing, not a hook for all manual and automatic consumption paths.

See [`let-standard-flushing-post-consumption-for-partial-output.good.al`](let-standard-flushing-post-consumption-for-partial-output.good.al).

## Anti Pattern

Stage manual consumption for every component with a remaining quantity before posting a partial output. A remaining quantity does not mean manual consumption is required: the same output can trigger standard flushing for that component.

See [`let-standard-flushing-post-consumption-for-partial-output.bad.al`](let-standard-flushing-post-consumption-for-partial-output.bad.al).

## Verification scenario

Use a released production order for 10 units with one operation and a linked **Backward** component requiring 2 units per output unit, without scrap, tracking, or warehouse picks. Post outputs of 4 and 6. Verify net component consumption of 8 after the first posting and 20 in total after the second, and verify that the integration did not stage manual consumption for that component. As a control, add a separate **Manual** component and verify that it is handled only by the explicit consumption step.

## References

- [Microsoft Learn: Flush components according to operation output](https://learn.microsoft.com/en-us/dynamics365/business-central/production-how-to-flush-components-according-to-operation-output).
- [Base Application: Mfg. Item Jnl.-Post Line, operation flushing and generated consumption](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Manufacturing/Inventory/Posting/MfgItemJnlPostLine.Codeunit.al#L831).
