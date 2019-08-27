" File: autoload/nimble_anyjump.vim
" Author: ToruIwashita <toru.iwashita@gmail.com>
" License: MIT License

let s:cpoptions_save = &cpoptions
set cpoptions&vim

if !exists('g:nimble_anyjump_output_style')
  let g:nimble_anyjump_output_style = 'vertical'
endif

if !exists('g:nimble_anyjump_after_jump')
  let g:nimble_anyjump_after_jump = 'zz'
endif

fun! s:output_style()
  let l:style = g:nimble_anyjump_output_style

  if match(l:style, 'horizontal') != -1
    return 'split'
  elseif match(l:style, 'tab') != -1
    return 'tabnew'
  else
    return 'vsplit'
  endif
endf

fun! s:after_jump()
  let l:action = g:nimble_anyjump_after_jump

  if match(l:action, 'zt') != -1
    return 'zt'
  elseif match(l:action, 'zb') != -1
    return 'zb'
  else
    return 'zz'
  endif
endf

fun! s:open_browser(url)
  if empty(a:url)
    return 0
  endif

  if executable('open')
    silent! execute '!open '.escape(shellescape(a:url), '#')
  elseif executable('xdg-open')
    silent! execute '!xdg-open '.escape(shellescape(a:url), '#')
  endif

  return 1
endf

fun! s:url_jump_by_cursor_line()
  let l:url = matchstr(getline('.'), "[a-z]*:\\/\\/[^ )\\]}>,;:'\"]*")

  if !s:open_browser(l:url)
    return 0
  end

  redraw!
  return 1
endf

fun! s:url_jump_by_specified_text(text)
  let l:url = matchstr(a:text, "[a-z]*:\\/\\/[^ )\\]}>,;:'\"]*")

  if !s:open_browser(l:url)
    return 0
  endif

  redraw!
  return 1
endf

fun! s:open_file(file_path,line_number)
  if empty(a:file_path) || !filereadable(expand(a:file_path))
    return 0
  endif

  execute ''.s:output_style()
  execute 'e '.a:file_path

  if a:line_number
    execute 'normal! '.a:line_number.'G'
  endif

  execute 'normal! '.s:after_jump()

  return 1
endf

fun! s:file_jump_by_cursor_word()
  let l:file_path = expand('<cfile>')
  let l:space_separated_keyword = expand('<cWORD>')
  let l:buffer_file_path_head = expand('%:p:h')
  let l:after_colon_text = matchstr(expand(l:space_separated_keyword), expand(l:file_path).':\zs\([0-9]*\)\ze', 0)

  if match(l:file_path, '^[/|\~]') == -1
    let l:corrected_file_path = l:buffer_file_path_head.'/'.substitute(l:file_path, '^\./', '', '')
  else
    let l:corrected_file_path = l:file_path
  endif

  if empty(l:after_colon_text)
    let l:line_number = 1
  else
    let l:line_number = l:after_colon_text
  endif

  if !s:open_file(l:corrected_file_path, l:line_number)
    return 0
  endif

  return 1
endf

fun! s:file_jump_by_specified_text(text)
  let l:file_path = matchstr(expand(a:text), '\zs\([^:]*\)\ze:\?')
  let l:buffer_file_path_head = expand('%:p:h')
  let l:after_colon_text = matchstr(expand(a:text), ':\zs\([0-9]*\)\ze', 0)

  if match(l:file_path, '^[/|\~]') == -1
    let l:corrected_file_path = l:buffer_file_path_head.'/'.substitute(l:file_path, '^\./', '', '')
  else
    let l:corrected_file_path = l:file_path
  endif

  if empty(l:after_colon_text)
    let l:line_number = 1
  else
    let l:line_number = l:after_colon_text
  endif

  if !s:open_file(l:corrected_file_path, l:line_number)
    return 0
  endif

  return 1
endf

fun! nimble_anyjump#anyjump(cmd)
  let l:keyword = expand('<cword>')
  let l:file_name = expand('<cfile>:t')
  let l:buffer_file_path = expand('%:p')
  let l:keyword_taglist_length = len(taglist('^'.l:keyword.'$'))
  let l:file_name_taglist_length = len(taglist('^'.l:file_name.'$'))

  if s:file_jump_by_cursor_word()
    return 0
  endif

  if l:keyword_taglist_length == 0 && l:file_name_taglist_length == 0
    if s:url_jump_by_cursor_line()
      return 1
    end

    echo 'No resource found.'
    return 0
  endif

  execute ''.s:output_style()

  try
    if l:keyword_taglist_length != 0
      execute a:cmd.' '.l:keyword
    elseif l:file_name_taglist_length != 0
      execute a:cmd.' '.l:file_name
    else
      throw 'failed to jump'
    endif

    execute 'normal! '.s:after_jump()
  finally
    if a:cmd ==# 'tjump' && l:buffer_file_path == expand('%:p')
      quit
      if s:output_style() ==# 'tabnew' | tabp | en
    endif

    if line('$') == 1 && getline(1) ==# ''
      tabclose
      if s:output_style() ==# 'tabnew' | tabp | en
    endif
  endtry
endf

fun! nimble_anyjump#anyjump_range(cmd) range
  let l:buffer_file_path = expand('%:p')
  let l:unnamed_register = @@
  silent! normal! gvy
  let l:selected_range = @@
  let @@ = l:unnamed_register

  if l:selected_range =~# "'"
    let l:escapted_selected_range = '"'.escape(l:selected_range, ' \"').'"'
  elseif l:selected_range =~# '[ \"]'
    let l:escapted_selected_range = string(l:selected_range)
  else
    let l:escapted_selected_range = l:selected_range
  endif

  let l:taglist_length = len(taglist('^'.l:escapted_selected_range .'$'))

  if s:file_jump_by_specified_text(l:escapted_selected_range)
    return 0
  endif

  if l:taglist_length == 0
    if s:url_jump_by_specified_text(l:escapted_selected_range)
      return 1
    end

    echo 'No resource found.'
    return 0
  endif

  execute s:output_style()

  try
    execute a:cmd.' '.l:escapted_selected_range
    execute 'normal! '.s:after_jump()
  finally
    if a:cmd ==# 'tjump' && l:buffer_file_path ==# expand('%:p')
      quit
      if s:output_style() ==# 'tabnew' | tabp | en
    endif

    if line('$') == 1 && getline(1) ==# ''
      tabclose
      if s:output_style() ==# 'tabnew' | tabp | en
    endif
  endtry
endf

let &cpoptions = s:cpoptions_save
unlet s:cpoptions_save
