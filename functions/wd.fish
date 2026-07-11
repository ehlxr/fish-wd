# wd — warp directory for fish
# ==============================
# Jump to custom directories in the terminal, because `cd` takes too long.
#
# A fish port of the zsh plugin: https://github.com/mfaerevaag/wd

set -g WD_VERSION 1.0.0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function _wd_config_file
    if set -q WD_CONFIG
        echo $WD_CONFIG
    else
        echo $HOME/.warprc
    end
end

function _wd_msg --argument-names color msg
    if set -q _wd_quiet
        return
    end
    set_color $color
    printf ' * '
    set_color normal
    printf '%s\n' $msg
end

function _wd_err --argument-names msg
    _wd_msg red $msg
    set -g _wd_exit_code 1
end

function _wd_warn --argument-names msg
    _wd_msg yellow $msg
    set -g _wd_exit_code 1
end

# Collapse a leading $HOME into ~
function _wd_tildify --argument-names path
    string replace -- $HOME '~' $path
end

# Expand a leading ~ into $HOME
function _wd_untildify --argument-names path
    string replace -r -- '^~' $HOME $path
end

# Look up the stored path for a warp point. Prints the (tildified) path and
# returns 0 on success, returns 1 if the point does not exist.
function _wd_lookup --argument-names name
    set -l config (_wd_config_file)
    test -f $config; or return 1
    while read -l line
        test -n "$line"; or continue
        set -l parts (string split -m1 ':' -- $line)
        if test "$parts[1]" = "$name"
            echo $parts[2]
            return 0
        end
    end <$config
    return 1
end

function _wd_print_usage
    printf 'Usage: wd [command] [point]\n\n'
    printf 'Commands:\n'
    printf '    <point>              Warps to the directory specified by the warp point\n'
    printf '    <point> <path>       Warps to the warp point, with a path appended\n'
    printf '    add <point>          Adds the current working directory as <point>\n'
    printf "    add                  Adds the current working directory (using its name)\n"
    printf "    addcd <path>         Adds <path> using the directory's name\n"
    printf '    addcd <path> <point> Adds <path> as <point>\n'
    printf '    rm <point>           Removes the given warp point\n'
    printf "    rm                   Removes the warp point named after the current dir\n"
    printf '    show <point>         Print path to given warp point\n'
    printf '    show                 Print warp points to current directory\n'
    printf '    list                 Print all stored warp points\n'
    printf '    ls <point>           Show files from given warp point (ls)\n'
    printf '    open <point>         Open the warp point in the file explorer\n'
    printf '    path <point>         Show the path to given warp point\n'
    printf '    clean                Remove points warping to nonexistent directories\n\n'
    printf '    -v | --version       Print version\n'
    printf '    -c | --config <file> Specify config file (default ~/.warprc)\n'
    printf '    -q | --quiet         Suppress all output\n'
    printf '    -f | --force         Allow overwriting without warning (add & clean)\n\n'
    printf '    help                 Show this extremely helpful text\n'
end

# ---------------------------------------------------------------------------
# Core commands
# ---------------------------------------------------------------------------

function _wd_warp --argument-names point sub
    # Dot syntax: `wd ..` -> up one level, `wd ...` -> up two, etc.
    if string match -qr '^\.+$' -- $point
        set -l dots (string length -- $point)
        if test $dots -lt 2
            _wd_warn "Warping to current directory?"
            return
        end
        set -l n (math $dots - 1)
        set -l target
        for i in (seq $n)
            set target "$target../"
        end
        cd $target
        set -g _wd_exit_code $status
        return
    end

    set -l dir (_wd_lookup $point)
    if test $status -ne 0
        _wd_err "Unknown warp point '$point'"
        return
    end

    set dir (_wd_untildify $dir)
    if test -n "$sub"
        cd $dir/$sub
    else
        cd $dir
    end
    set -g _wd_exit_code $status
end

function _wd_add --argument-names point force
    set -l config (_wd_config_file)

    if test -z "$point"
        set point (basename "$PWD")
    end

    if not test -w $config
        _wd_err "'$config' is not writeable."
        return
    end

    set -l reserved add addcd rm show list ls path clean help open browse

    if string match -qr '^\.+$' -- $point
        _wd_err "Warp point cannot be just dots"
    else if string match -qr '\s' -- $point
        _wd_err "Warp point should not contain whitespace"
    else if string match -q '*:*' -- $point; or string match -q '*/*' -- $point
        _wd_err "Warp point contains illegal character (:/)"
    else if contains -- $point $reserved
        _wd_err "Warp point name cannot be a wd command (see wd help)"
    else if _wd_lookup $point >/dev/null; and test -z "$force"
        _wd_warn "Warp point '$point' already exists. Use 'add --force' to overwrite."
    else
        # Remove any existing entry, then append the fresh one.
        _wd_remove $point >/dev/null 2>&1
        printf '%s:%s\n' $point (_wd_tildify "$PWD") >>$config
        if command -q sort
            set -l tmp (mktemp)
            sort -o $tmp $config; and command cp $tmp $config; and command rm $tmp
        end
        _wd_msg green "Warp point added"
        set -g _wd_exit_code 0
    end
end

function _wd_addcd --argument-names folder point force
    if test -z "$folder"
        _wd_err "You must specify a path"
        return
    end
    if not test -d $folder
        _wd_err "The directory does not exist"
        return
    end
    set -l current $PWD
    cd $folder; or return
    _wd_add "$point" "$force"
    cd $current
end

