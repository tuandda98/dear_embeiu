#!/usr/bin/env ruby
# Feature home-widget: adds the DearEmbeiuWidget (WidgetKit) extension target to
# ios/Runner.xcodeproj — sources, fonts from assets/fonts, en/vi strings, build
# settings per configuration, App Group on Runner, embed phase. Idempotent.
# Run through scripts/ios-add-widget-target.sh (needs the xcodeproj gem).
require 'xcodeproj'

PROJECT = File.expand_path('../ios/Runner.xcodeproj', __dir__)
NAME = 'DearEmbeiuWidget'
TEAM = '4UBR69C227'

project = Xcodeproj::Project.open(PROJECT)
if project.targets.any? { |t| t.name == NAME }
  puts "#{NAME} already in the project — nothing to do"
  exit 0
end
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'
generated = project.files.find { |f| f.display_name == 'Generated.xcconfig' } or
  abort 'Flutter/Generated.xcconfig missing — run `flutter build ios --config-only` first'

widget = project.new_target(:app_extension, NAME, :ios, '15.0')
group = project.main_group.new_group(NAME, NAME)

sources = %w[DayMath.swift WidgetSnapshot.swift DayCounterWidget.swift DayCounterView.swift]
widget.add_file_references(sources.map { |f| group.new_file(f) })

# Absolute paths: xcodeproj stores them relative to the group (ios/DearEmbeiuWidget),
# so a hand-written "../assets" would point at ios/assets, which does not exist.
fonts = %w[Bold SemiBold Medium].map do |w|
  group.new_file(File.expand_path("../assets/fonts/Quicksand-#{w}.ttf", __dir__))
end
strings = group.new_variant_group('Localizable.strings')
%w[en vi].each { |lang| strings.new_file("#{lang}.lproj/Localizable.strings") }
privacy = group.new_file('PrivacyInfo.xcprivacy')
widget.add_resources(fonts + [strings, privacy])
group.new_file('Info.plist')
group.new_file("#{NAME}.entitlements")

def dev?(config) = %w[Debug Profile].include?(config.name)

widget.build_configurations.each do |c|
  c.base_configuration_reference = generated # FLUTTER_BUILD_NAME / NUMBER
  c.build_settings.merge!(
    'INFOPLIST_FILE' => "#{NAME}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => "#{NAME}/#{NAME}.entitlements",
    'CODE_SIGN_STYLE' => 'Automatic',
    'DEVELOPMENT_TEAM' => TEAM,
    'PRODUCT_NAME' => '$(TARGET_NAME)', # xcodeproj leaves it empty -> product ".appex" (Multiple commands produce)
    'PRODUCT_BUNDLE_IDENTIFIER' => dev?(c) ? 'com.tony.dearembeiu.dev.widget' : 'com.tony.dearembeiu.widget',
    'APP_GROUP_ID' => dev?(c) ? 'group.com.tony.dearembeiu.dev' : 'group.com.tony.dearembeiu',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0',
    'TARGETED_DEVICE_FAMILY' => '1',
    'SWIFT_VERSION' => '5.0',
    'SKIP_INSTALL' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'],
  )
end

runner.build_configurations.each do |c|
  c.build_settings['APP_GROUP_ID'] = dev?(c) ? 'group.com.tony.dearembeiu.dev' : 'group.com.tony.dearembeiu'
end

runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# It must run BEFORE the "Thin Binary" / Pods script phases: placed after them
# Xcode refuses to build ("Cycle inside Runner").
thin = runner.build_phases.index { |p| p.display_name == 'Thin Binary' } or abort 'Thin Binary phase not found'
runner.build_phases.move(embed, thin)

project.save
puts "Added #{NAME}: #{sources.size} sources, #{fonts.size} fonts, strings en/vi, embedded in Runner"
