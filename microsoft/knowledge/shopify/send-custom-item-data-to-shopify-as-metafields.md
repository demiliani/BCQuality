---
bc-version: [all]
domain: shopify
keywords: [shopify-connector, shpfy-product, shpfy-metafield, onafterfillinshopifyproductfields, onbeforeupdateproductmetafields, product-export, metafields, shpfy-product-events, graphql]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Send custom item data to Shopify as metafields, not as product fields

## Description

The Shopify Connector exports items through `Shpfy Product Export`. `FillInProductFields` sets the title, vendor, product type, description HTML and status on the `Shpfy Product` record. Then it raises `OnAfterFillInShopifyProductFields(Item, var ShopifyProduct)`. `Shpfy Product API.UpdateProduct` builds the GraphQL `productUpdate` mutation from a fixed list of fields: title, descriptionHtml, productType, status, tags and vendor. A field that an extension adds to `Shpfy Product` or `Shpfy Variant` is never serialized. Setting it in the event changes only the BC copy, and nothing reaches Shopify.

The connector's own route for extra data is product and variant metafields. During the product update it raises `OnBeforeUpdateProductMetafields(ProductId)`. It then calls the public `Shpfy Metafields.SyncMetafieldsToShopify`, which sends the `Shpfy Metafield` rows for that product. A row is sent when it is new to Shopify, or when its `Last Updated by BC` is later than Shopify's timestamp. Rows with an empty `Value` are skipped. This step runs only when the shop has both `Can Update Shopify Products` and `Product Metafields To Shopify` turned on.

## Best Practice

To publish a custom item value, subscribe to `OnBeforeUpdateProductMetafields`. Find the item through `Shpfy Product."Item SystemId"`. Insert or update one `Shpfy Metafield` row with `Parent Table No.` set to `Database::"Shpfy Product"` and `Owner Id` set to the product id. Give it a fixed `Namespace` and `Name` and a valid `Type`, and set `Value` with `Validate` so the type check runs. Modify the row only when the value changed, so that unchanged rows are not sent again. Use `OnAfterFillInShopifyProductFields` only to change fields the connector already maps, such as `Vendor` or `Title`. Use `OnBeforeCreateProductBodyHtml` and `OnAfterCreateProductBodyHtml` to add text to the description. The design must state that the two shop settings above are required.

In the other direction, data that comes back from Shopify is available in `OnAfterCreateItem` and `OnAfterUpdateItem` on `Shpfy Product Events`. There you can read the stored `Shpfy Metafield` rows for the product.

See sample: [`send-custom-item-data-to-shopify-as-metafields.good.al`](send-custom-item-data-to-shopify-as-metafields.good.al).

## Anti Pattern

Add a field such as `Warranty Months` to `Shpfy Product`, fill it in `OnAfterFillInShopifyProductFields`, and expect it on the Shopify product. The connector compares records to detect changes, but the mutation only names its own fields. Shopify never sees the value, and no error tells you so. Writing your own GraphQL call from the extension is not possible either, because `Shpfy Communication Mgt.` and the API codeunits are internal; see [Shopify connector extension points](extend-the-shopify-connector-through-integration-events-and-public-objects.md).

See sample: [`send-custom-item-data-to-shopify-as-metafields.bad.al`](send-custom-item-data-to-shopify-as-metafields.bad.al).

## References

- [Shpfy Product Export, FillInProductFields and UpdateMetafields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProductExport.Codeunit.al).
- [Shpfy Product API, UpdateProduct mutation fields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProductAPI.Codeunit.al).
- [Shpfy Metafields, public sync procedures](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Metafields/Codeunits/ShpfyMetafields.Codeunit.al).
- [Shpfy Metafield table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Metafields/Tables/ShpfyMetafield.Table.al).
- [Shpfy Product Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProductEvents.Codeunit.al).
- [Extend the Shopify Connector](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-shopify).
