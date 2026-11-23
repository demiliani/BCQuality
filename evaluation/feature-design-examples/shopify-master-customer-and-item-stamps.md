# Feature design

> Shopify is the master for our customer and product data. When the Shopify Connector creates or updates a customer from Shopify, we want the Shopify customer id stored on the Business Central customer. When it creates or updates an item from a Shopify product, the Shopify product type must be stored in a new item field so purchasing can filter on it. The sync runs every hour in the background.

**Result:** Complete design. **Business process:** Store two Shopify values on Business Central master data when the Shopify Connector, with Shopify as the master side, creates or updates customers and items during its hourly background sync: the Shopify customer id on Customer and the Shopify product type on a new Item field that purchasing can filter on. **Knowledge used:** 11 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Customers and items already linked to Shopify before this app is installed will have blank fields until the connector next updates them. Should an install/upgrade routine (guarded by an upgrade tag) fill them from the existing Shpfy Customer and Shpfy Product links, or is waiting for the next sync acceptable? _(affects: customer-shopify-id-field, item-shopify-product-type-field)_
2. When the connector maps a Shopify customer to an existing BC customer but does not update it (for example Shopify Can Update Customer is off for that shop), no stamp is written. Is that acceptable, or must matched customers also be stamped? _(affects: shopify-master-data-stamps, customer-shopify-id-field)_
3. Is there more than one Shopify shop? A BC customer or item linked to products or customers in several shops would get the value of whichever shop synced last. _(affects: customer-shopify-id-field, item-shopify-product-type-field)_
4. Should the Shopify Customer Id be shown on the Customer Card or Customer List, or only stored? _(affects: customer-shopify-id-field)_
5. Should Shopify Product Type also appear on the Item Card, and should users be able to edit it (it is overwritten on the next sync) or should it be read-only? _(affects: item-shopify-product-type-field, item-list-product-type)_
6. Confirm the length of Shpfy Product 'Product Type' in the targeted connector version so the Item field can match it instead of truncating. _(affects: item-shopify-product-type-field)_
7. Which Business Central version does the app target? It decides whether the Item List column can inherit the ToolTip from the table field (BC24 and later). _(affects: item-list-product-type)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | tableextension | Customer | Holds the Shopify customer id that the connector's create and update paths stamp. Read-only for users because Shopify is the master. | Shopify Customer Id (BigInteger): Same type as the Shopify customer Id it copies. Editable = false. DataClassification = CustomerContent, set on the field because a tableextension has no table-level value to inherit. Field number from the app's ID range. | [1] [7] |
| 2 | create | tableextension | Item | New Item field that holds the Shopify product type so purchasing can filter items on it. | Shopify Product Type (Text[100]): Value copied with CopyStr to the field length. DataClassification = CustomerContent. Carry a Caption and a ToolTip on the table field so page controls inherit the tooltip (from BC24/runtime 13.0). Length must be confirmed against the Shpfy Product 'Product Type' field. | [1] [7] [9] |
| 3 | extend | pageextension | Item List | Show Shopify Product Type as a column on the item list so purchasing can see and filter on it. The bound control inherits the table field's ToolTip; on runtimes before 13.0 the control needs its own ToolTip. |  | [9] |
| 4 | create | codeunit | Shopify Master Data Stamps | Holds the four event subscribers on Shpfy Customer Events and Shpfy Product Events that stamp the customer id and the product type. Each subscriber delegates to a procedure of this codeunit that takes the Shopify and BC records, so tests can call the stamping logic directly. No UI and no Commit, because the sync runs as a job queue entry. |  | [1] [2] [5] |

## 3. How the data flows

