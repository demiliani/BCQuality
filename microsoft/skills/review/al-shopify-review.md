---
kind: action-skill
id: al-shopify-review
version: 1
title: AL shopify review
description: Reviews AL extensions of the Shopify Connector app against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL shopify review

Reviews AL source changes against the `shopify` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain shopify`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: an app.json dependency on Shopify Connector (ec255f57-31d0-4ca2-b751-f2fa7c745abb), table extensions of or code using `Shpfy Order Header`, `Shpfy Order Line`, `Shpfy Order Attribute`, `Shpfy Order Line Attribute`, `Shpfy Product`, `Shpfy Variant`, `Shpfy Metafield` or `Shpfy Shop`, subscribers to `Shpfy Order Events`, `Shpfy Product Events` or `Shpfy Customer Events`, or code that reads the `Shpfy Order Id` or `Shpfy Order Line Id` fields of sales documents.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `shopify` articles:

- A `Sales Header` or `Sales Line` insert-event subscriber reads `Shpfy Order Id` or Shopify order data to fill a field, an `OnAfterCreateSalesHeader` or `OnAfterCreateItemSalesLine` subscriber assigns a field without calling `Modify`, or sales-document values are written from `OnAfterImportShopifyOrderHeader` — `carry-shopify-order-values-to-the-created-sales-document`.
- A subscriber to an internal Shopify event (`OnBeforeMapCustomer`, `OnBeforeMapCompany`, `OnBeforeConvertTo...`, `OnAfterSetProductTitle`, `OnBeforeFindCustomerTemplate`, `OnAfterFindCustomerTemplate`, `OnAfterFindMapping`), a call to an internal connector codeunit from another app, or `Confirm`, `Message` or a modal page inside a Shopify event subscriber — `extend-the-shopify-connector-through-integration-events-and-public-objects`.
- A field on `Shpfy Product` or `Shpfy Variant` filled in `OnAfterFillInShopifyProductFields` or `OnAfterFillInProductVariantData` and expected to reach Shopify, or a `Shpfy Metafield` row modified on every sync or inserted without validating its type and value — `send-custom-item-data-to-shopify-as-metafields`.
- A subscriber to `OnAfterCreateCustomer`, `OnAfterUpdateCustomer` or `OnAfterCreateItem` assigns a field on the var record but never calls `Modify`, `OnAfterUpdateItem` is the only place that sets an item field from Shopify instead of `OnDoUpdateItemBeforeModify` with `IsModifiedByEvent := true`, a `Customer` `OnAfterInsertEvent` subscriber looks up `Shpfy Customer` by `"Customer SystemId"`, or a handled `OnBeforeFindMapping` sets `"Customer SystemId"` without modifying the Shopify customer — `decide-the-master-side-before-extending-shopify-customer-and-item-sync`.

Resolve layer conflicts per READ. When no shopify knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Shopify"`.
