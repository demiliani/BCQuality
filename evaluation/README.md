# AL review evaluation

The evaluation is convention-driven. The harness discovers every `<layer>/skills/review/al-<domain>-review.md` leaf across the enabled `microsoft`, `community`, and `custom` layers. Duplicate domains resolve with `custom > community > microsoft` precedence. For each selected leaf, the harness finds paired knowledge across the same layers, applies the same precedence to duplicate article slugs, selects the first article (by filename) with both `.bad.al` and `.good.al` companions, and derives the expected positive and clean control automatically. Adding a conforming leaf requires no scoring-contract edit.

`review-fixtures.json` contains only global thresholds and optional exceptional overrides. An override may select a different `article`, add context when the generic convention cannot express a scenario, or use an `articles` array when one domain needs explicit regression coverage for several paired articles. Specify either `article` or `articles`, not both. The first selected article retains the stable `<domain>-bad` and `<domain>-good` manifest IDs; additional articles use slug-qualified IDs. Overrides should remain empty in the normal case.

CI also measures selected paired articles against every effective article that
has both AL companions. A changed paired article must be selected by the
domain convention or an override. When adding it would not provide a useful
deterministic regression, add a narrow `coverageWaivers` entry with its exact
article path and a non-empty reason. Waivers are reviewable exceptions, not a
substitute for domain coverage. The generated coverage report includes totals
and per-domain ratios; the ratio is informational, while changed-file coverage
is mandatory.

On pull requests, changed paths are measured from the first parent of the
checked-out synthetic merge to that merge, so coverage uses the base actually
tested rather than a potentially stale event `base.sha`. Pushes retain the
event's before-to-after comparison (or last-commit fallback for an absent/zero
before SHA). The collector fails if a PR checkout is not a two-parent merge or
Git cannot resolve a requested comparison. Regression checks run in fixture CI
and can also be run with `pwsh .github/scripts/Test-ReviewChangedPaths.ps1`.

Model-facing preparation hashes case IDs, neutralizes `Good`/`Bad` object-name tokens, and removes full-line sample comments so neither the article slug, domain, nor expected outcome reveals the answer.

One kind of full-line comment is kept in every sample, the standalone BDD tag line: `//`, optional spaces or tabs, then one of the uppercase tags `[FEATURE]`, `[SCENARIO]`, `[GIVEN]`, `[WHEN]` or `[THEN]`, followed by a space, a tab or the end of the line. These tags are the evidence the testing articles read (`test-feature-scenario-tags`, `given-blocks-must-cover-full-precondition-chain`, `test-one-when-per-test`), so every selected testing sample with `[Test]` procedures carries them, except the untagged `test-feature-scenario-tags` positive. Other case or spelling (`[Given]`), longer tokens (`[WHENEVER]`), punctuation after the bracket (`[WHEN]:`), `///` comments and tags after code are not tag lines; inline comments after code are never removed. A kept tag line reaches the model, so it must describe the step neutrally and on one line: validation fails when a tag line in a selected sample contains `Good`, `Bad` or `anti-pattern`, checked before neutralization, and an explanation for human readers belongs in an ordinary comment line, which preparation removes. The patterns live in `tools/Review-FixtureText.ps1`.

When applicability depends on deployment facts that AL cannot establish, use
`articleOverrides` within the domain override, keyed by a selected article's
exact slug (without `.md`). Each entry requires a non-empty `context` string.
It replaces the domain-wide context for that article's positive and clean pair
and survives in all prepared request formats. Include all necessary deployment
facts, but no expected finding, article path, fix, or assessment of code quality.
Other selected articles retain their existing domain context, if any.

An article entry can also supply `cleanContexts`, an object mapping lowercase
hyphenated control names to non-empty context strings. Each control reuses the
article's `.bad.al` source with that context and expects no findings. Its stable
manifest ID is `<domain>-<slug>-clean-<name>`; model-facing IDs remain opaque.
Use this only when changing the deployment prerequisite makes the same source
legitimate. The MCP description article supplies Business Central online 28 and
MCP exposure to both normal cases, then adds a REST-only, non-MCP clean context.
This controls applicability without treating every API lacking `AboutText` as
a defect. Invalid or unselected article overrides fail validation.

