syntax on

set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set smartcase
set noswapfile
set nobackup
set incsearch
set hidden
set wildmenu
set path+=**
set wildignore+=**/node_modules/**
set relativenumber
set nohlsearch


highlight VertSplit cterm=NONE
set fillchars+=vert:\ 

highlight Pmenu ctermfg=white ctermbg=black
highlight PmenuSel ctermfg=white ctermbg=gray
highlight EndOfBuffer ctermfg=black ctermbg=black


map <C-f> :Files<CR>
set complete-=t
set complete-=i

" use <tab> for trigger completion and navigate to the next complete item
""""function! s:check_back_space() abort
""""  let col = col('.') - 1
""""  return !col || getline('.')[col - 1]  =~ '\s'
""""endfunction

""""inoremap <silent><expr> <Tab>
""""	  \ pumvisible() ? "\<C-n>" :
""""	  \ <SID>check_back_space() ? "\<Tab>" :
""""	  \ coc#refresh()

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'tpope/vim-fugitive'
	Plug 'vim-utils/vim-man'
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
    Plug 'maxboisvert/vim-simple-complete'
    call plug#end()


