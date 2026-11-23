---
bc-version: [all]
domain: data-modeling
keywords: [configuration-package, rapidstart, config-package-table, config-package-field, processing-order, delayed-insert, onbeforevalidateexception, oninsert, validate-order, data-migration]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Configuration packages insert key fields first, then validate the rest in field order

## Description

Configuration packages (RapidStart) are the standard way customers load setup and master data, including the tables of an extension. Codeunit 8611 `Config. Package Management` applies a package in two passes over all its tables:

- Pass one (`PrimaryKey`) sets only the primary key fields and inserts the record through codeunit 8622 `Config. Insert With Validation`, which calls `Insert(true)`. `OnInsert` runs while every non-key field is still blank.
- Pass two (`NonKeyFields`) evaluates the other fields and calls `Modify(true)`. A field is validated only when its `Config. Package Field` has `Validate Field` set.

Fields are processed in the `Processing Order` of `Config. Package Field`. When the table is added to a package, key fields get the first numbers and the other fields follow in field number order. So the `OnValidate` of a field with a higher number runs after, and can overwrite, a field with a lower number.

Two settings on `Config. Package Table` change this per package. `Delayed Insert` validates all fields first and then calls `Insert(true)`. `Skip Table Triggers` inserts and modifies without triggers.

## Best Practice

Design a table that customers will load by package so the default behaviour is right:

- Keep `OnInsert` to work that needs only the key, such as number series and defaults. Derive values from other fields in those fields' `OnValidate`, not in `OnInsert`.
- Give a field that defaults others, such as a customer number that fills address fields, a lower field number than the fields it fills. A value from the file for a dependent field is then applied after the default.
- When a field's `OnValidate` cannot run during an import, for example because it opens a page or needs a field validated later, subscribe to `OnBeforeValidateException` and return `true` for it. Base App does the same for `Contact` on `Customer` and `Vendor`. The field is then imported without validation by default.
- Test the table by applying a package, not only through the page.

See sample: [`config-packages-insert-key-fields-first-then-validate-by-field-order.good.al`](config-packages-insert-key-fields-first-then-validate-by-field-order.good.al).

## Anti Pattern

An `OnInsert` that tests or copies non-key fields, such as `TestField("Customer No.")`, or a default from the customer. It can work on a page with `DelayedInsert = true`, where the user fills fields before the insert. In a configuration package the insert fails or stores blanks, and the user must find and set `Delayed Insert` per table to work around it. A second form is a field with a low number whose value is later overwritten by the `OnValidate` of a higher-numbered field.

See sample: [`config-packages-insert-key-fields-first-then-validate-by-field-order.bad.al`](config-packages-insert-key-fields-first-then-validate-by-field-order.bad.al).

Related: [initialize document defaults in InitRecord](initialize-document-defaults-in-initrecord.md), [master data must be inserted with trigger](master-data-must-be-inserted-with-trigger.md).

## References

- [Config. Package Management: two apply passes, InsertPackageRecord, ModifyRecordDataFields, ValidateException](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/RapidStart/ConfigPackageManagement.Codeunit.al).
- [Config. Package Table: InitPackageFields and Processing Order, Delayed Insert, Skip Table Triggers](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/RapidStart/ConfigPackageTable.Table.al).
- [Config. Insert With Validation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/RapidStart/ConfigInsertWithValidation.Codeunit.al).