The context regression check runs the real preparer and scorer, verifies all
three request formats, context isolation, unchanged neutralization, mandatory
clean controls, and rejection of findings on the non-MCP input. It also checks
exact and near-miss BDD tag lines, that every prepared input minus its kept tag
lines equals the previous preparation, and that an outcome label in a tag line
fails validation:

```powershell
pwsh ./tools/Test-ReviewFixtureContexts.ps1 -Root .
```

The reporting Skip clarification is intentionally unpaired. Its former
`currreport-skip-does-not-stop-trigger-code` positive assumed that statements
after a direct `Skip()` ran in the same trigger; BC 28.4 evidence contradicts
that premise. Both obsolete companions and their override were retired, not
relabelled as a new defect. Negative knowledge remains available to reviewers
without inventing a positive for this paired-only harness. The separate Break
loop-control pair remains selected. No coverage waiver is needed for an
article without a pair.

The core AL samples for BLOB loading, isolated shipment events, expense-page
scope filters, and stream encoding include their minimal demo tables in each
companion independently. BLOB field types and shipment status members therefore
survive preparation without relying on another sample. The stream-encoding
clean control deliberately writes UTF-8 text and downloads the existing bytes
through a default-encoding InStream: transport alone does not transcode text
and must not trigger the encoding rule.

An article whose rule is about comments themselves cannot be evaluated once its samples lose their full-line comments. List it under `keepComments` in `review-fixtures.json` (an `article` path and a non-empty `reason`) and preparation keeps that article's sample comments; `Good`/`Bad` tokens are still neutralized. Use it only when the rule is about the comments, and prefer `coverageWaivers` when keeping them would reveal the expected outcome.

The SCM `articles` override deliberately selects every rule in the initial
functional domain, producing nine positive cases and nine clean controls.
Business context is executable: document/status `TestField` guards,
calculated-revaluation fields, source-transfer base quantities, warehouse
reconciliation steps, and additional-demand promising parameters survive
neutralization. Do not move those preconditions into comments or generic
"posting" helper names; removing them can turn a real defect into a valid
alternative workflow. The clean pairs exercise the supported APIs selected by
the same routing cues, not merely unrelated code that contains no SCM tokens.

The Finance override deliberately covers every paired Finance article, not
only the first filename. Its shared context supplies the target version and
localization but deliberately omits application area, as production callers
often do. Finance applicability must come from its source-surface gate, not
an artificial evaluation-only area hint. Scenario prerequisites live in
executable AL: the document-balance cases check the template setting, and the
VAT cases encode the imported net/VAT/gross totals and applicable VAT mode.
Do not move these prerequisites into comments that preparation removes.
Clean samples also retain supported operational edits, temporary ledger/set
buffers, legitimate entry-number APIs, and reads of individual shortcut
dimensions so these exceptions are exercised rather than blanket-excluded.

The testing license-failure pair supplies BC 29.2 deployment context only to
that article: the codeunit is newly introduced, purchase posting is licensed,
and direct insertion into the real posted header is not. Both companions
retain their fixture construction and retrieval after neutralization. The
clean companion visibly creates the vendor and invoice and sets the posting
date, consistent with the separate GIVEN-chain rule. The specific posted-write
cue owns that construction defect instead of emitting duplicate generic
fixture or missing-field findings. The pair exercises the introduced-fixture
branch of the rule; it does not prove
baseline-relative attribution from a standalone file, reproduce a tenant's
license checks, or establish that every SaaS identity has these rights.

The DataAccessIntent and hot-ledger related-table pairs are explicitly selected.
Their article-specific contexts supply BC 28; the latter also states that one
integration alone supplies and consumes the metadata, with no native ledger
list-column requirement. Those workload facts cannot be inferred from the
standalone table declarations after comments are stripped. The contexts reach
both positive and clean inputs without affecting other performance pairs.

## Validate the corpus

```powershell
pwsh ./tools/Test-ReviewFixtures.ps1 -Root .
```

This credential-free check proves every selected leaf maps to a same-named knowledge domain with at least one complete AL sample pair and that all configured overrides are valid.

To reproduce the changed-file gate and emit the same measurable report as CI:

```powershell
git diff --name-only origin/main...HEAD | Set-Content .changed-paths.txt
pwsh ./tools/Test-ReviewFixtures.ps1 -Root . -ChangedPathsFile .changed-paths.txt -CoverageReportPath .coverage.json
```

## Run a fast-model evaluation

