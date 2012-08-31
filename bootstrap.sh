#!/usr/bin/env sh

endpath="$HOME/.everbird-dotvim"

warn() {
	echo "$1" >&2
}

die() {
	warn "$1"
		exit 1
}

# Backup existing .vim stuff
echo "backing up current vim config\n"
today=`date +%Y%m%d`
for i in $HOME/.vim $HOME/.vimrc $HOME/.gvimrc; do [ -e $i ] && mv $i $i.$today; done


echo "cloning everbird-dotvim\n"
git clone --recursive git://github.com/everbird/dotvim.git $endpath
mkdir -p $endpath/bundle
ln -s $endpath/vimrc $HOME/.vimrc
ln -s $endpath $HOME/.vim
