" Vim plugin file
" Maintainer:       Nikolai Weibull <nikolai@bitwi.se>
" Latest Revision:  2011-03-18

if exists("loaded_plugin_now_syntax_export")
  finish
endif
let loaded_plugin_now_syntax_export = 1

let s:cpo_save = &cpo
set cpo&vim

noremap <silent> <Leader>S <Esc>:set operatorfunc=<SID>convert_range<CR>g@

command! -range=% ExportSyntax call s:main(<line1>, <line2>)
command! -range=% ExportSyntaxToHTML call s:html(<line1>, <line2>)
command! -range=% ExportSyntaxToNML call s:nml(<line1>, <line2>)
command! -range=% -nargs=? SubstituteSyntaxRangeWithNML call s:substitute_syntax_range_with_nml(<line1>, <line2>, <q-args>)

function! s:main(begin, end)
  let saved = s:save()
  let [original, export] = s:create()
  call s:setup(original, export)
  call s:export(original, export, a:begin, a:end)
  call s:finalize(original, export)
  call s:restore(saved)
  return export
endfunction

function! s:save()
  let saved = { 'title': &title, 'icon': &icon, 'search': @/ }
  set notitle noicon
  return saved
endfunction

function! s:restore(saved)
  let &title = a:saved.title
  let &icon = a:saved.icon
  let @/ = a:saved.search
endfunction

function! s:create()
  let original = winbufnr(0)
  if expand('%') == ""
    new untitled.xml
  else
    new %.xml
  endif
  return [bufwinnr(original), winnr()]
endfunction

function! s:setup(original, export)
  call s:activate(a:original)
  let path = expand('%:p')
  let filetype = &filetype
  call s:activate(a:export)
  set modifiable
  %delete _
  call s:header(path, filetype)
  call s:activate(a:original)
endfunction

function! s:activate(window)
  execute a:window . 'wincmd w'
endfunction

function! s:header(path, type)
  call setline(1, '<?xml version="1.0" encoding="utf-8"?>')
  call s:append('<file>')
  call s:information(a:path, a:type)
  call s:append('  <content>')
endfunction

function! s:append(line)
  call append(line('$'), a:line)
endfunction

function! s:information(path, type)
  if a:path == "" && a:type == ""
    return
  endif
  call s:append('  <information>')
  call s:information_element('path', a:path)
  call s:information_element('type', a:type)
  call s:append('  </information>')
endfunction

function! s:information_element(name, value)
  if a:value == ""
    return
  endif
  call s:append(printf('    <%s>%s</%s>', a:name, s:entitize(a:value), a:name))
endfunction

function! s:entitize(string)
  return substitute(substitute(a:string, '&', '\&amp;', 'g'), '<', '\&lt;', 'g')
endfunction

function! s:export(original, export, begin, end)
  let lnum = a:begin
  while lnum <= a:end
    call s:filler(a:original, a:export, lnum)
    let [line, lnum] = s:process(lnum)
    call s:output(a:original, a:export, s:line(line))
    let lnum += 1
  endwhile
endfunction

function! s:filler(original, export, lnum)
  let filler = diff_filler(a:lnum)
  if filler == 0
    return
  endif
  let char = s:fillchar('diff', '-')
  let n = a:filler
  while n > 0
    let line = repeat(a:fillchar, 3)

    " TODO: Remove this variable once we figure out what is actually displayed
    " in a diff buffer.  Output should be exactly like Vim display.
    if n > 2 && n < a:filler && !exists('g:xml_export_whole_filler')
      let line .= ' ' . a:filler . ' inserted lines '
      let n = 2
    endif

    let line .= repeat(char, &columns - strlen(new))
    call s:output(a:original, a:export, s:line(s:segment(s:entitize(line), "DiffDelete")))
    let n -= 1
  endwhile
endfunction

function! s:fillchar(char, default)
  let fillchar = &fillchars[matchend(&fillchars, a:char . ':')]
  return (fillchar != "" ? fillchar : default)
endfunction

function! s:segment(text, type)
  return printf('<segment type="%s">%s</segment>',
              \ a:type != "" ? a:type : "Normal", strtrans(a:text))
