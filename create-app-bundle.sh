#!/bin/bash

set -e

echo "📦 Creating .app bundle..."

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
APP_NAME="AntiGravity Claude Proxy"
BUNDLE_ID="com.irvanfza.antigravity-claude-proxy"
BUILD_DIR="$SRC_DIR/.build/release"
APP_DIR="$PROJECT_DIR/$APP_NAME.app"

# Build the Swift executable first
echo -e "${BLUE}Building Swift executable (release)...${NC}"
cd "$SRC_DIR"
swift build -c release
cd "$PROJECT_DIR"
echo -e "${GREEN}✅ Build complete${NC}"

# Get the built executable path
EXECUTABLE_PATH="$BUILD_DIR/AntiGravityClaudeProxy"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "Error: Executable not found at $EXECUTABLE_PATH"
    exit 1
fi

echo -e "${BLUE}Executable built at: $EXECUTABLE_PATH${NC}"

# Create .app structure
echo -e "${BLUE}Creating .app bundle structure...${NC}"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

# Copy executable
echo -e "${BLUE}Copying executable...${NC}"
cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy"
chmod +x "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy"

# Add rpath for Frameworks directory (needed for Sparkle)
echo -e "${BLUE}Adding @rpath for Frameworks...${NC}"
install_name_tool -add_rpath "@loader_path/../Frameworks" "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy" 2>/dev/null || true
echo -e "${GREEN}✅ @rpath added${NC}"

# Copy resources
echo -e "${BLUE}Copying resources...${NC}"
if [ -d "$SRC_DIR/Sources/Resources" ]; then
    for item in "$SRC_DIR/Sources/Resources/"*; do
        if [ -e "$item" ]; then
            # Skip if it's a Swift file
            if [[ "$item" != *.swift ]]; then
                cp -r "$item" "$APP_DIR/Contents/Resources/"
            fi
        fi
    done
fi
echo -e "${GREEN}✅ Resources copied${NC}"

# Copy Sparkle.framework
echo -e "${BLUE}Copying Sparkle.framework...${NC}"
SPARKLE_FRAMEWORK=$(find "$SRC_DIR/.build" -name "Sparkle.framework" -type d | head -1)
if [ -n "$SPARKLE_FRAMEWORK" ]; then
    cp -R "$SPARKLE_FRAMEWORK" "$APP_DIR/Contents/Frameworks/"
    echo -e "${GREEN}✅ Sparkle.framework bundled${NC}"
else
    echo -e "${YELLOW}⚠️ Sparkle.framework not found${NC}"
fi

# Copy Info.plist and inject version
echo -e "${BLUE}Copying Info.plist...${NC}"
cp "$SRC_DIR/Info.plist" "$APP_DIR/Contents/"

# Inject version from git tag or environment variable
VERSION="${APP_VERSION:-}"
if [ -z "$VERSION" ]; then
    # Try to get version from git tag
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
    # Remove 'v' prefix if present
    VERSION="${VERSION#v}"
fi

# Extract build number from commit count
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")

echo -e "${BLUE}Setting version to: ${VERSION} (build ${BUILD_NUMBER})${NC}"

# Update Info.plist with version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${VERSION}" "$APP_DIR/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUMBER}" "$APP_DIR/Contents/Info.plist"

echo -e "${GREEN}✅ Version set: ${VERSION} (${BUILD_NUMBER})${NC}"

# Create PkgInfo
echo -e "${BLUE}Creating PkgInfo...${NC}"
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

# Sign the app with Developer ID if available, otherwise ad-hoc
echo -e "${BLUE}Signing app...${NC}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -z "$CODESIGN_IDENTITY" ]; then
    # Try to find Developer ID automatically
    CODESIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/' || true)
fi

