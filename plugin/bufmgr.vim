" close split only or remove buffer
function! s:hasMultiWindow()
    let l:cur_bufid = bufnr('%')
    let l:tablist = range(1, tabpagenr("$"))
    let l:count = 0
    for tabnumber in l:tablist
        let l:buflist = tabpagebuflist(tabnumber)
        for bufid in l:buflist
            if (bufid == l:cur_bufid)
                let l:count = l:count + 1
                if (l:count > 1)
                    return 1
                endif
            endif
        endfor
    endfor
    return 0
endfunction

function! CloseBufOrWin()
    if (s:hasMultiWindow())
        execute 'q'
    else
        execute 'bd'
    endif
endfunction


" goto last tab
let g:mru_tabepage_list = []
let g:mru_tabepage_list_size = 20
function! <SID>OnTabLeave()
    let l:filename = expand("%:p")
    " echom "OnTabLeave " . l:filename
    if (len(l:filename))
        let l:bufnumber = bufnr('%')
        if (bufloaded(l:bufnumber) && buflisted(l:bufnumber))
            call add(g:mru_tabepage_list, expand("%:p"))
            if (len(g:mru_tabepage_list) > g:mru_tabepage_list_size)
                call remove(g:mru_tabepage_list, 0)
            endif
        endif
    endif
endfunction

function! <SID>GoToLastTab()
    " echom "GoToLastTab " . join(g:mru_tabepage_list)
    let l:found = 0
    while (len(g:mru_tabepage_list) && !l:found)
        let l:filename = remove(g:mru_tabepage_list, -1)
        let l:bufnumber = bufnr(l:filename)
        if (l:bufnumber < 0)
            continue
        endif
        let l:tablist = range(1, tabpagenr("$"))
        let l:tabnumber = -1
        for tabnumber in l:tablist
            let l:buflist = tabpagebuflist(tabnumber)
            for bufid in l:buflist
                if (bufloaded(bufid) && buflisted(bufid) && bufid == l:bufnumber)
                    let l:tabnumber = tabnumber
                    let l:found = 1
                    break
                endif
            endfor
            if (l:found)
                break
            endif
        endfor
        if (l:found)
            " echom "Switching to tab " . l:tabnumber
            execute "normal! " . l:tabnumber . "gt"
            " goto split
            let l:window_number = bufwinnr(l:bufnumber)
            if (l:window_number >= 0)
                execute l:window_number . "wincmd w"
            endif
            return
        endif
    endwhile
endfunction

autocmd TabLeave * call <SID>OnTabLeave()
autocmd TabClosed * call <SID>GoToLastTab()
" Alt - t
nnoremap <silent> † :call <SID>GoToLastTab()<CR>

