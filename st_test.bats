#!/usr/bin/env bats
# Tests for st.bash - Bash stepper library
# Uses automatic terminal detection via [ -t 1 ]

# Load the library
setup() {
    # Source the library
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    source "$SCRIPT_DIR/st.bash"
}

# Test color initialization based on terminal detection
# In Bats, stdout is piped (not a terminal), so colors should be disabled
@test "Colors are empty in non-terminal (Bats) context" {
    [ -z "$BOLD" ]
    [ -z "$OFFBOLD" ]
    [ -z "$RESET_COLOR" ]
    [ -z "$RED" ]
    [ -z "$GREEN" ]
    [ -z "$YELLOW" ]
    [ -z "$BLUE" ]
    [ -z "$BLUE_CYAN" ]
    [ -z "$GRAY_LIGHT" ]
}

# Test st.cmd.exists function
@test "st.cmd.exists returns true for existing command" {
    run st.cmd.exists bash

    [ "$status" -eq 0 ]
}

@test "st.cmd.exists returns false for non-existing command" {
    run st.cmd.exists nonexistent_command_12345

    [ "$status" -eq 1 ]
}

@test "st.cmd.exists works in conditional" {
    if st.cmd.exists echo; then
        result="found"
    else
        result="not_found"
    fi

    [ "$result" = "found" ]
}

# Test st.var.exists function
@test "st.var.exists returns true for existing variable" {
    TEST_VAR="some value"
    run st.var.exists TEST_VAR

    [ "$status" -eq 0 ]
}

@test "st.var.exists returns false for unset variable" {
    unset NONEXISTENT_VAR
    run st.var.exists NONEXISTENT_VAR

    [ "$status" -eq 1 ]
}

@test "st.var.exists returns false for empty variable" {
    EMPTY_VAR=""
    run st.var.exists EMPTY_VAR

    [ "$status" -eq 1 ]
}

@test "st.var.exists works in conditional" {
    MY_VAR="test"
    if st.var.exists MY_VAR; then
        result="exists"
    else
        result="not_exists"
    fi

    [ "$result" = "exists" ]
}

# Test st.h1 function
@test "st.h1 outputs correct format" {
    run st.h1 "Test Header 1"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.h1>"* ]]
    [[ "$output" == *"Test Header 1"* ]]
}

# Test st.h2 function
@test "st.h2 outputs correct format" {
    run st.h2 "Test Header 2"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.h2>"* ]]
    [[ "$output" == *"Test Header 2"* ]]
}

# Test st.h3 function
@test "st.h3 outputs correct format" {
    run st.h3 "Test Header 3"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.h3>"* ]]
    [[ "$output" == *"Test Header 3"* ]]
}

# Test st.doing function
@test "st.doing outputs correct format" {
    run st.doing "Test Action"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.doing>"* ]]
    [[ "$output" == *"Test Action"* ]]
}

@test "st.doing sets DOING_MSG variable" {
    st.doing "Test Message"

    [ "$DOING_MSG" = "Test Message" ]
}

# Test st.done function
@test "st.done outputs correct format with default message" {
    DOING_MSG="Previous action"
    run st.done

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.done>"* ]]
    [[ "$output" == *"Previous action : [DONE]"* ]]
}

@test "st.done outputs custom message" {
    DOING_MSG="Custom action"
    run st.done "COMPLETED"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Custom action : COMPLETED"* ]]
}


# Test st.nothing function
@test "st.nothing outputs correct format" {
    DOING_MSG="Check prerequisites"
    run st.nothing

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.nothingtd>"* ]]
    [[ "$output" == *"Check prerequisites"* ]]
    [[ "$output" == *"[NOTHING TO DO]"* ]]
}

@test "st.nothing with custom message" {
    DOING_MSG="Check configuration"
    run st.nothing "Already configured"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Check configuration"* ]]
    [[ "$output" == *"Already configured"* ]]
}

# Test st.skipped function
@test "st.skipped outputs correct format" {
    DOING_MSG="Skipped action"
    run st.skipped

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.skipped>"* ]]
    [[ "$output" == *"Skipped action"* ]]
    [[ "$output" == *"[SKIPPED]"* ]]
}

@test "st.skipped with custom message" {
    DOING_MSG="Optional optimization"
    run st.skipped "Not applicable"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Optional optimization"* ]]
    [[ "$output" == *"Not applicable"* ]]
}

# Test st.warn function
@test "st.warn outputs correct format" {
    run st.warn "This is a warning"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.warn>"* ]]
    [[ "$output" == *"This is a warning"* ]]
}

