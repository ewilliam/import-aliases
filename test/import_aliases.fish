# Tests for import_aliases
# Run with: fish test/import_aliases.fish
# Requires: Fish 2.7+ (for argparse support)

# --- Test helpers ---

set -g test_pass 0
set -g test_fail 0
set -g test_total 0

function test_setup
    # Create a temporary directory for test fixtures
    set -g test_tmpdir (mktemp -d)
    set -g test_functions_backup "$test_tmpdir/functions_backup"
    mkdir -p "$test_functions_backup"
end

function test_teardown
    # Clean up temporary files
    if test -d "$test_tmpdir"
        command rm -rf "$test_tmpdir"
    end
end

function assert_equal -a expected actual description
    set -g test_total (math $test_total + 1)
    if test "$expected" = "$actual"
        set -g test_pass (math $test_pass + 1)
        echo "  PASS: $description"
    else
        set -g test_fail (math $test_fail + 1)
        echo "  FAIL: $description"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
    end
end

function assert_success -a description
    set -g test_total (math $test_total + 1)
    if test $status -eq 0
        set -g test_pass (math $test_pass + 1)
        echo "  PASS: $description"
    else
        set -g test_fail (math $test_fail + 1)
        echo "  FAIL: $description (expected success, got status $status)"
    end
end

function assert_fail -a description
    set -g test_total (math $test_total + 1)
    if test $status -ne 0
        set -g test_pass (math $test_pass + 1)
        echo "  PASS: $description"
    else
        set -g test_fail (math $test_fail + 1)
        echo "  FAIL: $description (expected failure, got status 0)"
    end
end

function assert_contains -a needle haystack description
    set -g test_total (math $test_total + 1)
    if string match -q -- "*$needle*" "$haystack"
        set -g test_pass (math $test_pass + 1)
        echo "  PASS: $description"
    else
        set -g test_fail (math $test_fail + 1)
        echo "  FAIL: $description"
        echo "    expected to contain: '$needle'"
        echo "    actual: '$haystack'"
    end
end

# --- Source the function under test ---

set script_dir (status dirname)
source "$script_dir/../functions/import_aliases.fish"

# --- Tests ---

echo "=== import_aliases tests ==="
echo ""

# Test: --help flag
echo "Test: --help shows usage"
test_setup
set output (import_aliases --help 2>&1)
set exit_code $status
assert_equal 0 $exit_code "--help returns 0"
assert_contains "Usage:" "$output" "--help output contains Usage:"
assert_contains "--test" "$output" "--help output mentions --test flag"
test_teardown

# Test: -h flag
echo ""
echo "Test: -h shows usage"
test_setup
set output (import_aliases -h 2>&1)
set exit_code $status
assert_equal 0 $exit_code "-h returns 0"
assert_contains "Usage:" "$output" "-h output contains Usage:"
test_teardown

# Test: no arguments
echo ""
echo "Test: no arguments shows error"
test_setup
set output (import_aliases 2>&1)
set exit_code $status
assert_equal 1 $exit_code "no args returns 1"
assert_contains "no file specified" "$output" "error message mentions no file"
test_teardown

# Test: nonexistent file
echo ""
echo "Test: nonexistent file shows error"
test_setup
set output (import_aliases /tmp/nonexistent_file_12345 2>&1)
set exit_code $status
assert_equal 1 $exit_code "nonexistent file returns 1"
assert_contains "not found" "$output" "error mentions file not found"
test_teardown

# Test: dry run with single-quoted alias
echo ""
echo "Test: dry run with single-quoted alias"
test_setup
echo "alias ll='ls -la'" > "$test_tmpdir/aliases.txt"
set output (import_aliases --test "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "dry run returns 0"
assert_contains "ll" "$output" "output contains alias name"
assert_contains "dry run" "$output" "output mentions dry run"
test_teardown

# Test: dry run with double-quoted alias
echo ""
echo "Test: dry run with double-quoted alias"
test_setup
echo 'alias gs="git status"' > "$test_tmpdir/aliases.txt"
set output (import_aliases -t "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "dry run with double-quoted alias returns 0"
assert_contains "gs" "$output" "output contains alias name 'gs'"
assert_contains "git status" "$output" "output contains command 'git status'"
test_teardown

# Test: dry run with unquoted alias
echo ""
echo "Test: dry run with unquoted alias"
test_setup
echo "alias cls=clear" > "$test_tmpdir/aliases.txt"
set output (import_aliases -t "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "dry run with unquoted alias returns 0"
assert_contains "cls" "$output" "output contains alias name 'cls'"
assert_contains "clear" "$output" "output contains command 'clear'"
test_teardown

# Test: alias name with uppercase, hyphens, underscores
echo ""
echo "Test: alias names with uppercase, hyphens, underscores"
test_setup
printf "alias My-Alias='echo hello'\nalias my_alias2='echo world'\nalias ABC.123='echo test'\n" > "$test_tmpdir/aliases.txt"
set output (import_aliases -t "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "complex alias names return 0"
assert_contains "My-Alias" "$output" "output contains 'My-Alias'"
assert_contains "my_alias2" "$output" "output contains 'my_alias2'"
assert_contains "ABC.123" "$output" "output contains 'ABC.123'"
test_teardown

# Test: mixed file with comments and blank lines
echo ""
echo "Test: file with comments, blank lines, and non-alias lines"
test_setup
printf "# This is a comment\n\nexport FOO=bar\nalias ll='ls -la'\n# another comment\nalias gs='git status'\n" > "$test_tmpdir/aliases.txt"
set output (import_aliases -t "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "mixed file returns 0"
assert_contains "ll" "$output" "output contains alias 'll'"
assert_contains "gs" "$output" "output contains alias 'gs'"
test_teardown

# Test: invalid option
echo ""
echo "Test: invalid option"
test_setup
echo "alias ll='ls -la'" > "$test_tmpdir/aliases.txt"
set output (import_aliases --invalid "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 1 $exit_code "invalid option returns 1"
test_teardown

# Test: empty file
echo ""
echo "Test: empty file"
test_setup
touch "$test_tmpdir/empty.txt"
set output (import_aliases -t "$test_tmpdir/empty.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "empty file returns 0"
assert_contains "Dry run complete" "$output" "output mentions dry run complete"
test_teardown

# Test: leading whitespace on alias lines
echo ""
echo "Test: alias with leading whitespace"
test_setup
echo "  alias ll='ls -la'" > "$test_tmpdir/aliases.txt"
set output (import_aliases -t "$test_tmpdir/aliases.txt" 2>&1)
set exit_code $status
assert_equal 0 $exit_code "indented alias returns 0"
assert_contains "ll" "$output" "output contains alias 'll'"
test_teardown

# --- Summary ---
echo ""
echo "==========================="
echo "Results: $test_pass/$test_total passed, $test_fail failed"
echo "==========================="

if test $test_fail -gt 0
    exit 1
end
exit 0
