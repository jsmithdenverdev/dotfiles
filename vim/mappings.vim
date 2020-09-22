" ---------------------------
" Mappings
" ---------------------------

" Map <C-L> to also turn off search highlighting
nnoremap <C-L> :nohl<CR><C-L>

" Map <Leader>w to write buffer
nnoremap <Leader>w :w<CR>

" More natural split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" ---------------------------
" Auto Expand Brackets
" ---------------------------
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap (<CR> (<CR>)<ESC>O
inoremap [<CR> [<CR>]<ESC>O
inoremap {;<CR> {<CR>}<ESC>O
inoremap (;<CR> (<CR>)<ESC>O
inoremap [;<CR> [<CR>]<ESC>O


