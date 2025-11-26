return {
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			require("gruvbox").setup({
				terminal_colors = true,
				bold = true,
				italic = {
					strings = true,
					emphasis = true,
					comments = true,
					operators = false,
					folds = true,
				},
				contrast = "hard",
				transparent_mode = true,
			})
			vim.cmd("colorscheme gruvbox")

			vim.api.nvim_set_hl(0, "Cursor", { fg = "#000000", bg = "#689d6a" })
			vim.api.nvim_set_hl(0, "SignColumn", { bg = "#3C3836" })

			vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal" })
			vim.api.nvim_set_hl(0, "LspInfoBorder", { link = "Normal" })
			vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
			vim.api.nvim_set_hl(0, "Pmenu", { link = "Normal" })
			vim.api.nvim_set_hl(0, "PmenuSel", { link = "Search" })
			vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "Normal" })
			vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "Normal" })
			vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { link = "Search" })
			vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { link = "Search" })
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#111111" })
			vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#222222" })
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#fabd2f", bold = true })
			vim.api.nvim_set_hl(0, "StatusLine", { bg = "#111111", fg = "#ffffff" })
			vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#111111", fg = "#777777" })
		end,
	},
}
