" File: argedit.vim
" Description: Provides the :ArgEdit command to open your :args list
" in a buffer to manipulate it (add or remove files).
" Recommends: vim-itchy for improved scratch buffer opening.

if exists('loaded_argedit') || &cp || version < 700
	finish
endif
let loaded_argedit = 1

if !exists("g:argedit_remove_dupes ")
	let g:argedit_remove_dupes = 1
endif

command! ArgEdit call argedit#CreateArgEditBuffer()

