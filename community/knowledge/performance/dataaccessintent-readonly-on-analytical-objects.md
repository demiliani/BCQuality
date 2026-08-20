---
bc-version: [all]
domain: performance
keywords: [dataaccessintent, read-only, read-scale-out, report, api-page, query]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Set DataAccessIntent ReadOnly on analytical objects

> Contributions welcome — open a PR to refine or extend this article.

## Description

Reports, API pages, and queries that only read can run against a read replica when `DataAccessIntent = ReadOnly`. Without the property they hit the primary replica and compete with posting. Agents omit it because the default is read-write and the object "only reads" in AL. The replica routing is a metadata switch, not something the compiler infers from the absence of `Modify`.

## Best Practice

On report, query, and API page objects that never write, set `DataAccessIntent = ReadOnly`. Keep the default on objects that insert, modify, or call a write codeunit from a processing-only report.

See sample: `dataaccessintent-readonly-on-analytical-objects.good.al`.

## Anti Pattern

A listing report or API query with no `DataAccessIntent` that scans G/L or sales lines. The object is read-only in practice and still loads the primary.

See sample: `dataaccessintent-readonly-on-analytical-objects.bad.al`.
