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
        " 防止vim整体退出
        execute 'bd'
    endif
endfunction


" goto last tab
let g:mru_tabepage_list = []
let g:mru_tabepage_list_size = 20
function! <SID>OnTabLeave()
    if !g:goto_last_tab
        return
    endif
    try
        let l:filename = expand("%:p")
        if (len(l:filename))
            let l:bufnumber = bufnr('%')
            if (bufloaded(l:bufnumber) && buflisted(l:bufnumber))
                call add(g:mru_tabepage_list, l:filename)
                " echom "OnTabLeave " . l:filename  " DEBUG
                if (len(g:mru_tabepage_list) > g:mru_tabepage_list_size)
                    call remove(g:mru_tabepage_list, 0)
                endif
            endif
        endif
    catch
        return
    endtry
endfunction

let g:goto_last_tab = 1

function! <SID>GoToLastTab()
    if !g:goto_last_tab
        return
    endif
    " echom "GoToLastTab " . join(g:mru_tabepage_list)
    try
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
    catch
        return
    endtry
endfunction

function! <SID>TabOnly()
    let g:goto_last_tab = 0
    " First run official version tabonly, this will only close tabs but leaves
    " buffers open
    execute "tabonly"
    let g:goto_last_tab = 1
    " buflisted: appear in `ls` cmd
    " bufloaded: appear in foreground, can be seen and edited
    let l:cur_buflist = filter(tabpagebuflist(), 'buflisted(v:val)')
    let l:cur_buf_dict = {}
    for bid in l:cur_buflist
        let l:cur_buf_dict[bid] = ''
    endfor
    let l:bd_buflist = filter(range(1, bufnr('$')), 'buflisted(v:val) && !has_key(l:cur_buf_dict, v:val)')
    execute 'bd ' . join(l:bd_buflist)
endfunction

autocmd TabLeave * call <SID>OnTabLeave()
autocmd TabClosed * call <SID>GoToLastTab()
" Alt - t
" nnoremap <silent> † :call <SID>GoToLastTab()<CR>

command! Cot call<SID>TabOnly()

function! <SID>TabDrop(args)
    call <SID>OnTabLeave()
    let g:goto_last_tab = 0
    execute "silent tab drop " . a:args
    let g:goto_last_tab = 1
endfunction
command! -nargs=* TabDrop call<SID>TabDrop(<q-args>)
" command alias for auto completion
cnoreabbrev Td TabDrop

function! <SID>TabCloseToRight()
    let l:cur_tab = tabpagenr()
    if (l:cur_tab == tabpagenr('$'))
        return
    endif

    let g:goto_last_tab = 0

    let l:close_buflist = []
    for tabnumber in range(l:cur_tab + 1, tabpagenr('$'))
        " This will not include tagbar
        " let l:buflist = filter(tabpagebuflist(tabnumber), 'buflisted(v:val) && bufloaded(v:val)')
        " This include all (including tagbar)
        let l:buflist = tabpagebuflist(tabnumber)
        let l:close_buflist += l:buflist
    endfor
    if (len(l:close_buflist))
        execute 'bd ' . join(l:close_buflist)
    endif

    let g:goto_last_tab = 1
endfunction

" command! Crt call<SID>TabCloseToRight()

function! <SID>TabCloseRight(bang)
    let g:goto_last_tab = 0
    let cur=tabpagenr()
    while cur < tabpagenr('$')
        exe 'tabclose' . a:bang . ' ' . (cur + 1)
    endwhile
    " close all not loaded (shown) buffers
    let l:hidden_bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && !bufloaded(v:val)')
    if (len(l:hidden_bufs))
        execute 'bd ' . join(l:hidden_bufs)
    endif
    let g:goto_last_tab = 1
endfunction

function! <SID>TabCloseLeft(bang)
    let g:goto_last_tab = 0
    while tabpagenr() > 1
        exe 'tabclose' . a:bang . ' 1'
    endwhile
    let l:hidden_bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && !bufloaded(v:val)')
    if (len(l:hidden_bufs))
        execute 'bd ' . join(l:hidden_bufs)
    endif
    let g:goto_last_tab = 1
endfunction

command! -bang Crt call <SID>TabCloseRight('<bang>')
command! -bang Clt call <SID>TabCloseLeft('<bang>')
