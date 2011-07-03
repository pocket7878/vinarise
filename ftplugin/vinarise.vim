noremap <buffer><silent> <Plug>(vinarise_nextPage) :<C-u>call vinarise#nextPage()<CR>

nnoremap <buffer><silent> <Plug>(vinarise_backPage) :<C-u>call vinarise#backPage()<CR>

nmap <buffer><silent> > <Plug>(vinarise_nextPage)

nmap <buffer><silent> < <Plug>(vinarise_backPage)

noremap <buffer><silent> <Plug>(vinarise_cursorForward) :<C-u>call vinarise#cursorForward()<CR>

nnoremap <buffer><silent> <Plug>(vinarise_cursorBackward) :<C-u>call vinarise#cursorBackward()<CR>

nmap <buffer><silent> l <Plug>(vinarise_cursorForward)

nmap <buffer><silent> h <Plug>(vinarise_cursorBackward)

noremap <buffer><silent> <Plug>(vinarise_moveCursorBetweenAsciiAndHex) :<C-u>call vinarise#moveBetweenAsciiAndHex()<CR>

nmap <buffer><silent> % <Plug>(vinarise_moveCursorBetweenAsciiAndHex)

noremap <buffer><silent> <Plug>(vinarise_showVinaryInfo) :<C-u>call vinarise#showVinaryInfo()<CR>

nmap <buffer><silent> <Leader>i <Plug>(vinarise_showVinaryInfo)

command! -buffer -nargs=? -complete=file WriteOut call vinarise#writeOut(<q-args>)

noremap <buffer><silent> <Plug>(vinarise_removeHex) :<C-u>call vinarise#removeVinary()<CR>

nmap <buffer><silent> <BS> <Plug>(vinarise_removeHex)

noremap <buffer><silent> <Plug>(vinarise_overwriteHex) :<C-u>call vinarise#overWriteVinary()<CR>
nmap <buffer><silent> r <Plug>(vinarise_overwriteHex)

command! -buffer -nargs=1 -complete=file WriteBimapView call vinarise#writeBitmapView(<f-args>)
