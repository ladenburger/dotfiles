require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"clangd",
		"rust_analyzer",
		"ts_ls",
		"angularls",
		"jedi_language_server",
        "somesass_ls",
	},
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig").lua_ls.setup({})
require("lspconfig").clangd.setup({})
require("lspconfig").rust_analyzer.setup({})
require("lspconfig").ts_ls.setup({})
require("lspconfig").angularls.setup({
	capabilities = capabilities,
})
require("lspconfig").jedi_language_server.setup({})
require("lspconfig").somesass_ls.setup({})
