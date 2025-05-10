Pod::Spec.new do |spec|
    spec.name         = "authmatech-sdk-ios"
    spec.version      = "1.0.0"
    spec.summary      = "SDK for Authmatech"
    spec.description  = <<-DESC
    iOS SDK for Authmatech: SIM Based Authentication.
    DESC
    spec.homepage     = "https://github.com/authmatech/authmatech-sdk-ios"
    spec.license      = { :type => "MIT", :file => "LICENSE.md" }
    spec.author             = { "author" => "support@authmatech.com" }
    spec.documentation_url = "https://github.com/authmatech/authmatech-sdk-ios/blob/main/README.md"
    spec.platforms = { :ios => "12.0" }
    spec.swift_version = "5.3"
    spec.source       = { :git => "https://github.com/Authmatech/authmatech-sdk-ios.git", :tag => "#{spec.version}" }
    spec.source_files  = "Sources/AuthmatechSDK/**/*.swift"
    spec.xcconfig = { "SWIFT_VERSION" => "5.3" }
    spec.resource_bundles ={ "authmatech-sdk-ios" => ["Sources/PrivacyInfo.xcprivacy"]}
end
