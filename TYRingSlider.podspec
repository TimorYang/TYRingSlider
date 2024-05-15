#
# Be sure to run `pod lib lint TYRingSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TYRingSlider'
  s.version          = '1.0.1'
  s.summary          = 'TYRingSlider 圆环选择器'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
多点圆环选择器，支持多点选择，步长，碰撞
                       DESC

  s.homepage         = 'https://github.com/TimorYang/TYRingSlider'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'TeemoYang' => 'iyangzhidong@gmail.com' }
  s.source           = { :git => 'https://github.com/TimorYang/TYRingSlider.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'TYRingSlider/Classes/**/*'
  
  s.resource_bundles = {
    'TYRingSlider' => ['TYRingSlider/Assets/**/*']
  }
end