function _wd_remove
    set -l config (_wd_config_file)
    set -l points $argv

    if test (count $points) -eq 0
        set points (basename "$PWD")
    end

    if not test -w $config
        _wd_err "'$config' is not writeable."
        return
    end

    for name in $points
        if _wd_lookup $name >/dev/null
            set -l tmp (mktemp)
            set -l pattern '^'(string escape --style=regex -- $name)':'
            # `string match -rv` returns non-zero when nothing is left to
            # print (e.g. removing the last entry), so ignore its status and
            # rely on the copy succeeding instead.
            string match -rv -- $pattern <$config >$tmp
            if command cp $tmp $config
                command rm $tmp
                _wd_msg green "Warp point removed"
            else
                command rm -f $tmp
                _wd_err "Something bad happened! Sorry."
            end
        else
            _wd_err "Warp point was not found"
        end
    end
end

function _wd_list
    set -l config (_wd_config_file)
    _wd_msg blue "All warp points:"
    test -f $config; or return

    set -l max 0
    while read -l line
        test -n "$line"; or continue
        set -l key (string split -m1 ':' -- $line)[1]
        set -l len (string length -- $key)
        test $len -gt $max; and set max $len
    end <$config

    if set -q _wd_quiet
        return
    end

    while read -l line
        test -n "$line"; or continue
        set -l parts (string split -m1 ':' -- $line)
        printf '%*s  ->  %s\n' $max $parts[1] $parts[2]
    end <$config
end

function _wd_getdir --argument-names name
    if test -z "$name"
        _wd_err "You must enter a warp point"
        return 1
    end
    set -l dir (_wd_lookup $name)
    if test $status -ne 0
        _wd_err "Unknown warp point '$name'"
        return 1
    end
    _wd_untildify $dir
end

function _wd_ls --argument-names name
    set -l dir (_wd_getdir $name); or return
    ls $dir
end

function _wd_path --argument-names name
    set -l dir (_wd_getdir $name); or return
    echo $dir
end

function _wd_open --argument-names name
    set -l dir (_wd_getdir $name); or return
    if command -q open
        open $dir
    else if command -q xdg-open
        xdg-open $dir
    else
        _wd_err "No known file opener found (need 'open' or 'xdg-open')."
    end
end

function _wd_show --argument-names name
    set -l config (_wd_config_file)
    if test -n "$name"
        set -l dir (_wd_lookup $name)
        if test $status -ne 0
            _wd_msg blue "No warp point named $name"
        else
            _wd_msg green "Warp point: $name -> $dir"
        end
        return
    end

    # Reverse lookup: which points map to the current directory?
    set -l here (_wd_tildify "$PWD")
    set -l matches
    if test -f $config
        while read -l line
            test -n "$line"; or continue
            set -l parts (string split -m1 ':' -- $line)
            if test "$parts[2]" = "$here"
                set -a matches $parts[1]
            end
        end <$config
    end

    if test (count $matches) -gt 0
        _wd_msg blue (count $matches)" warp point(s) to current directory: $matches"
    else
        _wd_warn "No warp point to $here"
    end
end

function _wd_clean --argument-names force
    set -l config (_wd_config_file)

    if not test -w $config
        _wd_err "'$config' is not writeable."
        return
    end

    set -l keep
    set -l count 0
    while read -l line
        test -n "$line"; or continue
        set -l parts (string split -m1 ':' -- $line)
        set -l dir (_wd_untildify $parts[2])
        if test -d $dir
            set -a keep $line
        else
            _wd_warn "Nonexistent directory: $parts[1] -> $parts[2]"
            set count (math $count + 1)
        end
    end <$config

    if test $count -eq 0
        _wd_msg blue "No warp points to clean, carry on!"
        return
    end

    set -l proceed 0
    if test -n "$force"
        set proceed 1
    else
        read -l -P "Removing $count warp points. Continue? (y/n) " answer
        if string match -qir '^y' -- $answer
            set proceed 1
        end
    end

    if test $proceed -eq 1
        printf '%s\n' $keep >$config
        _wd_msg green "Cleanup complete. $count warp point(s) removed"
    else
        _wd_msg blue "Cleanup aborted"
    end
end

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

function wd --description "Warp directory: jump to custom directories"
    set -l _wd_exit_code 0
    set -e _wd_quiet

    argparse -i c/config= q/quiet v/version f/force h/help -- $argv
    or return 1

    if set -q _flag_config
        set -gx WD_CONFIG $_flag_config
    end
    if set -q _flag_quiet
        set -g _wd_quiet 1
    end

    set -l force
    if set -q _flag_force
        set force 1
    end

    if set -q _flag_version
        echo "wd version $WD_VERSION"
        if test (count $argv) -eq 0
            return 0
        end
    end

    if set -q _flag_help
        _wd_print_usage
        return 0
    end

    if test (count $argv) -eq 0
        _wd_print_usage
        set -e _wd_quiet
        return 1
    end

    # Ensure the config file exists.
    set -l config (_wd_config_file)
    test -e $config; or touch $config

    set -l cmd $argv[1]
    switch $cmd
        case add
            _wd_add "$argv[2]" "$force"
        case addcd
            _wd_addcd "$argv[2]" "$argv[3]" "$force"
        case rm
            _wd_remove $argv[2..-1]
        case list ls-all
            _wd_list
        case ls
            _wd_ls "$argv[2]"
        case open
            _wd_open "$argv[2]"
        case path
            _wd_path "$argv[2]"
        case show
            _wd_show "$argv[2]"
        case clean
            _wd_clean "$force"
        case help
            _wd_print_usage
        case '*'
            _wd_warp "$argv[1]" "$argv[2]"
    end

    set -l rc $_wd_exit_code
    set -e _wd_quiet
    return $rc
end
