return {
	{
		"stevearc/conform.nvim",
		opts = {},
		config = function()
			require("conform").setup({
				format_on_save = true,
				formatters_by_ft = {
					lua = { "stylua" },

					python = { "isort", "black" },

					rust = { "rustfmt", lsp_format = "fallback" },

					javascript = { "prettierd", "prettier", stop_after_first = true },
				},
			})
		end,
	},
}
