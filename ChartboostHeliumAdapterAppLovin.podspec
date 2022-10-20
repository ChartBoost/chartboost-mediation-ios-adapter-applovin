Pod::Spec.new do |spec|
  spec.name        = 'ChartboostHeliumAdapterAppLovin'
  spec.version     = '4.11.3.1.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/helium-ios-adapter-applovin'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Helium iOS SDK AppLovin adapter.'
  spec.description = 'AppLovin adapters for mediating through Helium. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'HeliumAdapterAppLovin'
  spec.source       = { :git => 'https://github.com/ChartBoost/helium-ios-adapter-applovin.git', :tag => '#{spec.version}' }
  spec.source_files = 'Source/**/*.{swift}'
  spec.static_framework = true

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'
  
  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'WebKit']
  
  # This adapter is compatible with all Helium 4.X versions of the SDK.
  spec.dependency 'ChartboostHelium', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'AppLovinSDK', '11.3.1'
end