# Test st.fail function
@test "st.fail returns error without exiting" {
    DOING_MSG="Test operation"
    run st.fail "Test failure message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"st.fail"* ]]
    [[ "$output" == *"Test operation"* ]]
    [[ "$output" == *"Test failure message"* ]]
}

@test "st.fail with default message" {
    DOING_MSG="Another operation"
    run st.fail

    [ "$status" -eq 1 ]
    [[ "$output" == *"st.fail"* ]]
    [[ "$output" == *"Another operation"* ]]
    [[ "$output" == *"[FAILED]"* ]]
}

# Test st.abort function
@test "st.abort exits with error" {
    run st.abort "Test abort message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"st.abort>"* ]]
    [[ "$output" == *"Test abort message"* ]]
}

# Test st.success function
@test "st.success outputs correct format" {
    run st.success "Deployment complete"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.success>"* ]]
    [[ "$output" == *"Deployment complete"* ]]
}

@test "st.success with default message" {
    run st.success

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.success>"* ]]
    [[ "$output" == *"[SUCCESS]"* ]]
}

# Test st.do function
@test "st.do executes command successfully" {
    run st.do echo "Hello World"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.do>"* ]]
    [[ "$output" == *"echo Hello World"* ]]
    [[ "$output" == *"Hello World"* ]]
}

@test "st.do shows command before executing" {
    run st.do true

    [[ "$output" == *"st.do>"* ]]
    [[ "$output" == *"true"* ]]
}

@test "st.do with multiple arguments" {
    run st.do echo "arg1" "arg2" "arg3"

    [ "$status" -eq 0 ]
    [[ "$output" == *"arg1 arg2 arg3"* ]]
}

# Test workflow integration
@test "Complete workflow: doing -> done" {
    output=$(st.doing "Test workflow" && st.done)

    [[ "$output" == *"Test workflow"* ]]
    [[ "$output" == *"Test workflow : [DONE]"* ]]
}

@test "Complete workflow: doing -> nothingTodo" {
    output=$(st.doing "Check something" && st.nothing)

    [[ "$output" == *"Check something"* ]]
    [[ "$output" == *"[NOTHING TO DO]"* ]]
}

@test "Complete workflow: doing -> skipped" {
    output=$(st.doing "Optional step" && st.skipped)

    [[ "$output" == *"Optional step"* ]]
    [[ "$output" == *"[SKIPPED]"* ]]
}

# Test with actual commands
@test "st.do with successful command shows output" {
    run st.do ls /tmp

    [ "$status" -eq 0 ]
}

@test "st.do with command that has options" {
    run st.do ls -la /tmp

    [ "$status" -eq 0 ]
    [[ "$output" == *"ls -la /tmp"* ]]
}

@test "st.do returns command exit code on failure" {
    run st.do false

    [ "$status" -eq 1 ]
}

@test "st.do returns command exit code on success" {
    run st.do true

    [ "$status" -eq 0 ]
}

@test "st.do passes through custom exit codes" {
    run st.do sh -c "exit 42"

    [ "$status" -eq 42 ]
}

# Edge cases
@test "st.h1 with empty string" {
    run st.h1 ""

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.h1>"* ]]
}

@test "st.doing with special characters" {
    run st.doing "Test with 'quotes' and \"double quotes\""

    [ "$status" -eq 0 ]
    [[ "$output" == *"quotes"* ]]
}

@test "st.done without prior st.doing" {
    unset DOING_MSG
    run st.done

    [ "$status" -eq 0 ]
    # Should handle gracefully even with empty DOING_MSG
}

@test "Multiple st.doing calls update DOING_MSG" {
    st.doing "First action"
    [ "$DOING_MSG" = "First action" ]

    st.doing "Second action"
    [ "$DOING_MSG" = "Second action" ]
}

# Test non-terminal output has no ANSI codes
@test "Non-terminal output is plain text" {
    # In Bats, output is piped so colors should be disabled
    output=$(st.h1 "Test" && st.doing "Action" && st.done)

    # Should not contain ANSI escape codes
    [[ ! "$output" =~ $'\033' ]]
}

# Performance test - functions should be fast
@test "st functions execute quickly" {
    start=$(date +%s%N)
    st.h1 "Test"
    st.h2 "Test"
    st.h3 "Test"
    st.doing "Test"
    st.done
    end=$(date +%s%N)

    # Should take less than 100ms (100000000 nanoseconds)
    elapsed=$((end - start))
    [ "$elapsed" -lt 100000000 ]
}

