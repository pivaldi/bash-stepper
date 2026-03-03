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
    [[ "$output" == *"Doing « Test Action »…"* ]]
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
    [[ "$output" == *"Previous action : DONE"* ]]
}

@test "st.done outputs custom message" {
    DOING_MSG="Custom action"
    run st.done "COMPLETED"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Custom action : COMPLETED"* ]]
}


# Test st.nothingTodo function
@test "st.nothingTodo outputs correct format" {
    run st.nothingTodo

    [ "$status" -eq 0 ]
    [[ "$output" == *"nothingtd>"* ]]
    [[ "$output" == *"Nothing to do"* ]]
}

# Test st.skipped function
@test "st.skipped outputs correct format" {
    DOING_MSG="Skipped action"
    run st.skipped

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.skiped>"* ]]
    [[ "$output" == *"Skipped action"* ]]
    [[ "$output" == *"SKIPPED"* ]]
}

# Test st.warn function
@test "st.warn outputs correct format" {
    DOING_MSG="Warning test"
    run st.warn "This is a warning"

    [ "$status" -eq 0 ]
    [[ "$output" == *"st.warn>"* ]]
    [[ "$output" == *"Warning test"* ]]
    [[ "$output" == *"This is a warning"* ]]
}

# Test st.fail function
@test "st.fail outputs error and exits with non-zero" {
    run st.fail "Test failure message"

    [ "$status" -eq 1 ]
    [[ "$output" == *"st.fail>"* ]]
    [[ "$output" == *"Test failure message"* ]]
    [[ "$output" == *"PROCESS ABORTED"* ]]
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

    [[ "$output" == *"Doing « Test workflow »…"* ]]
    [[ "$output" == *"Test workflow : DONE"* ]]
}

@test "Complete workflow: doing -> nothingTodo" {
    output=$(st.doing "Check something" && st.nothingTodo)

    [[ "$output" == *"Doing « Check something »…"* ]]
    [[ "$output" == *"Nothing to do"* ]]
}

@test "Complete workflow: doing -> skipped" {
    output=$(st.doing "Optional step" && st.skipped)

    [[ "$output" == *"Doing « Optional step »…"* ]]
    [[ "$output" == *"SKIPPED"* ]]
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
