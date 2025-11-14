.PHONY: test test-unit test-integration clean

# Run all tests
test:
	@echo "Running all tests..."
	nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.vim' }"

# Run only unit tests
test-unit:
	@echo "Running unit tests..."
	nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/unit/ { minimal_init = 'tests/minimal_init.vim' }"

# Run only integration tests
test-integration:
	@echo "Running integration tests..."
	nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/integration/ { minimal_init = 'tests/minimal_init.vim' }"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	@find . -name "*.log" -type f -delete
	@echo "Clean complete!"

# Help
help:
	@echo "Available targets:"
	@echo "  test             - Run all tests"
	@echo "  test-unit        - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  clean            - Clean up generated files"
	@echo "  help             - Show this help message"
