# Sourced after config.fish on machines that import the workstation module

# Init Atuin
ATUIN_NOBIND=true atuin init fish | source
bind \ca _atuin_search

eval "$(micromamba shell hook --shell fish)"
