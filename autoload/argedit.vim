" File: argedit.vim
" Description: Provides the :ArgEdit command to open your :args list
" in a buffer to manipulate it (add or remove files).
" Recommends: vim-itchy for improved scratch buffer opening.

function! s:UniquifyList(input_list) abort
	" Use a dictionary to create a unique list of inputs (since dictionary
	" keys must be unique).

	let d = {}
	for item in a:input_list
		let d[item] = 1
	endfor

	return keys(d)
endf

function! s:GetNewlineSeparatedArgs() abort
	" Get a string with the current args separated by newlines.

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
		let file_list = s:UniquifyList(file_list)
	endif

	let files = join(file_list, "\n")

	return files
endf

function! s:AddLineToArgs() abort
	" Add the current line to the argument list.
	"
	" Only add valid files to the arglist. We could add pseudo buffers (like
	" BufExplorer), but what exceptions would I want?
	let fname = getline('.')

	if filereadable(fname)
		" argadd uses spaces as separators. Since only adding one, we can
		" safely escape all spaces. This works even on windows with
		" noshellslash (where \ is escape and directory separator).
		let fname = escape(fname, ' ')
		exec 'argadd '. fname
	endif
endf

function! s:ApplyChangesAndExit() abort
	" Modify argument list to match buffer.

	" Clear all old args.
	0,$argdelete

	" Add each uncommented line.
	vglobal/^#/call s:AddLineToArgs()

	" Clear the scratch buffer
	bwipeout

	" Print out new arglist
	args
endf

function! s:AppendFiles(string_of_filenames) abort
	let files = substitute(a:string_of_filenames, ' ', "\n", 'g')
	silent $put =files
endf

function! s:SetupArgEditBufferControl() abort
	" Add some methods to signal completion of args modification.

	nnoremap <buffer> ZZ :call <SID>ApplyChangesAndExit()<CR>

	" WriteArgs won't be available if it's already defined.
	silent! command -buffer WriteArgs call <SID>ApplyChangesAndExit()<CR>
	" TODO: Add a :w and :wq and :x command. Probably need to use cmdalias:
	" https://github.com/vim-scripts/cmdalias.vim

	if exists(":Qargs") == 2 && exists("*QuickfixFilenames") > 0
		" Replace normal Qargs with one that just operates on this buffer.
		command! -buffer Qargs call <SID>AppendFiles(QuickfixFilenames())
	endif
endf

function! argedit#CreateArgEditBuffer() abort
	" Create the arg modifying buffer.

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

