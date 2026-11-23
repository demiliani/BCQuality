---
kind: action-skill
id: al-subscription-billing-review
version: 1
title: AL subscription billing review
description: Reviews AL extensions of the Subscription Billing app against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL subscription billing review

Reviews AL source changes against the `subscription-billing` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain subscription-billing`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: an app.json dependency on Subscription Billing (3099ffc7-4cf7-4df6-9b96-7e4bc2bb587c), table extensions of or code using `Customer Subscription Contract`, `Cust. Sub. Contract Line`, `Subscription Line`, `Subscription Header`, `Billing Line`, `Billing Line Archive` or `Vendor Subscription Contract`, subscribers to `Billing Proposal`, `Create Billing Documents` or `Sales Documents`, or code that reads `Recurring Billing` on sales documents.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `subscription-billing` articles:

- A custom `Billing Line` field is copied to `Sales Line` in `OnBeforeInsertSalesLineFromContractLine` without a matching `OnBeforeInsertTempBillingLine` copy, `Billing Line` is filtered by document number inside `OnBeforeInsertSalesLineFromContractLine`, or a `Billing Line` field that the archive must show has no same-numbered field on `Billing Line Archive` — `carry-contract-line-fields-to-billing-lines-and-contract-invoices`.
- A contract header field is carried only through `OnAfterCreateSalesHeaderFromContract` or matching field numbers with no handling of `OnAfterCreateSalesHeaderForCustomerNo`, or those subscribers call `SalesHeader.Modify` — `carry-customer-contract-header-fields-to-contract-invoices`.
- `Modify(true)` changes dimensions, price, quantity, discount, customer or address on a recurring billing document or billing-linked line, for example in `OnAfterInsertSalesLineFromBillingLine`, or a subscriber to billing events uses `Confirm`, `Message` or pages — `contract-invoice-documents-are-locked-set-values-before-insert`.
- A field on `Usage Data Generic Import` and `Usage Data Billing` has no `OnBeforInsertUsageDataBilling` subscriber, `OnAfterCreateUsageDataBillingFromTempSubscriptionLine` assigns `Usage Data Billing` fields without `Modify`, or `OnBeforeInsertSalesLineFromContractLine` / `OnBeforeInsertPurchaseLineFromContractLine` filters `Usage Data Billing` on the new line's document number — `carry-usage-data-values-to-contract-invoices-through-usage-data-billing`.
- A renewable field on `Subscription Line` has no same-number field on `Planned Subscription Line` or no copy in `OnAfterCopyFromSalesSubscriptionLine` and `OnBeforeUpdateSubscriptionLineFromPlannedSubscriptionLine`, `Subscription Line.Modify` is called from `OnAfterInsertPlannedSubscriptionLineFromSalesSubscriptionLine`, or an `OnAfterInsertSubscriptionLine` subscriber assigns `Sales Subscription Line` fields without `Modify` — `contract-renewal-updates-subscription-lines-through-planned-lines`.

Resolve layer conflicts per READ. When no subscription-billing knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Subscription billing"`.
