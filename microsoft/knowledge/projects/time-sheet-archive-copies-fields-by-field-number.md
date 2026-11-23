---
bc-version: [all]
domain: projects
keywords: [time-sheet-header-archive, time-sheet-line-archive, time-sheet-detail-archive, movetimesheettoarchive, move-time-sheets-to-archive, transferfields, onbeforetimesheetlinearchiveinsert, time-sheet-posting-entry, field-number]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Time sheet archive copies fields by field number

## Description

Report 953 `Move Time Sheets to Archive` calls `MoveTimeSheetToArchive` in `Time Sheet Management` for each time sheet. That procedure first calls `Check` on `Time Sheet Header`. Every line must be Approved and `Posted`, and a time sheet without lines raises an error. So open, rejected, or partly posted time sheets cannot be archived.

The archive uses `TransferFields`, unlike posting. It copies `Time Sheet Header` to `Time Sheet Header Archive`, each `Time Sheet Line` to `Time Sheet Line Archive`, each `Time Sheet Detail` to `Time Sheet Detail Archive`, and comments to `Time Sheet Cmt. Line Archive`. It then deletes the originals. Before each insert it raises an event: `OnBeforeTimeSheetHeaderArchiveInsert`, `OnBeforeTimeSheetLineArchiveInsert`, `OnBeforeTimeSheetDetailArchiveInsert` and `OnBeforeTimeSheetCmtLineArchiveInsert`.

`Time Sheet Posting Entry` records are not archived or deleted. They keep the time sheet number after the time sheet itself has moved to the archive.

## Best Practice

Give each archive table the same field, with the same number and type, as the time sheet table it mirrors. `TransferFields` then archives the value with no code. Use the `OnBefore...ArchiveInsert` events only for values that are computed or have no matching field. Assign them without `Modify`, because the record is not inserted yet.

Plan for the archive check. A feature that adds unposted or unapproved lines blocks archiving until those lines are posted. Reports that read history by time sheet number must read both the live and the archive tables, and can join to `Time Sheet Posting Entry`. For how lines become posted, see [time sheet posting runs in Res. Jnl.-Post Line](time-sheet-posting-runs-in-res-jnl-post-line.md).

See sample: [`time-sheet-archive-copies-fields-by-field-number.good.al`](time-sheet-archive-copies-fields-by-field-number.good.al).

## Anti Pattern

Use a different field number or field type on `Time Sheet Line Archive`, as if the archive copied fields one by one, or as if a later step could fill it. `TransferFields` silently leaves the archived field empty. The same routine then deletes the original line, so no later job can recover the value.

See sample: [`time-sheet-archive-copies-fields-by-field-number.bad.al`](time-sheet-archive-copies-fields-by-field-number.bad.al).

## References

- [Time Sheet Management, MoveTimeSheetToArchive and its events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetManagement.Codeunit.al).
- [Time Sheet Header, Check](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetHeader.Table.al).
- [Move Time Sheets to Archive report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/MoveTimeSheetstoArchive.Report.al).
- [Time Sheet Line Archive table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/TimeSheet/TimeSheetLineArchive.Table.al).
