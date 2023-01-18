Pod::Spec.new do |s|
  s.name             = "Visilabs"
  s.version          = "2.5.26"
  s.summary          = "Visilabs IOS SDK for Analytics and Target modules."
  s.description      = "Visilabs IOS SDK for Analytics and Target modules. SDK tracks user interactions and makes recommendations to enhance conversion and user retention."
  s.homepage         = "http://www.visilabs.com"
  s.license          = 'Visilabs'
  s.author           = { "visilabs" => "egemen.gulkilik@relateddigital.com" }
  s.source           = { :git => "https://github.com/visilabs/Visilabs-IOS.git", :tag => s.version.to_s }
  s.social_media_url = 'https://www.facebook.com/visilabs/'

  s.requires_arc = true

  s.ios.deployment_target = '8.0'


  s.source_files  = 'Pod/**/*.{m,h}', 'Pod/**/*.swift'
  s.resources 	 = ['Pod/**/*.{png,storyboard}']

end
