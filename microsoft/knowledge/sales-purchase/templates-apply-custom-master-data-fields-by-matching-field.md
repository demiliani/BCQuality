---
bc-version: [all]
domain: sales-purchase
keywords: [customer-templ, vendor-templ, item-templ, customer-templ-mgt, applytemplate, onapplytemplateonbeforecustomermodify, create-customer-from-contact, default-values, tableextension, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Templates apply custom master data fields only through a matching template field

## Description

New customers, vendors and items are usually created from a template, not typed on a blank card. `Customer Templ. Mgt.`, `Vendor Templ. Mgt.` and `Item Templ. Mgt.` first insert the new record with `Insert(true)`, so its `OnInsert` trigger runs. Then `ApplyTemplate` copies the template. Creating a customer or vendor from a contact follows the same order: `Contact` inserts the record, then calls `ApplyCustomerTemplate` or `ApplyVendorTemplate`.

`ApplyTemplate` copies with `RecordRef`, field by field, from `Customer Templ.`, `Vendor Templ.` or `Item Templ.`. A template field is used only when the master table has a field with the same number, name, type and length, and both are normal fields. A field that differs in any of these is skipped without an error. A template value is also skipped when it is empty.

When a customer or vendor is created, the template does not overwrite values already set. A field that `OnInsert` or an insert subscriber has filled keeps that value. A field that still holds its `InitValue` counts as empty and takes the template value. Customer and vendor values are assigned without `Validate`. Item creation is different: it overwrites existing values and validates each copied field.

Each routine raises an event before its final `Modify(true)`: `OnApplyTemplateOnBeforeCustomerModify`, `OnApplyTemplateOnBeforeVendorModify` and `OnApplyTemplateOnBeforeItemModify`, all on the matching `Templ. Mgt.` codeunit.

## Best Practice

To make a custom master data field templatable, add it to the template table with the same field number, name, type and length as on the master table. Show it on the template card, such as `Customer Templ. Card`. Base App does the same: its service extension adds `Service Zone Code` to both `Customer` and `Customer Templ.` as field 5900. No subscriber is needed for the copy. "Save as template" fills the template with `TransferFields`, so the same field also flows back into new templates.

Set a fallback default with `InitValue` on the master field, or in the `OnApplyTemplateOnBefore...Modify` subscriber when the field is still empty. Then the template value wins when it has one. If the field has validation logic that must run, call `Validate` in that subscriber for customers and vendors, because the template assigns the value directly.

Test every creation path the feature supports: a customer from a template, a customer from a contact, and a vendor or item when they are in scope.

See sample: [`templates-apply-custom-master-data-fields-by-matching-field.good.al`](templates-apply-custom-master-data-fields-by-matching-field.good.al).

## Anti Pattern

Set the default only on the customer card page, or in a subscriber on the customer's insert. Records created from a template, a contact or an API never get the card default. The insert subscriber runs before the template, so the field is no longer empty and the template value is ignored. Another mistake is to add the template field with a different name or length, which the template skips without any message.

See sample: [`templates-apply-custom-master-data-fields-by-matching-field.bad.al`](templates-apply-custom-master-data-fields-by-matching-field.bad.al).

Defaults on documents follow other rules; see [default sales and purchase fields from customer, vendor and item](default-sales-and-purchase-fields-from-master-data.md).

## References

- [Customer Templ. Mgt., CreateCustomerFromTemplate, ApplyTemplate and TemplateFieldCanBeProcessed](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Customer/CustomerTemplMgt.Codeunit.al).
- [Vendor Templ. Mgt., ApplyTemplate](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Vendor/VendorTemplMgt.Codeunit.al).
- [Item Templ. Mgt., InitFromTemplate validates copied fields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Item/ItemTemplMgt.Codeunit.al).
- [Contact, CreateCustomerFromTemplate inserts then applies the template](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/CRM/Contact/Contact.Table.al).
- [Serv. Customer Templ., a template field mirrored by Base App](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Sales/Customer/ServCustomerTempl.TableExt.al).
