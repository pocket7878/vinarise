"=============================================================================
" FILE: vinarise.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Jan 2011.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Version: 0.2, for Vim 7.0
"=============================================================================

" Check vimproc."{{{
try
  let s:exists_vimproc_version = vimproc#version()
catch
  echoerr 'Please install vimproc Ver.4.1 or above.'
  finish
endtry
if s:exists_vimproc_version < 401
  echoerr 'Please install vimproc Ver.4.1 or above.'
  finish
endif"}}}
" Check Python."{{{
if !has('python')
  echoerr 'Vinarise requires python interface.'
  finish
endif
"}}}

" Constants"{{{
let s:FALSE = 0
let s:TRUE = !s:FALSE

if has('win16') || has('win32') || has('win64')  " on Microsoft Windows
  let s:vinarise_BUFFER_NAME = '[vinarise]'
else
  let s:vinarise_BUFFER_NAME = '*vinarise*'
endif
"}}}

" Variables  "{{{
let s:vinarise_dicts = []
"}}}

function! vinarise#open(filename, is_overwrite)"{{{
  if a:filename == ''
    let l:filename = bufname('%')
  else
    let l:filename = a:filename
  endif

  if !a:is_overwrite
    edit `=s:vinarise_BUFFER_NAME . ' - ' . l:filename`
  endif

  "silent % delete _
  call s:initialize_vinarise_buffer()

  " Print lines.
  setlocal modifiable

  if !exists('b:pageNum')
	  let b:pageNum = 1
  endif
  let b:lastFileName = a:filename
  let b:lastOverWrite = a:is_overwrite
  if !exists('b:localBuf')
	  let b:localBuf = []
	  python << EOF
import mmap, os, vim
def vimstr(s) :
	return "'" + s.replace("'","''") + "'"
def vinariseFile() :
	with open(vim.eval("l:filename"), "r+") as f:
		# Open file by memory mapping.
		m = mmap.mmap(f.fileno(), 0)
		# "vim.command('let l:output = "hoge"')

		pos = 0
		max_lines = m.size()/16 + 1
		for line_number in range(0, max_lines) :
			# Make new lines.
			hex_line = ""
			ascii_line = ""

			for char in m[pos : pos+16]:
				num = ord(char)
				hex_line += "{0:02x} ".format(num)
				ascii_line += "." if num < 32 or num > 127 else char
				pos += 1

			vim.command('call add(b:localBuf, %s)' % vimstr('{0:07x}0: {1:48s}|  {2:16s}  '.format(line_number, hex_line, ascii_line)))

vinariseFile()
EOF
	endif
	for lineNum in range((b:pageNum - 1) * 100, (b:pageNum * 100 - 1) >= (len(b:localBuf) -1) ? (len(b:localBuf) -1) : b:pageNum * 100 - 1)
		call setline((lineNum - ((b:pageNum - 1) * 100)) + 1, b:localBuf[lineNum])
	endfor
	setlocal nomodifiable
endfunction"}}}

"Page change function"{{{
function! vinarise#nextPage() 
	if exists('b:pageNum')
		if (b:pageNum * 100 < (len(b:localBuf) -1))
			let b:pageNum += 1
		endif
	endif
	call vinarise#open(b:lastFileName,b:lastOverWrite)
endfunction

function! vinarise#backPage() 
	if exists('b:pageNum')
		if (b:pageNum != 1)
			let b:pageNum -= 1
		endif
	endif
	call vinarise#open(b:lastFileName,b:lastOverWrite)
endfunction"}}}

"Cursor move function"{{{
function! vinarise#cursorForward()
	let l:cursorPos=getpos(".")
	let l:nextChar=(getline(".")[(getpos(".")[2] + getpos(".")[3])])
	if l:nextChar == " "
		let l:cursorPos[2] += 2
		call setpos(".", cursorPos)
	else
		let l:cursorPos[2] += 1
		call setpos(".", cursorPos)
	endif
endfunction

function! vinarise#cursorBackward()
	let l:cursorPos=getpos(".")
	let l:prevChar=(getline(".")[(getpos(".")[2] + getpos(".")[3]) - 2])
	if l:prevChar == " "
		let l:cursorPos[2] -= 2
		call setpos(".", cursorPos)
	else
		let l:cursorPos[2] -= 1
		call setpos(".", cursorPos)
	endif
endfunction"}}}
" Misc.
function! s:initialize_vinarise_buffer()"{{{
  " The current buffer is initialized.
  let b:vinarise = {}

  " Basic settings.
  setlocal number
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nofoldenable
  setlocal foldcolumn=0

  " Autocommands.
  augroup plugin-vinarise
  augroup END

  " User's initialization.
  setfiletype vinarise

  return
endfunction"}}}

" vim: foldmethod=marker
