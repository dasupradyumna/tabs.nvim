"-------------------------------------------- TABS.NVIM -------------------------------------------"

command! -nargs=? TabsRename lua require('tabs').set_name(false, <q-args>)

augroup tabs_nvim
    autocmd!

    " TODO: handle tabpages from restored sessions
    autocmd VimEnter * let t:tabs_nvim_name = 'main'
    autocmd TabNew * lua require('tabs').set_name(true)

augroup END
