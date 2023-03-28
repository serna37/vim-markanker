let g:mark_char = 'abcdefghijklmnopqrstuvwxyz'
let g:mark_char_manual = 'abcdefghijklm'
let g:mark_char_auto = 'nopqrstuvwxyz'

" mark
nnoremap <silent><Leader>m :cal markanker#MarkMenu()<CR>
nnoremap <silent>mm :cal markanker#Marking()<CR>
nnoremap <silent>mj :cal markanker#MarkHank("down", g:mark_char_manual)<CR>
nnoremap <silent>mk :cal markanker#MarkHank("up", g:mark_char_manual)<CR>

" mark anker
nnoremap <silent><Tab> :cal markanker#MarkHank("down", g:mark_char_auto)<CR>
nnoremap <silent><S-Tab> :cal markanker#MarkHank("up", g:mark_char_auto)<CR>
nnoremap <silent><Leader>w :cal markanker#MarkFieldOut()<CR>

