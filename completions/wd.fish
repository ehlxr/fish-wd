# Completions for wd (warp directory)

function __wd_config_file
    if set -q WD_CONFIG
        echo $WD_CONFIG
    else
        echo $HOME/.warprc
    end
end

# List all stored warp point names
function __wd_points
    set -l config (__wd_config_file)
    test -f $config; or return
    while read -l line
        test -n "$line"; or continue
        set -l parts (string split -m1 ':' -- $line)
        set -l path (string replace -r '^~' $HOME $parts[2])
        printf '%s\t%s\n' $parts[1] $path
    end <$config
end

# True when no subcommand has been given yet
function __wd_needs_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

# True when the given subcommand is the active one
function __wd_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = "$argv[1]"
end

complete -c wd -f

# Subcommands
complete -c wd -n __wd_needs_command -a add -d 'Add current directory as a warp point'
complete -c wd -n __wd_needs_command -a addcd -d 'Add a given path as a warp point'
complete -c wd -n __wd_needs_command -a rm -d 'Remove a warp point'
complete -c wd -n __wd_needs_command -a show -d 'Show warp point(s)'
complete -c wd -n __wd_needs_command -a list -d 'List all warp points'
complete -c wd -n __wd_needs_command -a ls -d 'List files in a warp point'
complete -c wd -n __wd_needs_command -a path -d 'Print path of a warp point'
complete -c wd -n __wd_needs_command -a open -d 'Open a warp point in the file explorer'
complete -c wd -n __wd_needs_command -a clean -d 'Remove points to nonexistent directories'
complete -c wd -n __wd_needs_command -a help -d 'Show help'

# Warp point names as first argument (and for commands that take a point)
complete -c wd -n __wd_needs_command -a '(__wd_points)' -d 'Warp point'
complete -c wd -n '__wd_using_command rm' -a '(__wd_points)' -d 'Warp point'
complete -c wd -n '__wd_using_command show' -a '(__wd_points)' -d 'Warp point'
complete -c wd -n '__wd_using_command ls' -a '(__wd_points)' -d 'Warp point'
complete -c wd -n '__wd_using_command path' -a '(__wd_points)' -d 'Warp point'
complete -c wd -n '__wd_using_command open' -a '(__wd_points)' -d 'Warp point'

# Global options
complete -c wd -s v -l version -d 'Print version'
complete -c wd -s q -l quiet -d 'Suppress all output'
complete -c wd -s f -l force -d 'Allow overwriting without warning'
complete -c wd -s h -l help -d 'Show help'
complete -c wd -s c -l config -r -d 'Specify config file'
