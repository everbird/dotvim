#!/usr/bin/env sh
set -eu

usage() {
    cat <<'EOF'
Usage: sh bootstrap.sh [--basic|--full] [--vim-only|--nvim-only] [--checkout DIR]

The default installs basic configuration for both Vim and Neovim.
--full downloads pinned plugins with vim-plug; Git and Vim or Neovim are required.
--checkout uses an existing checkout or clones into DIR if it is absent.
DOTVIM_HOME overrides the installation home (useful for a trial installation).
XDG_CONFIG_HOME sets the Neovim configuration parent directory.
DOTVIM_INSTALL_EDITOR selects the Vim or Neovim executable for plugin installation.
Existing configurations are backed up under DOTVIM_HOME/.dotvim-backups.
EOF
}

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

profile=basic
editors=both
checkout=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --basic) profile=basic ;;
        --full) profile=full ;;
        --vim-only) editors=vim ;;
        --nvim-only) editors=nvim ;;
        --checkout)
            [ "$#" -ge 2 ] || die '--checkout requires a directory'
            checkout=$2
            shift
            ;;
        --help|-h) usage; exit 0 ;;
        *) die "Unknown option: $1 (see --help)" ;;
    esac
    shift
done

install_home=${DOTVIM_HOME:-$HOME}
config_home=${XDG_CONFIG_HOME:-$install_home/.config}
script_dir=$(CDPATH='' cd -P "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=
if [ -z "$checkout" ]; then
    if [ -f "$script_dir/vimrc" ] && [ -f "$script_dir/plugins.vim" ]; then
        checkout=$script_dir
    else
        checkout=$install_home/.everbird-dotvim
    fi
fi

stage=$(mktemp -d "${TMPDIR:-/tmp}/dotvim-install.XXXXXX")
clone_dir=
profile_tmp=
committed=0
touch "$stage/journal"

cleanup() {
    if [ "$committed" -eq 0 ]; then
        while IFS= read -r target && IFS= read -r source && IFS= read -r saved; do
            if [ "$source" = '@profile' ]; then
                if [ -f "$target" ] && cmp -s "$stage/profile" "$target"; then
                    rm -f "$target"
                fi
            elif [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
                rm "$target"
            fi
            if [ "$saved" != '-' ] && { [ -e "$saved" ] || [ -L "$saved" ]; }; then
                if [ ! -e "$target" ] && [ ! -L "$target" ]; then
                    mv "$saved" "$target"
                else
                    printf 'Restore the saved configuration manually: %s\n' "$saved" >&2
                fi
            fi
        done < "$stage/journal"
    fi
    [ -z "$clone_dir" ] || rm -rf "$clone_dir"
    [ -z "$profile_tmp" ] || rm -f "$profile_tmp"
    rm -rf "$stage"
}
trap cleanup 0
trap 'exit 1' HUP INT TERM

# Complete downloads and validation before changing existing editor configuration.
if [ ! -e "$checkout" ] && [ ! -L "$checkout" ]; then
    command -v git >/dev/null 2>&1 || die 'Git is required to clone the configuration.'
    mkdir -p "$(dirname "$checkout")"
    clone_dir=$(mktemp -d "$checkout.clone.XXXXXX")
    git clone "${DOTVIM_REPOSITORY:-https://github.com/everbird/dotvim.git}" "$clone_dir"
    mv "$clone_dir" "$checkout"
    clone_dir=
fi
checkout=$(CDPATH='' cd -P "$checkout" && pwd) || die 'Cannot access the checkout.'
for file in vimrc plugins.vim gvimrc init.vim; do
    [ -f "$checkout/$file" ] || die "Missing $file in $checkout"
done
if [ "$profile" = full ]; then
    command -v git >/dev/null 2>&1 || die 'Git is required to download plugins.'
    install_editor=${DOTVIM_INSTALL_EDITOR:-}
    if [ -z "$install_editor" ]; then
        if [ "$editors" = nvim ] && command -v nvim >/dev/null 2>&1; then
            install_editor=nvim
        elif command -v vim >/dev/null 2>&1; then
            install_editor=vim
        elif command -v nvim >/dev/null 2>&1; then
            install_editor=nvim
        else
            die 'Vim or Neovim is required to install plugins with vim-plug.'
        fi
    fi
    command -v "$install_editor" >/dev/null 2>&1 || die "Cannot find the installation editor: $install_editor"
    [ -f "$checkout/scripts/install_plugins.vim" ] || die 'Missing scripts/install_plugins.vim'
    # Vim 7.4 expands -S paths through the shell; use POSIX quoting before it does.
    if ! "$install_editor" -u NONE -i NONE -n -es --noplugin --cmd 'set shell=/bin/sh' -S "$checkout/scripts/install_plugins.vim"; then
        die 'Plugin installation failed; editor configuration was not changed.'
    fi
fi
mkdir -p "$install_home"
install_home=$(CDPATH='' cd -P "$install_home" && pwd)
if [ "$editors" != vim ]; then
    mkdir -p "$config_home"
    config_home=$(CDPATH='' cd -P "$config_home" && pwd)
fi
printf '%s\n' "$profile" > "$stage/profile"
backup_dir=$install_home/.dotvim-backups/$(date +%Y%m%dT%H%M%S).$$

save_target() {
    target=$1
    source=$2
    label=$3
    saved=-
    if [ -e "$target" ] || [ -L "$target" ]; then
        saved=$backup_dir/$label
    fi
    # Record intent before moving anything, so a failed link can be rolled back.
    printf '%s\n%s\n%s\n' "$target" "$source" "$saved" >> "$stage/journal"
    if [ "$saved" != '-' ]; then
        mkdir -p "$backup_dir"
        mv "$target" "$saved"
    fi
}

link_config() {
    source=$1
    target=$2
    label=$3
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        return
    fi
    # Manual installations may already use ~/.vim as the actual checkout.
    if [ -d "$source" ] && [ -d "$target" ] && [ "$(CDPATH='' cd -P "$target" && pwd)" = "$source" ]; then
        return
    fi
    save_target "$target" "$source" "$label"
    ln -s "$source" "$target"
}

if [ "$editors" != nvim ]; then
    link_config "$checkout" "$install_home/.vim" vim
    link_config "$checkout/vimrc" "$install_home/.vimrc" vimrc
    link_config "$checkout/gvimrc" "$install_home/.gvimrc" gvimrc
fi
if [ "$editors" != vim ]; then
    link_config "$checkout" "$config_home/nvim" nvim
fi
if ! cmp -s "$stage/profile" "$install_home/.dotvim-profile"; then
    profile_tmp=$(mktemp "$install_home/.dotvim-profile.XXXXXX")
    cp "$stage/profile" "$profile_tmp"
    save_target "$install_home/.dotvim-profile" '@profile' profile
    mv "$profile_tmp" "$install_home/.dotvim-profile"
    profile_tmp=
fi
committed=1
printf 'Installed the %s profile from %s\n' "$profile" "$checkout"
if [ -d "$backup_dir" ]; then
    printf 'Previous configuration: %s\n' "$backup_dir"
fi
printf 'Restart the editor, then run :DotvimHealth for optional feature status.\n'
