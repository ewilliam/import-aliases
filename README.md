# import-aliases

Import bash aliases into fish shell functions.

## Requirements

- Fish shell 2.7+ (uses `argparse` and `string` builtins)

## Install

With [Fisher][Fisher]:

```
fisher install ewilliam/import-aliases
```

## Usage

```
import_aliases [-t | --test] [-h | --help] <file>
```

### Options

| Flag | Description |
|------|-------------|
| `-t`, `--test` | Dry run. Show what would be imported without making changes. |
| `-h`, `--help` | Show help message. |

### Examples

Preview what would be imported:

```fish
import_aliases --test ~/.bash_aliases
```

Import all aliases:

```fish
import_aliases ~/.bash_aliases
```

### Supported alias formats

The following bash alias formats are recognized:

```bash
alias ll='ls -la'          # single-quoted
alias gs="git status"      # double-quoted
alias cls=clear            # unquoted
alias My-Alias='echo hi'   # uppercase, hyphens, underscores, dots
```

Aliases that conflict with existing fish functions are skipped automatically.

## Testing

```fish
fish test/import_aliases.fish
```

## License

[MIT](http://opensource.org/licenses/MIT) &copy; [William Albright][Author]

[Author]: https://github.com/ewilliam
[Fisher]: https://github.com/jorgebucaran/fisher
