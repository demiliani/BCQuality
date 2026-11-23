---
bc-version: [all]
domain: feature-design
keywords: [feature-design, g-l-account, general-posting-setup, posting-group, setup-table, testfield, finance-feature, journal-posting, dimensions]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan G/L account determination and posting for a finance feature

## Description

A feature that creates financial effects, such as fees, accruals, commissions or settlement differences, must decide which G/L accounts it posts to and how it posts. The decision is often skipped because a hard-coded account number works in the developer's company. It then fails in every other company, chart of accounts and country.

Business Central offers two sources for an account. Posting groups resolve accounts from the combination of business and product groups, and `General Posting Setup` getters such as `GetSalesAccount` return them. When the account is blank, a getter logs the missing field through the error message framework but still returns the blank value. A feature setup table holds accounts that do not depend on such combinations.

## Best Practice

Plan one decision per row and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Account source | Use the posting groups already on the record when the account depends on customer, vendor or item groups. Use a feature setup table when the account is one per company or per feature type | [setup is a singleton](../data-modeling/setup-table-is-a-singleton.md) |
| Missing account | Check every account the feature needs before creating journal lines, including the value a posting setup getter returns, because a getter can return a blank account | [TestField a required setup field](../data-modeling/testfield-required-setup-field.md) |
| How to post | Create journal lines in a batch reserved for the feature and post them through the posting engine | [post finance journal lines from code in a dedicated batch](../finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md), [post through posting codeunits](../finance/post-ledger-entries-through-posting-codeunits.md) |
| Balance | Every document in the batch must balance by date and document number | [preserve journal batch document balance](../finance/preserve-journal-batch-document-balance.md) |
| Dimensions | Pass the source record's dimension set to the journal line; never edit a shared set | [write dimensions as dimension set entries](../finance/write-dimensions-as-dimension-set-entries.md), [do not edit shared dimension sets](../finance/do-not-edit-shared-dimension-sets.md) |
| VAT | Decide whether the posting carries VAT; a Normal VAT journal amount includes VAT | [normal VAT journal amount includes VAT](../finance/normal-vat-journal-amount-includes-vat.md) |
| Custom values on entries | Carry custom journal fields to G/L entries in the copy event, and define what reversal does with them | [carry Gen. Journal Line fields to G/L, VAT and bank entries](../finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md) |
| Corrections | Correct posted effects by reversal or a new posting, never by editing entries | [reverse transactions by transaction number](../finance/reverse-transactions-by-transaction-number.md), [do not modify posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md) |
| Tests | Test with a blanked account to prove the check fires, and post then reverse to prove the entries net to zero | [library fixtures](../testing/use-library-codeunits-for-test-fixtures.md) |

Which account a fee or difference belongs to is an accounting decision for the requester. When the request does not name it, raise an open question rather than choosing an account type.

## Anti Pattern

Hard-code account numbers in code or in an install codeunit, or read an account from setup without checking it. The feature posts to a wrong or blank account in another company, and the error, if any, appears deep inside posting instead of naming the missing setup field.

## References

- [General Posting Setup: account getters](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Setup/GeneralPostingSetup.Table.al).
- [PostingSetupManagement: missing-account logging](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/ReceivablesPayables/PostingSetupManagement.Codeunit.al).