endfunction

function! s:line(text)
  if a:text == ""
    return '    <line/>'
  endif
  return printf('    <line>%s</line>', a:text)
endfunction

function! s:output(original, export, line)
  call s:activate(a:export)
  call s:append(a:line)
  call s:activate(a:original)
endfunction

function! s:process(lnum)
  if foldclosed(a:lnum) != -1
    return s:process_fold(a:lnum)
  elseif diff_hlID(a:lnum, 1) != 0
    return s:process_diff(a:lnum)
  else
    return s:process_normal(a:lnum)
  endif
endfunction

function! s:process_fold(lnum)
  let line = foldtextresult(a:lnum)
  return [s:segment(s:entitize(line .
                             \ repeat(s:fillchar('fold', '-'),
                                    \ &columns - strlen(line)),
                  \ 'Folded'),
        \ foldclosedend(a:lnum)]
endfunction

function! s:process_diff(lnum)
  let line = getline(a:lnum)
  let len = strlen(line)
  if len < &columns
    let line .= repeat(' ', &columns - strlen(line))
    let len = &columns
  endif

  return [s:parse(a:lnum, line, len, function('diff_hlID')), a:lnum]
endfunction

function! s:parse(lnum, line, len, id_f)
  let parsed = ""

  let i = 1
  while i <= a:len
    let start = i
    let id = synIDtrans(a:id_f(a:lnum, i, 1))
    let i += 1
    while i <= a:len && synIDtrans(a:id_f(a:lnum, i, 1)) == id
      let i += 1
    endwhile

    let parsed .= s:parse_range(a:line, start - 1, i - start, id)
  endwhile

  return parsed
endfunction

function! s:parse_range(line, offset, end, id)
  return s:segment(s:whitespace(s:entitize(s:expand(strpart(a:line, a:offset,
                                                          \ a:end), a:offset))),
                 \ synIDattr(synIDtrans(a:id), 'name'))
endfunction

function! s:expand(text, offset)
  let expanded = ""
  let start = 0
  let i = stridx(expanded, "\t", start)
  while i >= 0
    let expanded .= strpart(a:text, start, i + 1)
    let expanded .= repeat(' ', &ts - (i + a:offset) % &ts)
    let start = i + 1
    let i = stridx(a:text, "\t", start)
  endwhile
  return expanded . strpart(a:text, start)
endfunction

function! s:whitespace(text)
  return substitute(a:text, '\s\+', '<whitespace>&</whitespace>', 'g')
endfunction

function! s:process_normal(lnum)
  let line = getline(a:lnum)
  return [s:parse(a:lnum, line, strlen(line), function('synID')), a:lnum]
endfunction

function! s:finalize(original, export)
  call s:activate(a:export)
  call s:append('  </content>')
  call s:append('</file>')
  silent %s/\s\+$//e
  call s:activate(a:original)
endfunction

function! s:html(begin, end)
  let export = s:main(a:begin, a:end)
  call s:activate(export)
  write
  execute '!xsltproc -o ' expand("%:p") . '.html ~/.vim/plugin/now/syntax-export-to-html.xsl' expand("%:p")
endfunction

function! s:nml(begin, end)
  let export = s:main(a:begin, a:end)
  call s:activate(export)
  write
  execute '!xsltproc -o ' expand("%:p") . '.html ~/.vim/plugin/now/syntax-export-to-nml.xsl' expand("%:p")
endfunction

function! s:substitute_syntax_range_with_nml(begin, end, ...)
  let filetype = a:0 > 0 ? a:1 : &filetype
  let saved_reg = @a
  execute a:begin . ',' . a:end . 'delete a'
  let text = @a
  new
  1put! a
  $delete _
  execute 'setf' filetype

  let export = s:main(1, line('$'))
  call s:activate(export)
  silent %!xsltproc ~/.vim/plugin/now/syntax-export-to-nml-fragment.xsl -
  %delete a
  bdelete!

  bdelete!

  undojoin
  execute a:begin . 'put! a'
  let @a = saved_reg
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
