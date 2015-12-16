#
# Be sure to run `pod lib lint Visilabs.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Visilabs"
  s.version          = "2.1.0"
  s.summary          = "Visilabs IOS SDK for Analytics and Target modules."
  s.homepage         = "http://www.visilabs.com"
  s.license          = 'Visilabs'
  s.author           = { "visilabs" => "egemen@visilabs.com" }
  s.source           = { :git => "https://github.com/visilabs/Visilabs-IOS.git", :tag => s.version.to_s }
  s.social_media_url = 'https://www.facebook.com/visilabs/'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Visilabs' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
