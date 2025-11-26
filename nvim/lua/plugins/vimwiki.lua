return {
	"vimwiki/vimwiki",
	lazy = false,
	init = function()
		vim.g.vimwiki_list = {
			{
				-- I prefer using VimWiki instead of Obsidian, but due
				-- VimWiki also supporting markdown and links we can use
				-- them in both editors
				path = "~/files/documents/obsidian-vault/",
				syntax = "markdown",
				ext = ".md",
			},
		}
		vim.g.vimwiki_global_ext = 0
	end,

	keys = {
		{ "<leader>ww", "<cmd>VimwikiIndex<CR>", desc = "Goto VimWiki Indexfile" },
		{ "<CR>", "<cmd>VimwikiFollowLink<CR>", desc = "Follow VimWiki Link", mode = "n" },
	},
}
