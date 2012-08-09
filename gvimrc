"==============================================================================
"HOW IT LOOKS
"==============================================================================

colorscheme wombat

if &background == "dark"
    hi normal guibg=black
    set transp=1
endif

"Macvim
"
if has('gui_macvim')
    "set lines=56 columns=240
    set guifont=Monaco:h12
    set guifontwide=Monaco:h12

    "" full screen on statup
    set fu
    set fuopt=maxvert,maxhorz
endif
