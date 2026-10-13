---
bc-version: [all]
domain: query
keywords: [sqljointype, left-outer-join, inner-join, dataitemlink, query-dataitem, null-columns, join]
technologies: [al]
countries: [w1]
application-area: [all]
---

# A lower query data item without SqlJoinType is a left outer join

## Description

When a lower `dataitem` in a query sets `DataItemLink` but omits `SqlJoinType`, the join is `LeftOuterJoin`. The dataset keeps every row of the upper data item, including rows with no matching record below; for those rows the lower data item's columns are null and are read in AL as blank or zero. Developers coming from SQL, where a plain `JOIN` is an inner join, expect only matched rows. Code that iterates such a query to find "customers with open orders" or "items with ledger entries" then also processes upper rows without any match, counts them, or writes zero totals for them.

## Best Practice

Set `SqlJoinType` explicitly on every lower data item. Use `InnerJoin` when only matched rows are meaningful. Keep `LeftOuterJoin` when unmatched upper rows are intended, for example to list customers with zero sales, and make the consuming code handle the blank lower columns.

See sample: [`query-dataitems-default-to-left-outer-join.good.al`](query-dataitems-default-to-left-outer-join.good.al).

## Anti Pattern

A query whose lower data item has a `DataItemLink` and no `SqlJoinType`, consumed by code or named for a purpose that assumes only matching rows ("with", "having", "open orders per customer"), or that reads lower columns without handling the blank values of unmatched rows.

Do not flag an explicit `SqlJoinType = LeftOuterJoin`, or an implicit one where the consumer clearly expects and handles unmatched rows.

See sample: [`query-dataitems-default-to-left-outer-join.bad.al`](query-dataitems-default-to-left-outer-join.bad.al).

## References

[Linking and joining data items to define the query dataset](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-links-joins#how-to-link-and-join-data-items) (by default, SqlJoinType is LeftOuterJoin; unmatched rows get null values) and [SqlJoinType property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqljointype-property).
