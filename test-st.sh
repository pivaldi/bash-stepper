#!/usr/bin/env bash
# Standalone test runner for st.bash (doesn't require bats)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for test output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        [ -n "$message" ] && echo "  Message:  $message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  Expected to contain: '$needle'"
        echo "  In: '$haystack'"
        [ -n "$message" ] && echo "  Message: $message"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-}"

    if [ -n "$value" ]; then
        return 0
    else
        echo "  Expected non-empty value"
        [ -n "$message" ] && echo "  Message: $message"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local message="${2:-}"

    if [ -z "$value" ]; then
        return 0
    else
        echo "  Expected empty value but got: '$value'"
        [ -n "$message" ] && echo "  Message: $message"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [ "$expected" -eq "$actual" ]; then
        return 0
    else
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        [ -n "$message" ] && echo "  Message: $message"
        return 1
    fi
}

# Test runner
run_test() {
    local test_name="$1"
    local test_function="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -ne "${BLUE}[TEST]${NC} $test_name ... "

    # Create a subshell for test isolation
    # Capture output and redirect through a pipe to ensure [ -t 1 ] returns false
    local test_output
    local test_result
    test_output=$(
        # Source the library fresh in subshell (with piped stdout, [ -t 1 ] will be false)
        source "$SCRIPT_DIR/st.bash" 2>&1
        # Run the test function
        "$test_function" 2>&1
    )
    test_result=$?

    if [ $test_result -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        # Display test output if there is any
        if [ -n "$test_output" ]; then
            echo "$test_output"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test functions

# Note: In non-terminal output, colors are automatically disabled
# so we test for plain output without ANSI codes

test_colors_disabled_in_non_terminal() {
    # When output is not a terminal, colors should be empty
    assert_empty "$BOLD" "BOLD should be empty"
    assert_empty "$OFFBOLD" "OFFBOLD should be empty"
    assert_empty "$RESET_COLOR" "RESET_COLOR should be empty"
    assert_empty "$RED" "RED should be empty"
    assert_empty "$GREEN" "GREEN should be empty"
    assert_empty "$YELLOW" "YELLOW should be empty"
    assert_empty "$BLUE" "BLUE should be empty"
    assert_empty "$BLUE_CYAN" "BLUE_CYAN should be empty"
}

test_h1_outputs_correct_format() {
    local output
    output=$(st.h1 "Test Header")

    assert_contains "$output" "st.h1>" "should contain st.h1>"
    assert_contains "$output" "Test Header" "should contain header text"
}

test_h2_outputs_correct_format() {
    local output
    output=$(st.h2 "Test Header 2")

    assert_contains "$output" "st.h2>" "should contain st.h2>"
    assert_contains "$output" "Test Header 2" "should contain header text"
}

test_h3_outputs_correct_format() {
    local output
    output=$(st.h3 "Test Header 3")

    assert_contains "$output" "st.h3>" "should contain st.h3>"
    assert_contains "$output" "Test Header 3" "should contain header text"
}

test_doing_outputs_correct_format() {
    local output
    output=$(st.doing "Test Action")

    assert_contains "$output" "st.doing>" "should contain st.doing>"
    assert_contains "$output" "Test Action" "should contain action text"
}

test_doing_sets_variable() {
    st.doing "Test Message" >/dev/null

    assert_equals "Test Message" "$DOING_MSG" "DOING_MSG should be set"
}

test_done_with_default_message() {
    DOING_MSG="Previous action"
    local output
    output=$(st.done)

    assert_contains "$output" "st.done>" "should contain st.done>"
    assert_contains "$output" "Previous action" "should contain action name"
    assert_contains "$output" "DONE" "should contain DONE"
}

test_done_with_custom_message() {
    DOING_MSG="Custom action"
    local output
    output=$(st.done "COMPLETED")

    assert_contains "$output" "Custom action" "should contain action name"
    assert_contains "$output" "COMPLETED" "should contain custom message"
}

test_nothingTodo_outputs_correct_format() {
    local output
    output=$(st.nothingTodo 2>&1 || true)

    assert_contains "$output" "Nothing to do" "should contain 'Nothing to do'"
}

test_skipped_outputs_correct_format() {
    DOING_MSG="Skipped action"
    local output
    output=$(st.skipped)

    assert_contains "$output" "st.skiped>" "should contain st.skiped>"
    assert_contains "$output" "Skipped action" "should contain action name"
    assert_contains "$output" "SKIPPED" "should contain SKIPPED"
}

test_warn_outputs_correct_format() {
    DOING_MSG="Warning test"
    local output
    output=$(st.warn "This is a warning")

    assert_contains "$output" "st.warn>" "should contain st.warn>"
    assert_contains "$output" "Warning test" "should contain action name"
    assert_contains "$output" "This is a warning" "should contain warning text"
}

test_fail_exits_with_error() {
    local output
    local exit_code
    output=$(st.fail "Test failure" 2>&1) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "should exit with code 1"
    assert_contains "$output" "st.fail>" "should contain st.fail>"
    assert_contains "$output" "Test failure" "should contain failure message"
    assert_contains "$output" "PROCESS ABORTED" "should contain PROCESS ABORTED"
}

test_do_executes_command() {
    local output
    output=$(st.do echo "Hello World" 2>&1)

    assert_contains "$output" "st.do>" "should show st.do>"
    assert_contains "$output" "echo Hello World" "should show command"
    assert_contains "$output" "Hello World" "should show output"
}

test_do_with_multiple_arguments() {
    local output
    output=$(st.do echo "arg1" "arg2" "arg3" 2>&1)

    assert_contains "$output" "arg1 arg2 arg3" "should show all arguments"
}

test_workflow_doing_then_done() {
    local output
    output=$(st.doing "Test workflow" && st.done)

    assert_contains "$output" "Test workflow" "should show workflow name"
    assert_contains "$output" "DONE" "should show done"
}

test_multiple_doing_updates_variable() {
    st.doing "First action" >/dev/null
    assert_equals "First action" "$DOING_MSG" "first call should set variable"

    st.doing "Second action" >/dev/null
    assert_equals "Second action" "$DOING_MSG" "second call should update variable"
}

test_h1_with_empty_string() {
    local output
    output=$(st.h1 "")

    assert_contains "$output" "st.h1>" "should handle empty string"
}

test_doing_with_special_characters() {
    local output
    output=$(st.doing "Test with 'quotes' and \"double quotes\"")

    assert_contains "$output" "quotes" "should handle special characters"
}

test_output_has_no_ansi_codes_in_non_terminal() {
    local output
    output=$(st.h1 "Test" && st.doing "Action" && st.done)

    # Output should not contain ANSI escape codes when not in a terminal
    if [[ "$output" =~ $'\033' ]]; then
        echo "Output contains ANSI codes: $output"
        return 1
    fi
    return 0
}

test_done_without_prior_doing() {
    unset DOING_MSG
    local output
    output=$(st.done)

    # Should handle gracefully even with empty DOING_MSG
    assert_contains "$output" "st.done>" "should contain st.done>"
}

# Main test execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running st.bash Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo

    # Color tests (automatic based on terminal detection)
    run_test "Colors disabled in non-terminal" test_colors_disabled_in_non_terminal

    # Header tests
    run_test "st.h1 outputs correct format" test_h1_outputs_correct_format
    run_test "st.h2 outputs correct format" test_h2_outputs_correct_format
    run_test "st.h3 outputs correct format" test_h3_outputs_correct_format

    # Action tests
    run_test "st.doing outputs correct format" test_doing_outputs_correct_format
    run_test "st.doing sets DOING_MSG variable" test_doing_sets_variable
    run_test "st.done with default message" test_done_with_default_message
    run_test "st.done with custom message" test_done_with_custom_message
    run_test "st.nothingTodo outputs correct format" test_nothingTodo_outputs_correct_format
    run_test "st.skipped outputs correct format" test_skipped_outputs_correct_format
    run_test "st.warn outputs correct format" test_warn_outputs_correct_format
    run_test "st.fail exits with error" test_fail_exits_with_error

    # Command execution tests
    run_test "st.do executes command" test_do_executes_command
    run_test "st.do with multiple arguments" test_do_with_multiple_arguments

    # Workflow tests
    run_test "Workflow: doing then done" test_workflow_doing_then_done
    run_test "Multiple st.doing updates variable" test_multiple_doing_updates_variable

    # Edge case tests
    run_test "st.h1 with empty string" test_h1_with_empty_string
    run_test "st.doing with special characters" test_doing_with_special_characters
    run_test "No ANSI codes in non-terminal" test_output_has_no_ansi_codes_in_non_terminal
    run_test "st.done without prior st.doing" test_done_without_prior_doing

    # Summary
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total:  ${TESTS_RUN}"
    echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
    echo

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed! ✗${NC}"
        exit 1
    fi
}

# Run tests
main
