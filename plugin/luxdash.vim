if exists('g:luxdash_loaded') | finish | endif
let g:luxdash_loaded = 1

lua require('luxdash').setup()