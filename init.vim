" Neovim entry point; resolve the symlink to find the shared checkout.
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . fnameescape(s:root . '/vimrc')
