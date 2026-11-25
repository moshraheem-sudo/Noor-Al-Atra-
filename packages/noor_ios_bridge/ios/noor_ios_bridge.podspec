Pod::Spec.new do |s|
  s.name             = 'noor_ios_bridge'
  s.version          = '0.0.1'
  s.summary          = 'iOS native bridge plugin for Noor Al-Atra'
  s.homepage         = 'https://github.com/moshraheem-sudo/Noor-Al-Atra-'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Noor Al-Atra' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
