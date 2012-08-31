# The automatic installer
You can install this via the command line with either `curl` or `wget`.
## via `curl`

	curl -L https://raw.github.com/everbird/dotvim/master/bootstrap.sh | sh
## via `wget`

	wget --no-check-certificate https://raw.github.com/everbird/dotvim/master/bootstrap.sh -O - | sh

# The manual way
## 1. Installation:
	git clone git@github.com:everbird/dotvim.git ~/.vim

## 2. Create symlinks:
    ln -s ~/.vim/vimrc ~/.vimrc
    ln -s ~/.vim/gvimrc ~/.gvimrc

## 3. Switch to the `~/.vim` directory and fetch submodules:
    cd ~/.vim
    git submodule init
    git submodule update
