require('telescope').setup{
 defaults = {
   file_ignore_patterns = { 
       "node_modules",
       "target",
       "dist",
       "package%-lock.json"
   },
 }
}
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") });
vim.keymap.set("n", "<leader>pl", "<cmd>Telescope live_grep<CR>")
end)
