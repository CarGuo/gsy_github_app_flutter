#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_performance_monitor.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_performance_monitor'
  s.version          = '0.1.0'
  s.summary          = 'Bounded, process-wide performance observations for Flutter.'
  s.description      = <<-DESC
Optional process CPU sampling for the Flutter performance monitor.
                       DESC
  s.homepage         = 'https://github.com/CarGuo/flutter_performance_monitor'
  s.license          = { :type => 'Proprietary', :file => '../LICENSE' }
  s.author           = 'Flutter Performance Monitor contributors'

  s.source           = { :path => '.' }
  s.source_files = 'flutter_performance_monitor/Sources/flutter_performance_monitor/**/*'

  s.resource_bundles = {'flutter_performance_monitor_privacy' => ['flutter_performance_monitor/Sources/flutter_performance_monitor/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
