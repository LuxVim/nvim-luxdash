" Minimal init.vim for testing

" Add plenary to runtimepath (you'll need to install it)
set rtp+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim

" Add the plugin itself to runtimepath
set rtp+=.

" Required for plenary
runtime plugin/plenary.vim

" Set up basic Neovim settings for tests
set noswapfile
set nobackup
set nowritebackup
