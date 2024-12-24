vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Explore)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", '"_dp')

vim.api.nvim_set_keymap("n", "<leader>i", ":lua vim.diagnostic.open_float()<CR>", { noremap = true, silent = true })



vim.keymap.set('n','gD','<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n','gd','<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n','K','<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n','gr','<cmd>lua vim.lsp.buf.references()<CR>')
vim.keymap.set('n','gs','<cmd>lua vim.lsp.buf.signature_help()<CR>')
vim.keymap.set('n','gi','<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n','gt','<cmd>lua vim.lsp.buf.type_definition()<CR>')
vim.keymap.set('n','<leader>gw','<cmd>lua vim.lsp.buf.document_symbol()<CR>')
vim.keymap.set('n','<leader>gW','<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
vim.keymap.set('n','<leader>ah','<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n','<leader>af','<cmd>lua vim.lsp.buf.code_action()<CR>')
vim.keymap.set('n','<leader>ee','<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')
vim.keymap.set('n','<leader>ar','<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set('n','<leader>=', '<cmd>lua vim.lsp.buf.formatting()<CR>')
vim.keymap.set('n','<leader>ai','<cmd>lua vim.lsp.buf.incoming_calls()<CR>')
vim.keymap.set('n','<leader>ao','<cmd>lua vim.lsp.buf.outgoing_calls()<CR>')
