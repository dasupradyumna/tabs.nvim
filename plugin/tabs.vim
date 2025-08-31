"-------------------------------------------- TABS.NVIM -------------------------------------------"

command! -nargs=? TabsRename lua require('tabs').set_name(false, <q-args>)

augroup tabs_nvim
    autocmd!

    " set default name for the first tabpage, only outside session loading and if currently unnamed
    autocmd VimEnter * if !exists('g:SessionLoad') && !exists('t:tabs_nvim_name') |
                \          let t:tabs_nvim_name = 'main' |
                \      endif

    " get tabpage name from user, only outside session loading
    autocmd TabNew * if !exists('g:SessionLoad') |
                \        if !exists('g:tabs_nvim_no_prompt') |
                \            execute "lua require('tabs').set_name(true)" |
                \        else |
                \            unlet g:tabs_nvim_no_prompt |
                \        endif |
                \    endif

    " restore previous session tabpage names
    autocmd SessionLoadPost * lua require('tabs').load_from_global()

augroup END
