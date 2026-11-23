---
bc-version: [all]
domain: shopify
keywords: [shopify-connector, sync-direction, shopify-can-update-customer, can-update-shopify-products, onaftercreatecustomer, onafterupdatecustomer, ondoupdateitembeforemodify, onaftercreateitem, onbeforefindmapping, shpfy-customer-events]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Decide the master side before extending Shopify customer and item sync

## Description

The `Shpfy Shop` card decides, per entity, which side owns the data. The two flags of each pair exclude each other: validating one clears the other.

- Customers: `Shopify Can Update Customer` lets an import from Shopify update BC customers. `Can Update Shopify Customer` lets BC update Shopify customers. `Customer Import From Shopify` (`AllCustomers` or `WithOrderImport`) chooses which Shopify customers are imported. An unknown customer becomes a BC customer only when `Auto Create Unknown Customers` is on, or when the user creates it explicitly.
- Items: `Sync Item` (`To Shopify` or `From Shopify`) makes `Shpfy Sync Products` export or import. `Shopify Can Update Items` and `Can Update Shopify Products` are the exclusive update pair. Unknown products become items only with `Auto Create Unknown Items`.

So the BC-side update events run only when Shopify is the master. `Shpfy Customer Import` runs `Shpfy Update Customer` only when `Shopify Can Update Customer` is on. `Shpfy Product Import` runs `Shpfy Update Item` only when `Shopify Can Update Items` is on. In a shop where BC is the master, a subscriber to these events never runs.

The integration events on `Shpfy Customer Events` (codeunit 30115) and `Shpfy Product Events` behave like this:

- `OnAfterCreateCustomer(Shop, var ShopifyCustomerAddress, var Customer)`: the customer was inserted from the template, filled from the default address and modified. The link to the Shopify customer is stored only afterwards. It is raised even when a subscriber to `OnBeforeCreateCustomer` handled the creation.
- `OnAfterUpdateCustomer(Shop, var ShopifyCustomer, var Customer)`: raised after `Customer.Modify`, also when `OnBeforeUpdateCustomer` was handled. The standard update overwrites name, contact, address, country, county, post code, city, phone, e-mail and tax area fields. It never touches extension fields.
- `OnBeforeFindMapping(Direction, var ShopifyCustomer, var Customer, var Handled)`: for the Shopify-to-BC direction, a handled call returns whether `ShopifyCustomer."Customer SystemId"` is filled. The connector does not save that link for you. `OnAfterFindMapping` and the customer template events are `[InternalEvent]`.
- `OnAfterCreateItem(Shop, var ShopifyProduct, ShopifyVariant, var Item)`: the item was inserted from the item template and modified. `OnBeforeFindItemTemplate` and `OnAfterFindItemTemplate` are integration events, unlike the customer template events.
- `OnDoUpdateItemBeforeModify(var ShopifyShop, var ShopifyProduct, var Item, var IsModifiedByEvent)`: raised inside the item update, before the connector decides whether to modify. `OnAfterUpdateItem` is raised only when the update really modified the item, and not when `OnBeforeUpdateItem` was handled.
- `OnBeforeFindProductMapping(Direction, var ShopifyProduct, var ShopifyVariant, var Item, var ItemVariant, var Handled)`: when handled with an item set, the connector stores the link itself.

## Best Practice

Write the master side into the design for customers and for items, and name the shop settings it requires. Then hook only the events of that direction.

- Shopify is the master: set your fields in `OnAfterCreateCustomer` and `OnAfterUpdateCustomer`, and call `Customer.Modify`, because the record is already saved. For items, set fields in `OnDoUpdateItemBeforeModify` and set `IsModifiedByEvent` to true. The connector then modifies the item even when no standard field changed. In `OnAfterCreateItem`, assign and call `Item.Modify`.
- BC is the master: adjust the standard `Shpfy Customer` and `Shpfy Customer Address` values in `OnBeforeSendCreateShopifyCustomer` and `OnBeforeSendUpdateShopifyCustomer`, just before the connector sends them. For products, see [send custom item data as metafields](send-custom-item-data-to-shopify-as-metafields.md).
- Custom matching of Shopify customers: use `OnBeforeFindMapping`, set `"Customer SystemId"` and save the Shopify customer yourself.

Both directions can run in a job queue session, so subscribers must not need UI; see [Shopify connector extension points](extend-the-shopify-connector-through-integration-events-and-public-objects.md).

See sample: [`decide-the-master-side-before-extending-shopify-customer-and-item-sync.good.al`](decide-the-master-side-before-extending-shopify-customer-and-item-sync.good.al).

## Anti Pattern

Fill an item field in `OnAfterUpdateItem` without `Modify`, and expect it on every sync. The event fires only when a standard field changed, and the item is already saved. Detecting Shopify-created customers in `Customer` `OnAfterInsertEvent` fails as well: the template insert happens before any Shopify link exists. A design that wants "BC owns the credit data, Shopify owns the address" cannot be set up with the flags, because they exclude each other. It needs its own rule in the update events.

See sample: [`decide-the-master-side-before-extending-shopify-customer-and-item-sync.bad.al`](decide-the-master-side-before-extending-shopify-customer-and-item-sync.bad.al).

## References

- [Shpfy Shop, sync direction fields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Base/Tables/ShpfyShop.Table.al).
- [Shpfy Customer Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Customers/Codeunits/ShpfyCustomerEvents.Codeunit.al) and [Shpfy Product Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProductEvents.Codeunit.al).
- [Shpfy Customer Import, update only when Shopify can update customers](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Customers/Codeunits/ShpfyCustomerImport.Codeunit.al).
- [Shpfy Create Customer](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Customers/Codeunits/ShpfyCreateCustomer.Codeunit.al) and [Shpfy Customer Mapping](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Customers/Codeunits/ShpfyCustomerMapping.Codeunit.al).
- [Shpfy Update Item, OnDoUpdateItemBeforeModify](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyUpdateItem.Codeunit.al) and [Shpfy Product Import](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProductImport.Codeunit.al).
- [Extend the Shopify Connector](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-shopify).
