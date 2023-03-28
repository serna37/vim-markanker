fu! s:get_mark(target) abort
  try
    retu execute('marks ' . a:target)
  catch
    retu ''
  endtry
endf

" show mark list and jump {{{
fu! markanker#MarkMenu() abort
  let get_marks = s:get_mark(g:mark_char_manual)
  if get_marks == ''
    echo 'no marks'
    retu
  endif
  let markdicarr = []
  for v in split(get_marks , '\n')[1:]
    cal add(markdicarr, {'linenum': str2nr(filter(split(v, ' '), { i,v -> v != '' })[1]), 'val': v})
  endfor
  cal sort(markdicarr, { x, y -> x['linenum'] - y['linenum'] })
  let marks_this = map(markdicarr, { i,v -> v['val'] })
  cal popup_menu(marks_this, #{ title: 'choose marks', border: [], zindex: 100, minwidth: &columns/2, maxwidth: &columns/2, minheight: 2, maxheight: &lines/2, filter: function('markanker#MarkChoose', [{'idx': 0, 'files': marks_this}]) })
endf

fu! markanker#MarkChoose(ctx, winid, key) abort
  if a:key is# 'j' && a:ctx.idx < len(a:ctx.files)-1
    let a:ctx.idx = a:ctx.idx+1
  elseif a:key is# 'k' && a:ctx.idx > 0
    let a:ctx.idx = a:ctx.idx-1
  elseif a:key is# "\<CR>"
    execute('normal!`' . a:ctx.files[a:ctx.idx][1])
  endif
  retu popup_filter_menu(a:winid, a:key)
endf
" }}}

" mark auto word, toggle {{{
fu! markanker#Marking() abort
  let get_marks = s:get_mark(g:mark_char_manual)
  if get_marks == ''
    execute('mark a')
    cal markanker#MarkShow()
    echo 'marked'
    retu
  endif
  let l:now_marks = []
  let l:warr = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm']
  for row in split(get_marks , '\n')[1:]
    let l:r = filter(split(row, ' '), {i, v -> v != ''})
    if stridx(g:mark_char, r[0]) != -1 && r[1] == line('.')
      cal markanker#MarkSignDel()
      execute('delmarks ' . r[0])
      cal markanker#MarkShow()
      echo 'delete mark '.r[0]
      retu
    endif
    let l:now_marks = add(now_marks, r[0])
  endfor
  let l:can_use = filter(warr, {i, v -> stridx(join(now_marks, ''), v) == -1})
  if len(can_use) != 0
    cal markanker#MarkSignDel()
    execute('mark ' . can_use[0])
    cal markanker#MarkShow()
    echo 'marked '.can_use[0]
  else
    echo 'over limit markable char'
  endif
endf
" }}}

" delete sign from row {{{
fu! markanker#MarkSignDel() abort
  let get_marks = s:get_mark(g:mark_char)
  if get_marks == ''
    retu
  endif
  let mark_dict = {}
  for row in split(get_marks, '\n')[1:]
    let l:r = filter(split(row, ' '), {i, v -> v != ''})
    let mark_dict[r[0]] = r[1]
  endfor
  for mchar in keys(mark_dict)
    let id = stridx(g:mark_char, mchar) + 1
    exe "sign unplace " . id . " file=" . expand("%:p")
    exe "sign undefine " . mchar
  endfor
endf
" }}}

" show marks on row {{{
fu! markanker#MarkShow() abort
  let get_marks = s:get_mark(g:mark_char)
  if get_marks == ''
    retu
  endif
  let mark_dict = {}
  for row in split(get_marks, '\n')[1:]
    let l:r = filter(split(row, ' '), {i, v -> v != ''})
    let mark_dict[r[0]] = r[1]
  endfor
  for mchar in keys(mark_dict)
    let id = stridx(g:mark_char, mchar) + 1
    let txt = stridx(g:mark_char_auto, mchar) != -1 ? "=" : mchar
    let txthl = stridx(g:mark_char_auto, mchar) != -1 ? "CursorLineNr" : "ErrorMsg"
    exe "sign define " . mchar . " text=" . txt . " texthl=" . txthl
    exe "sign place " . id . " line=" . mark_dict[mchar] . " name=" . mchar . " file=" . expand("%:p")
  endfor
endf

aug sig_aus
  au!
  au BufEnter,CmdwinEnter * cal markanker#MarkShow()
aug END
" }}}

" move to next/prev mark {{{
fu! markanker#MarkHank(vector, mchar) abort
  let get_marks = s:get_mark(a:mchar)
  if get_marks == ''
    if a:mchar == g:mark_char_auto " expand marks
      cal markanker#MarkField()
      retu
    endif
    echo 'no marks'
    retu
  endif
  let mark_dict = {} " [linenum: mark char]
  let rownums = []
  for row in split(get_marks, '\n')[1:]
    let l:r = filter(split(row, ' '), {i, v -> v != ''})
    let mark_dict[r[1]] = r[0]
    let rownums = add(rownums, r[1])
  endfor
  cal sort(rownums, a:vector == 'up' ? {x, y -> y-x} : {x, y -> x - y})
  if a:mchar == g:mark_char_auto " if auto mark & out of range, create marks
    if line('.') <= rownums[a:vector == 'up' ? -1 : 0] || rownums[a:vector == 'up' ? 0 : -1] <= line('.')
      let do = a:vector == 'up' ? "5k" : "5j"
      execute("normal! " . do)
      cal markanker#MarkField()
      retu
    endif
  endif
  for rownum in rownums
    if a:vector == 'down' && rownum > line('.')
      exe "normal! `" . mark_dict[rownum]
      echo index(rownums, rownum) + 1 . "/" . len(rownums)
      retu
    elseif a:vector == 'up' && rownum < line('.')
      exe "normal! `" . mark_dict[rownum]
      echo len(rownums) - index(rownums, rownum) . "/" . len(rownums)
      retu
    endif
  endfor
  echo "last mark"
endf
" }}}

" create short marks {{{
fu! markanker#MarkField() abort
  cal markanker#MarkSignDel()
  execute('delmarks '.g:mark_char_auto)
  let warr = ['n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y']
  let now_line = line('.')
  let col = col('.')
  let last = line('$')
  mark z
  for v in range(1, 6)
    if now_line + v*5 <= last
      cal cursor(now_line + v*5, 1)
      execute('mark '.warr[2*(v-1)])
    endif
    if now_line + v*-5 > 0
      cal cursor(now_line + v*-5, 1)
      execute('mark '.warr[2*(v-1)-1])
    endif
  endfor
  cal cursor(now_line, col)
  cal markanker#MarkShow()
  echo 'mode [marker] expand'
endf

fu! markanker#MarkFieldOut()
  cal markanker#MarkSignDel()
  execute('delmarks '.g:mark_char_auto)
  cal markanker#MarkShow()
  echo '[marker] mode out'
endf
" }}}
