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
  setlocal modifiable

  if !exists('b:pageNum')
	  let b:pageNum = 1
  endif
  "Save latest args
  let b:lastFileName = a:filename
  let b:lastOverWrite = a:is_overwrite

  if !exists('b:localBuf')
	  let b:localBuf = [[], [], []]
	  python << EOF
import mmap, os, vim
#escaping string to vimstyle
def vimstr(s) :
	return "'" + s.replace("'","''") + "'"
#House data to vim buffer local array as vinary
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
		"Convert data structure
		let l:hexLineArry = []
		let l:AsciiLineArry = []
		for i in range(0,len(b:localBuf[0])-1)
			call extend(l:hexLineArry,split(b:localBuf[1][i]))
			call extend(l:AsciiLineArry, split(b:localBuf[2][i],'\zs'))
		endfor
		let b:localBuf = [b:localBuf[0],l:hexLineArry, l:AsciiLineArry]
	endif
	"Print Page in buffer
	for lineNum in range((b:pageNum - 1) * 100, (b:pageNum * 100 - 1) >= (len(b:localBuf[0]) - 1) ? (len(b:localBuf[0]) - 1) : b:pageNum * 100 - 1)
		call setline((lineNum - ((b:pageNum - 1) * 100)) + 1, 
					\ printf('%s %s%s |  %s',
					\ 		b:localBuf[0][lineNum],
					\               join(b:localBuf[1][(lineNum * 16) : (lineNum * 16 + 15)]),
					\		repeat(' ',(16 - len(b:localBuf[1][(lineNum * 16) :])) * 3),
					\		join(b:localBuf[2][(lineNum * 16) : (lineNum * 16 + 15)], '')))
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

