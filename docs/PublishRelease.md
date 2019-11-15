# Publish Release

Uluru is not yet available on a build machine. So you have to deploy from your local machine.

1. Commit your code and push to repo.
2. run 
     `bundle exec fastlane ios release_dry_run` to if you want to ensure the tests are passind and indeed able to create the framework. This will not publish anything.
     To publish a release run
     `bundle exec fastlane ios do_release`
     This will do all the steps of testing, packaging, tagging and publishing a github release. It will also update the git tag and push it.

The following steps will publish the updated podspec.

3. Update Uluru.podspec `spec.version` to the git tag we just released. As a convention this should match the git tag.
4. commit with message "Updated podspec to < git tag version >"
5. push the commit.

Step 3-5 is to publish a podspec so that cocoapods can find the updated code release. We will eventually automate these steps as well. Since the frequency of changes is often and quite variable we have to do this manually,

On the consuming side, run `pod update` to get the latest published version.
For Carthage, get the latest binary from github releases https://github.com/Tabcorp/ios-uluru-releases/releases/
