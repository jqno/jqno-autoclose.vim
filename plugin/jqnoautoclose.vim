if exists('g:loaded_jqno_autoclose')
    finish
endif
let g:loaded_jqno_autoclose = 1

" We don't want conflicting <CR> mappings.
" This plugin will call Endwise when needed.
let g:endwise_no_mappings = 1

" ***
" Logic
" ***

" 7.4.849 support <C-G>U to avoid breaking '.'
" Issue talk: https://github.com/jiangmiao/auto-pairs/issues/3
" Vim note: https://github.com/vim/vim/releases/tag/v7.4.849
" Solution 'borrowed' from jiangmiao/auto-pairs
let s:Go = "\<C-G>U"
let s:Left = s:Go . "\<Left>"
let s:Right = s:Go . "\<Right>"

function! s:Config(base, overrides = {}) abort
    let l:result = deepcopy(a:base)
    if has_key(a:overrides, 'parens')
        let l:result.parens = deepcopy(a:overrides.parens)
    endif
    if has_key(a:overrides, 'parens_backspaceonly')
        let l:result.parens_backspaceonly = deepcopy(a:overrides.parens_backspaceonly)
    endif
    if has_key(a:overrides, 'quotes')
        let l:result.quotes = deepcopy(a:overrides.quotes)
    endif
    if has_key(a:overrides, 'doublequotes')
        let l:result.doublequotes = deepcopy(a:overrides.doublequotes)
    endif
    if has_key(a:overrides, 'triplequotes')
        let l:result.triplequotes = deepcopy(a:overrides.triplequotes)
    endif
    return l:result
endfunction

let s:jqnoautoclose_openclosers = { '(': ')', '[': ']', '{': '}', '<': '>' }
let s:jqnoautoclose_code = {
    \   'parens': '([{',
    \   'parens_backspaceonly': '<',
    \   'quotes': '''"`',
    \   'doublequotes': '',
    \   'triplequotes': '',
    \ }
let s:jqnoautoclose_prose = {
    \   'parens': '([{',
    \   'parens_backspaceonly' : '',
    \   'quotes': '''"`',
    \   'doublequotes': '',
    \   'triplequotes': '',
    \ }
let s:jqnoautoclose_punctuation = [ '.', ',', ':', ';', '?', '!', '=', '+', '-', '*', '/' ]

