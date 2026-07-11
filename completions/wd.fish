# Completions for wd (warp directory)

function __wd_config_file
    if set -q WD_CONFIG
        echo $WD_CONFIG
    else
        echo $HOME/.warprc
    end
end

# List all stored warp point names (with their paths as description)
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

# Resolve the (expanded) path for a given warp point name
function __wd_point_path --argument-names name
    set -l config (__wd_config_file)
    test -f $config; or return 1
    while read -l line
        test -n "$line"; or continue
        set -l parts (string split -m1 ':' -- $line)
        if test "$parts[1]" = "$name"
            string replace -r '^~' $HOME $parts[2]
            return 0
        end
    end <$config
    return 1
end

# True when no subcommand / warp point has been given yet
function __wd_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# True when the given subcommand is the active one
function __wd_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = "$argv[1]"
end

# True when the second token is a valid warp point (so we can offer subdirs)
function __wd_has_point
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2; or return 1
    __wd_point_path $cmd[2] >/dev/null
end

# Complete subdirectories inside the active warp point
function __wd_subdirs
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; or return
    set -l base (__wd_point_path $cmd[2])
    test -n "$base"; and test -d $base; or return

    set -l token (commandline -ct)
    # Keep any leading directory part already typed (e.g. "foo/ba" -> "foo/")
    set -l dir (string replace -r '[^/]*$' '' -- $token)
    set -l scan $base
    test -n "$dir"; and set scan $base/$dir
    test -d $scan; or return

    for entry in (find $scan -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
        set -l rel (string replace -- $base/ '' $entry)
        printf '%s/\n' $rel
    end
end

# Disable default file completion
complete -c wd -f

# `wd <tab>` -> only list the stored warp points
complete -c wd -n __wd_needs_command -a '(__wd_points)' -d 'Warp point'

# `wd <point> <tab>` -> list subdirectories of that warp point
complete -c wd -n __wd_has_point -a '(__wd_subdirs)' -d 'Subdirectory'

# Warp point names for the point-taking subcommands
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
