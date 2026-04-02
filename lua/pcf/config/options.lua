-- See `:help vim.o`
-- [[ Setting options ]]
local opt = vim.opt

vim.wo.number = true -- Make line numbers default
-- Disable Netrw, Vim's built-in file explorer, to use a custom file tree plugin instead
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.markdown_recommended_style = 0 -- Disable default markdown styling for custom configuration

opt.autowrite = true -- Automatically save files when switching buffers or leaving Vim
opt.autoindent = true -- Automatically indent new lines based on the previous line

opt.backup = false -- Disable backup files to avoid cluttering directories
opt.breakindent = true -- Maintain indent when wrapping lines for better readability

opt.completeopt = "menu,menuone,noselect" -- Configure completion menu for better usability
opt.conceallevel = 2 -- Hide certain syntax characters in markdown and other files
opt.confirm = true -- Prompt to save changes when closing unsaved buffers
opt.cursorline = true -- Highlight the current line for easier visual tracking

opt.expandtab = true -- Use spaces instead of tabs for consistent indentation

-- Configure various UI folding elements and characters for a cleaner interface
opt.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
opt.foldenable = true -- Enable code folding functionality
opt.foldlevel = 99 -- Start with all folds open by default
opt.foldlevelstart = 99 -- Start with all folds open
opt.foldcolumn = "1" -- Display fold indicators in the left column (1 character wide)
opt.formatoptions = "jcroqlnt" -- Auto-format: comments, text wrap, lists; preserve long lines

opt.grepformat = "%f:%l:%c:%m" -- Set the format for grep results
opt.grepprg = "rg --vimgrep" -- Use ripgrep for faster and more powerful searching

opt.hlsearch = true -- Highlight all matches when searching

opt.inccommand = "nosplit" -- Show live results of substitute commands
opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search
opt.iskeyword = opt.iskeyword + "-" -- this makes kebab-case one whole word when selecting a word.

opt.list = true -- Show hidden characters like tabs and trailing spaces
opt.laststatus = 3 -- Enable global statusline (single statusline at bottom)

opt.mouse = "a" -- Enable mouse support in all modes for easier navigation

opt.number = true -- Show absolute line numbers

opt.pumblend = 0 -- Sets popup menu transparency
opt.pumheight = 10 -- Maximum number of items to show in the popup menu

opt.relativenumber = true -- Relative line numbers

opt.scrolloff = 8 -- Number of screen lines to keep above and below the cursor
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,terminal,skiprtp"
opt.shiftround = true -- Round indent to multiple of 'shiftwidth'
opt.shiftwidth = 2 -- Size of an indent
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- -- Always show the sign column to prevent text shifting
opt.shortmess:append({ W = true, I = true, c = true, C = true }) -- Shorten various Vim messages
opt.showmode = false -- Disable, lualine already shows mode in lualine_a
opt.showtabline = 0 -- neovim only display tabline when there are at least two tab pages. If you want always display tabline
opt.smartindent = true -- Insert indents automatically
opt.smartcase = true -- Make searches case-sensitive when using uppercase letters.Don't ignore case with capitals
opt.smoothscroll = true -- Enable smooth scrolling for better visual experience
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = "screen"
opt.splitright = true -- Put new windows right of current
opt.swapfile = false -- Disable swap files to avoid cluttering directories
opt.softtabstop = 2 -- Number of spaces that a <Tab> counts for while performing editing operations

opt.tabstop = 2 -- Number of spaces tabs count for-- Set the width of a tab character
-- NOTE: termguicolors is now a Neovim default (0.10+)
opt.timeout = true -- Enable timeout for key mappings
opt.timeoutlen = 300

opt.undolevels = 10000 -- Increase the number of available undo levels
opt.undofile = true -- Save undo history -- Enable persistent undo across sessions
opt.updatetime = 200 -- Reduce updatetime for faster response and better user experience

opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap
