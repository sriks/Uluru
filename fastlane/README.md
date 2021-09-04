fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
### publish_github_release
```
fastlane publish_github_release
```
Publish GitHub release

The version for the release is picked from Xcode project CFBundleShortVersionString

----

## iOS
### ios pr_check
```
fastlane ios pr_check
```
PR Check intended to run for every PR
### ios tests
```
fastlane ios tests
```
Run tests
### ios github_release_pre_check
```
fastlane ios github_release_pre_check
```
Precheck for github release to ensure we can indeed publish a github release.

This step should run and pass before merging into master.

This is safe to run on your local machine also.
### ios prepare_release
```
fastlane ios prepare_release
```
Prepares for release by updating version number as per semver.

Intended to run locally.

options[:type]: 'major', 'minor' or 'patch'

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
