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
                require("lspconfig")[server].setup({})
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
