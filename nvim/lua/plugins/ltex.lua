return {
    'vigoux/ltex-ls.nvim',
    requires = 'neovim/nvim-lspconfig',
        config = function()
        require'ltex-ls'.setup {
            on_attach = on_attach,
            capabilities = capabilities,
            use_spellfile = false,
            filetypes = { "latex", "tex", "bib", "markdown", "gitcommit", "text" },
            settings = {
                ltex = {
                    enabled = { "latex", "tex", "bib", "markdown", },
                    language = "auto",
                    diagnosticSeverity = "information",
                    sentenceCacheSize = 2000,
                    additionalRules = {
                        enablePickyRules = true,
                        motherTongue = "de",
                    },
                    dictionary = (function()
                        local files = {}
                        for _, file in ipairs(vim.api.nvim_get_runtime_file("dict/*", true)) do
                            local lang = vim.fn.fnamemodify(file, ":t:r")
                            local fullpath = vim.fs.normalize(file, ":p")
                            files[lang] = { ":" .. fullpath }
                        end

                        if files.default then
                            for lang, _ in pairs(files) do
                                if lang ~= "default" then
                                    vim.list_extend(files[lang], files.default)
                                end
                            end
                            files.default = nil
                        end
                        return files
                    end)(),
                },
            },
        }
    end,
}