# Test st.quiet and st.unquiet functions
@test "st.quiet and st.unquiet toggle quiet mode" {
    source "$SCRIPT_DIR/st.bash"

    # Default should have prefix
    run st.h1 "Test"
    [[ "$output" == *"st.h1>"* ]]

    # After st.quiet, no prefix
    st.quiet
    run st.h1 "Test"
    [[ "$output" == "Test" ]]

    # After st.unquiet, prefix again
    st.unquiet
    run st.h1 "Test"
    [[ "$output" == *"st.h1>"* ]]
}

# Test ST_QUIET environment variable
@test "ST_QUIET disables st.h1 prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.h1 "Test Header"

    [ "$status" -eq 0 ]
    [[ "$output" == "Test Header" ]]
    [[ ! "$output" =~ "st.h1>" ]]
}

@test "ST_QUIET disables st.h2 prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.h2 "Test Header"

    [ "$status" -eq 0 ]
    [[ "$output" == "Test Header" ]]
    [[ ! "$output" =~ "st.h2>" ]]
}

@test "ST_QUIET disables st.h3 prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.h3 "Test Header"

    [ "$status" -eq 0 ]
    [[ "$output" == "Test Header" ]]
    [[ ! "$output" =~ "st.h3>" ]]
}

@test "ST_QUIET disables st.doing prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.doing "Test Action"

    [ "$status" -eq 0 ]
    [[ "$output" == "Test Action" ]]
    [[ ! "$output" =~ "st.doing>" ]]
}

@test "ST_QUIET disables st.done prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    DOING_MSG="Test Action"
    run st.done

    [ "$status" -eq 0 ]
    [[ "$output" == *"Test Action"* ]]
    [[ "$output" == *"[DONE]"* ]]
    [[ ! "$output" =~ "st.done>" ]]
}

@test "ST_QUIET disables st.success prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.success "Complete"

    [ "$status" -eq 0 ]
    [[ "$output" == "Complete" ]]
    [[ ! "$output" =~ "st.success>" ]]
}

@test "ST_QUIET disables st.nothing prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    DOING_MSG="Test Action"
    run st.nothing

    [ "$status" -eq 0 ]
    [[ "$output" == *"Test Action"* ]]
    [[ "$output" == *"[NOTHING TO DO]"* ]]
    [[ ! "$output" =~ "st.nothingtd>" ]]
}

@test "ST_QUIET disables st.skipped prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    DOING_MSG="Test Action"
    run st.skipped

    [ "$status" -eq 0 ]
    [[ "$output" == *"Test Action"* ]]
    [[ "$output" == *"[SKIPPED]"* ]]
    [[ ! "$output" =~ "st.skipped>" ]]
}

@test "ST_QUIET disables st.warn prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.warn "Warning message"

    [ "$status" -eq 0 ]
    [[ "$output" == "Warning message" ]]
    [[ ! "$output" =~ "st.warn>" ]]
}

@test "ST_QUIET disables st.fail prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    DOING_MSG="Test Action"
    run st.fail

    [ "$status" -eq 1 ]
    [[ "$output" == *"Test Action"* ]]
    [[ "$output" == *"[FAILED]"* ]]
    [[ ! "$output" =~ "st.fail" ]]
}

@test "ST_QUIET disables st.abort prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    DOING_MSG="Test Action"
    run st.abort

    [ "$status" -eq 1 ]
    [[ ! "$output" =~ "st.abort>" ]]
}

@test "ST_QUIET disables st.do prefix" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    run st.do echo "test"

    [ "$status" -eq 0 ]
    [[ "$output" == *"test"* ]]
    [[ ! "$output" =~ "st.do>" ]]
}

@test "ST_QUIET workflow: doing -> done" {
    source "$SCRIPT_DIR/st.bash"
    st.quiet
    output=$(st.doing "Build app" && st.done)

    [[ "$output" == *"Build app"* ]]
    [[ "$output" == *"[DONE]"* ]]
    [[ ! "$output" =~ "st.doing>" ]]
    [[ ! "$output" =~ "st.done>" ]]
}

@test "ST_QUIET can be toggled dynamically" {
    source "$SCRIPT_DIR/st.bash"

    # Start with ST_QUIET off (default)
    run st.h1 "First"
    [[ "$output" == *"st.h1>"* ]]

    # Toggle ST_QUIET on
    st.quiet
    run st.h1 "Second"
    [[ "$output" == "Second" ]]
    [[ ! "$output" =~ "st.h1>" ]]

    # Toggle ST_QUIET off again
    st.unquiet
    run st.h1 "Third"
    [[ "$output" == *"st.h1>"* ]]
}
