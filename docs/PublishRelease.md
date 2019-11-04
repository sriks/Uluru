# Publish Release

1. Commit your code.
2. Update podspec to next logical version. As a convention this should match the next logical git tag.
3. commit with message "Updated podspec to < new_version >"


Usually this step is run on build machine.

`fastlane do_release`
This will add git tag and push the git tags
