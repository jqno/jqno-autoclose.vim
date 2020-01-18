" ***
" Logic
" ***

let s:openclosers = { '(': ')', '[': ']', '{': '}', '<': '>' }
let s:autoclosejqno_code = {
    \   'parens': '([{',
    \   'quotes': '''"`',
    \ }
let s:autoclosejqno_prose = {
    \   'parens': '([{',
    \   'quotes': '''"`',
    \ }

let s:autoclosejqno_config = {
    \   '_default': s:autoclosejqno_code,
    \   'gitcommit': s:autoclosejqno_prose,
    \   'html': { 'parens': '([{<', 'quotes': s:autoclosejqno_code['quotes'] },
    \   'markdown': s:autoclosejqno_prose,
    \   'text': s:autoclosejqno_prose,
    \   'ruby': { 'parens': s:autoclosejqno_code['parens'], 'quotes': '''"`|' },
    \   'rust': { 'parens': s:autoclosejqno_code['parens'], 'quotes': '''"`|' },
    \   'vim': { 'parens': s:autoclosejqno_code['parens'], 'quotes': '''`' },
    \   'xml': { 'parens': '([{<', 'quotes': s:autoclosejqno_code['quotes'] },
    \ }


function! AutocloseOpen(open, close) abort
    return <SID>ExpandParenFully(v:true) ? a:open . a:close . "\<Left>" : a:open
endfunction

function! AutocloseClose(close) abort
    let l:i = 0
    let l:result = "\<Right>"
    while <SID>NextChar(l:i) ==? ' '
        let l:result .= "\<Right>"
        let l:i += 1
    endwhile
    return <SID>NextChar(l:i) ==? a:close ? l:result : a:close
endfunction

function! AutocloseToggle(char) abort
    return <SID>NextChar() ==? a:char ? "\<Right>" : <SID>ExpandParenFully(v:false) ? a:char . a:char . "\<Left>" : a:char
endfunction

function! AutocloseSmartReturn() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    if pumvisible()
        return "\<C-Y>"
    elseif l:prev !=? '' && index(b:autoclosejqno_parens, l:prev) >= 0 && l:next ==? b:autoclosejqno_openclose[l:prev]
        return "\<CR>\<Esc>O"
    else
        return "\<CR>"
    endif
endfunction

function! AutocloseSmartSpace() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    if l:prev !=? '' && index(b:autoclosejqno_parens, l:prev) >= 0 && l:next ==? b:autoclosejqno_openclose[l:prev]
        return "  \<Left>"
    else
        return " "
    endif
endfunction

function! AutocloseSmartBackspace() abort
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    for c in b:autoclosejqno_combined
        if l:prev ==? c && l:next ==? b:autoclosejqno_openclose[c]
            return "\<BS>\<Del>"
        elseif l:prev ==? ' ' && <SID>PrevChar(1) ==? c && l:next ==? ' ' && <SID>NextChar(1) ==? b:autoclosejqno_openclose[c]
            return "\<BS>\<Del>"
        endif
    endfor
    return "\<BS>"
endfunction

function! AutocloseSmartJump() abort
    let l:i = 0
    let l:result = ''
    while index(b:autoclosejqno_closers, <SID>NextChar(l:i)) >= 0
        let l:result .= "\<Right>"
        let l:i += 1
    endwhile
    return l:result
endfunction

function! s:ExpandParenFully(expandIfAfterWord) abort
    let l:nextchar = <SID>NextChar()
    let l:nextok = l:nextchar ==? '' || index(b:autoclosejqno_closers, l:nextchar) >= 0
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
    return &filetype ==? '' || !has_key(s:autoclosejqno_config, &filetype) ? '_default' : &filetype
endfunction

function! s:Parens() abort
    return split(s:autoclosejqno_config[<SID>Filetype()]['parens'], '\zs')
endfunction

function! s:Quotes() abort
    return split(s:autoclosejqno_config[<SID>Filetype()]['quotes'], '\zs')
endfunction

function! s:OpenClose(combined) abort
    let l:result = {}
    for c in a:combined
        if has_key(s:openclosers, c)
            let l:result[c] = s:openclosers[c]
        else
            let l:result[c] = c
        end
    endfor
    return l:result
endfunction

function! s:Closers(combined) abort
    let l:result = [' ']
    for c in a:combined
        call add(l:result, b:autoclosejqno_openclose[c])
    endfor
    return l:result
endfunction


" ***
" Mappings
" ***

function! s:CreateMappings() abort
    let b:autoclosejqno_parens = <SID>Parens()
    let b:autoclosejqno_quotes = <SID>Quotes()
    let b:autoclosejqno_combined = b:autoclosejqno_parens + b:autoclosejqno_quotes
    let b:autoclosejqno_openclose = <SID>OpenClose(b:autoclosejqno_combined)
    let b:autoclosejqno_closers = <SID>Closers(b:autoclosejqno_combined)

    for c in b:autoclosejqno_parens
        exec 'inoremap <expr><silent><buffer> ' . c . ' AutocloseOpen("' . c . '", "' . b:autoclosejqno_openclose[c] . '")'
        exec 'inoremap <expr><silent><buffer> ' . b:autoclosejqno_openclose[c] . ' AutocloseClose("' . b:autoclosejqno_openclose[c] . '")'
    endfor
    for c in b:autoclosejqno_quotes
        let l:mapchar = c ==? '|' ? '\|' : c
        let l:togglechar = c ==? '"' || c ==? '|' ? '\' . c : c
        exec 'inoremap <expr><silent><buffer> ' . l:mapchar . ' AutocloseToggle("' . l:togglechar . '")'
    endfor

    inoremap <expr><silent> <BS> AutocloseSmartBackspace()
    inoremap <expr><silent> <CR> AutocloseSmartReturn()
    inoremap <expr><silent> <Space> AutocloseSmartSpace()
    inoremap <expr><silent> <C-L> AutocloseSmartJump()
endfunction

augroup AutoClose
    autocmd!

    autocmd BufReadPost,BufNewFile * call <SID>CreateMappings()
augroup END
