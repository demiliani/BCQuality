---
bc-version: [all]
domain: web-services
keywords: [data-exchange-definition, data-exch-def, data-exch-field-mapping, process-data-exch, processalllinescolumnmapping, generic-import, csv-import, file-import, mapping-codeunit, transformation-rule]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Import external files through a data exchange definition, and map into a temporary record

## Description

Business Central has a configurable file import framework. A data exchange definition (table 1222 `Data Exch. Def`, type `Generic Import`) describes the file: file type, column separator, encoding and header lines. `Data Exch. Line Def` (1227) and `Data Exch. Column Def` (1223) describe lines and columns. `Data Exch. Mapping` (1224) names the target table and its pre-mapping, mapping and post-mapping codeunits. `Data Exch. Field Mapping` (1225) maps each column to a field, with `Optional`, `Transformation Rule`, `Multiplier` and `Priority`.

`Data Exch.` (1220) holds one file. `ImportToDataExch` runs the definition's `Reading/Writing Codeunit`, or its `Reading/Writing XMLport` such as 1220 `Data Exch. Import - CSV`, and stores every value in `Data Exch. Field` (1221). Codeunit 1201 `Process Data Exch.` then writes the target records with `ProcessAllLinesColumnMapping(DataExch, RecRef)`. Users can adapt the definition to a new file layout without code, and transformation rules handle dates, substrings and lookups.

`ProcessColumnMapping` has rules a target table must fit:

- The last field of the primary key must be `Integer` or `BigInteger`. It is set to the file line number times 10000, plus the last existing value. The other key fields come from the template `RecRef`.
- Each mapped value is assigned and then validated with `FieldRef.Validate()`. Order follows `Priority`, highest first, when any mapping has a priority. Otherwise it follows column number.
- A mapping that is not `Optional` raises an error naming the line and column when the value is missing.
- The record is written with `RecRef.Insert()`, without the `OnInsert` trigger.

## Best Practice

Ship a data exchange definition for the format, for example as an XML file imported with XMLport 1225 `Imp / Exp Data Exch Def & Map` in a setup step. Write a mapping codeunit with `TableNo` set to the target table and call `ProcessAllLinesColumnMapping`. Map into a temporary template record, then insert the real records in your own code with `Insert(true)` and any checks. Base App does this in `Process Bank Acc. Rec Lines`: it maps into a temporary `Bank Acc. Reconciliation Line` and inserts the lines afterwards.

Give a mapped field that depends on another a lower `Priority` so it validates after it. Set `File Encoding` on the definition explicitly; see [XMLport text encoding defaults to MS-DOS](../xmlport/xmlport-text-encoding-defaults-to-msdos.md).

See sample: [`import-files-through-data-exchange-definitions.good.al`](import-files-through-data-exchange-definitions.good.al).

## Anti Pattern

A bespoke parser that reads the file with `InStream.ReadText`, splits each line on a hard-coded separator, and `Evaluate`s columns by position. Any change in column order, separator, date format or encoding needs a new release. A second trap is mapping straight into the real table with `Process Data Exch.` and expecting `OnInsert` to run: number series, defaults and checks in `OnInsert` are skipped.

See sample: [`import-files-through-data-exchange-definitions.bad.al`](import-files-through-data-exchange-definitions.bad.al).

## References

- [Process Data Exch.: ProcessColumnMapping, SetField, GetLastIntegerKeyField](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/DataExchange/ProcessDataExch.Codeunit.al).
- [Data Exch.: ImportToDataExch](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/DataExchange/DataExch.Table.al) and [Data Exch. Field Mapping: keys and Priority](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/System/DataExchange/DataExchFieldMapping.Table.al).
- [Process Bank Acc. Rec Lines: map into a temporary record, then insert](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Reconciliation/ProcessBankAccRecLines.Codeunit.al).
