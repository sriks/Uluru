#
#  Be sure to run `pod spec lint Uluru.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name           = "Uluru"
  # Ensure this matched the git tag
  spec.version        = "0.0.3"
  spec.summary        = "JSON REST API module using declarative API definitions and plugins."
  spec.description    = <<-DESC
  Uluru is a simple and agnostic layer for REST APIs using declarative API concept and written in Swift.
  DESC
  spec.homepage       = "https://github.tabcorp.com.au/TabDigital/Uluru"
  spec.license        = { :type => "MIT", :file => "License.md" }
  spec.author         = { "Tabcorp Digital" => "srikanth.sombhatla@tabcorp.com.au" }
  spec.ios.deployment_target = "10.0"
  spec.swift_version  = "5.0"
  spec.source         = { :git => "https://github.tabcorp.com.au/TabDigital/Uluru.git", :tag => spec.version }
  spec.source_files   = "Uluru/Sources/**/*.{h,m,swift}"
end
