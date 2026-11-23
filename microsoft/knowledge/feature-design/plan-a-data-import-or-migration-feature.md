---
bc-version: [all]
domain: feature-design
keywords: [feature-design, data-import, data-migration, data-exchange, xmlport, configuration-package, staging-table, job-queue, retention-policy, error-collection]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a data import or migration feature

## Description

Requests such as "import the supplier price file every morning", "load our legacy customers" or "let the partner portal create orders" bring outside data into Business Central. Business Central offers several import mechanisms, each with its own rules for how target records are inserted and validated: data exchange definitions, XMLports, API pages and configuration packages. Around the mechanism, the design must decide where raw data waits, how bad rows are reported, whether the work runs in the background, how long staged data and logs are kept, and who may run it.

Most of these decisions have a rule in the web-services, xmlport, data-modeling, error-handling, performance, privacy, telemetry and security domains. This map puts them in planning order.

## Best Practice

Plan one decision per row and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Mechanism | A file whose layout users adapt: data exchange definition. A fixed structured file: XMLport. Another system pushing records: API page. Setup and master data loaded by customers: configuration package | [data exchange definitions](../web-services/import-files-through-data-exchange-definitions.md), [XMLport Import argument](../xmlport/xmlport-run-import-argument-must-match-direction.md), [plan API exposure](plan-api-exposure-and-background-sync.md), [configuration packages](../data-modeling/config-packages-insert-key-fields-first-then-validate-by-field-order.md) |
| One-time migration | A migration from a source system follows its own pipeline, not upgrade codeunits | [hybrid migration is not upgrade](../upgrade/hybrid-migration-codeunits-not-standard-upgrade.md) |
| Reading the file | Streams instead of the `File` type; explicit encoding; culture-independent values; JSON nulls checked | [File type is OnPrem-only](../appsource/file-datatype-saas.md), [XMLport encoding](../xmlport/xmlport-text-encoding-defaults-to-msdos.md), [stream encoding](../web-services/set-text-encoding-on-streams-exchanged-externally.md), [standard format 9](../web-services/format-exchanged-values-with-standard-format-9.md), [JSON null](../web-services/check-json-null-before-converting-values.md) |
| Staging | Map into a temporary record and insert the real records in own code; a persistent staging table need not fit a business table type; guard bulk helpers against the real table | [data exchange definitions](../web-services/import-files-through-data-exchange-definitions.md), [table types](../data-modeling/table-design-must-match-bc-table-type-conventions.md), [guard with IsTemporary](../security/guard-bulk-operations-with-istemporary.md) |
| Creating target records | Insert with triggers so number series and defaults run; keep `OnInsert` to key-only work so packages load | [insert with trigger](../data-modeling/master-data-must-be-inserted-with-trigger.md), [configuration packages](../data-modeling/config-packages-insert-key-fields-first-then-validate-by-field-order.md), [defaults in InitRecord](../data-modeling/initialize-document-defaults-in-initrecord.md) |
| Validation order | Validate through field triggers; dependent fields validate after the fields they depend on (priority or field order) | [data exchange definitions](../web-services/import-files-through-data-exchange-definitions.md), [configuration packages](../data-modeling/config-packages-insert-key-fields-first-then-validate-by-field-order.md) |
| Posting imported data | Journal or document data posts through the standard routines in a dedicated batch | [dedicated journal batch](../finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md), [post through item journals](../scm/post-item-ledger-changes-through-item-journals.md) |
| Error collection | Collect row errors instead of stopping at the first; act on the XMLport return value; actionable messages | [collect with ErrorBehavior](../error-handling/collect-validation-errors-with-errorbehavior.md), [XMLport return value](../xmlport/xmlport-import-export-return-value-controls-failure-handling.md), [ErrorInfo with actions](../error-handling/prefer-errorinfo-for-actionable-errors.md), [consume TryFunction results](../error-handling/ignored-tryfunction-return-disables-try-semantics.md) |
| Error log | A log of failures must survive the rollback of the failed work | [log writes survive rollback](../error-handling/log-writes-must-survive-rollback.md) |
| Transactions | No commit per row; commit before `Codeunit.Run` inside a write transaction; protect atomic steps | [no Commit in loops](../performance/avoid-commit-inside-loops.md), [commit before Codeunit.Run](../performance/codeunit-run-requires-prior-commit-inside-transaction.md), [CommitBehavior](../security/commitbehavior-attribute-scopes-explicit-commits.md) |
| Background run | Job queue handler without UI, failures propagated, conflicting imports serialized by category | [no UI](../performance/job-queue-handlers-must-not-require-ui.md), [propagate failures](../performance/job-queue-handlers-must-propagate-failures.md), [category serializes](../performance/job-queue-category-code-serializes-conflicting-jobs.md), [on hold does not stop a run](../performance/job-queue-on-hold-does-not-stop-running-work.md) |
| Idempotency | Detecting a file or row imported twice: none yet; rests on judgment. Calls back to the source system use a stable request ID | [idempotent external effects](../performance/job-queue-external-effects-must-be-idempotent.md) |
| Volume | Buffered inserts, triggers only where needed, batched number series | [buffered inserts](../performance/preserve-buffered-inserts-by-separating-target-reads.md), [Insert(false) when no trigger is needed](../performance/pass-false-to-insert-when-trigger-not-needed.md), [batch number series](../performance/batch-number-series-instead-of-getnextno-per-row.md) |
| Retention | Register staging and log tables for retention policies, consider a default setup, delete processed rows in bulk | [register log tables](../privacy/register-owned-log-tables-for-retention-policies.md), [default retention setup](../privacy/ship-a-default-retention-policy-setup.md), [DeleteAll](../performance/use-deleteall-for-filtered-bulk-deletion.md) |
| Privacy | Classify the destination and staging fields; consent before pulling from an external service | [classify the destination](../privacy/migration-destination-classification.md), [classification on sensitive fields](../privacy/data-classification-required-on-pii-fields.md), [privacy notice consent](../privacy/privacy-notice-consent-for-external-data-transfer.md) |
| Telemetry | Uptake and usage after success; stable dimensions without personal data | [uptake in order](../telemetry/feature-uptake-transitions-in-order.md), [usage after success](../telemetry/feature-usage-only-after-success.md), [stable dimensions](../telemetry/keep-custom-dimension-schema-stable.md), [no PII in dimensions](../privacy/featuretelemetry-customdimensions-no-pii.md) |
| Permissions | Permission sets for staging, log and setup tables; indirect access where only the import code may write; least-privilege API writes | [exposed objects](../security/exposed-objects-must-be-in-a-permission-set.md), [indirect permissions](../security/indirect-permissions-for-elevated-access.md), [included sets](../security/compose-permission-sets-with-included-sets.md), [API writes](../web-services/api-page-least-privilege-write-access.md) |
| Tests | Test with a real file or package, not only through the page; match the transaction model to the commits | [configuration packages](../data-modeling/config-packages-insert-key-fields-first-then-validate-by-field-order.md), [TransactionModel](../testing/transactionmodel-attribute-governs-test-transactions.md), [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md) |

Facts the request leaves open, such as file format and owner, how often it arrives, what happens to rows that fail, and how long staged data is kept, are questions for the requester.

## Anti Pattern

Read the file with a hand-written parser, insert each row into the real table with `Insert(false)` inside one loop that commits per row, and show a message for every error. A new column order needs a release, number series and defaults are skipped, a failure leaves half the file imported with no log, and the staging and log tables grow without limit.

## References

- [Data exchange framework](https://learn.microsoft.com/dynamics365/business-central/across-about-the-data-exchange-framework).
- [Configuration packages](https://learn.microsoft.com/dynamics365/business-central/admin-how-to-prepare-a-configuration-package).
