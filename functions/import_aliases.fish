function import_aliases
  if test -n "$argv"
    getopts $argv | while read key value
      for a in (cat $argv | grep "^alias")
        set aname (echo $a | grep -Eoe "[a-z0-9.]+=" | sed 's/=//')
        set acommand (echo $a | sed 's/^alias .*=//' \
                              | sed 's/^ *\'//' | sed 's/\' *$//')

        printf "Processing "
        print_status yellow $aname as $acommand

        if test -f ~/.config/fish/functions/$aname.fish
          print_status red $aname "is already defined. Skipped."

        else if test $key = "_"
          alias $aname $acommand
          funcsave $aname
          print_status green $aname "is defined."

        else if test $key = "t"
          print_status blue $aname "will be defined."

        else if test $key = "h"
          printf "usage: $_ [-t | --test] <file>\n"
          return

        else if test $key = \*
          printf "$_: '%s' is not a valid option.\n" $key
          return
        end
        echo
      end
    end

  else
    print_status red "Error:" "pick a file."
  end
end

function print_status -a color name message command
  set_color $color
  printf $name
  set_color normal
  printf " "
  printf $message
  if test -n $command
    printf " "
    set_color $color
    echo $command
    set_color normal
  end
end
