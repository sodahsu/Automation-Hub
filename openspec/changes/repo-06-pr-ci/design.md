# Design

`resolve` already validates that every supplied SHA is exactly 40 lowercase hexadecimal characters before the claim step makes network requests. Remove the alias-specific rejection and use the existing pending claim and report jobs unchanged.

The existing status credential must have repository access to repo-06 with Commit statuses: write before the feature can write statuses there. Do not broaden the credential to Contents, Pull requests, or other permissions. If the credential lacks this access, the pending-status API call returns a non-2xx response, resolve fails closed before CI starts, and no success status is written.

For `repo-06`, keep the existing sparse clone and exact path list. In PR mode, authenticate a depth-one fetch of the supplied object ID, detach-checkout `FETCH_HEAD`, and compare `git rev-parse HEAD` with the supplied SHA before sparse materialization. Keep Git diagnostics in a runner-temporary file and emit only a fixed public error if fetch or checkout fails. Remove remotes and credentials as the current sparse adapter already does.

The detector already enumerates all six aliases for default-branch checks. Apply its existing open-PR filtering, per-alias unique SHA enumeration, status lookup, claim, and dispatch flow to all six aliases by removing the `repo-06` skip. The public summary continues to contain only aliases and run/skip counts. Existing masking and sanitized evidence publishing remain unchanged.

Local workflow tests exercise mode selection and SHA validation, exact sparse checkout invariants, the detector's `repo-06` dispatch path, and fail-closed handling for denied pending/final status writes. The live status write is verified after the owner adds the required narrow status permission and after merge on an ObsidianBook PR.
