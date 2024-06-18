-- Set relative line numbers
vim.cmd("set number")
vim.cmd("set relativenumber")

-- Set color scheme(s)
vim.cmd("set termguicolors")
vim.cmd.colorscheme("base16-atelier-dune")

-- Always show the tabline
vim.cmd("set stal=2")

-- Code folding
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
