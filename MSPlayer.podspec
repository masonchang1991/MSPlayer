#
# Be sure to run `pod lib lint MSPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MSPlayer'
  s.version          = '1.1.1'
  s.summary          = 'A quick use videoPlayer'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/masonchang1991/MSPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'masonchang1991' => 'masonchang1991@gmail.com' }
  s.source           = { :git => 'https://github.com/masonchang1991/MSPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files  = 'MSPlayer/Classes/' , 'MSPlayer/Classes/VideoTimeRecord.xcdatamodeld', 'MSPlayer/Classes/VideoTimeRecord.xcdatamodeld/*.xcdatamodel'
  s.resources = ['MSPlayer/Classes/VideoTimeRecord.xcdatamodeld', 'MSPlayer/Classes/VideoTimeRecord.xcdatamodeld/*.xcdatamodel']
  s.preserve_paths = 'MSPlayer/Classes/VideoTimeRecord.xcdatamodeld'
  s.resource_bundles = {
    'MSPlayer' => ['MSPlayer/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData'
  s.dependency 'NVActivityIndicatorView', '4.0.0'
end
