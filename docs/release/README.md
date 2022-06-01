# Framework release process

Uses fastlane to automate release process.

## On your local branch
1. Start branching from `master` into your local branch. 
2. Apply code changes. 
3. Ensure unit tests are passing, else fix the tests. New test cases should be added with every new feature changes. This ensures the code sanity.

## Prepare your PR
We follow [semver](semver.org) for verion numbering.

With each PR merging into `master`, you should update the version number which will also be the github release version.

Depending on the nature of your change, you should update the `CFBundleShortVersionString` before merging into `master`

1. To ease this process use `bundle exec fastlane ios prepare_release` and use `major` or `minor` or `patch` depending on the nature of change. This will update the version accordingly in project and any dependency managers. 

2. `push` changes to your local branch. This will kick CI build in github. 
3. Once all PR checks are passed, you can ask the PR to be merged into `master`.
4. Once a PR is raised against `master` the CI runs pre merge checks. Your PR is ready to merge into `master` after these checks pass.
 
> Tip: If you are not sure, run `bundle exec fastlane ios github_release_pre_check` locally which will list out all pre check errors. 

## Merging into `master`

1. Once all checks are passed, the reviewer can merge your PR into `master`.
2. Once merged, CI runs post merge checks.
3. Once checks pass, a github release is performed automatically and a tag with your release number is created. 

> We use github actions provided `GITHUB_TOKEN`. So ensure it has enough permissions to perform a release.

## Publishing changes via Cocoapods

The repo admin have to release the version to cocoapods manually. 