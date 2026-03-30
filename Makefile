PROJECT := kutuk.xcodeproj
SCHEME := kutuk
CONFIGURATION ?= Release
DESTINATION ?= generic/platform=macOS
DERIVED_DATA := $(CURDIR)/build/DerivedData
BUILD_PRODUCTS_DIR := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)
APP_NAME := Kutuk
APP_BUNDLE := $(BUILD_PRODUCTS_DIR)/$(APP_NAME).app
DIST_DIR := $(CURDIR)/dist
DIST_APP_BUNDLE := $(DIST_DIR)/$(APP_NAME).app
DMG_STAGING_DIR := $(DIST_DIR)/dmg
DMG_VOLUME_NAME ?= Kutuk
DMG_NAME ?= Kutuk-$(CONFIGURATION).dmg
DMG_PATH := $(DIST_DIR)/$(DMG_NAME)
BUNDLE_IDENTIFIER ?= io.github.irajul.kutuk

# Build flags: Universal Binary (Intel + Apple Silicon), no code signing for CI
XCODEBUILD_FLAGS ?= \
	CODE_SIGNING_ALLOWED=NO \
	ONLY_ACTIVE_ARCH=NO \
	ARCHS="arm64 x86_64"

.PHONY: build dist-app dmg clean verify-app verify-universal bump-version bump-build

build:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		build \
		$(XCODEBUILD_FLAGS)

verify-app: build
	@test -d "$(APP_BUNDLE)" || (echo "Expected app bundle not found at $(APP_BUNDLE)" && exit 1)

verify-universal: verify-app
	@echo "Checking Universal Binary architectures..."
	@lipo -info "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)" | grep -q "arm64" || (echo "Missing arm64 architecture" && exit 1)
	@lipo -info "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)" | grep -q "x86_64" || (echo "Missing x86_64 architecture" && exit 1)
	@echo "Universal Binary verified: arm64 + x86_64"

dist-app: verify-app
	rm -rf "$(DIST_APP_BUNDLE)"
	mkdir -p "$(DIST_DIR)"
	ditto "$(APP_BUNDLE)" "$(DIST_APP_BUNDLE)"
	codesign --force --deep --sign - --identifier "$(BUNDLE_IDENTIFIER)" "$(DIST_APP_BUNDLE)"
	@echo "App bundle created at $(DIST_APP_BUNDLE)"

dmg: dist-app
	rm -rf "$(DMG_STAGING_DIR)" "$(DMG_PATH)"
	mkdir -p "$(DMG_STAGING_DIR)"
	ditto "$(DIST_APP_BUNDLE)" "$(DMG_STAGING_DIR)/$(APP_NAME).app"
	ln -s /Applications "$(DMG_STAGING_DIR)/Applications"
	hdiutil create \
		-volname "$(DMG_VOLUME_NAME)" \
		-srcfolder "$(DMG_STAGING_DIR)" \
		-ov \
		-format UDZO \
		"$(DMG_PATH)"
	@if [ -n "$(DMG_CODESIGN_IDENTITY)" ]; then \
		codesign --force --sign "$(DMG_CODESIGN_IDENTITY)" --timestamp "$(DMG_PATH)"; \
	fi
	rm -rf "$(DMG_STAGING_DIR)"
	@echo "DMG created at $(DMG_PATH)"

clean:
	rm -rf "$(CURDIR)/build" "$(DIST_DIR)"

bump-version:
	@test -n "$(VERSION)" || (echo "Usage: make bump-version VERSION=1.0.2" && exit 1)
	./scripts/bump_version.sh "$(VERSION)" "$(BUILD)"

bump-build:
	./scripts/bump_build.sh
