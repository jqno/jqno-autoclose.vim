" ***
" Logic
" ***

let s:jqnoautoclose_openclosers = { '(': ')', '[': ']', '{': '}', '<': '>' }
let s:jqnoautoclose_code = {
    \   'parens': '([{',
    \   'quotes': '''"`',
    \ }
let s:jqnoautoclose_prose = {
    \   'parens': '([{',
    \   'quotes': '''"`',
    \ }

let s:jqnoautoclose_config = {
    \   '_default': s:jqnoautoclose_code,
    \   'gitcommit': s:jqnoautoclose_prose,
    \   'html': { 'parens': '([{<', 'quotes': s:jqnoautoclose_code['quotes'] },
    \   'markdown': s:jqnoautoclose_prose,
    \   'text': s:jqnoautoclose_prose,
    \   'ruby': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '''"`|' },
    \   'rust': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '''"`|' },
    \   'vim': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '''`' },
    \   'xml': { 'parens': '([{<', 'quotes': s:jqnoautoclose_code['quotes'] },
    \ }


function! JqnoAutocloseOpen(open, close) abort
    return <SID>ExpandParenFully(v:true) ? a:open . a:close . "\<Left>" : a:open
endfunction

function! JqnoAutocloseClose(close) abort
    let l:i = 0
    let l:result = "\<Right>"
    while <SID>NextChar(l:i) ==? ' '
        let l:result .= "\<Right>"
        let l:i += 1
    endwhile
    return <SID>NextChar(l:i) ==? a:close ? l:result : a:close
endfunction

function! JqnoAutocloseToggle(char) abort
    return <SID>NextChar() ==? a:char ? "\<Right>" : <SID>ExpandParenFully(v:false) ? a:char . a:char . "\<Left>" : a:char
endfunction

function! JqnoAutocloseSmartReturn() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    let l:prevprev = <SID>PrevChar(1)
    if pumvisible()
        return "\<C-Y>"
    elseif index(b:jqnoautoclose_parens, l:prev) >= 0 &&
                \ l:next ==? b:jqnoautoclose_openclose[l:prev]
        return "\<CR>\<Esc>O"
    elseif l:prev ==? ' ' && index(b:jqnoautoclose_parens, l:prevprev) >= 0 &&
                \ l:next ==? ' ' && <SID>NextChar(1) ==? b:jqnoautoclose_openclose[l:prevprev]
        return "\<BS>\<CR>\<Esc>O"
    else
        return "\<CR>"
    endif
endfunction

function! JqnoAutocloseSmartSpace() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    if l:prev !=? '' && index(b:jqnoautoclose_parens, l:prev) >= 0 && l:next ==? b:jqnoautoclose_openclose[l:prev]
        return "  \<Left>"
    else
        return " "
    endif
endfunction

function! JqnoAutocloseSmartBackspace() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    let l:prevprev = <SID>PrevChar(1)
    if index(b:jqnoautoclose_combined, l:prev) >= 0 &&
                \ l:next ==? b:jqnoautoclose_openclose[l:prev]
        return "\<BS>\<Del>"
    elseif l:prev ==? ' ' && index(b:jqnoautoclose_combined, l:prevprev) >= 0 &&
                \ l:next ==? ' ' && <SID>NextChar(1) ==? b:jqnoautoclose_openclose[l:prevprev]
        return "\<BS>\<Del>"
    else
        return "\<BS>"
    endif
endfunction

function! JqnoAutocloseSmartJump() abort
    let l:i = 0
    let l:result = ''
    while index(b:jqnoautoclose_allclosers, <SID>NextChar(l:i)) >= 0
        let l:result .= "\<Right>"
        let l:i += 1
    endwhile
    return l:result
endfunction

function! s:ExpandParenFully(expandIfAfterWord) abort
    let l:nextchar = <SID>NextChar()
    let l:nextok = l:nextchar ==? '' || index(b:jqnoautoclose_parenclosers, l:nextchar) >= 0
    let l:prevchar = <SID>PrevChar()
    let l:prevok = a:expandIfAfterWord || l:prevchar !~# '\w'
    return l:nextok && l:prevok
endfunction

function! s:NextChar(i = 0) abort
    return strpart(getline('.'), col('.')-1+a:i, 1)
endfunction

function! s:PrevChar(i = 0) abort
    return strpart(getline('.'), col('.')-2-a:i, 1)
endfunction


" ***
" Helpers
" ***

function! s:Filetype() abort
    return &filetype ==? '' || !has_key(s:jqnoautoclose_config, &filetype) ? '_default' : &filetype
endfunction

function! s:Parens() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['parens'], '\zs')
endfunction

function! s:Quotes() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['quotes'], '\zs')
endfunction

function! s:OpenClose(combined) abort
    let l:result = {}
    for c in a:combined
        if has_key(s:jqnoautoclose_openclosers, c)
            let l:result[c] = s:jqnoautoclose_openclosers[c]
        else
            let l:result[c] = c
        end
    endfor
    return l:result
endfunction

function! s:Closers(openers) abort
    let l:result = [' ']
    for c in a:openers
        call add(l:result, b:jqnoautoclose_openclose[c])
    endfor
    return l:result
endfunction


" ***
" Mappings
" ***

function! s:CreateMappings() abort
    let b:jqnoautoclose_parens = <SID>Parens()
    let b:jqnoautoclose_quotes = <SID>Quotes()
    let b:jqnoautoclose_combined = b:jqnoautoclose_parens + b:jqnoautoclose_quotes
    let b:jqnoautoclose_openclose = <SID>OpenClose(b:jqnoautoclose_combined)
    let b:jqnoautoclose_parenclosers = <SID>Closers(b:jqnoautoclose_parens)
    let b:jqnoautoclose_allclosers = <SID>Closers(b:jqnoautoclose_combined)

    for c in b:jqnoautoclose_parens
        exec 'inoremap <expr><silent><buffer> ' . c . ' JqnoAutocloseOpen("' . c . '", "' . b:jqnoautoclose_openclose[c] . '")'
        exec 'inoremap <expr><silent><buffer> ' . b:jqnoautoclose_openclose[c] . ' JqnoAutocloseClose("' . b:jqnoautoclose_openclose[c] . '")'
    endfor
    for c in b:jqnoautoclose_quotes
        let l:mapchar = c ==? '|' ? '\|' : c
        let l:togglechar = c ==? '"' || c ==? '|' ? '\' . c : c
        exec 'inoremap <expr><silent><buffer> ' . l:mapchar . ' JqnoAutocloseToggle("' . l:togglechar . '")'
    endfor

    inoremap <expr><silent> <BS> JqnoAutocloseSmartBackspace()
    inoremap <expr><silent> <CR> JqnoAutocloseSmartReturn()
    inoremap <expr><silent> <Space> JqnoAutocloseSmartSpace()
    inoremap <expr><silent> <C-L> JqnoAutocloseSmartJump()
endfunction

augroup AutoClose
    autocmd!

    autocmd BufReadPost,BufNewFile * call <SID>CreateMappings()
augroup END
