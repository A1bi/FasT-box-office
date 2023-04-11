platform :ios, '12.0'
use_frameworks!

target 'FasT-box-office' do
    pod 'iZettleSDK', '~> 3.4.0'
    pod 'MBProgressHUD', '~> 1.2.0'
    pod 'AFNetworking', '~> 3.2.1'
    pod 'Sentry', '~> 7.16.0'
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
            end
        end
    end
end
