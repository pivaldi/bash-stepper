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

# Test runner for ST_QUIET tests (uses st.quiet function)
run_test_quiet() {
    local test_name="$1"
    local test_function="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -ne "${BLUE}[TEST]${NC} $test_name ... "

    # Create a subshell for test isolation with quiet mode enabled
    local test_output
    local test_result
    test_output=$(
        # Source the library fresh in subshell
        source "$SCRIPT_DIR/st.bash" 2>&1
        # Enable quiet mode using st.quiet
        st.quiet
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
    assert_empty "$GRAY_LIGHT" "GRAY_LIGHT should be empty"
}

test_cmd_exists_returns_true_for_existing_command() {
    st.cmd.exists bash
    assert_exit_code 0 $? "should return 0 for existing command"
}

test_cmd_exists_returns_false_for_nonexisting_command() {
    st.cmd.exists nonexistent_command_12345 && local result=$? || local result=$?
    assert_exit_code 1 $result "should return 1 for non-existing command"
}

test_cmd_exists_works_in_conditional() {
    local result="not_found"
    if st.cmd.exists echo; then
        result="found"
    fi
    assert_equals "found" "$result" "should work in conditional"
}

test_var_exists_returns_true_for_existing_variable() {
    TEST_VAR="some value"
    st.var.exists TEST_VAR
    assert_exit_code 0 $? "should return 0 for existing variable"
}

test_var_exists_returns_false_for_unset_variable() {
    unset NONEXISTENT_VAR
    st.var.exists NONEXISTENT_VAR && local result=$? || local result=$?
    assert_exit_code 1 $result "should return 1 for unset variable"
}

test_var_exists_returns_false_for_empty_variable() {
    EMPTY_VAR=""
    st.var.exists EMPTY_VAR && local result=$? || local result=$?
    assert_exit_code 1 $result "should return 1 for empty variable"
}

test_var_exists_works_in_conditional() {
    MY_VAR="test"
    local result="not_exists"
    if st.var.exists MY_VAR; then
        result="exists"
    fi
    assert_equals "exists" "$result" "should work in conditional"
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
    assert_contains "$output" "[DONE]" "should contain [DONE]"
}

test_done_with_custom_message() {
    DOING_MSG="Custom action"
    local output
    output=$(st.done "COMPLETED")

    assert_contains "$output" "Custom action" "should contain action name"
    assert_contains "$output" "COMPLETED" "should contain custom message"
}

test.nothing_outputs_correct_format() {
    DOING_MSG="Check prerequisites"
    local output
    output=$(st.nothing)

    assert_contains "$output" "st.nothingtd>" "should contain st.nothingtd>"
    assert_contains "$output" "Check prerequisites" "should contain action name"
    assert_contains "$output" "[NOTHING TO DO]" "should contain [NOTHING TO DO]"
}

test.nothing_with_custom_message() {
    DOING_MSG="Check configuration"
    local output
    output=$(st.nothing "Already configured")

    assert_contains "$output" "Check configuration" "should contain action name"
    assert_contains "$output" "Already configured" "should contain custom message"
}

test_skipped_outputs_correct_format() {
    DOING_MSG="Skipped action"
    local output
    output=$(st.skipped)

    assert_contains "$output" "st.skipped>" "should contain st.skipped>"
    assert_contains "$output" "Skipped action" "should contain action name"
    assert_contains "$output" "[SKIPPED]" "should contain [SKIPPED]"
}

test_skipped_with_custom_message() {
    DOING_MSG="Optional optimization"
    local output
    output=$(st.skipped "Not applicable")

    assert_contains "$output" "Optional optimization" "should contain action name"
    assert_contains "$output" "Not applicable" "should contain custom message"
}

test_warn_outputs_correct_format() {
    local output
    output=$(st.warn "This is a warning")

    assert_contains "$output" "st.warn>" "should contain st.warn>"
    assert_contains "$output" "This is a warning" "should contain warning text"
}

test_fail_returns_error() {
    DOING_MSG="Test operation"
    local output
    local exit_code
    output=$(st.fail "Test failure") || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "should return exit code 1"
    assert_contains "$output" "st.fail" "should contain st.fail>"
    assert_contains "$output" "Test operation" "should contain action name"
    assert_contains "$output" "Test failure" "should contain failure message"
}

test_fail_with_default_message() {
    DOING_MSG="Another operation"
    local output
    local exit_code
    output=$(st.fail) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "should return exit code 1"
    assert_contains "$output" "st.fail" "should contain st.fail>"
    assert_contains "$output" "Another operation" "should contain action name"
    assert_contains "$output" "[FAILED]" "should contain [FAILED]"
}

test_abort_exits_with_error() {
    local output
    local exit_code
    output=$(st.abort "Test abort" 2>&1) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "should exit with code 1"
    assert_contains "$output" "st.abort>" "should contain st.abort>"
    assert_contains "$output" "Test abort" "should contain abort message"
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

test_do_returns_command_exit_code_on_failure() {
    st.do false 2>&1 || local exit_code=$?
    assert_exit_code 1 ${exit_code:-0} "should return exit code 1 for false command"
}

test_do_returns_command_exit_code_on_success() {
    st.do true 2>&1
    assert_exit_code 0 $? "should return exit code 0 for true command"
}

test_do_passes_through_custom_exit_codes() {
    st.do sh -c "exit 42" 2>&1 || local exit_code=$?
    assert_exit_code 42 ${exit_code:-0} "should pass through exit code 42"
}

test_success_outputs_correct_format() {
    local output
    output=$(st.success "Deployment complete")

    assert_contains "$output" "st.success>" "should contain st.success>"
    assert_contains "$output" "Deployment complete" "should contain success message"
}

test_success_with_default_message() {
    local output
    output=$(st.success)

    assert_contains "$output" "st.success>" "should contain st.success>"
    assert_contains "$output" "[SUCCESS]" "should contain [SUCCESS]"
}

test_workflow_doing_then_done() {
    local output
    output=$(st.doing "Test workflow" && st.done)

    assert_contains "$output" "Test workflow" "should show workflow name"
    assert_contains "$output" "[DONE]" "should show [DONE]"
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

test_st_quiet_disables_h1_prefix() {
    local output
    output=$(st.h1 "Test Header")

    assert_equals "Test Header" "$output" "should not contain st.h1> prefix"
}

test_st_quiet_disables_h2_prefix() {
    local output
    output=$(st.h2 "Test Header")

    assert_equals "Test Header" "$output" "should not contain st.h2> prefix"
}

test_st_quiet_disables_h3_prefix() {
    local output
    output=$(st.h3 "Test Header")

    assert_equals "Test Header" "$output" "should not contain st.h3> prefix"
}

test_st_quiet_disables_doing_prefix() {
    local output
    output=$(st.doing "Test Action")

    assert_equals "Test Action" "$output" "should not contain st.doing> prefix"
}

test_st_quiet_disables_done_prefix() {
    DOING_MSG="Test Action"
    local output
    output=$(st.done)

    assert_contains "$output" "Test Action" "should contain action"
    assert_contains "$output" "[DONE]" "should contain [DONE]"

    # Should not contain prefix
    if [[ "$output" =~ "st.done>" ]]; then
        echo "Output contains st.done> prefix when ST_QUIET is set"
        return 1
    fi
}

test_st_quiet_disables_success_prefix() {
    local output
    output=$(st.success "Complete")

    assert_equals "Complete" "$output" "should not contain st.success> prefix"
}

test_st_quiet_disables_nothing_prefix() {
    DOING_MSG="Test Action"
    local output
    output=$(st.nothing)

    assert_contains "$output" "Test Action" "should contain action"
    assert_contains "$output" "[NOTHING TO DO]" "should contain [NOTHING TO DO]"

    # Should not contain prefix
    if [[ "$output" =~ "st.nothingtd>" ]]; then
        echo "Output contains st.nothingtd> prefix when ST_QUIET is set"
        return 1
    fi
}

test_st_quiet_disables_skipped_prefix() {
    DOING_MSG="Test Action"
    local output
    output=$(st.skipped)

    assert_contains "$output" "Test Action" "should contain action"
    assert_contains "$output" "[SKIPPED]" "should contain [SKIPPED]"

    # Should not contain prefix
    if [[ "$output" =~ "st.skipped>" ]]; then
        echo "Output contains st.skipped> prefix when ST_QUIET is set"
        return 1
    fi
}

test_st_quiet_disables_warn_prefix() {
    local output
    output=$(st.warn "Warning message")

    assert_equals "Warning message" "$output" "should not contain st.warn> prefix"
}

test_st_quiet_disables_fail_prefix() {
    DOING_MSG="Test Action"
    local output
    output=$(st.fail) || true

    assert_contains "$output" "Test Action" "should contain action"
    assert_contains "$output" "[FAILED]" "should contain [FAILED]"

    # Should not contain prefix
    if [[ "$output" =~ "st.fail" ]]; then
        echo "Output contains st.fail prefix when ST_QUIET is set"
        return 1
    fi
}

test_st_quiet_disables_do_prefix() {
    local output
    output=$(st.do echo "test" 2>&1)

    assert_contains "$output" "test" "should contain command output"

    # Should not contain prefix
    if [[ "$output" =~ "st.do>" ]]; then
        echo "Output contains st.do> prefix when ST_QUIET is set"
        return 1
    fi
}

test_st_quiet_workflow() {
    local output
    output=$(st.doing "Build app" && st.done)

    assert_contains "$output" "Build app" "should contain action"
    assert_contains "$output" "[DONE]" "should contain [DONE]"

    # Should not contain prefixes
    if [[ "$output" =~ "st.doing>" ]] || [[ "$output" =~ "st.done>" ]]; then
        echo "Output contains st. prefixes when ST_QUIET is set"
        return 1
    fi
    return 0
}

test_st_quiet_function() {
    local output

    # Default should have prefix
    output=$(st.h1 "Test")
    assert_contains "$output" "st.h1>" "should have prefix by default"

    # After st.quiet, no prefix
    st.quiet
    output=$(st.h1 "Test")
    assert_equals "Test" "$output" "should not have prefix after st.quiet"

    # After st.unquiet, prefix again
    st.unquiet
    output=$(st.h1 "Test")
    assert_contains "$output" "st.h1>" "should have prefix after st.unquiet"
}

test_st_quiet_dynamic_toggle() {
    local output

    # Start in normal mode
    output=$(st.h1 "First")
    assert_contains "$output" "st.h1>" "should have prefix when quiet mode is off"

    # Toggle quiet mode on
    st.quiet
    output=$(st.h1 "Second")
    assert_equals "Second" "$output" "should not have prefix when quiet mode is on"

    # Toggle quiet mode off again
    st.unquiet
    output=$(st.h1 "Third")
    assert_contains "$output" "st.h1>" "should have prefix when quiet mode is off again"
}

# Main test execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running st.bash Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo

    # Color tests (automatic based on terminal detection)
    run_test "Colors disabled in non-terminal" test_colors_disabled_in_non_terminal

    # Helper function tests
    run_test "st.cmd.exists returns true for existing command" test_cmd_exists_returns_true_for_existing_command
    run_test "st.cmd.exists returns false for non-existing command" test_cmd_exists_returns_false_for_nonexisting_command
    run_test "st.cmd.exists works in conditional" test_cmd_exists_works_in_conditional
    run_test "st.var.exists returns true for existing variable" test_var_exists_returns_true_for_existing_variable
    run_test "st.var.exists returns false for unset variable" test_var_exists_returns_false_for_unset_variable
    run_test "st.var.exists returns false for empty variable" test_var_exists_returns_false_for_empty_variable
    run_test "st.var.exists works in conditional" test_var_exists_works_in_conditional

    # Header tests
    run_test "st.h1 outputs correct format" test_h1_outputs_correct_format
    run_test "st.h2 outputs correct format" test_h2_outputs_correct_format
    run_test "st.h3 outputs correct format" test_h3_outputs_correct_format

    # Action tests
    run_test "st.doing outputs correct format" test_doing_outputs_correct_format
    run_test "st.doing sets DOING_MSG variable" test_doing_sets_variable
    run_test "st.done with default message" test_done_with_default_message
    run_test "st.done with custom message" test_done_with_custom_message
    run_test "st.success with custom message" test_success_outputs_correct_format
    run_test "st.success with default message" test_success_with_default_message
    run_test "st.nothing outputs correct format" test.nothing_outputs_correct_format
    run_test "st.nothing with custom message" test.nothing_with_custom_message
    run_test "st.skipped outputs correct format" test_skipped_outputs_correct_format
    run_test "st.skipped with custom message" test_skipped_with_custom_message
    run_test "st.warn outputs correct format" test_warn_outputs_correct_format
    run_test "st.fail returns error" test_fail_returns_error
    run_test "st.fail with default message" test_fail_with_default_message
    run_test "st.abort exits with error" test_abort_exits_with_error

    # Command execution tests
    run_test "st.do executes command" test_do_executes_command
    run_test "st.do with multiple arguments" test_do_with_multiple_arguments
    run_test "st.do returns command exit code on failure" test_do_returns_command_exit_code_on_failure
    run_test "st.do returns command exit code on success" test_do_returns_command_exit_code_on_success
    run_test "st.do passes through custom exit codes" test_do_passes_through_custom_exit_codes

    # Workflow tests
    run_test "Workflow: doing then done" test_workflow_doing_then_done
    run_test "Multiple st.doing updates variable" test_multiple_doing_updates_variable

    # Edge case tests
    run_test "st.h1 with empty string" test_h1_with_empty_string
    run_test "st.doing with special characters" test_doing_with_special_characters
    run_test "No ANSI codes in non-terminal" test_output_has_no_ansi_codes_in_non_terminal
    run_test "st.done without prior st.doing" test_done_without_prior_doing

    # ST_QUIET tests
    run_test "st.quiet and st.unquiet functions" test_st_quiet_function
    run_test_quiet "ST_QUIET disables st.h1 prefix" test_st_quiet_disables_h1_prefix
    run_test_quiet "ST_QUIET disables st.h2 prefix" test_st_quiet_disables_h2_prefix
    run_test_quiet "ST_QUIET disables st.h3 prefix" test_st_quiet_disables_h3_prefix
    run_test_quiet "ST_QUIET disables st.doing prefix" test_st_quiet_disables_doing_prefix
    run_test_quiet "ST_QUIET disables st.done prefix" test_st_quiet_disables_done_prefix
    run_test_quiet "ST_QUIET disables st.success prefix" test_st_quiet_disables_success_prefix
    run_test_quiet "ST_QUIET disables st.nothing prefix" test_st_quiet_disables_nothing_prefix
    run_test_quiet "ST_QUIET disables st.skipped prefix" test_st_quiet_disables_skipped_prefix
    run_test_quiet "ST_QUIET disables st.warn prefix" test_st_quiet_disables_warn_prefix
    run_test_quiet "ST_QUIET disables st.fail prefix" test_st_quiet_disables_fail_prefix
    run_test_quiet "ST_QUIET disables st.do prefix" test_st_quiet_disables_do_prefix
    run_test_quiet "ST_QUIET workflow" test_st_quiet_workflow
    run_test "ST_QUIET dynamic toggle" test_st_quiet_dynamic_toggle

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