- **Shpfy Customer Address.Customer Id** → **Customer.Shopify Customer Id**: copied in an event subscriber. Customer creation (import with Auto Create Unknown Customers, or explicit creation from the Shopify customer): in OnAfterCreateCustomer the customer is already inserted and modified, and the connector stores the Shopify link only afterwards, so take the id from the Shopify customer address parameter, assign it and call Customer.Modify. [1]
- **Shpfy Customer.Id** → **Customer.Shopify Customer Id**: copied in an event subscriber. Customer update by Shpfy Customer Import, which runs only when Shopify Can Update Customer is on: in OnAfterUpdateCustomer the customer is already saved, so assign and call Customer.Modify, only when the value differs. The standard update never touches extension fields. [1]
- **Shpfy Product.Product Type** → **Item.Shopify Product Type**: copied in an event subscriber. Item creation from a Shopify product (Auto Create Unknown Items): in OnAfterCreateItem the item is already inserted from the template and modified, so assign with CopyStr and call Item.Modify. [1]
- **Shpfy Product.Product Type** → **Item.Shopify Product Type**: copied in an event subscriber. Item update by Shpfy Product Import, which runs Shpfy Update Item only when Shopify Can Update Items is on: in OnDoUpdateItemBeforeModify assign the value without Modify and set IsModifiedByEvent to true, so the connector modifies the item even when no standard field changed. [1]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Shpfy Customer Events | `OnAfterCreateCustomer` | Stamp the Shopify customer id on a customer the connector just created, then Modify. | Exit when Customer."No." is blank. · Take the id from ShopifyCustomerAddress."Customer Id"; the connector stores the Shopify customer link only after this event. · Raised also when an OnBeforeCreateCustomer subscriber handled the creation. · No UI and no Commit: the sync can run in a job queue session. | [1] [2] [5] [6] |
| Shpfy Customer Events | `OnAfterUpdateCustomer` | Keep the Shopify customer id in step on every customer update from Shopify, then Modify. | Compare in memory and exit when Customer."Shopify Customer Id" already equals ShopifyCustomer.Id, before calling Modify. · Raised after Customer.Modify, also when OnBeforeUpdateCustomer was handled. · No UI and no Commit. | [1] [2] [5] [11] |
| Shpfy Product Events | `OnAfterCreateItem` | Stamp the Shopify product type on an item the connector just created from a Shopify product, then Modify. | Exit when Item."No." is blank. · CopyStr the product type to the field length. · No UI and no Commit. | [1] [2] [5] |
| Shpfy Product Events | `OnDoUpdateItemBeforeModify` | Set the Shopify product type during the item update and let the connector save it. | Exit when the value already equals the truncated product type, so IsModifiedByEvent is not set needlessly. · Do not call Modify; set IsModifiedByEvent to true. · Do not use OnAfterUpdateItem: it fires only when a standard field changed and the item is already saved. · No UI and no Commit. | [1] [2] [5] [11] |

## 5. Setup, permissions and lifecycle

- **setup**: Document the shop settings the feature requires on each Shpfy Shop: Shopify Can Update Customer on (not Can Update Shopify Customer), Sync Item = From Shopify with Shopify Can Update Items on (not Can Update Shopify Products), and Auto Create Unknown Customers / Auto Create Unknown Items on if Shopify should create new records. With BC as the master the update events never run and the fields stay blank. [1]
- **background**: The hourly sync runs as job queue entries when Allow Background Syncs is on. All subscribers stay non-interactive (no Confirm, RunModal or Message) and do not Commit; let errors propagate so the connector marks the failure. [2] [5] [4]
- **privacy**: Classify both new fields as CustomerContent on the field itself; a tableextension cannot inherit a table-level classification. [7]
- **other**: Add an app.json dependency on the Shopify Connector app. [2]

## Required app dependencies

- **Shopify Connector** (`ec255f57-31d0-4ca2-b751-f2fa7c745abb`, Microsoft): The subscribers bind to Shpfy Customer Events and Shpfy Product Events and read Shpfy Customer, Shpfy Customer Address and Shpfy Product. [2]

## 6. Tests

1. **create-customer-stamps-shopify-id** [1] [10]
    - Given A customer created with LibrarySales.CreateCustomer and a Shpfy Customer Address record with a random Customer Id
    - When The stamping procedure behind OnAfterCreateCustomer runs
    - Then Customer."Shopify Customer Id" read back from the database equals the address's Customer Id. The connector's create path calls Shopify and its event publishers are internal procedures, so the test calls the subscriber's procedure directly.
2. **update-customer-stamps-shopify-id** [1] [10] [11]
    - Given A customer with a blank or different Shopify Customer Id and a Shpfy Customer record with a random Id
    - When The stamping procedure behind OnAfterUpdateCustomer runs
    - Then The stored Customer."Shopify Customer Id" equals the Shpfy Customer Id; running it again with the same Id performs no further change.
3. **create-item-stamps-product-type** [1] [10]
    - Given An item created with LibraryInventory.CreateItem and a Shpfy Product with a random Product Type
    - When The stamping procedure behind OnAfterCreateItem runs
    - Then Item."Shopify Product Type" read back from the database equals the product type.
4. **update-item-sets-modified-flag** [1] [10]
    - Given An item whose Shopify Product Type differs from the Shpfy Product's Product Type
    - When The procedure behind OnDoUpdateItemBeforeModify runs with IsModifiedByEvent = false
    - Then The item variable carries the new product type and IsModifiedByEvent is true; the procedure itself did not modify the item in the database.