let s:jqnoautoclose_config = {
    \   '_default': <SID>Config(s:jqnoautoclose_code),
    \   'gitcommit': <SID>Config(s:jqnoautoclose_prose),
    \   'java': <SID>Config(s:jqnoautoclose_code, {'triplequotes': '"'}),
    \   'html': <SID>Config(s:jqnoautoclose_code),
    \   'markdown': <SID>Config(s:jqnoautoclose_prose, {'quotes': '''"`*_', 'doublequotes': '*_', 'triplequotes': '`:'}),
    \   'text': <SID>Config(s:jqnoautoclose_prose),
    \   'python': <SID>Config(s:jqnoautoclose_code, {'triplequotes': '"'}),
    \   'ruby': <SID>Config(s:jqnoautoclose_code, {'quotes': '''"`|'}),
    \   'rust': <SID>Config(s:jqnoautoclose_code, {'quotes': '"`|'}),
    \   'scala': <SID>Config(s:jqnoautoclose_code, {'triplequotes': '"'}),
    \   'vim': <SID>Config(s:jqnoautoclose_code, {'quotes': '''`'}),
    \   'xml': <SID>Config(s:jqnoautoclose_code),
    \   'xml.pom': <SID>Config(s:jqnoautoclose_code),
    \ }


function! JqnoAutocloseOpen(open, close) abort
    return <SID>ExpandParenFully(v:true) ? a:open . a:close . s:Left : a:open
endfunction

function! JqnoAutocloseClose(close) abort
    let l:i = 0
    let l:result = s:Right
    while <SID>NextChar(l:i) ==? ' '
        let l:result .= s:Right
        let l:i += 1
    endwhile
    return <SID>NextChar(l:i) ==? a:close ? l:result : a:close
endfunction

function! JqnoAutocloseToggle(char) abort
    if <SID>NextChar() ==? a:char
        if index(b:jqnoautoclose_doublequotes, a:char) >= 0
            return a:char . a:char . s:Left
        else
            let l:i = 0
            let l:result = ""
            while <SID>NextChar(l:i) ==? a:char
                let l:result .= s:Right
                let l:i += 1
            endwhile
            return l:result
        endif
    endif
    if <SID>ExpandParenFully(v:false, a:char)
        if index(b:jqnoautoclose_triplequotes, a:char) >= 0 &&
                    \ <SID>PrevChar() ==? a:char && <SID>PrevChar(1) ==? a:char
            return a:char . a:char . a:char . a:char . s:Left . s:Left . s:Left
        endif
        if index(b:jqnoautoclose_doublequotes, a:char) >= 0 &&
                    \ <SID>PrevChar() ==? a:char
            return a:char . a:char . a:char . s:Left . s:Left
        endif
        if index(b:jqnoautoclose_quotes, a:char) >= 0 &&
                    \ <SID>PrevChar() !=? a:char
            return a:char . a:char . s:Left
        endif
    endif
    return a:char
endfunction

function! JqnoAutocloseSmartReturn() abort
    if !exists('b:jqnoautoclose_active')
        return "\<CR>"
    endif

    let l:first = <SID>FirstChar()
    let l:prev = <SID>PrevChar()
    let l:next = <SID>NextChar()
    let l:prevprev = <SID>PrevChar(1)
    if index(b:jqnoautoclose_parens, l:prev) >= 0 &&
                \ l:next ==? b:jqnoautoclose_openclose[l:prev]
        return "\<CR>\<Esc>O"
    elseif l:prev ==? ' ' && index(b:jqnoautoclose_parens, l:prevprev) >= 0 &&
                \ l:next ==? ' ' && <SID>NextChar(1) ==? b:jqnoautoclose_openclose[l:prevprev]
        return "\<BS>\<CR>\<Esc>O"
    elseif index(b:jqnoautoclose_triplequotes, l:next) >= 0 &&
                \ l:first ==? l:next
        return "\<CR>\<Esc>O"
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
    " Then, if an UltiSnips jump is possible, do that.
    if exists('g:did_plugin_ultisnips') && UltiSnips#CanJumpForwards()
        return "\<C-R>=UltiSnips#JumpForwards()\<CR>"
    endif
    " Next, if at the end of the line and the next line contains a closer, jump to the end of that next line.
    if <SID>NextChar() ==? '' && index(b:jqnoautoclose_parenclosers, trim(getline(line('.')+1))) >= 0
        return "\<Down>\<End>"
    endif
    " Next, if the next char is punctuation, jump through that.
    if index(s:jqnoautoclose_punctuation, <SID>NextChar()) >= 0
        return s:Right
    endif
    " Finally, jump through parens and quotes.
    let l:i = 0
    let l:result = ''
    while index(b:jqnoautoclose_allclosers, <SID>NextChar(l:i)) >= 0
        let l:result .= s:Right
        let l:i += 1
    endwhile
    return l:result
endfunction

function! s:ExpandParenFully(expandIfAfterWord, char = v:null) abort
    let l:nextchar = <SID>NextChar()
    let l:nextok = l:nextchar ==? '' || index(s:jqnoautoclose_punctuation, l:nextchar) >= 0 || index(b:jqnoautoclose_parenclosers, l:nextchar) >= 0
    let l:prevchar = <SID>PrevChar()
    let l:prevok = a:expandIfAfterWord || l:prevchar !~# '\w' || a:char ==? '_'
    return l:nextok && l:prevok
endfunction

function! s:NextChar(i = 0) abort
    return strpart(getline('.'), col('.')-1+a:i, 1)
endfunction

function! s:PrevChar(i = 0) abort
    return strpart(getline('.'), col('.')-2-a:i, 1)
endfunction

function! s:FirstChar() abort
    return strpart(getline('.'), 0, 1)
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

function! s:BackspaceOnly() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['parens_backspaceonly'], '\zs')
endfunction

function! s:Quotes() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['quotes'], '\zs')
endfunction

function! s:Doublequotes() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['doublequotes'], '\zs')
endfunction

function! s:Triplequotes() abort
    return split(s:jqnoautoclose_config[<SID>Filetype()]['triplequotes'], '\zs')
endfunction

function! s:AllQuotes() abort
    let l:result = deepcopy(b:jqnoautoclose_quotes)
    for c in b:jqnoautoclose_doublequotes
        if index(b:jqnoautoclose_quotes, c) == -1
            let l:result += [c]
        endif
    endfor
    for c in b:jqnoautoclose_triplequotes
        if index(b:jqnoautoclose_quotes, c) == -1
            let l:result += [c]
        endif
    endfor
    return l:result
endfunction

function! s:OpenClose(combined) abort
    let l:result = {}
    for c in a:combined
        if has_key(s:jqnoautoclose_openclosers, c)
            let l:result[c] = s:jqnoautoclose_openclosers[c]
        else
            let l:result[c] = c
        endif
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
    let b:jqnoautoclose_backspaceonly = <SID>BackspaceOnly()
    let b:jqnoautoclose_quotes = <SID>Quotes()
    let b:jqnoautoclose_doublequotes = <SID>Doublequotes()
    let b:jqnoautoclose_triplequotes = <SID>Triplequotes()
    let b:jqnoautoclose_all_quotes = <SID>AllQuotes()
    let b:jqnoautoclose_combined = b:jqnoautoclose_parens + b:jqnoautoclose_all_quotes + b:jqnoautoclose_backspaceonly
    let b:jqnoautoclose_openclose = <SID>OpenClose(b:jqnoautoclose_combined)
    let b:jqnoautoclose_parenclosers = <SID>Closers(b:jqnoautoclose_parens)
    let b:jqnoautoclose_allclosers = <SID>Closers(b:jqnoautoclose_combined)

    for c in b:jqnoautoclose_parens
        exec 'inoremap <expr><silent><buffer> ' . c . ' JqnoAutocloseOpen("' . c . '", "' . b:jqnoautoclose_openclose[c] . '")'
        exec 'inoremap <expr><silent><buffer> ' . b:jqnoautoclose_openclose[c] . ' JqnoAutocloseClose("' . b:jqnoautoclose_openclose[c] . '")'
    endfor
    for c in b:jqnoautoclose_all_quotes
        let l:mapchar = c ==? '|' ? '\|' : c
        let l:togglechar = c ==? '"' || c ==? '|' ? '\' . c : c
        exec 'inoremap <expr><silent><buffer> ' . l:mapchar . ' JqnoAutocloseToggle("' . l:togglechar . '")'
    endfor

    inoremap <expr><silent><buffer> <BS> JqnoAutocloseSmartBackspace()
    inoremap <expr><silent><buffer> <Space> JqnoAutocloseSmartSpace()

    if maparg('<C-L>', 'i') ==# ''
        inoremap <expr><silent><buffer> <C-L> JqnoAutocloseSmartJump()
    endif
    inoremap <expr><silent><buffer> <CR> JqnoAutocloseSmartReturn()
endfunction

augroup AutoClose
    autocmd!

    autocmd VimEnter,BufReadPost,BufNewFile * call <SID>CreateMappings()
augroup END
