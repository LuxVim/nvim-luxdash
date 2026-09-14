" Minimal init.vim for testing

" Set PLENARY_PATH to use an existing checkout in local or CI test runs.
let s:plenary_path = empty($PLENARY_PATH)
      \ ? expand('~/.local/share/nvim/site/pack/packer/start/plenary.nvim')
      \ : $PLENARY_PATH
execute 'set rtp+=' . fnameescape(s:plenary_path)

" Add the plugin itself to runtimepath
set rtp+=.
lua package.path = './?.lua;./?/init.lua;' .. package.path

" Required for plenary
runtime plugin/plenary.vim

" Set up basic Neovim settings for tests
set noswapfile
set nobackup
set nowritebackup
