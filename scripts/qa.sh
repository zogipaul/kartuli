#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
qa_destination="${QA_DESTINATION:-platform=iOS Simulator,name=iPhone 17e,OS=latest}"
qa_derived_data="${QA_DERIVED_DATA:-/tmp/kartuli-local-qa}"

# Test fixtures use their own UserDefaults domains and do not update the widget.
xcodebuild -project Kartuli.xcodeproj -scheme Kartuli \
  -configuration Debug -destination "$qa_destination" \
  -derivedDataPath "$qa_derived_data" -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test

# Compile app and embedded widget using the shipping optimization settings.
xcodebuild -project Kartuli.xcodeproj -scheme Kartuli \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$qa_derived_data" CODE_SIGNING_ALLOWED=NO build
