---
bc-version: [all]
domain: feature-design
keywords: [feature-design, api-page, api-query, job-queue, outbox, idempotency, httpclient, secrets, webhook, telemetry]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan API exposure and background synchronization before building it

## Description

Requests such as "expose contracts to our portal" or "sync orders to the warehouse system every night" combine two concerns. Inbound, external systems read or write Business Central data through API pages or queries. Outbound, Business Central calls an external service, usually from a job queue entry. Each side has rules that are easy to break at design time and expensive to change after the API is published or the integration is live.

BCQuality holds a rule for most of these decisions in the web-services, performance, security, privacy and telemetry domains. This map puts them in planning order.

## Best Practice

Plan the inbound side first, then the outbound side, then what both share:

| Side | Decision | What to settle | Knowledge |
| --- | --- | --- | --- |
| Inbound | Page or query | A query is read-only and has no webhooks; use an API page when consumers write or subscribe | [API query is read-only](../web-services/api-query-is-read-only-and-has-no-webhooks.md) |
| Inbound | Routing and version | Publisher, group, version and entity names; a changed shape is a new version | [required API properties](../web-services/set-required-api-page-properties.md), [version by adding](../web-services/version-apis-by-adding-not-mutating-published-versions.md), [entity naming](../style/api-page-entity-naming-singular-plural.md) |
| Inbound | Keys and parts | Address records by `SystemId`, and link subpages on it | [SystemId as the key](../web-services/expose-systemid-as-the-api-key.md), [link parts on SystemId](../web-services/link-api-parts-on-systemid-and-set-multiplicity.md) |
| Inbound | Writes and operations | Least-privilege writes, read-only pages locked down, business operations as bound actions | [least-privilege writes](../web-services/api-page-least-privilege-write-access.md), [lock read-only pages](../web-services/disable-write-operations-on-read-only-api-pages.md), [bound actions](../web-services/expose-operations-as-bound-actions.md) |
| Inbound | Change notifications | Webhook eligibility and subscription renewal, when consumers want pushes instead of polling | [webhooks](../web-services/webhook-eligibility-and-validationtoken-renewal.md) |
| Inbound | Permissions | Every API page, query and published codeunit in a permission set | [exposed objects](../security/exposed-objects-must-be-in-a-permission-set.md) |
| Outbound | Where the call runs | Never inside a write transaction; record an outbox row and send it from a recurring job queue entry | [HttpClient outside write transactions](../performance/httpclient-inside-write-transaction-holds-locks.md) |
| Outbound | Retries | A stable idempotency key per outbox row; the external service must deduplicate | [idempotent job queue effects](../performance/job-queue-external-effects-must-be-idempotent.md) |
| Outbound | Job queue handler | No UI, failures propagated so the entry shows an error, conflicting jobs serialized by category | [no UI](../performance/job-queue-handlers-must-not-require-ui.md), [propagate failures](../performance/job-queue-handlers-must-propagate-failures.md), [category serializes](../performance/job-queue-category-code-serializes-conflicting-jobs.md) |
| Outbound | Responses | Check platform failure and HTTP status before reading the body | [platform failure first](../web-services/handle-httpclient-platform-failure-before-response-access.md), [status before body](../web-services/check-http-status-before-consuming-response-body.md) |
| Outbound | Credentials and endpoint | OAuth2 where the service supports it, secrets in isolated storage as `SecretText`, configurable URLs validated | [prefer OAuth2](../security/prefer-oauth2-over-api-keys-for-external-http-calls.md), [secrets in isolated storage](../security/secrets-isolated-storage.md), [SecretText](../security/secrettext-for-credentials.md), [validate URLs](../security/validate-user-configurable-urls.md) |
| Outbound | Consent | A privacy notice the admin approves before data leaves Business Central | [privacy notice consent](../privacy/privacy-notice-consent-for-external-data-transfer.md) |
| Both | Exchanged values | Culture-independent formats and explicit text encoding | [standard format 9](../web-services/format-exchanged-values-with-standard-format-9.md), [text encoding](../web-services/set-text-encoding-on-streams-exchanged-externally.md) |
| Both | Telemetry | Who receives the signal, usage logged only after success, no personal data in dimensions | [telemetry scope](../telemetry/choose-telemetry-scope-by-audience.md), [usage after success](../telemetry/feature-usage-only-after-success.md), [no PII in dimensions](../privacy/featuretelemetry-customdimensions-no-pii.md) |

Facts the request leaves open, such as who calls whom, how often, and what the external service does with a repeated request, are questions for the requester. The outbound design depends on the answers.

When the data being exposed is a new entity, plan it first with [plan a new business entity end to end](plan-a-new-business-entity-end-to-end.md).

## Anti Pattern

Design the API page and a codeunit that calls the external service from the posting or page action that changes the data. The call holds locks during the request, a failure leaves no retry, a retry creates duplicates, and the API shape cannot change once a consumer depends on it.

## References

- [API page type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype).
- [Job queue](https://learn.microsoft.com/en-us/dynamics365/business-central/admin-job-queues-schedule-tasks).
