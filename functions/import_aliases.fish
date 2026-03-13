function import_aliases -d "Import bash aliases into fish shell functions"
    # Parse arguments using Fish's built-in argparse (replaces getopts dependency)
    argparse --name=import_aliases 't/test' 'h/help' -- $argv
    or return 1

    # Handle --help / -h
    if set -q _flag_help
        echo "Usage: import_aliases [-t | --test] <file>"
        echo ""
        echo "Import bash-style aliases from a file into persistent fish shell functions."
        echo ""
        echo "Options:"
        echo "  -t, --test    Dry run. Show what would be imported without making changes."
        echo "  -h, --help    Show this help message."
        return 0
    end

    # Validate that a file argument was provided
    if test (count $argv) -eq 0
        __import_aliases_status red "Error:" "no file specified."
        echo "Usage: import_aliases [-t | --test] <file>" >&2
        return 1
    end

    set -l filepath $argv[1]

    # Validate the file exists and is readable
    if not test -f "$filepath"
        __import_aliases_status red "Error:" "file '$filepath' not found."
        return 1
    end

    if not test -r "$filepath"
        __import_aliases_status red "Error:" "file '$filepath' is not readable."
        return 1
    end

    set -l imported 0
    set -l skipped 0
    set -l failed 0

    # Read lines starting with 'alias' from the file
    for line in (string match --regex '^\s*alias\s+.*' < "$filepath")
        # Extract alias name: supports letters, digits, hyphens, underscores, dots
        set -l aname (string match --regex --groups-only '^\s*alias\s+([A-Za-z0-9._-]+)=' "$line")
        if test -z "$aname"
            __import_aliases_status yellow "Warning:" "could not parse alias name from: $line"
            set failed (math $failed + 1)
            echo
            continue
        end

        # Extract alias command: handles single-quoted, double-quoted, and unquoted values
        # First, get everything after 'alias name='
        set -l raw_value (string replace --regex '^\s*alias\s+[A-Za-z0-9._-]+=' '' "$line")

        # Strip surrounding quotes (single or double) if present
        set -l acommand (string match --regex --groups-only '^[\'"](.+)[\'"]$' "$raw_value")
        if test -z "$acommand"
            # No surrounding quotes — use the raw value, trimmed
            set acommand (string trim "$raw_value")
        end

        # Skip empty commands
        if test -z "$acommand"
            __import_aliases_status yellow "Warning:" "empty command for alias '$aname'. Skipped."
            set failed (math $failed + 1)
            echo
            continue
        end

        printf "Processing "
        __import_aliases_status yellow "$aname" "as" "$acommand"

        if test -f ~/.config/fish/functions/$aname.fish
            __import_aliases_status red "$aname" "is already defined. Skipped."
            set skipped (math $skipped + 1)

        else if set -q _flag_test
            __import_aliases_status blue "$aname" "will be defined. (dry run)"

        else
            # Create and persist the alias
            if alias "$aname" "$acommand" 2>/dev/null
                if funcsave "$aname" 2>/dev/null
                    __import_aliases_status green "$aname" "is defined."
                    set imported (math $imported + 1)
                else
                    __import_aliases_status red "$aname" "alias created but funcsave failed."
                    set failed (math $failed + 1)
                end
            else
                __import_aliases_status red "$aname" "failed to create alias."
                set failed (math $failed + 1)
            end
        end
        echo
    end

    # Print summary
    echo "---"
    if set -q _flag_test
        echo "Dry run complete. No changes were made."
    else
        echo "Imported: $imported | Skipped: $skipped | Failed: $failed"
    end

    # Return non-zero if any failures occurred
    if test $failed -gt 0
        return 1
    end
    return 0
end

# Helper function for colored status output.
# Prefixed with __ to indicate it's a private helper (Fish convention).
function __import_aliases_status -a color name message command
    set_color $color
    printf "%s" $name
    set_color normal
    printf " "
    printf "%s" $message
    if test -n "$command"
        printf " "
        set_color $color
        printf "%s\n" $command
        set_color normal
    end
end