if [ -n "$CODESIGN_IDENTITY" ]; then
    echo -e "${GREEN}Signing with: $CODESIGN_IDENTITY${NC}"

    # Clean up extended attributes and resource forks that prevent signing
    echo -e "${BLUE}Cleaning extended attributes...${NC}"
    xattr -cr "$APP_DIR"

    # Remove any existing signatures first
    echo -e "${BLUE}Removing existing signatures...${NC}"
    codesign --remove-signature "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy" 2>/dev/null || true

    # Sign Sparkle.framework (required for notarization)
    if [ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]; then
        echo -e "${BLUE}Signing Sparkle.framework...${NC}"
        SPARKLE_FW="$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B"
        SPARKLE_ENTITLEMENTS="$PROJECT_DIR/sparkle-entitlements.plist"

        # Sign XPC services with entitlements (deepest nested)
        for xpc in "$SPARKLE_FW/XPCServices"/*.xpc; do
            if [ -d "$xpc" ]; then
                echo -e "${BLUE}  Signing XPC service: $(basename "$xpc")${NC}"
                codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
                    --entitlements "$SPARKLE_ENTITLEMENTS" "$xpc"
            fi
        done

        # Sign Autoupdate with entitlements
        if [ -f "$SPARKLE_FW/Autoupdate" ]; then
            echo -e "${BLUE}  Signing Autoupdate${NC}"
            codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
                --entitlements "$SPARKLE_ENTITLEMENTS" "$SPARKLE_FW/Autoupdate"
        fi

        # Sign Updater.app with entitlements
        if [ -d "$SPARKLE_FW/Updater.app" ]; then
            echo -e "${BLUE}  Signing Updater.app${NC}"
            codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
                --entitlements "$SPARKLE_ENTITLEMENTS" "$SPARKLE_FW/Updater.app"
        fi

        # Sign the framework itself
        echo -e "${BLUE}  Signing Sparkle.framework${NC}"
        codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
            "$APP_DIR/Contents/Frameworks/Sparkle.framework"
        echo -e "${GREEN}✅ Sparkle.framework signed${NC}"
    fi

    # Sign the main executable with hardened runtime and entitlements
    echo -e "${BLUE}Signing main executable...${NC}"
    if [ -f "$PROJECT_DIR/entitlements.plist" ]; then
        codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
            --entitlements "$PROJECT_DIR/entitlements.plist" \
            "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy"
    else
        codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp \
            "$APP_DIR/Contents/MacOS/AntiGravityClaudeProxy"
    fi

    # Then sign the entire app bundle
    echo -e "${BLUE}Signing app bundle...${NC}"
    codesign --force --sign "$CODESIGN_IDENTITY" --options runtime --timestamp "$APP_DIR"

    echo -e "${GREEN}✅ Code signed successfully${NC}"

    # Verify the signature
    echo -e "${BLUE}Verifying signature...${NC}"
    if codesign --verify --deep --strict --verbose=2 "$APP_DIR" 2>&1; then
        echo -e "${GREEN}✅ Signature verified${NC}"
    else
        echo -e "${YELLOW}⚠️ Signature verification failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ No Developer ID found, using ad-hoc signature${NC}"

    # Clean extended attributes even for ad-hoc signing
    xattr -cr "$APP_DIR" 2>/dev/null || true

    # Sign Sparkle framework with ad-hoc signature
    if [ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]; then
        echo -e "${BLUE}Signing Sparkle framework with ad-hoc signature...${NC}"
        SPARKLE_FW="$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B"

        # Sign XPC services
        for xpc in "$SPARKLE_FW/XPCServices"/*.xpc; do
            if [ -d "$xpc" ]; then
                codesign --force --sign - "$xpc" 2>/dev/null || true
            fi
        done

        codesign --force --sign - "$SPARKLE_FW/Autoupdate" 2>/dev/null || true
        codesign --force --sign - "$SPARKLE_FW/Updater.app" 2>/dev/null || true
        codesign --force --sign - "$APP_DIR/Contents/Frameworks/Sparkle.framework"
    fi

    codesign --force --deep --sign - "$APP_DIR"
    echo -e "${GREEN}✅ App signed with ad-hoc signature (for local use only)${NC}"
fi

echo ""
echo -e "${GREEN}✅ App bundle created successfully!${NC}"
echo ""
echo -e "${GREEN}Location: $APP_DIR${NC}"
echo -e "${GREEN}Version: $VERSION (build $BUILD_NUMBER)${NC}"
echo ""
echo "To install:"
echo "  1. Drag '$APP_NAME.app' to /Applications"
echo "  2. Double-click to launch"
echo ""
echo "To allow opening (if macOS blocks it):"
echo "  Right-click > Open, then click 'Open' in the dialog"
echo ""
