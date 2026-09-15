set fish_greeting
set sponge_purge_only_on_exit true

# SSH forwards TERM, but not COLORTERM. Ghostty uses xterm-256color here.
if set -q SSH_CONNECTION; and test "$TERM" = xterm-256color; and not set -q COLORTERM
    set -gx COLORTERM truecolor
end

# Set PATH and environment
# If TERM_PROGRAM is not tmux, since tmux will already have sourced the environment
if test -z "$TMUX" -a "$TERM_PROGRAM" != tmux
    source ~/dotfiles/fish/env.fish
end

# Add correct new lines for starship prompt
_spaced_prompts

# Init Atuin
ATUIN_NOBIND=true atuin init fish | source
bind \ca _atuin_search

# Config any-nix-shell
any-nix-shell fish | source

function ya
    set tmp (mktemp -t "yazi-cwd.XXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

eval "$(micromamba shell hook --shell fish)"
