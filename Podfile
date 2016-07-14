platform :ios, '8.0'
use_frameworks!

target 'FasT-box-office' do
    pod 'iZettleSDK', '~> 1.3.0'
    pod 'MBProgressHUD', '~> 0.9.1'
    pod 'MKNetworkKit', '~> 0.87'
    pod 'Socket.IO-Client-Swift', '~> 6.1.4'
end

post_install do |installer|
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end
end
