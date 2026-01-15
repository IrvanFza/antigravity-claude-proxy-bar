.PHONY: build clean install run dev

# Build the app bundle
build:
	@./create-app-bundle.sh

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf "AntiGravity Claude Proxy.app"
	@cd src && swift package clean
	@echo "Clean complete"

# Install to Applications folder
install: build
	@echo "Installing to /Applications..."
	@rm -rf "/Applications/AntiGravity Claude Proxy.app"
	@cp -R "AntiGravity Claude Proxy.app" /Applications/
	@echo "Installed to /Applications/AntiGravity Claude Proxy.app"

# Run the app
run: build
	@echo "Running AntiGravity Claude Proxy..."
	@open "AntiGravity Claude Proxy.app"

# Development build (faster, debug mode)
dev:
	@cd src && swift build
	@echo "Debug build complete"
	@cd src && .build/debug/AntiGravityClaudeProxy

# Quick test build
test-build:
	@cd src && swift build
	@echo "Build successful"
