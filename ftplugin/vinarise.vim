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
