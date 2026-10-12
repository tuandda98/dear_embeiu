#!/bin/bash
# Feature home-widget: one-off, idempotent. Adds the widget extension target to
# ios/Runner.xcodeproj with the xcodeproj gem that ships inside Homebrew's
# CocoaPods. GEM_HOME must point at cocoapods' libexec and GEM_PATH must stay
# unset — with GEM_PATH set the gem is not found.
set -euo pipefail
cd "$(dirname "$0")/.."
RUBY="$(brew --prefix ruby)/bin/ruby"
export GEM_HOME="$(brew --prefix cocoapods)/libexec"
unset GEM_PATH
exec "$RUBY" scripts/ios-add-widget-target.rb "$@"
