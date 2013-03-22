" File: argedit.vim
" Description: Provides the :ArgEdit command to open your :args list
" in a buffer to manipulate it (add or remove files).
" Recommends: vim-itchy for improved scratch buffer opening.

function! s:GetNewlineSeparatedArgs()
	let old_c = @c

	let @c = ''
	redir @c
	silent args
	redir END

	" Remove the square brackets from around the selected file and trim off
	" the leading escape character.
	let files = substitute(@c[1:], '[\[\]]', '', 'g')
	let @c = old_c

	let file_list = split(files, ' ')
	let s:arg_count = len(file_list)

	if g:argedit_remove_dupes
		" uniquify arguments
		let d = {}
		for fname in file_list
			let d[fname] = 1
		endfor
		let file_list = keys(d)
	endif

	let files = join(file_list, "\n")

	return files
endf

function! s:AddLineToArgs()
	" Only add valid files to the arglist. We could add pseudo buffers (like
	" BufExplorer), but what exceptions.
	let fname = getline('.')
	if filereadable(fname)
		exec 'argadd '. fname
	endif
endf

function! s:ApplyChangesAndExit()
	" Clear all old args. Use how many we started with. This may have changed
	" if the user touched the arglist while the buffer was open.
	exec '0,'. s:arg_count .'argdelete'

	" Add each uncommented line.
	vglobal/^#/call s:AddLineToArgs()

	" Clear the scratch buffer
	bwipeout
endf

function! s:SetupArgEditBufferControl()
	nnoremap <buffer> ZZ :call <SID>ApplyChangesAndExit()<CR>
	silent! command -buffer WriteArgs :call <SID>ApplyChangesAndExit()<CR>
	" TODO: Add a :w and :wq and :x command. Probably need to use cmdalias:
	" https://github.com/vim-scripts/cmdalias.vim
endf

function! argedit#CreateArgEditBuffer()
	let file_list = s:GetNewlineSeparatedArgs()

	if exists(':Scratch') == 2
		" Itchy has some fancy split behavior and sets lots of buf options.
		let old_suffix = g:itchy_buffer_suffix
		let g:itchy_buffer_suffix = '-ArgEdit'
		Scratch
		let g:itchy_buffer_suffix = old_suffix
		" TODO: Are there any of itchy's options that we don't want? (hidden)
	else
		" Basic scratch buffer.
		vnew
		setlocal buftype=nofile
	endif

	let instructions = "# These are the files in your argument list."
	let instructions .= "\n# Update the list and use :WriteArgs or type ZZ to apply."
	let instructions .= "\n# Commented lines (like this one) and invalid files will be ignored."

	silent put =file_list
	silent 0put =instructions
	call s:SetupArgEditBufferControl()
endf

