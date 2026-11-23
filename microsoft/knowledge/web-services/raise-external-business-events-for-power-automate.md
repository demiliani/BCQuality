---
bc-version: [all]
domain: web-services
keywords: [external-business-event, externalbusinessevent, eventcategory, power-automate, requiredpermissions, business-event-versioning, obsolete, dataverse, notification-after-commit]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Raise external business events for Power Automate, and version them by adding new ones

## Description

An external business event is how a Business Central action triggers Power Automate or another external subscriber. It is a procedure with an empty body and the `ExternalBusinessEvent(Name, DisplayName, Description, Category [, Version])` attribute. The category is a value of the extensible enum `EventCategory`. The procedure parameters are the payload. Learn lists the allowed payload types: simple types such as `Guid`, `Text`, `Code`, `Enum`, `Decimal`, `Date` and `RecordId`, not records.

Business Central sends the notification only after the current transaction commits. If the transaction rolls back, for example on an error, the notification is never sent. A long transaction only delays it. So the event can be raised inside a posting or status change. It needs no `Commit`, and a failed posting does not leak a notification.

Subscribers bind to the event by its name and version, and read the payload by parameter name. AppSourceCop treats them as a contract: the name cannot change (AS0114), the version cannot be added, removed or changed (AS0134), and the event cannot be removed in one step (AS0135).

## Best Practice

- Add an `enumextension` of `EventCategory` for the app's category, as E-Documents (`E-Doc. Event Category`) and Quality Management do.
- Declare each event in one codeunit, with an explicit version such as `'1.0'` from the first release. Pass identifiers and small values: the record `SystemId`, a status enum, a document number, an API or web client URL. The flow reads details back through the API.
- Add the optional `RequiredPermissions` attribute when subscribers must hold a specific permission.
- Raise the event from a subscriber to an existing event that fires when the business action happens. `E-Document Business Events` raises `EDocumentStatusChanged` from `OnAfterModifyEDocumentStatus` on `E-Document Processing`.
- To change the payload, add a new procedure with the same name and a higher version, raise both, and mark the old one `[Obsolete]` with `[OBSOLETE]` at the start of its display name. Remove it in a later release.

See sample: [`raise-external-business-events-for-power-automate.good.al`](raise-external-business-events-for-power-automate.good.al).

## Anti Pattern

Call a Power Automate HTTP trigger URL with `HttpClient` from inside posting. The call runs before the commit, so a later error sends a notification for a document that was never posted, and the HTTP wait holds the posting locks. See [webhook eligibility and validation token renewal](webhook-eligibility-and-validationtoken-renewal.md) for when a record webhook is the better fit.

Edit a shipped event in place: rename it, add or change its version, or change its parameters. Existing flows stop matching or read missing values. The same rule for integration events is in [do not change shipped event attribute flags](../events/do-not-change-shipped-event-attribute-flags.md).

See sample: [`raise-external-business-events-for-power-automate.bad.al`](raise-external-business-events-for-power-automate.bad.al).

## References

- [Business events on Business Central: payload types, notification after commit, custom events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/business-events-overview).
- [ExternalBusinessEvent attribute](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-externalbusinessevent-attribute).
- [Deprecate external business events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-deprecate-external-business-events).
- [AppSourceCop AS0114](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0114) and [AS0134](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0134).
- [E-Document Business Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/API/EDocumentBusinessEvents.Codeunit.al) and [E-Doc. Event Category](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/EDocument/App/src/Processing/API/EDocEventCategory.EnumExt.al).