"Edit function"{{{
function! s:isHexAlpha(char)
	let l:nr = char2nr(a:char)
	if (97 <= l:nr && l:nr <= 102)
		return 1
	else
		return 0
	endif
endfunction

function! s:isNumber(char)
	let l:nr = char2nr(a:char)
	if (48 <= l:nr && l:nr <= 57)
		return 1
	else
		return 0
	endif
endfunction

function! s:overWriteHex()
	let l:char = nr2char(getchar())
	let l:cursorPos = getpos('.')
	let l:HexIndex = ((b:pageNum - 1) * 100 * 16 
				\ 	+ (l:cursorPos[1] - 1)* 16
				\	+ (l:cursorPos[2] - 11)/3)
	let l:figure = (l:cursorPos[2] - 11) % 3 == 0 ? 1 : 0
	let l:newChar = ''
	if s:isHexAlpha(l:char) || s:isNumber(l:char)
		if l:figure == 1
			let l:newChar = join([l:char, b:localBuf[1][l:HexIndex][1 :]], '')
		else
			let l:newChar = join([b:localBuf[1][l:HexIndex][0], l:char], '')
		endif
		let b:localBuf[1][l:HexIndex] = l:newChar
		let b:localBuf[2][l:HexIndex] = nr2char(str2nr(l:newChar,16))
		"Redisplay Vinary
		call vinarise#open(b:lastFileName,b:lastOverWrite)
		"Replace cursor
		call setpos('.',l:cursorPos)
	endif
endfunction

function! s:overWriteAscii()
	let l:charDec = getchar()
	let l:cursorPos = getpos('.')
	let l:AsciiIndex = ((b:pageNum - 1) * 100 * 16 
				\ 	+ (l:cursorPos[1] - 1)* 16
				\	+ (l:cursorPos[2] - 62))
	let l:newHex = printf('%x',l:charDec)
	let b:localBuf[1][l:AsciiIndex] = l:newHex
	let b:localBuf[2][l:AsciiIndex] = nr2char(str2nr(l:newHex,16))
	"Redisplay Vinary
	call vinarise#open(b:lastFileName,b:lastOverWrite)
	"Replace cursor
	call setpos('.',l:cursorPos)
endfunction

function! vinarise#overWriteVinary()
	let l:cursorPos = getpos('.')
	if (l:cursorPos[2] + l:cursorPos[3]) >= 11 && (l:cursorPos[2] + l:cursorPos[3]) <= 57
		call s:overWriteHex()
	elseif (l:cursorPos[2] + l:cursorPos[3]) >= 62 && (l:cursorPos[2] + l:cursorPos[3]) <= 77
		call s:overWriteAscii()
	else

	endif
endfunction

function! s:removeHex()
	let l:currentHexLine=split(strpart(getline("."),10,47))
	let l:cursorPos = getpos(".")
	let l:HexIndex = (((b:pageNum - 1) * 100 
				\	+ l:cursorPos[1]-1) * 16  
				\	+ (l:cursorPos[2] - 11)/3)
	call remove(b:localBuf[1], l:HexIndex)
	call remove(b:localBuf[2], l:HexIndex)
	if (len(b:localBuf[1][((len(b:localBuf[0]) -1) * 16 - 1) :]) ) == 1
		echo "RemoveLast Line"
		call remove(b:localBuf[0], -1)
		if len(b:localBuf[0]) % 100 == 0
			let b:pageNum -= 1
			let l:cursorPos[1] = 100
			let l:cursorPos[2] = 56
		endif
		call vinarise#open(b:lastFileName,b:lastOverWrite)
		if l:cursorPos[1] == (len(b:localBuf[0]) - ((b:pageNum - 1) * 100) + 1)
			let  l:cursorPos[1] -= 1
			let  l:cursorPos[2] = 56 
		endif
		call setpos('.', l:cursorPos)
	else 
		call vinarise#open(b:lastFileName,b:lastOverWrite)
		call setpos('.',cursorPos)	
	endif
endfunction

function! s:removeAscii()
	let l:cursorPos = getpos(".")
	let l:AsciiIndex = (((b:pageNum - 1) * 100 
				\	+ l:cursorPos[1]-1) * 16  
				\	+ (l:cursorPos[2] - 62))
	call remove(b:localBuf[1], l:AsciiIndex)
	call remove(b:localBuf[2], l:AsciiIndex)
	if (len(b:localBuf[1][((len(b:localBuf[0]) -1) * 16 - 1) :]) ) == 1
		call remove(b:localBuf[0], -1)
		if len(b:localBuf[0]) % 100 == 0
			let b:pageNum -= 1
			let l:cursorPos[1] = 100
			let l:cursorPos[2] = 77 
		endif
		call vinarise#open(b:lastFileName,b:lastOverWrite)
		if l:cursorPos[1] == (len(b:localBuf[0]) - ((b:pageNum - 1) * 100) + 1)
			let  l:cursorPos[1] -= 1
			let  l:cursorPos[2] = 77
		endif
		call setpos('.', l:cursorPos)
	else 
		call vinarise#open(b:lastFileName,b:lastOverWrite)
		call setpos('.',cursorPos)	
	endif
endfunction

function! vinarise#removeVinary()
	let l:cursorPos = getpos('.')
	if (l:cursorPos[2] + l:cursorPos[3]) >= 11 && (l:cursorPos[2] + l:cursorPos[3]) <= 57
		call s:removeHex()
	elseif (l:cursorPos[2] + l:cursorPos[3]) >= 62 && (l:cursorPos[2] + l:cursorPos[3]) <= 77
		call s:removeAscii()
	else

	endif
endfunction
"}}}

"Write Binary File"{{{
function! vinarise#writeOut(filePath)
	let l:outFile = ''	
	echo a:filePath
	if a:filePath == ''
		let l:outFile = b:lastFileName
	else
		let l:outFile = a:filePath
	endif
	python <<EOF
import os,vim
from struct import *

def writeOut() :
	f = open(vim.eval('l:outFile'),'wb')
	lines = vim.eval('b:localBuf[1]')
	for hexStr in lines :
		f.write(pack('B', int(hexStr,16)))

	f.close()

writeOut()
EOF
endfunction"}}}

"Bitmap view""{{{
function! s:calcColor(hexStr)
	let l:nr = str2nr(a:hexStr,16)
	if l:nr == str2nr('00', 16)
		return [255, 255, 255]
	elseif str2nr('01',16) <= l:nr && l:nr <= str2nr('1F', 16)
		return [0,255,255]
	elseif str2nr('20', 16) <= l:nr && l:nr <= str2nr('7F', 16)
		return [255, 0,0]
	elseif str2nr('80', 16) <= l:nr && l:nr <= str2nr('FF', 16)
		return [255, 255, 255]
	endif
endfunction

function! vinarise#writeBitmapView(filepath)
	"Fillable image line
	let l:fillAbleImgLine = len(b:localBuf[1])/128 
	"rest line
	let l:rest = 128 - len(b:localBuf[1])%128
	python<<EOM
from PIL import Image
def createBitmapImage():
	img = Image.new('RGB', (128, int(vim.eval('l:fillAbleImgLine')) + 1))
	buflen = int(vim.eval('len(b:localBuf[1])'))
	#if there is no bite in vinary
	if buflen == 0:
		return
	#if 0 < buflen <= 128
	elif buflen <= 128:
		for x in range(0, buflen):
			img.putpixel((x,0),(int(vim.eval('s:calcColor(\'%s\')[0]' % vim.eval('b:localBuf[1][%d]' % x))),
					    int(vim.eval('s:calcColor(\'%s\')[1]' % vim.eval('b:localBuf[1][%d]' % x))),
					    int(vim.eval('s:calcColor(\'%s\')[2]' % vim.eval('b:localBuf[1][%d]' % x)))))
	else:
		for y in range(0, buflen / 128):
			for x in range(0, 128):
				index = y * 128 + x
				img.putpixel( (x, y), (int(vim.eval('s:calcColor(\'%s\')[0]' % vim.eval('b:localBuf[1][%d]' % index))),
						       int(vim.eval('s:calcColor(\'%s\')[1]' % vim.eval('b:localBuf[1][%d]' % index))),
						       int(vim.eval('s:calcColor(\'%s\')[2]' % vim.eval('b:localBuf[1][%d]' % index)))))

		for x in range(0, buflen % 128):
			index = (buflen/128) * 128 + x
			img.putpixel( (x, buflen/128), (int(vim.eval('s:calcColor(\'%s\')[0]' % vim.eval('b:localBuf[1][%d]' % index))),
							int(vim.eval('s:calcColor(\'%s\')[1]' % vim.eval('b:localBuf[1][%d]' % index))),
							int(vim.eval('s:calcColor(\'%s\')[2]' % vim.eval('b:localBuf[1][%d]' % index)))))

	img.save(vim.eval('a:filepath'), "PNG")

createBitmapImage()
EOM
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