1. Prepare neutral inputs:

   ```powershell
   pwsh ./tools/Test-ReviewFixtures.ps1 -Root . -PrepareDirectory ./.evaluation-run
   ```

   This is also the CI path. It derives all cases, builds the current index, requires the convention-selected article to rank naturally into the candidate cutoff, and prepares the neutral requests.

2. For a fast/small model, use one fresh invocation per `request-case-*.json`. Each request embeds the exact leaf instructions, that domain's candidate index rows with authoritative paths, and one opaque case. The model opens only matching articles and copies finding IDs from `candidateArticles[].path`. Save each response with the matching `result-case-*.json` name in the same directory.

  `request-<domain>.json` files provide optional leaf batches containing every selected case for that domain and identify the selected layer-owned skill path; save those as `result-<domain>.json`. A normal convention-selected domain has one bad/good pair, while an `articles` override contributes one pair per listed article plus any registered context controls. Directory scoring prefers `result-case-*.json` when present and otherwise falls back to `result-*.json`. `review-request.json` is an optional all-domains stress test for larger models. Neither batch form is the preferred fast-model profile.

3. Save only this result shape:

   ```json
   {
     "cases": [
       {
         "id": "case-a1b2c3d4",
         "findings": [
           { "id": "microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md" }
         ]
       }
     ]
   }
   ```

   Include every case. A clean control has an empty `findings` array.

4. Score all per-leaf results together:

   ```powershell
   pwsh ./tools/Test-ReviewFixtures.ps1 -Root . -ResultsDirectory ./.evaluation-run
   ```

   For a single combined stress-test result, use `-ResultsPath` instead.

The committed gate requires full expected recall, the exact convention-derived article ID, and no findings on clean controls.

## Feature design evaluation (experimental)

`feature-design-fixtures.json` holds plain-language feature requests for the
experimental `al-feature-design` skill. Each case lists what a reviewer would
insist on in the design, not one exact answer: articles it must cite, objects
it must extend, events it must or must not subscribe to, guards it must apply,
and gaps it must either design or raise as an open question. A `must-cover-any`
rule passes when any of its options holds: `object-target`,
`open-question-contains`, `lifecycle-concern`, `subscribes-to` (an event name),
`design-contains` (text in an element's purpose, note or step), `cites` (an
article path) or `object-type-count`.

Score a report produced for one case with:

    python tools/score_feature_design.py <case-id> <report.json>

The scorer validates the report against
`schemas/feature-design-report.schema.json`, checks that every cited article
exists and that every path a design element uses is listed in `knowledge`, then
applies the case's checks. It exits 1 when any check fails. It requires
`jsonschema`.

`feature-design-examples/` holds one report per case. Each `.json` file was
produced by an agent that ran the skill with only the request and the plugin.
Each `.md` file is the readable version that
`tools/ConvertTo-FeatureDesignMarkdown.ps1` renders from it, which is what a
user sees. Reports were generated as the knowledge grew, so a few reflect an
earlier state:

- The three first sales reports used the first version of the skill.
- `sales-defaults-propagation-and-gl` was generated before the
  `OnAfterInitHeaderDefaults` guidance existed; it reported that gap as
  `partial`, and the fixture now also checks that event.
- `collection-agent-on-reminders` is `partial`: no article yet names the event
  for defaulting a customer field onto `Reminder Header` and
  `Finance Charge Memo Header`, and the report says so.
- `customer-po-ref-through-prepayment-and-drop-shipment` misses one check: the
  agent read "sales order lines carry the customer's PO reference" as an
  existing field and did not extend `Sales Line`. The request is ambiguous.
- `contracts-api-and-nightly-sync` is not fully blind: the agent saw one line
  of its fixture while searching. The skill now forbids reading `evaluation/`.
- The 18 cases added with the five new feature-design maps and the wave-6
  articles were run with version 3 of the skill. Three of their fixtures were
  widened after the run, because the reports met the requirement in an element's
  text or with an equivalent pattern: `contract-ref-on-deferral-gl-entries`,
  `ic-settlement-journal-with-reference` and `nightly-customer-csv-import`.
- `carry-carrier-seal-from-warehouse-shipment-to-posted-sales-shipment` was run
  with version 4 and misses one check: it does not ask how the seal behaves
  when one warehouse shipment holds several orders or an order ships in
  several shipments.
