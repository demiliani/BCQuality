---
bc-version: [all]
domain: performance
keywords: [httpclient, write-transaction, lock, commit, outbound-http, session-block]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Do not call HttpClient inside an open write transaction

> Contributions welcome — open a PR to refine or extend this article.

## Description

The first database write opens an AL write transaction that the runtime holds until the execution completes or `Commit()` runs — see `understand-implicit-transaction-boundary.md`. `HttpClient` blocks the session until the remote call returns. Any locks taken by earlier `Insert`/`Modify`/`Delete` therefore stay held for the HTTP wall-clock time, and interactive users see a spinner. This is not generic "don't block": it is the AL transaction model plus lock lifetime around outbound I/O.

## Best Practice

Finish database writes and `Commit()` (or return from the write execution) before `HttpClient.Send`/`Get`/`Post`. If the call can be slow or retry, isolate it in a job queue or `TaskScheduler` task so UI and other sessions are not sitting on the writer's locks.

See sample: `httpclient-inside-write-transaction-holds-locks.good.al`.

## Anti Pattern

`Modify`/`Insert` followed by `HttpClient` in the same procedure with no `Commit` between them. Detection signal: any `HttpClient` use after a write on the same execution path, especially in posting, page actions, or subscribers.

See sample: `httpclient-inside-write-transaction-holds-locks.bad.al`.
