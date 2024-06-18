return {
	'VonHeikemen/lsp-zero.nvim',
	dependencies = {
		-- LSP support
		{ 'neovim/nvim-lspconfig' },
		{ 'williamboman/mason.nvim' },
		{ 'williamboman/mason-lspconfig.nvim' },

		-- Autocompletion
		{ 'hrsh7th/nvim-cmp' },
		{ 'hrsh7th/cmp-buffer' },
		{ 'hrsh7th/cmp-path' },
		{ 'hrsh7th/cmp-nvim-lsp' },
		{ 'hrsh7th/cmp-nvim-lua' },
		{ 'L3MON4D3/LuaSnip' },
	}
}
