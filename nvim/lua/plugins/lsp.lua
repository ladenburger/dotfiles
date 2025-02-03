local servers = {
    "lua_ls",
    "clangd",
    "rust_analyzer",
    "ts_ls",
    "angularls",
    "jedi_language_server",
    "somesass_ls",
    "csharp_ls",
}

return {
    {
        'williamboman/mason.nvim',
        config = function()
            require('mason').setup()
        end,
    },
    {
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = servers,
                automatic_installation = true,
            })
        end,
    },
    {
        'neovim/nvim-lspconfig',
        config = function()
            for _, server in ipairs(servers) do
                if server == "angularls" then
                    -- --------------------------------------------------------
                    -- ------------------ Setup AngularLS ---------------------
                    -- --------------------------------------------------------
                    -- NOTE: angularls cant seem to find project root manually 
                    -- for the language server, so just use the working 
                    -- directory for now. This requires to install the LSP in 
                    -- the project.
                    -- npm i --save-dev @angular/language-server
                    -- npm i --save-dev @angular/language-service
                    -- npm i --save-dev typescript
                    -- npm i --save-dev typescript-language-server

                    local project_library_path = vim.fn.getcwd()

                    local cmd = {
                        "ngserver", "--stdio", "--tsProbeLocations",
                        project_library_path , "--ngProbeLocations",
                        project_library_path
                    }
                    require'lspconfig'.angularls.setup{
                        cmd = cmd,
                        on_new_config = function(new_config)
                            new_config.cmd = cmd
                        end,
                    }
                else
                    -- --------------------------------------------------------
                    -- ----------- Setup all default servers ------------------
                    -- --------------------------------------------------------
                    require("lspconfig")[server].setup({})
                end
            end
        end,
    },
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        dependencies = 'rafamadriz/friendly-snippets',

        version = '*',
        opts = {
            keymap = { preset = 'default' },
            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono'
            },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
        },
        opts_extend = { "sources.default" }
    }

}
