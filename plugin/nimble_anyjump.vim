" File: plugin/nimble_anyjump.vim
" Author: ToruIwashita <toru.iwashita@gmail.com>
" License: MIT License

if exists('g:loaded_nimble_anyjump')
  finish
endif
let g:loaded_nimble_anyjump = 1

let s:cpoptions_save = &cpoptions
set cpoptions&vim

command! NimbleAnyjump call nimble_anyjump#anyjump('tag')
command! NimbleTAnyjump call nimble_anyjump#anyjump('tjump')
command! -range NimbleAnyjumpRange call nimble_anyjump#anyjump_range('tag')
command! -range NimbleTAnyjumpRange call nimble_anyjump#anyjump_range('tjump')

noremap <silent><Plug>(nimble-anyjump) :<C-u>NimbleAnyjump<CR>
noremap <silent><Plug>(nimble-t-anyjump) :<C-u>NimbleTAnyjump<CR>
vnoremap <silent><Plug>(nimble-anyjump-range) :<C-u>NimbleAnyjumpRange<CR>
vnoremap <silent><Plug>(nimble-t-anyjump-range) :<C-u>NimbleTAnyjumpRange<CR>

let &cpoptions = s:cpoptions_save
unlet s:cpoptions_save