5. **update-item-unchanged-leaves-flag** [1] [11]
    - Given An item whose Shopify Product Type already equals the Shpfy Product's Product Type
    - When The procedure behind OnDoUpdateItemBeforeModify runs with IsModifiedByEvent = false
    - Then IsModifiedByEvent stays false.
6. **long-product-type-is-truncated** [1]
    - Given A Shpfy Product whose Product Type is longer than the Item field
    - When The procedure behind OnAfterCreateItem runs
    - Then The item stores the first characters up to the field length and no overflow error is raised.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no repository or app.json was supplied.
- The Item List page extension rests partly on judgment: no article says which page purchasing filters on; only its ToolTip rule is grounded.
- Testing approach rests partly on judgment: tests call the subscriber codeunit's procedures directly because the connector's sync calls Shopify and its publishers are internal procedures; no opened article prescribes a test library for the Shopify Connector.
- Whether a secondary key on Item 'Shopify Product Type' is needed for purchasing's filters is not covered by an opened article.

## Sources

[1] `microsoft/knowledge/shopify/decide-the-master-side-before-extending-shopify-customer-and-item-sync.md`: Master side, the four subscriber events, where each one needs Modify or IsModifiedByEvent, and the shop settings.
    - Write the master side into the design and hook only the events of that direction; with BC as master the BC-side update events never run.
    - Shopify as master: set customer fields in OnAfterCreateCustomer and OnAfterUpdateCustomer and call Customer.Modify, because the record is already saved.
    - Items: set fields in OnDoUpdateItemBeforeModify and set IsModifiedByEvent to true; in OnAfterCreateItem assign and call Item.Modify.
    - Do not rely on OnAfterUpdateItem without Modify, nor on Customer OnAfterInsertEvent to detect Shopify-created customers.
    - The Shopify customer link is stored only after OnAfterCreateCustomer; OnAfterFindMapping and the customer template events are [InternalEvent].
[2] `microsoft/knowledge/shopify/extend-the-shopify-connector-through-integration-events-and-public-objects.md`: Dependency on the Shopify Connector, subscribable integration events, background sync behavior.
    - Depend on Shopify Connector, id ec255f57-31d0-4ca2-b751-f2fa7c745abb, publisher Microsoft.
    - Check that each event exists and is an [IntegrationEvent]; [InternalEvent] publishers cannot be subscribed to from another app.
    - Subscribers must not need UI and must not Commit; with Allow Background Syncs the sync runs as a job queue entry.
    - Do not copy connector code; ask for missing events in BCApps.
[3] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Cross-cutting rows for a new field: privacy, upgrade back-fill of existing rows, tests reading the value back.
    - Existing rows keep blank unless upgrade code fills them; whether to back-fill is a question for the requester.
    - Classify the field on every table that holds it.
    - Test through each chosen entry point and read the value back from the target.
[4] `microsoft/knowledge/feature-design/plan-api-exposure-and-background-sync.md`: Background-sync row: the job queue handler must be non-interactive and propagate failures.
    - Job queue work has no UI and lets failures propagate so the entry shows an error.
[5] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Guards on every subscriber, which run inside the connector's job queue sync.
    - No Confirm, Page.RunModal, Report.RunModal, upload or download in code run by the job queue.
    - Do not use Message as the only result notification; let failures propagate to the job queue log.
[6] `microsoft/knowledge/events/treat-local-and-internal-events-as-subscriber-contracts.md`: Confirms that the connector's event publishers declared internal can still be subscribed to, unlike [InternalEvent].
    - local and internal access on Business and Integration event publishers restricts who raises the event, not who subscribes; [InternalEvent] is module-only.
[7] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of the two new tableextension fields.
    - Every Normal field a tableextension adds must set its own DataClassification.
    - Use the value that matches the data, such as CustomerContent; never SystemMetadata or ToBeClassified for customer data.
[8] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Open question on back-filling customers and items that were synced before the app is installed.
    - New fields on existing tables get the datatype default on existing rows; filling them needs an upgrade or install routine guarded by an upgrade tag.
[9] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: ToolTip placement for the Item List column; applies from BC24 (runtime 13.0).
    - On runtime 13.0 or later a bound page field inherits the table field's ToolTip; do not duplicate it on the page.
    - On earlier runtimes, or when the table field has no ToolTip, the page control needs its own.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers and items.
    - Create customers and items with LibrarySales.CreateCustomer and LibraryInventory.CreateItem, and values with LibraryRandom, not hand-rolled Init/Insert.
[11] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Cheap in-memory comparison before Modify in the update subscribers, which fire for every synced record.
    - Open the subscriber with an in-memory check that exits when there is nothing to do, before any database call.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

