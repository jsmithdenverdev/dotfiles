" ---------------------------
" Base settings
" ---------------------------

" Attempts to determine the type of a file based on its name
filetype indent plugin on

" Syntax Highlighting
syntax on

" Hides buffers when switching instead of closing them
set hidden

" Better command-line completion
set wildmenu

" Show partial commands in the last line of the screen
set showcmd

" Set highlight searches
set hlsearch

" Set <Leader> to space
nnoremap <SPACE> <Nop>
let mapleader=" "

" Stops Vim from doing scary things
set nocompatible

" Enable good colors
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" ---------------------------
" Colorscheme
" ---------------------------

" Set dark background mode
" set background=dark

" Set colorscheme (installed in ~/.vim_config/plugins.vim)
colorscheme dracula

" ---------------------------
" Quality of Life
" ---------------------------

" Case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Allow backspacing over autoindent, line breaks and start of insert action
set backspace=indent,eol,start

" Be smart about indents
set autoindent

" Turn on line numbers
set number

" Display cursor position
set ruler

" Always display status line
set laststatus=2

" Start a dialog for saves instead of a failure
set confirm

" Turn off the annoying beep
set visualbell

" Set command window height to 2 lines to avoid "press <Enter> to continue"
set cmdheight=2

" Use <F11> to toggle between 'paste' and 'nopaste'
set pastetoggle=<F11>

" ---------------------------
" Tabs and Spaces
" --------------------------- 
set tabstop=2
set shiftwidth=2
set expandtab

" ---------------------------
" SWP and Backup Files
" --------------------------- 

set backupdir=/tmp//
set directory=/tmp//
set undodir=/tmp//
