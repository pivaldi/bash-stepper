# Bash Stepper

A lightweight Bash library for creating beautiful, structured output in shell scripts with automatic terminal detection.

**Note**: [stream-stepper](https://github.com/pivaldi/stream-stepper), a Go implementation with streaming and progress-bar, has a processor supporting this lib.

## Features

- **Hierarchical Headers** - Three levels of headers (h1, h2, h3) with bold formatting
- **Progress Indicators** - Track ongoing operations with `doing`/`done` workflow
- **Status Messages** - Built-in support for success, warnings, failures, and skipped operations
- **Command Execution** - Execute and display commands with `st.do`
- **Automatic Terminal Detection** - Colors automatically disabled in non-terminal contexts
- **Zero Configuration** - Works out of the box, no environment variables needed

## Installation

### Option 1: Direct Download

```bash
curl -O https://raw.githubusercontent.com/yourusername/bash-stepper/main/st.bash
chmod +x st.bash
```

### Option 2: Git Submodule

```bash
git submodule add https://github.com/yourusername/bash-stepper.git lib/bash-stepper
```

### Option 3: Copy to Your Project

```bash
cp st.bash /path/to/your/project/libs/
```

## Quick Start

```bash
#!/usr/bin/env bash
source ./st.bash

st.h1 "Starting Deployment"

st.doing "Building application"
st.do ./build.sh
st.done

st.doing "Running tests"
st.do ./test.sh
st.done "TESTS PASSED"

st.success "Deployment complete!"
```

**Output (in terminal):**
```
st.h1> Starting Deployment

st.doing> Building application

st.done> Building application : [DONE]

st.doing> Running tests

st.done> Running tests : TESTS PASSED

st.success> Deployment complete!
```
*(In terminal, headers and text will appear in bold with colors)*

**Output (piped or in logs):**
```
st.h1> Starting Deployment

st.doing> Building application

st.done> Building application : [DONE]

st.doing> Running tests

st.done> Running tests : TESTS PASSED

st.success> Deployment complete!
```
*(No colors or formatting codes in piped output)*

## API Reference

### Headers

Display hierarchical section headers with bold formatting:

```bash
st.h1 "Main Section"     # Top-level header
st.h2 "Subsection"       # Second-level header
st.h3 "Detail"           # Third-level header
```

### Progress Tracking

Track the progress of operations:

```bash
st.doing "Connecting to database"   # Start an operation
# ... do work ...
st.done                              # Mark as complete (uses "[DONE]")
st.done "CONNECTED"                  # Mark as complete with custom message
st.success                           # Success message (uses "[SUCCESS]")
st.success "Deployment complete"     # Custom success message
```

### Status Messages

Communicate different outcomes:

```bash
st.nothing                       # Indicate no action needed (uses "[NOTHING TO DO]")
st.nothing "Already configured"  # Custom message
st.skipped                           # Mark operation as skipped (uses "[SKIPPED]")
st.skipped "Not applicable"          # Custom message
st.warn "Deprecation warning"        # Display a warning (standalone)
st.fail                              # Display error (uses "[FAILED]"), returns false
st.fail "Connection failed"          # Custom error message, returns false
st.abort                             # Abort with error (uses "[ABORTED]"), exits with code 1
st.abort "Critical error"            # Custom abort message, exits with code 1
```

### Command Execution

Execute commands with output display:

```bash
st.do npm install                    # Shows command before executing
st.do docker build -t myapp .        # Handles multi-argument commands
# Note: st.do just executes the command, check $? for success/failure
```

### Helper Functions

Utility functions for common checks:

```bash
st.cmd.exists docker                 # Returns 0 if command exists, 1 otherwise
st.var.exists MY_VAR                 # Returns 0 if variable is set and non-empty, 1 otherwise

# Use in conditionals
if st.cmd.exists docker; then
    st.success "Docker is installed"
else
    st.fail "Docker not found"
fi

if st.var.exists DATABASE_URL; then
    st.done "DATABASE_URL is configured"
else
    st.warn "DATABASE_URL not set"
fi
```

## Workflow Patterns

### Basic Workflow

```bash
st.h1 "Setup Process"

st.doing "Installing dependencies"
st.do npm install && st.done || st.fail
st.doing "Configuring environment"
st.do cp .env.example .env && st.done "CONFIGURED" || st.fail
```

### Conditional Operations

```bash
st.doing "Checking prerequisites"
if command -v docker &>/dev/null; then
    st.done "FOUND"
else
    st.fail "Docker not installed"
    exit 1  # Exit if this is critical
fi
```

### Nothing to Do

```bash
st.doing "Updating configuration"
if [ -f .env ]; then
    st.nothing
else
    st.do cp .env.example .env
    st.done
fi
```

### Skipped Operations

```bash
st.doing "Running optional optimization"
if [ "$SKIP_OPTIMIZATION" = "1" ]; then
    st.skipped
else
    st.do ./optimize.sh
    st.done
fi
```

### Using st.do

```bash
st.h1 "Build Process"

st.doing "Compiling application"
st.do go build -o app ./cmd/app
st.done

st.doing "Running tests"
st.do go test ./...
st.done
```

## Terminal Detection

The library automatically detects whether output is going to a terminal or being piped/redirected:

- **Terminal output** (stdout is a TTY): Colors and bold formatting enabled
- **Piped/redirected output**: Colors and formatting disabled automatically

This means:
- ✅ `./script.sh` - Colorized with bold formatting
- ✅ `./script.sh | tee log.txt` - Plain text, no ANSI codes
- ✅ `./script.sh > output.log` - Plain text, no ANSI codes
- ✅ Works perfectly in CI/CD environments

No configuration needed - it just works!

## Quiet Mode

Use the `st.quiet` and `st.unquiet` functions to **dynamically toggle prefix visibility** during script execution:

```bash
#!/usr/bin/env bash
source ./st.bash

# With prefixes (normal mode)
st.h1 "Deployment Pipeline"
st.doing "Setup root project"
st.do mise run setup
st.done
# Output:
# st.h1> Deployment Pipeline
# st.doing> Setup root project
# st.do> mise run setup
# st.done> Setup root project : [DONE]

# Without prefixes (quiet mode)
st.quiet
st.doing "Install/Update tools"
st.do mise run tools:update
st.done
# Output:
# Install/Update tools
# mise run tools:update
# Install/Update tools : [DONE]

# Back to normal mode
st.unquiet
st.doing "Running tests"
st.do npm test
st.done
# Output:
# st.doing> Running tests
# st.do> npm test
# st.done> Running tests : [DONE]
```

**Dynamic toggling during execution:**

```bash
#!/usr/bin/env bash
source ./st.bash

# Show section headers with prefixes
st.h1 "Data Processing Pipeline"

# Run detailed setup steps with prefixes
st.doing "Validating prerequisites"
st.do ./validate.sh
st.done

# Run the main processing quietly (cleaner output for logs)
st.quiet
st.doing "Processing 10,000 records"
st.do ./process.sh
st.done

# Show final results with prefixes
st.unquiet
st.success "Pipeline complete! 🚀"
```

**Setting quiet mode via environment variable:**

You can also enable quiet mode globally by setting `ST_QUIET=true` before sourcing the library:

```bash
#!/usr/bin/env bash
ST_QUIET=true source ./st.bash

st.h1 "Deployment"
st.doing "Building"
st.done
# Output (no prefixes):
# Deployment
# Building
# Building : [DONE]

# You can still toggle dynamically even when initialized via environment
st.unquiet
st.success "Complete!"
# Output:
# st.success> Complete!
```

Or pass it when executing a script:

```bash
# Run entire script in quiet mode
ST_QUIET=true ./my-script.sh
```

**Use cases for quiet mode:**
- Toggle quiet mode for different script sections
- Show important steps with prefixes, hide verbose ones without
- Cleaner output for end-user facing scripts
- Integration with other logging systems
- Generating clean output for reports or documentation
- Run entire scripts in quiet mode via environment variable

## Testing

The library includes a comprehensive test suite:

```bash
# Run standalone test suite (no dependencies)
./test-st.sh

# Run Bats test suite (requires bats)
bats st_test.bats
```

Both test suites include comprehensive coverage:
- **test-st.sh**: 49 tests covering all functions, helpers, ST_QUIET mode, dynamic toggling, and workflows
- **st_test.bats**: 56 tests including performance, helper functions, ST_QUIET mode, dynamic toggling, and edge cases

## Design Philosophy

### Simple and Focused

Bash Stepper does one thing well: structured output. No dependencies, no complex configuration, just source and use.

### Automatic Behavior

Terminal detection using `[ -t 1 ]` means:
- Scripts work correctly in any environment
- No manual color/formatting management
- Clean logs without ANSI escape codes when piped

### Fail-Fast

`st.fail` returns false (exit code 1) but doesn't exit the script - you control whether to continue or exit. Use `st.abort` when you need to exit immediately. The `st.do` command executes commands and returns their exit code - check `$?` to handle failures appropriately.

## Real-World Example

```bash
#!/usr/bin/env bash
set -euo pipefail

source ./st.bash

st.h1 "Application Deployment"

st.h2 "Pre-flight Checks"

st.doing "Verifying Docker installation"
if ! command -v docker &>/dev/null; then
    st.fail "Docker is not installed"
    exit 1
fi
st.done

st.doing "Checking disk space"
available=$(df / | tail -1 | awk '{print $4}')
if [ "$available" -lt 1000000 ]; then
    st.warn "Low disk space: ${available}KB available"
else
    st.done
fi

st.h2 "Building Application"

st.doing "Building Docker image"
st.do docker build -t myapp:latest .
st.done

st.doing "Tagging image"
st.do docker tag myapp:latest myapp:v1.0.0
st.done

st.h2 "Deployment"

st.doing "Pushing to registry"
st.do docker push myapp:v1.0.0
st.done

st.success "Deployment Complete! 🚀"
```

## Requirements

- Bash 4.0 or later
- `tput` command (usually available by default)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `./test-st.sh`
5. Submit a pull request

## Testing Your Changes

```bash
# Run the test suite
./test-st.sh

# Run specific test frameworks
bats st_test.bats           # If you have Bats installed
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2026 Philippe Ivaldi

## Related Projects

- [stream-stepper](https://github.com/pivaldi/stream-stepper) - Go implementation with streaming support

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Made with ❤️ for better Bash scripts**
