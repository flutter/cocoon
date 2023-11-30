# Triage Automation Bot

This bot implements the automations originally proposed in
[https://docs.google.com/document/d/1RBvsolWL9nUkcEFhPZV4b-tstVUDHfHKzs-uQ3HiX-w/edit#heading=h.34a91yqebirw](Flutter
project proposed new triage processes for 2023).

## Implemented automations

The core logic is in `lib/engine.dart`.

There are four components:

- the GitHub webhook
- background updates
- the cleanup process
- the tidy process

In addition, there is an internal model that tracks the state of the
project. Most notably, it tracks various attributes of the project's
open issues. This is stored in memory as a Hash table and takes about
200MB of RAM for about 10,000 issues. It is written to disk
periodically, taking about 2MB of disk. This is used on startup to
warm the cache, so that brief interruptions in service do not require
the multiple days of probing GitHub APIs to fetch all the data.

You can see the current state of this data model by fetching the
`/debug` HTTP endpoint from a browser.

## The GitHub webhook

The triage bot listens to notifications from GitHub. When it receives
them, it first updates the issue model accordingly, then (if
appropriate) sends a message Discord.

The following updates are among those that update the model:

 - new issues, closing issues, reopening issues
 - issue comments
 - changes to the assignee
 - changes to labels
 - updates to who is a team member
 - changes to an issue's lock state

Most of these updates are just a matter of tracking whether the issue
is still open, and whether the update came from a team member, so that
we can track how long it's been since an issue was updated.

The following updates are among those repeated on Discord:

 - when someone stars a repo
 - when someone creates a new label
 - when issues are opened, closed, or reopened
 - when PRs are filed or closed
 - when comments are left on issues and PRs
 - when issues are locked or unlocked
 - when the wiki is updated

The channels used vary based on the message. Most of them go to
`#github2`, some go to `#hidden-chat`.

## Background updates

Every few seconds (`backgroundUpdatePeriod`), the bot attempts to
fetch an issue from GitHub. If the issue is open (and not a pull
request), the model is updated with the information obtained from
GitHub.

## The cleanup process

Issues that have recently been examined (either for the webhook or the
background updates) are added to a cleanup queue.

Roughly every minute (`cleanupUpdatePeriod`), all the issues in the
queue that were last touched more than 45 minutes ago
(`cleanupUpdateDelay`) are checked to see if they need cleaning up.
Cleaning up in this context means making automated changes to the
issue that enforce invariants. Specifically:

 - If an issue has multiple priorities, all but the highest one are
   removed.
 - Issues with multiple `team-*` labels lose all of them (sending the
   issue back to front-line triage).
 - `fyi-*` labels are removed if they're redundant with a `team-*`
   label or acknowledged by a `triaged-*` label.
 - `triaged-*` labels that don't have a corresponding `team-*` label
   are removed as redundant.
 - Issues that have a `triaged-*` label but no priority have their
   `triaged-*` label removed. This only happens once every two days or
   so (`refeedDelay`) per team; if more than one issue has this
   condition at a time, the other issues are left alone until the next
   time the issue is examined by the background update process.
 - The thumbs-up label is removed if the issue has been marked as
   triaged.
 - The "stale issue" label (the hourglass) is removed if the issue has
   received an update from a team member since it was added.
 - Recently re-opened issues are unlocked if necessary.

## The tidy process

Every few hours (`longTermTidyingPeriod`), all the known open issues
that are _not_ pending a cleanup update are examined, and have
invariants applied, as follows:

 - If the issue is "stale" (`timeUntilStale`), i.e. is assigned or
   marked P1 and hasn't received an update from a team member in some
   time, it is pinged and labeled with the "stale issue" label (the
   hourglass).
 - If the issue doesn't receive an update even after getting pinged
   (`timeUntilReallyStale`), the assignee is removed and the issue is
   sent back to the team's triage meeting. This process is subject to
   the same per-team rate-limiting (`refeedDelay`) as the removal of
   priority labels discussed in the cleanup process section.
 - Issues that have been locked for a while (`timeUntilUnlock`) are
   automatically unlocked.
 - Issues that have gained a lot of thumbs-up recently are flagged for
   additional triage.

## The self-test issue

Every now and then (`selfTestPeriod`), an issue is filed to test the
triage process itself. After some additional time (`selfTestWindow`),
if the issue is open, it is assigned to the critical triage meeting
for further follow-up.

## Secrets

The following files need to exist in the `secrets` subdirectory to run
this locally:

* `discord.appid`: The Discord app ID.
* `discord.token`: The Discord authentication token.
* `github.app.id`: The GitHub app ID.
* `github.app.key.pem`: The GitHub application private key.
* `github.installation.id`: The GitHub application installation ID.
* `github.webhook.secret`: The GitHub webhook secret password.
* `server.cert.pem`: The TLS certificate.
* `server.intermediates.pem`: The TLS intermediate certificates, if
  any, or else an empty file.
* `server.key.pem`: The TLS private key.

Alternatively, these files can be provided as secrets in Google
Cloud's secrets manager.
