---
bc-version: [all]
domain: projects
keywords: [job-calculate-wip, job-wip-method, job-wip-entry, job-post-wip-to-gl, onbeforecalcrecognizedsales, onbeforecalcrecognizedcosts, oninsertwipglonbeforegenjnpostline, enumextension, project-wip, recognized-sales]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Add custom project WIP methods through the recognition events

## Description

Report `Job Calculate WIP` calls `Job Calculate WIP.JobCalcWIP` for each project. `JobCalcWIP` first runs `DeleteWIP`, which deletes the open `Job WIP Entry` rows and sets `Recognized Sales Amount` and `Recognized Costs Amount` to zero on every task. For each posting task that is not excluded from WIP, `CalcWIP` then sets those two amounts from the WIP method. `CalcRecognizedCosts` and `CalcRecognizedSales` are `case` statements on the `Job WIP Method` fields `Recognized Costs` and `Recognized Sales`.

Both fields use extensible enums, `Job WIP Recognized Costs Type` and `Job WIP Recognized Sales Type`. The `case` statements have no `else` branch. A new enum value with no code behind it leaves the amount at zero.

The order matters. Right after `CalcWIP`, the task is modified and `CreateTempJobWIPBuffers` builds the WIP buffers from the recognized amounts. `CreateWIPEntries` then inserts `Job WIP Entry` rows field by field from those buffers. When the project is complete, `CalcWIP` sets the amounts from the invoiced price and the usage cost and returns before the method is used.

Report `Job Post WIP to G/L` calls `CalcGLWIP`. It reverses earlier WIP postings, writes `Job WIP G/L Entry` rows from the `Job WIP Entry` rows, and posts each one as a system-created `Gen. Journal Line` through `Gen. Jnl.-Post Line`. Then it deletes the WIP entries.

## Best Practice

Add a method value with an `enumextension` on `Job WIP Recognized Sales Type` or `Job WIP Recognized Costs Type`. Subscribe to `OnBeforeCalcRecognizedSales` or `OnBeforeCalcRecognizedCosts` on `Job Calculate WIP`. When `JobWIPMethod` uses your value, set `JobTask."Recognized Sales Amount"` or `"Recognized Costs Amount"` and set `IsHandled`. The buffers, WIP entries and G/L postings are then built from your amount.

Use the other events for their own step. `OnInitWIPBufferEntryFromTaskOnBeforeSetDimCombinationID` changes the dimensions of a buffer built from a task. `OnCreateWIPEntriesOnBeforeJobWIPEntryInsert` fills custom `Job WIP Entry` fields. `OnInsertWIPGLOnBeforeGenJnPostLine` adds values to the journal line that posts each WIP amount. Users must still create a `Job WIP Method` record that uses the new value.

See sample: [`add-custom-project-wip-methods-through-the-recognition-events.good.al`](add-custom-project-wip-methods-through-the-recognition-events.good.al).

## Anti Pattern

Let the standard method run, then overwrite the task's recognized amounts in a subscriber to `OnAfterJobTaskCalcWIP`, or in a separate action. By then the WIP buffers already hold the old amounts. The `Job WIP Entry` rows, and the G/L postings built from them, do not match the task. The next calculation runs `DeleteWIP` and clears the overwritten values.

Posting your own G/L journal lines for WIP is the same mistake. `Job Post WIP to G/L` does not know about them, so they are never reversed.

See sample: [`add-custom-project-wip-methods-through-the-recognition-events.bad.al`](add-custom-project-wip-methods-through-the-recognition-events.bad.al).

## References

- [Job Calculate WIP: JobCalcWIP, CalcWIP, CreateWIPEntries, CalcGLWIP and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/WIP/JobCalculateWIP.Codeunit.al).
- [Job WIP Recognized Sales Type enum](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/WIP/JobWIPRecognizedSalesType.Enum.al).
- [Job Post WIP to G/L report](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/WIP/JobPostWIPtoGL.Report.al).
- [Job Task: InitWIPFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Job/JobTask.Table.al).
