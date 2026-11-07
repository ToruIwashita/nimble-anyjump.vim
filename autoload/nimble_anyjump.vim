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

fun! s:parse_file_path_and_line(raw_path)
  let l:match = matchlist(a:raw_path, '^\(.\{-}\):\(\d\+\)\%(-\d\+\)\?$')
  if !empty(l:match) && !empty(l:match[1])
    return [l:match[1], l:match[2]]
  endif
  return [a:raw_path, '']
endf

fun! s:url_jump_by_cursor_line()
  let l:url = matchstr(getline('.'), "[a-z]*:\\/\\/[^ )\\]}>,;'\"]*")

  if !s:open_browser(l:url)
    return 0
  end

  redraw!
  return 1
endf

fun! s:url_jump_by_specified_text(text)
  let l:url = matchstr(a:text, "[a-z]*:\\/\\/[^ )\\]}>,;'\"]*")

  if !s:open_browser(l:url)
    return 0
  endif

  redraw!
  return 1
endf

" 先頭の`~`のみをホームディレクトリへ展開する
" expand()はバッククォート等をシェルコマンドとして実行するため,パスには使わない
fun! s:expand_home(path)
  if a:path ==# '~' || a:path[0:1] ==# '~/'
    return expand('~').a:path[1:]
  endif

  return a:path
endf

fun! s:open_file(file_path,line_number)
  let l:resolved_file_path = s:expand_home(a:file_path)

  if empty(a:file_path) || !filereadable(l:resolved_file_path)
    return 0
  endif

  execute ''.s:output_style()
  execute 'e '.fnameescape(l:resolved_file_path)

  if a:line_number
    execute 'normal! '.a:line_number.'G'
  endif

  execute 'normal! '.s:after_jump()

  return 1
endf

fun! s:file_jump_by_cursor_word()
  let l:raw_cfile = expand('<cfile>')
  let l:space_separated_keyword = expand('<cWORD>')
  let l:buffer_file_path_head = expand('%:p:h')
  let [l:file_path, l:parsed_line] = s:parse_file_path_and_line(l:raw_cfile)
  let l:after_colon_text = matchstr(l:space_separated_keyword, escape(l:file_path, '.\/').':\zs\(\d\+\)\ze\%(-\d\+\)\?', 0)

  if match(l:file_path, '^[/|\~]') == -1
    let l:buffer_relative = l:buffer_file_path_head.'/'.substitute(l:file_path, '^\./', '', '')
    if filereadable(s:expand_home(l:buffer_relative))
      let l:corrected_file_path = l:buffer_relative
    else
      let l:corrected_file_path = l:file_path
    endif
  else
    let l:corrected_file_path = l:file_path
  endif

  if !empty(l:after_colon_text)
    let l:line_number = l:after_colon_text
  elseif !empty(l:parsed_line)
    let l:line_number = l:parsed_line
  else
    let l:line_number = 1
  endif

  if !s:open_file(l:corrected_file_path, l:line_number)
    return 0
  endif

  return 1
endf

fun! s:file_jump_by_specified_text(text)
  let l:file_path = matchstr(a:text, '\zs\([^:]*\)\ze:\?')
  let l:buffer_file_path_head = expand('%:p:h')
  let l:after_colon_text = matchstr(a:text, ':\zs\(\d\+\)\ze\%(-\d\+\)\?', 0)

  if match(l:file_path, '^[/|\~]') == -1
    let l:buffer_relative = l:buffer_file_path_head.'/'.substitute(l:file_path, '^\./', '', '')
    if filereadable(s:expand_home(l:buffer_relative))
      let l:corrected_file_path = l:buffer_relative
    else
      let l:corrected_file_path = l:file_path
    endif
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
  let [l:file_name, l:_] = s:parse_file_path_and_line(expand('<cfile>:t'))
  let l:buffer_file_path = expand('%:p')
  let l:keyword_taglist_length = len(taglist('^'.l:keyword.'$'))
  let l:file_name_taglist_length = len(taglist('^'.l:file_name.'$'))
  let l:cword_line = matchstr(expand('<cWORD>'), ':\zs\(\d\+\)\ze\%(-\d\+\)\?', 0)

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

      if !empty(l:cword_line)
        execute 'normal! '.l:cword_line.'G'
      endif
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

fun! nimble_anyjump#anyjump_range(cmd) abort range
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

  let [l:selected_tag_name, l:selected_line] = s:parse_file_path_and_line(l:escapted_selected_range)
  let l:taglist_length = len(taglist('^'.l:selected_tag_name.'$'))

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
    execute a:cmd.' '.l:selected_tag_name

    if !empty(l:selected_line)
      execute 'normal! '.l:selected_line.'G'
    endif

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
