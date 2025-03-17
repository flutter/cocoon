GitHub Issues Analysis
======================

This is a command line program that downloads the entirety of a GitHub
project's issues database and then runs certain analyses against the
collected data.

It's not intended for production use; instead it is used to
occasionally do scans of our repos, to learn about how things are
going, to find users who are no longer active, to audit our use of
labels, and so forth. For example, it was instrumental in the research
that led to the [Flutter project proposed new triage processes for
2023](https://flutter.dev/go/triage-2023-rfc).

To use this tool, first create the following files in this directory:

   `.github-token`: [Personal access
   token](https://github.com/settings/personal-access-tokens/new) with
   the resource owner "flutter", set to have read-only access to all
   public repositories, and set to have access to "Organization
   permissions -> Members -> Read-only".

   `members.txt`: List of all people who are expected to be members of
   the flutter-hackers group, one to a line.

   `exmembers.txt`: List of all people who were once members of the
   flutter-hackers group, but are not currently members, one to a
   line.

Then, run: `dart run --enable-asserts bin/githubanalysis.dart`

See also:

 * [Output from 2023-03-30](https://docs.google.com/spreadsheets/d/15hyxxapUmsK6J05X1goQ__9xJdzhJQM-BqsvM31-CTk/edit#gid=0) as a spreadsheet (with graphs).
 * [Output from 2024-04-12](https://docs.google.com/spreadsheets/d/1h9IPF4ZKhfh4FbdzzqFFbznbGSxj-syVfruOIge9fac/edit?usp=sharing) as a spreadsheet (with graphs).
 * [Output from 2024-02-13](https://docs.google.com/spreadsheets/d/19QjfBBYrdWNlL1rnWLuacGYcndmbha9tn4sAgk-cYxY/edit?usp=sharing) as a spreadsheet (with graphs).
