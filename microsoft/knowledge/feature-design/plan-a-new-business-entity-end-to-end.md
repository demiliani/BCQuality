---
bc-version: [all]
domain: feature-design
keywords: [feature-design, new-table, master-table, supplemental-table, setup-table, number-series, permission-set, data-classification, install-codeunit, card-page]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a new business entity end to end before building it

## Description

A feature that adds a new kind of record, such as maintenance contracts or delivery zones, touches far more than one table. The table type decides the key, the numbering and the pages. Numbering needs a setup table. Every new object needs permissions, every field needs a data classification, and data that must exist after installation needs install code that also behaves on upgrade.

BCQuality already holds a rule for each of these decisions, spread across several domains and written for code review. Without a plan, an agent builds the table and the page and discovers the rest one review finding at a time.

## Best Practice

Plan one decision per row, in this order, and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Table type | Master, Supplemental, Subsidiary, Document, Setup or another type; it fixes the primary key, captions and pages | [table type conventions](../data-modeling/table-design-must-match-bc-table-type-conventions.md) |
| Numbering | A Master `No.` comes from a number series assigned in `OnInsert`, through codeunit `"No. Series"` | [number series in OnInsert](../data-modeling/master-table-no-from-number-series-in-oninsert.md), [No. Series codeunit](../data-modeling/use-no-series-codeunit-not-noseriesmanagement.md) |
| Setup | A singleton setup table with a card page holds the series and other options; check required values before use | [setup is a singleton](../data-modeling/setup-table-is-a-singleton.md), [TestField required setup](../data-modeling/testfield-required-setup-field.md) |
| Guided setup | Register an assisted setup only when users need a guide, and only one primary guide per app | [register assisted setup](../ui/register-assisted-setup-on-every-registration-event.md), [one primary guide](../ui/one-primary-guided-experience-setup-per-app.md) |
| Data rules | Insert and delete with triggers, delete dependents in `OnDelete`, check `Blocked` where the record is used, match related field lengths | [insert with trigger](../data-modeling/master-data-must-be-inserted-with-trigger.md), [delete with trigger](../data-modeling/delete-master-data-with-trigger.md), [owner deletes dependents](../data-modeling/owning-table-must-delete-dependents-in-ondelete.md), [Blocked at use](../data-modeling/check-blocked-in-referencing-code-not-in-master.md), [relation length](../data-modeling/tablerelation-field-length-must-match-related-field.md) |
| Privacy | Classify at table level where possible and resolve every `ToBeClassified` | [table-level classification](../privacy/table-level-data-classification-cascades.md), [resolve ToBeClassified](../privacy/resolve-tobeclassified-before-release.md) |
| Pages | Card and list as the table type requires, named after the table, with no business logic | [page names](../style/page-name-must-match-source-table.md), [no logic in pages](../style/pages-must-not-contain-business-logic.md), [tooltips](../style/tooltip-required-on-page-fields.md) |
| Permissions | Ship permission sets for the new tables and pages, composed from included sets and without wildcards; give API pages and web services explicit entries | [included sets](../security/compose-permission-sets-with-included-sets.md), [no wildcards](../security/permission-set-avoid-wildcard-grants.md), [exposed objects](../security/exposed-objects-must-be-in-a-permission-set.md) |
| Install and upgrade | Install code does not run on upgrade; use upgrade tags for data changes | [install vs upgrade](../upgrade/install-code-does-not-run-on-version-upgrade.md), [upgrade tags](../upgrade/use-upgrade-tags-not-version-checks.md) |
| Tests | Build fixtures with library codeunits, lower permissions in permission tests, tag scenarios | [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md), [permission tests](../testing/permission-tests-must-lower-the-execution-context.md), [scenario tags](../testing/test-feature-scenario-tags.md) |
| Source layout | Group the files by feature, not by object type | [organize by feature](../style/source-organized-by-feature-not-object-type.md) |

When the entity is a document with lines that is posted, also plan its document defaults, Navigate support and report selections: see [initialize defaults in InitRecord](../data-modeling/initialize-document-defaults-in-initrecord.md), [extend Find Entries](../data-modeling/extend-find-entries-navigate-for-new-document-types.md) and [report selection usage](../data-modeling/extend-report-selection-usage-for-new-document-types.md).

A row the request does not settle, such as whether the entity needs a number series at all, is a question for the requester, not a default to assume.

## Anti Pattern

Design only the table and its page because the request names nothing else. Numbering, setup, permissions, classification and install behavior then surface late as review findings or production errors. Users without SUPER cannot open the new page, and records created before the setup exists have no number.

## References

- [Identify functional table types and characteristics (training)](https://learn.microsoft.com/en-us/training/modules/identify-table-types/).
- [Work with master data: setup tables, No. Series and Blocked patterns (training)](https://learn.microsoft.com/en-us/training/modules/work-with-master-data-business-central/).
