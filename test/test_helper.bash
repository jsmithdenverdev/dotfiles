#!/bin/bash

# Common setup for all tests
setup() {
    # Create isolated test environment
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_TEMP_DIR"
    
    # Ensure we're in the repo root
    cd "$BATS_TEST_DIRNAME/.." || exit 1
}

# Common teardown for all tests
teardown() {
    # Restore original HOME
    export HOME="$ORIGINAL_HOME"
    
    # Clean up temp directory
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper function to assert file exists
assert_file_exists() {
    local file="$1"
    [ -f "$file" ] || {
        echo "Expected file to exist: $file"
        return 1
    }
}

# Helper function to assert output contains string
assert_output_contains() {
    local expected="$1"
    # shellcheck disable=SC2154
    [[ "$output" == *"$expected"* ]] || {
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    }
}
