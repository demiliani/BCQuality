---
bc-version: [all]
domain: finance-extensions
keywords: [reminder-header, finance-charge-memo-header, reminder-make, finchrgmemo-make, create-reminders, create-finance-charge-memos, onvalidatecustomernoonafterassigncustomervalues, default-values]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Default customer fields on reminder and finance charge memo headers

## Description

`Reminder Header` (295) and `Finance Charge Memo Header` (302) copy their defaults from the customer in the `OnValidate` trigger of `Customer No.`, field by field. After the copy, each table raises `OnValidateCustomerNoOnAfterAssignCustomerValues(var <Header>; Customer)`. The sales header events such as `OnAfterCopySellToCustomerAddressFieldsFromCustomer` do not run for these documents.

The batch jobs use the same trigger. `Create Reminders` (report 188) and the reminder automation job both run `"Reminder-Make"` (392). It inserts an empty header, then calls `Validate("Customer No.")` and finally `Modify`. `Create Finance Charge Memos` (report 191) runs `"FinChrgMemo-Make"` (394) the same way. So one subscriber covers manual entry, the batch jobs and reminder automation.

`"FinChrgMemo-Make"` also has a checking mode. In that mode it validates `Customer No.` on a header that is never inserted or modified.

## Best Practice

Add the field to the header table and subscribe to `OnValidateCustomerNoOnAfterAssignCustomerValues` on each header table in scope. Assign the value from the `Customer` parameter and do nothing else. The page or the make codeunit saves the record afterwards. To show the value on the issued document, give it the same field number on the issued header; see [carry reminder and finance charge memo fields when issuing](carry-reminder-and-finance-charge-fields-when-issuing.md).

Reminders and finance charge memos are separate documents with separate events. A design that defaults the field on reminders must add the finance charge memo subscriber too, if both are in scope. For the sales and purchase document equivalents, see [default sales and purchase fields from master data](../sales-purchase/default-sales-and-purchase-fields-from-master-data.md).

See sample: [`default-customer-fields-on-reminder-and-finance-charge-headers.good.al`](default-customer-fields-on-reminder-and-finance-charge-headers.good.al).

## Anti Pattern

Subscribe only to `OnBeforeReminderHeaderInsert` on `"Reminder-Make"`. Reminders a user creates on the page never get the value. Calling `Modify` inside the customer event is also wrong. In the finance charge memo checking mode the header does not exist, so `Modify` fails. In the normal flow the make codeunit modifies the same record again right after.

See sample: [`default-customer-fields-on-reminder-and-finance-charge-headers.bad.al`](default-customer-fields-on-reminder-and-finance-charge-headers.bad.al).

## References

- [Reminder Header, Customer No. trigger and event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Reminder/ReminderHeader.Table.al).
- [Reminder-Make](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Reminder/ReminderMake.Codeunit.al).
- [Finance Charge Memo Header, Customer No. trigger and event](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/FinanceCharge/FinanceChargeMemoHeader.Table.al).
- [FinChrgMemo-Make](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/FinanceCharge/FinChrgMemoMake.Codeunit.al).
