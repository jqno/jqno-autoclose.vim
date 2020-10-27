if exists('g:loaded_jqno_autoclose')
    finish
endif
let g:loaded_jqno_autoclose = 1

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
let s:jqnoautoclose_punctuation = [ '.', ',', ':', ';', '?', '!', '=', '+', '-', '*', '/' ]

let s:jqnoautoclose_config = {
    \   '_default': s:jqnoautoclose_code,
    \   'gitcommit': s:jqnoautoclose_prose,
    \   'html': { 'parens': '([{<', 'quotes': s:jqnoautoclose_code['quotes'] },
    \   'markdown': s:jqnoautoclose_prose,
    \   'text': s:jqnoautoclose_prose,
    \   'ruby': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '''"`|' },
    \   'rust': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '"`|' },
    \   'vim': { 'parens': s:jqnoautoclose_code['parens'], 'quotes': '''`' },
    \   'xml': { 'parens': '([{<', 'quotes': s:jqnoautoclose_code['quotes'] },
    \   'xml.pom': { 'parens': '([{<', 'quotes': s:jqnoautoclose_code['quotes'] },
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
    if <SID>NextChar() ==? a:char
        let l:i = 0
        let l:result = ""
        while <SID>NextChar(l:i) ==? a:char
            let l:result .= "\<Right>"
            let l:i += 1
        endwhile
        return l:result
    endif
    if <SID>ExpandParenFully(v:false)
        if <SID>PrevChar() ==? a:char && <SID>PrevChar(1) ==? a:char
            return a:char . a:char . a:char . a:char . "\<Left>\<Left>\<Left>"
        endif
        if <SID>PrevChar() !=? a:char
            return a:char . a:char . "\<Left>"
        endif
    endif
    return a:char
endfunction

function! JqnoAutocloseSmartReturn() abort
    if !exists('b:jqnoautoclose_active')
        return "\<CR>"
    endif

    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    let l:prevprev = <SID>PrevChar(1)
    if index(b:jqnoautoclose_parens, l:prev) >= 0 &&
                \ l:next ==? b:jqnoautoclose_openclose[l:prev]
        return "\<CR>\<Esc>O"
    elseif l:prev ==? ' ' && index(b:jqnoautoclose_parens, l:prevprev) >= 0 &&
                \ l:next ==? ' ' && <SID>NextChar(1) ==? b:jqnoautoclose_openclose[l:prevprev]
        return "\<BS>\<CR>\<Esc>O"
    elseif exists('g:loaded_endwise')
        return "\<CR>\<C-R>=EndwiseDiscretionary()\<CR>"
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
    " First, if a CoC jump is possible, do that.
    if exists('g:did_coc_loaded')
        if coc#jumpable()
            return "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump', ''])\<CR>"
        endif
    endif
    " Next, if at the end of the line and the next line contains a closer, jump to the end of that next line.
    if <SID>NextChar() ==? '' && index(b:jqnoautoclose_parenclosers, trim(getline(line('.')+1))) >= 0
        return "\<Down>\<End>"
    endif
    " Next, if the next char is punctuation, jump through that.
    if index(s:jqnoautoclose_punctuation, <SID>NextChar()) >= 0
        return "\<Right>"
    endif
    " Finally, jump through parens and quotes.
    let l:i = 0
    let l:result = ''
    while index(b:jqnoautoclose_allclosers, <SID>NextChar(l:i)) >= 0
        let l:result .= "\<Right>"
        let l:i += 1
    endwhile
    return l:result
endfunction

function! JqnoAutocloseSmartSlash() abort
    if <SID>PrevChar() ==? '<'
        if <SID>NextChar() ==? '>'
            return "/\<Del>\<C-X>\<C-O>"
        endif
        return "/\<C-X>\<C-O>"
    endif
    return '/'
endfunction

function! s:ExpandParenFully(expandIfAfterWord) abort
    let l:nextchar = <SID>NextChar()
    let l:nextok = l:nextchar ==? '' || index(s:jqnoautoclose_punctuation, l:nextchar) >= 0 || index(b:jqnoautoclose_parenclosers, l:nextchar) >= 0
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
    let b:jqnoautoclose_active = 1
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

    inoremap <expr><silent><buffer> <BS> JqnoAutocloseSmartBackspace()
    inoremap <expr><silent><buffer> <Space> JqnoAutocloseSmartSpace()
    inoremap <expr><silent><buffer> <C-L> JqnoAutocloseSmartJump()

    if exists('g:loaded_jqno_tab')
        inoremap <expr><silent><buffer> <CR> pumvisible() ? tabjqno#accept() : JqnoAutocloseSmartReturn()
    else
        inoremap <expr><silent><buffer> <CR> JqnoAutocloseSmartReturn()
    endif
endfunction

augroup AutoClose
    autocmd!

    autocmd VimEnter,BufReadPost,BufNewFile * call <SID>CreateMappings()

    " I promised myself I wouldn't do this, but: here's some special-case logic for HTML and XML:
    " after </, remove the closing > again and call omni-complete instead (which will also close the tag).
    autocmd FileType xml inoremap <silent><expr><buffer> / JqnoAutocloseSmartSlash()
    autocmd FileType html inoremap <silent><expr><buffer> / JqnoAutocloseSmartSlash()
augroup END
