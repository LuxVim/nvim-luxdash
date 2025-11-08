.PHONY: help test lint format install uninstall clean check health doc

# Default target
help:
	@echo "nvim-luxdash Development Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  help      - Show this help message"
	@echo "  test      - Run tests (requires plenary.nvim)"
	@echo "  lint      - Run luacheck linter"
	@echo "  format    - Format Lua code with stylua"
	@echo "  check     - Run lint + test"
	@echo "  health    - Run Neovim health check for luxdash"
	@echo "  install   - Install plugin locally for testing"
	@echo "  uninstall - Remove local installation"
	@echo "  clean     - Remove temporary files"
	@echo "  doc       - Generate documentation (if applicable)"
	@echo ""
	@echo "Installation:"
	@echo "  make install   - Creates symlink in ~/.local/share/nvim/site/pack/vendor/start/"
	@echo ""
	@echo "Development workflow:"
	@echo "  1. make install     # Set up for testing"
	@echo "  2. make check       # Run linter and tests"
	@echo "  3. make health      # Check plugin health"

# Run tests with plenary.nvim
test:
	@echo "Running tests..."
	@if [ ! -d "tests" ]; then \
		echo "❌ No tests directory found. Tests not implemented yet."; \
		echo "   Consider adding tests using plenary.nvim"; \
		exit 1; \
	fi
	@nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" || \
		(echo "❌ Tests failed or plenary.nvim not installed"; exit 1)

# Lint Lua code with luacheck
lint:
	@echo "Running luacheck..."
	@if ! command -v luacheck >/dev/null 2>&1; then \
		echo "❌ luacheck not found. Install with: luarocks install luacheck"; \
		exit 1; \
	fi
	@luacheck lua/ --globals vim || (echo "❌ Linting failed"; exit 1)
	@echo "✅ Linting passed"

# Format code with stylua
format:
	@echo "Formatting Lua code..."
	@if ! command -v stylua >/dev/null 2>&1; then \
		echo "❌ stylua not found. Install from: https://github.com/JohnnyMorganz/StyLua"; \
		exit 1; \
	fi
	@stylua lua/ plugin/
	@echo "✅ Code formatted"

# Run both lint and test
check: lint test
	@echo "✅ All checks passed"

# Run Neovim health check
health:
	@echo "Running health check..."
	@nvim --headless -c "checkhealth luxdash" -c "quit" 2>&1 | grep -A 50 "luxdash" || \
		nvim -c "checkhealth luxdash"
	@echo "✅ Health check complete"

# Install plugin locally for testing
install:
	@echo "Installing nvim-luxdash locally..."
	@mkdir -p ~/.local/share/nvim/site/pack/vendor/start/
	@if [ -L ~/.local/share/nvim/site/pack/vendor/start/luxdash ]; then \
		echo "⚠️  Symlink already exists, removing old one..."; \
		rm ~/.local/share/nvim/site/pack/vendor/start/luxdash; \
	fi
	@ln -sf $(PWD) ~/.local/share/nvim/site/pack/vendor/start/luxdash
	@echo "✅ Installed at: ~/.local/share/nvim/site/pack/vendor/start/luxdash"
	@echo ""
	@echo "Add to your Neovim config:"
	@echo "  require('luxdash').setup()"
	@echo ""
	@echo "Then test with: nvim"

# Uninstall local installation
uninstall:
	@echo "Uninstalling nvim-luxdash..."
	@if [ -L ~/.local/share/nvim/site/pack/vendor/start/luxdash ]; then \
		rm ~/.local/share/nvim/site/pack/vendor/start/luxdash; \
		echo "✅ Uninstalled"; \
	else \
		echo "⚠️  Not installed (symlink not found)"; \
	fi

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.log" -delete
	@find . -type f -name "*~" -delete
	@find . -type d -name ".luacache" -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ Cleaned"

# Generate documentation (placeholder)
doc:
	@echo "Generating documentation..."
	@echo "ℹ️  Documentation is maintained in README.md and CHANGELOG.md"
	@echo "   For API docs, see inline LuaCATS annotations"
	@echo ""
	@echo "Documentation files:"
	@ls -1 *.md 2>/dev/null || echo "  (none found)"

# Development helpers
.PHONY: dev-setup validate-install
dev-setup: install
	@echo "Setting up development environment..."
	@echo ""
	@echo "Recommended tools:"
	@echo "  • luacheck (linter):  luarocks install luacheck"
	@echo "  • stylua (formatter): cargo install stylua"
	@echo "  • plenary.nvim (testing): Install via package manager"
	@echo ""
	@echo "Run 'make check' to verify everything works"

validate-install:
	@echo "Validating installation..."
	@nvim --version | head -1
	@if [ -d ~/.local/share/nvim/site/pack/vendor/start/luxdash ]; then \
		echo "✅ Plugin symlink exists"; \
	else \
		echo "❌ Plugin not installed (run 'make install')"; \
		exit 1; \
	fi
	@echo "✅ Installation valid"

# Quick test command that opens Neovim with the dashboard
.PHONY: demo
demo: install
	@echo "Opening Neovim with LuxDash..."
	@nvim -c "lua require('luxdash').setup()" -c "LuxDash"
