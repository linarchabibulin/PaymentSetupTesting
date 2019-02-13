source 'https://github.com/cheskapac/epay-ios-sdk-lib.git'
source 'https://github.com/linarchabibulin/DibsPayment.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

pre_install do |installer|
	# workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
	Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

target 'PaymentSetupTesting' do

	pod 'PaymentModule', :git => 'https://github.com/linarchabibulin/PaymentModule.git'
end
