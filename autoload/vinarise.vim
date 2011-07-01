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
	  let b:localBuf = [[], [], []]
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
			
			vim.command('call add(b:localBuf[0], %s)' % vimstr('{0:07x}0:'.format(line_number)))
			vim.command('call add(b:localBuf[1], %s)' % vimstr('{0:48s}'.format(hex_line)))
			vim.command('call add(b:localBuf[2], %s)' % vimstr('{0:16s}'.format(ascii_line)))

vinariseFile()
EOF
	endif
	for lineNum in range((b:pageNum - 1) * 100, (b:pageNum * 100 - 1) >= (len(b:localBuf[0]) - 1) ? (len(b:localBuf[0]) - 1) : b:pageNum * 100 - 1)
		call setline((lineNum - ((b:pageNum - 1) * 100)) + 1, printf('%s %s | %s',b:localBuf[0][lineNum],b:localBuf[1][lineNum],b:localBuf[2][lineNum]))
	endfor
	setlocal nomodifiable
endfunction"}}}

"Page change function"{{{
function! vinarise#nextPage() 
	if exists('b:pageNum')
		if (b:pageNum * 100 < (len(b:localBuf[0]) -1))
			let b:pageNum += 1
			call vinarise#open(b:lastFileName,b:lastOverWrite)
		endif
	endif
endfunction

function! vinarise#backPage() 
	if exists('b:pageNum')
		if (b:pageNum != 1)
			let b:pageNum -= 1
			call vinarise#open(b:lastFileName,b:lastOverWrite)
		endif
	endif
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
endfunction

function! vinarise#moveBetweenAsciiAndHex()
	let l:cursorPos = getpos(".")
	if (l:cursorPos[2] + l:cursorPos[3]) >= 11 && (l:cursorPos[2] + l:cursorPos[3]) <= 57
		let l:cursorPos[2] -= 11
		let l:cursorPos[2] = l:cursorPos[2] / 3
		let l:cursorPos[2] += 62
		call setpos(".",cursorPos)
	elseif (l:cursorPos[2] + l:cursorPos[3]) >= 62 && (l:cursorPos[2] + l:cursorPos[3]) <= 77
		let l:cursorPos[2] -= (51 - (l:cursorPos[2] - 62) * 2)
		call setpos(".",cursorPos)
	endif
endfunction"}}}

"Show Hex and Ascii Info"{{{
function! s:getHexUnderCursor()
	let l:currentHexLine=split(strpart(getline("."),10,47))
	let l:cursorPos = getpos(".")
	return l:currentHexLine[(l:cursorPos[2] - 11)/3]
endfunction

function! s:getAsciiUndirCursor() 
	let l:currentLine=getline(".")
	let l:cursorPos = getpos(".")
	return l:currentLine[l:cursorPos[2] - 1]
endfunction

function! vinarise#showVinaryInfo()
	let l:cursorPos = getpos(".")[2]
	if 11 <= l:cursorPos && l:cursorPos <= 57
		let l:currentHex = s:getHexUnderCursor()
		let l:binStr=''
		let l:asciiStr=''
		"Convert Hex to binary and ascii by Python
		python << EOF
import binascii,re,os,vim
vim.command('let l:binStr = \'%s\'' % bin(int(vim.eval('l:currentHex'),16))[2:])
def asciirepl(s):
  return binascii.unhexlify(s)  

vim.command('let l:asciiStr = \'%s\'' % asciirepl(vim.eval('l:currentHex')))
EOF
		echo printf("Bin: %s Dec: %d Oct: %o Hex: %x Ascii: %s", l:binStr, str2nr(l:currentHex,16),str2nr(l:currentHex,16),str2nr(l:currentHex,16), l:asciiStr)
	elseif 62 <= l:cursorPos && l:cursorPos <= 77
		let l:currentAscii = s:getAsciiUndirCursor()
		let l:Dec = char2nr(l:currentAscii)
		let l:binStr=''
		"Convert Hex to binary and ascii by Python
		python << EOF
import binascii,re,os,vim
vim.command('let l:binStr = \'%s\'' % bin(int(vim.eval('l:Dec'),10))[2:])
EOF
		echo printf("Bin: %s Dec: %d Oct: %o Hex: %x Ascii: %s", l:binStr, l:Dec,l:Dec,l:Dec, l:currentAscii)
	endif
endfunction"}}}

"Write Binary File"{{{
function! vinarise#writeOut(filePath)
	let l:binaryBuf = []
	for line in b:localBuf
		call add(l:binaryBuf, split(strpart(line,10,47)))
	endfor
	let l:outFile = ''	
	if a:filePath == ''
		let l:outFile = bufname('%')
	else
		let l:outFile = a:filePath
	endif
	python <<EOF
import os,vim
from struct import *

f = open(vim.eval('l:outFile'),'wb')

lines = vim.eval('l:binaryBuf')
for line in lines :
	for hexStr in line :
		f.write(pack('B', int(hexStr,16)))

f.close()
EOF
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
