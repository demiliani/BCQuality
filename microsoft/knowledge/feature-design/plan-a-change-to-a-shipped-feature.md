---
bc-version: [all]
domain: feature-design
keywords: [feature-design, shipped-feature, obsoletion, upgrade-codeunit, upgrade-tag, datatransfer, enum-extension, event-contract, api-versioning, appsource]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a change to a shipped feature

## Description

Requests such as "replace the Priority option with a Priority Level code", "split the address field", "add a status value" or "change what the integration event passes" change a feature that customers already run. Their data exists in every company, other extensions subscribe to its events and call its procedures, external clients read its APIs and flows bind to its business events. A change that compiles can still lose data, break a dependent app or stop a flow.

BCQuality holds the rules for each part of such a change in the upgrade, breaking-changes, events, interfaces and web-services domains. Without a plan, an agent edits the shipped objects in place and leaves migration, obsoletion and contract versions to review findings or a failed upgrade.

## Best Practice

First decide whether the symbol was ever released: [an unreleased change is not breaking](../breaking-changes/unreleased-symbol-change-is-not-a-breaking-change.md) and [needs no upgrade path](../upgrade/unreleased-schema-change-needs-no-upgrade-path.md). For a released feature, plan one decision per row and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Fields and tables | Obsolete instead of deleting, renaming or renumbering; no key or type change on tables with data | [obsolete fields](../breaking-changes/obsolete-table-fields-instead-of-deleting-them.md), [only on tables without data](../upgrade/breaking-changes-only-on-tables-without-data.md), [do not change the primary key](../data-modeling/do-not-change-primary-key.md), [moving a field to a table extension](../breaking-changes/relocating-a-field-to-a-tableextension-is-not-a-deletion.md) |
| Obsoletion staging | `Pending` first with reason and tag, `Removed` in a later release; migrate data when the element moves to `Removed` | [Pending to Removed](../upgrade/obsolete-pending-to-removed-staging.md), [reason and tag](../upgrade/obsoletion-requires-reason-and-tag.md), [reason need not restate version](../upgrade/obsoletereason-need-not-restate-removal-version.md), [do not build on obsolete code](../breaking-changes/do-not-modify-code-already-marked-obsolete.md) |
| Procedures and access | Keep published signatures; add a new procedure or overload beside the original; keep new members narrow | [published signatures](../breaking-changes/do-not-change-published-procedure-signatures.md), [Obsolete lifecycle for members](../breaking-changes/deprecate-public-members-with-the-obsolete-lifecycle.md), [access modifiers](../breaking-changes/choose-access-modifiers-deliberately.md) |
| Upgrade code | A codeunit with `Subtype = Upgrade`, guarded by upgrade tags, with no order assumed between codeunits | [upgrade subtype](../upgrade/upgrade-codeunit-subtype.md), [upgrade tags, not versions](../upgrade/use-upgrade-tags-not-version-checks.md), [no order](../upgrade/install-and-upgrade-codeunits-have-no-order.md), [shallow tag logic](../upgrade/upgrade-tag-logic-must-not-nest-deeply.md), [AppVersion depends on context](../upgrade/appversion-meaning-depends-on-execution-context.md) |
| Upgrade safety | Log and continue on bad data; no external calls; no `ChangeCompany`; checks only in check triggers; guard reads | [do not block upgrade](../upgrade/do-not-block-upgrade-on-data-errors.md), [no external calls](../upgrade/no-external-calls-in-upgrade.md), [no ChangeCompany](../upgrade/no-changecompany-in-upgrade.md), [check-only triggers](../upgrade/check-only-triggers-do-not-migrate-data.md), [guard database reads](../upgrade/guard-database-reads.md) |
| Back-fill of a new field | `InitValue` reaches new rows only; existing rows need upgrade code | [InitValue does not update existing rows](../upgrade/initvalue-does-not-update-existing-rows.md) |
| Bulk copy or initialization | Prefer `DataTransfer`, knowing it skips triggers and subscribers; keep validation in upgrade minimal | [DataTransfer for bulk init](../upgrade/datatransfer-for-bulk-init.md), [skips triggers](../upgrade/datatransfer-skips-triggers-and-subscribers.md), [minimize OnValidate](../upgrade/minimize-onvalidate-upgrade-triggers.md) |
| New companies and installs | Register upgrade tags for new companies; install code does not run on upgrade; tell a first install from a reinstall | [register upgrade tags](../upgrade/register-upgrade-tags-with-subscribers.md), [install vs upgrade](../upgrade/install-code-does-not-run-on-version-upgrade.md), [DataVersion zero](../upgrade/first-install-dataversion-zero-check.md) |
| Enum values | Append values at the end; obsolete instead of deleting; give implementations a default and an unknown-value fallback | [additive at end](../upgrade/enum-values-additive-at-end.md), [DefaultImplementation](../interfaces/set-defaultimplementation-on-enum.md), [UnknownValueImplementation](../interfaces/handle-unknown-enum-ordinals-with-unknownvalueimplementation.md) |
| Opening an enum or interface to others | Whether to make it extensible; a published interface is extended by a new one, not edited | [extend published interfaces](../interfaces/extend-published-interfaces-dont-edit-them.md); `Extensible` on an existing enum: none yet; rests on judgment |
| Events | Keep names, parameters and attribute flags; add parameters at the end; no `IsHandled` on an existing event; local and internal events are contracts too | [attribute flags](../events/do-not-change-shipped-event-attribute-flags.md), [new parameters at the end](../events/add-new-event-parameters-at-the-end.md), [adding a parameter](../events/adding-a-parameter-to-an-event-is-not-a-breaking-change.md), [no IsHandled added](../events/do-not-add-ishandled-to-an-existing-event.md), [local and internal events](../events/treat-local-and-internal-events-as-subscriber-contracts.md) |
| APIs | Add a version instead of changing a published one; enum values are a contract by name | [version APIs by adding](../web-services/version-apis-by-adding-not-mutating-published-versions.md), [API enum names](../web-services/api-enum-values-are-a-contract-by-name-not-ordinal.md) |
| External business events | Raise a new version beside the old one, then obsolete the old one | [external business events](../web-services/raise-external-business-events-for-power-automate.md) |
| Telemetry | Keep event IDs and custom dimensions stable | [stable event IDs](../telemetry/telemetry-event-id-stable-unique.md), [stable custom dimensions](../telemetry/keep-custom-dimension-schema-stable.md) |
| Captions and translations | A rename changes translation IDs | [renaming changes translation IDs](../style/renaming-objects-or-members-changes-translation-ids.md) |
| Release | Raise the app version; dependency versions are minimums | [update the app version](../appsource/release-must-update-app-version.md), [dependency version is a minimum](../upgrade/dependency-version-is-a-minimum.md) |
| Tests | Test the upgrade path on data shaped like the old version | none yet for upgrade tests; rests on judgment. General fixtures: [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md) |

Which release removes an obsolete element, and whether dependent apps or flows are known, are questions for the requester. When the request does not settle them, raise open questions instead of choosing a timeline.

## Anti Pattern

Change the option field to a code field in place, rename the event parameter that now carries it, and set `InitValue` on the new field. Existing rows keep the default, dependent apps fail to compile or silently stop receiving values, flows bound to the old event stop matching, and the upgrade either loses data or stops on the first unexpected record.

## References

- [Upgrading extensions: installation and upgrade codeunits (training)](https://learn.microsoft.com/en-us/training/modules/easy-application-upgrade/3-installation-upgrade-codeunits).
- [Transferring data with DataTransfer](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-transfer).
- [Deprecate external business events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-deprecate-external-business-events).
