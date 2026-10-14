# Fork workflow

- This fork focuses on maintaining the owner's fixes and improvements by rebasing them onto updates from the original project.
- Keep changes minimal to reduce conflicts when rebasing. Touch only code required for the requested fix or improvement.
- Do not run formatters or linters, reformat code, or make unrelated cleanup changes.

# App updates

- Keep app updates manual so upstream updates cannot replace this fork's changes. Preserve the separate engine-update workflow.

# Wine runtime

- Use the owner's maintained Wine distribution through one fixed installation, without adding a runtime selector or silently falling back to an older runtime.

# Windows Steam

- Keep Steam client updates enabled. The owner accepts skipping its startup file verification for the browser compatibility workaround and relaunching after an update when necessary.
- Preserve Valve's current browser helper when applying the workaround; never replace that saved original with the compatibility wrapper.
