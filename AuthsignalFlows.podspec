Pod::Spec.new do |s|
  s.name             = 'AuthsignalFlows'
  s.version          = '1.0.0-alpha1'
  s.summary          = 'Authsignal Flows SDK for iOS'

  s.homepage         = 'https://github.com/authsignal/authsignal-flows-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Authsignal' => 'support@authsignal.com' }
  s.source           = { :git => 'https://github.com/authsignal/authsignal-flows-ios.git', :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/AuthsignalFlows/**/*'
end
