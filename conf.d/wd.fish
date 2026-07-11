# wd default configuration
#
# WD_CONFIG defines the path where warp points get stored.
# Defaults to $HOME/.warprc. Uncomment and edit to override globally.
#
# set -gx WD_CONFIG $HOME/.warprc

if not set -q WD_CONFIG
    set -gx WD_CONFIG $HOME/.warprc
end
