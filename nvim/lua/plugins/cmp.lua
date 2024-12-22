return {
	{
		"hrsh7th/nvim-cmp", -- Completion plugin
		"hrsh7th/cmp-nvim-lsp", -- LSP completion source for nvim-cmp
		"hrsh7th/cmp-buffer", -- Buffer completion source for nvim-cmp
		"hrsh7th/cmp-path", -- Path completion source for nvim-cmp
		"saadparwaiz1/cmp_luasnip", -- Snippet completion source for nvim-cmp
		event = "InsertEnter",
		config = function() end,
	},
}
