" --- General

syntax on

set termguicolors
set tabstop=4 
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set number
set numberwidth=1
set relativenumber
set signcolumn=yes
set noswapfile
set nobackup
set undodir=~/.config/nvim/undodir
set undofile
set incsearch
set nohlsearch
set ignorecase
set smartcase
set nowrap
set splitbelow
set splitright
set hidden
set scrolloff=999
set noshowmode
set updatetime=250 
set encoding=UTF-8
set mouse=a
set clipboard+=unnamedplus

" --- Plugins
call plug#begin('~/.config/nvim/plugged')

Plug 'nvim-lua/plenary.nvim' " Telescope requires plenary to function
Plug 'nvim-telescope/telescope.nvim' " The main Telescope plugin
Plug 'nvim-telescope/telescope-fzf-native.nvim', {'do': 'make' } " An optional plugin recommended by Telescope docs
Plug 'tpope/vim-fugitive' " Git integration
Plug 'vim-airline/vim-airline' "Status bar plugin
Plug 'lewis6991/gitsigns.nvim' " git changes decorator
Plug 'editorconfig/editorconfig-vim'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update

" Autocompletion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'onsails/lspkind-nvim'

" ---- Plugin Themes
Plug 'sainnhe/gruvbox-material'

call plug#end()

colorscheme gruvbox-material

let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
let mapleader = " "

" ----- Key mappings
""nnoremap <C-p> :Telescope find_files<Cr>
nnoremap <C-p> :Telescope find_files<Cr>
"nnoremap <leader>fg <cmd>Telescope live_grep<cr>
"nnoremap <leader>fb <cmd>Telescope buffers<cr>
"nnoremap <leader>fh <cmd>Telescope help_tags<cr>

:lua require('peterf')
