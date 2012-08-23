platform :osx

set_arc_compatibility_flag!
pod 'AFNetworking', '~> 1.0RC1'
pod 'ConciseKit',     '~> 0.1.1'
pod 'SSKeychain',     '~> 0.1.4'
pod 'SBJson',         '~> 3.0.4'

target :test, :exclusive => true do
  pod 'Specta',       '~> 0.1.4'
  pod 'Expecta',      '~> 0.1.3'
  pod 'OCMock',       '~> 1.77.1'
  pod 'OCHamcrest',   '~> 1.6'
end

post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = '$(ARCHS_STANDARD_32_64_BIT)'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.6'
      config.build_settings['GCC_ENABLE_OBJC_GC'] = 'supported'
    end
  end
end
