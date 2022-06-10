A standalone app to codesign Mac engine binaries.

During flutter release, engineers need to code sign Mac engine binaries to assure users that they come from a known source and haven't been modified since they were last signed. A general process to sign artifacts is detailed in go/signing-flutter-artifacts (opensource version: https://github.com/christopherfujino/codesign.py). 

However, the process to code sign and produce Apple verified artifacts is a bit different. Currently, release engineers follow go/flutter-manual-codesign to produce Apple verified artifacts. If we could automate this process, we can remove humans and local machines from the release process, and make the release process scalable, deterministic and secure.

design docs: 
    codesign standalone design doc: go/code-signing-standalone.
    codesign project overall design doc: go/code-signing-bot. 
