# Mutagenix Pack for Neovim (Lazy‑nvim)

This repository contains a collection of Neovim settings, plug‑in specifications and custom commands packaged for use with [lazy.nvim](https://github.com/folke/lazy.nvim).  It is designed to be imported as a single module into an existing Lazy setup, providing sensible defaults, LSP support, syntax highlighting, multiple cursors, linting helpers and Australian/British spell checking.

## Features

- **Editor options**: sensible defaults such as line numbers, cursor line, smart case search, folding, system clipboard integration and a custom cursor style.
- **Spell checking**: automatic spell checking for a wide range of filetypes using Australian English (`en_AU`) with persistent custom dictionary support.
- **Plug‑in suite**:
  - [todo‑comments.nvim](https://github.com/folke/todo‑comments.nvim) for highlighting and navigating TODO/FIX/NOW markers.
  - [markdown‑preview.nvim](https://github.com/iamcco/markdown-preview.nvim) with sensible server defaults.
  - [catppuccin.nvim](https://github.com/catppuccin/nvim) colourscheme with integrated support for Telescope, NvimTree and cmp.
  - GitHub Copilot client.
  - Multi‑cursor support via [vim‑visual‑multi](https://github.com/mg979/vim-visual-multi).
  - LSP configuration via [mason.nvim](https://github.com/williamboman/mason.nvim), [mason‑lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim), [nvim‑lspconfig](https://github.com/neovim/nvim-lspconfig) and [nvim‑cmp](https://github.com/hrsh7th/nvim-cmp).
  - Syntax highlighting via [nvim‑treesitter](https://github.com/nvim-treesitter/nvim-treesitter).
  - File explorer ([nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)), Telescope, lualine, gitsigns, autopairs and Comment.nvim.
- **Custom commands**:
  - `:Wt` runs **pylint** on the current file and presents errors in a floating window.
  - `:Wg` runs **golangci‑lint** on the current file and displays results similarly.
  - `:Wtsh` runs **ShellCheck** on the current file (Unix shell scripts).
  - `:NSearch <pattern>` searches the file `~/.config/nvim/nsearch.txt` and prints matching rows in aligned columns.
  - `:Todo` opens a Telescope search for `TODO` markers.
  - `:Models` and `:ChangeModel` wrappers for an optional AI UI (only if installed).
- **Keymaps** for scratch buffers, running Python/Bash, window navigation, smart word navigation, multi‑cursor actions and more.

## File structure

```
mutagenix-pack/
├── README.md              ← this file
└── lua/
    └── mutagenix_pack/
        ├── core.lua       ← applies editor options, autocmds, keymaps, commands and helpers
        └── spec.lua       ← returns a list of Lazy plug‑in specs including the core config
```

```lua
vim.opt.termguicolors = true

-- ============================================================================
--  Neovim configuration (lazy‑nvim edition)                                   
--  Keeps prior behaviour, now wires cmp → LSP so Python IntelliSense works.   
--  Australian / British spelling.                                             
-- ============================================================================

-------------------------------------------------------------------------------
--  Bootstrap lazy.nvim -------------------------------------------------------
-------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-------------------------------------------------------------------------------
--  Helper --------------------------------------------------------------------
-------------------------------------------------------------------------------
local function safe_require(mod)
  local ok, pkg = pcall(require, mod)
  return ok and pkg or nil
end

-------------------------------------------------------------------------------
--  Plug‑in spec --------------------------------------------------------------
-------------------------------------------------------------------------------
require("lazy").setup({
-- In your require("lazy").setup({ ... })
{
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    signs = true,
    highlight = {
      keyword = "bg",        -- highlight the whole keyword
      after = "fg",          -- colour the text after the keyword a bit
    },
    search = {               -- uses ripgrep
      command = "rg",
      args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
      pattern = [[\b(KEYWORDS):]], -- leave as-is
    },
    keywords = {
      TODO  = { icon = " ", colour = "info" },
      FIX   = { icon = " ", colour = "error", alt = { "FIXME", "BUG" } },
      WARN  = { icon = " ", colour = "warning", alt = { "WARNING" } },
      NOTE  = { icon = " ", colour = "hint", alt = { "INFO" } },
      PERF  = { icon = " ", colour = "default", alt = { "PERFORMANCE" } },
      CHORE = { icon = " ", colour = "default" },
      IDEA  = { icon = "💡", colour = "hint" },
    },
  },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO/FIX/WARN" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO/FIX/WARN" },
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Todos (Telescope)" },
    { "<leader>tq", "<cmd>TodoQuickFix<cr>",  desc = "Todos → Quickfix" },
    { "<leader>tl", "<cmd>TodoLocList<cr>",   desc = "Todos → Loclist" },
    { "<leader>tt", "<cmd>TodoTrouble<cr>",   desc = "Todos (Trouble)" }, -- if you use Trouble
  },
},

  -- Markdown preview plugin
{
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = "cd app && npm install",  -- ✅ avoids mkdp#util#install timing issues
  init = function()
    -- Behaviour
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_command_for_global = 0
    -- Server / networking
    vim.g.mkdp_open_to_the_world = 0
    vim.g.mkdp_open_ip = "127.0.0.1"
    vim.g.mkdp_port = "8080"
    -- Appearance
    vim.g.mkdp_theme = "dark"
  end,
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview (HTTP)" },
  },
},
  ---------------------------------------------------------------------------
  --  Colourscheme -----------------------------------------------------------
  ---------------------------------------------------------------------------
{
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      integrations = {
        telescope = true,
        nvimtree  = true,
        cmp       = true,
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
},
  {
    "github/copilot.vim",
    lazy = false,
  },
---------------------------------------------------------------------------
-- Multi Cursor -----------------------------------------------------------
---------------------------------------------------------------------------
{
  "mg979/vim-visual-multi",
  branch = "master",
  init = function()
    vim.g.VM_default_mappings = 0  -- we'll define our own
  end
},

---------------------------------------------------------------------------
--  LSP / Mason / Completion ----------------------------------------------
---------------------------------------------------------------------------
{
  "neovim/nvim-lspconfig",
},

{
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
  config = function()
    safe_require("mason").setup()
  end,
},

{
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    safe_require("mason-lspconfig").setup({
      ensure_installed = {
        -- Web
        "html", "cssls", "emmet_ls", "vtsls", "eslint", "jsonls",

        -- Backend
        "pyright", "bashls", "lua_ls", "gopls", "rust_analyzer",
        "clangd", "dockerls", "yamlls", "graphql",

        -- Java / .NET / JVM
        "jdtls", "kotlin_language_server", "lemminx", "omnisharp",

        -- Database / Configs
        "sqlls", "taplo",

        -- Others
        "perlpls", "powershell_es", "ansiblels", "terraformls",

        -- Markdown and docs
        "marksman", "ltex",
      },
    })
  end,
},

{
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp     = safe_require("cmp")
    local luasnip = safe_require("luasnip")
    if not (cmp and luasnip) then return end

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"]      = cmp.mapping.confirm({ select = true }),
        ["<Tab>"]     = cmp.mapping.select_next_item(),
        ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
      }),
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip"  },
      },
    })
  end,
},

---------------------------------------------------------------------------
--  Treesitter -------------------------------------------------------------
---------------------------------------------------------------------------

{
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    safe_require("nvim-treesitter.configs").setup({
      ensure_installed = {
        -- Web
        "css", "html", "javascript", "json", "scss", "typescript",

        -- Backend / General-purpose
        "bash", "c", "cpp", "elixir", "go", "java", "kotlin",
        "lua", "perl", "php", "python", "ruby", "rust",

        -- Infra / Scripting
        "dockerfile", "make", "terraform", "toml", "yaml",

        -- Markup / Docs
        "latex", "markdown", "markdown_inline",

        -- Other
        "graphql", "regex", "sql",
      },
      highlight = {
        enable = true,
      },
    })
  end,
},


  ---------------------------------------------------------------------------
  --  File explorer ----------------------------------------------------------
  ---------------------------------------------------------------------------
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" },
    },
    config = function()
     safe_require("nvim-tree").setup({
     view = {
      width = 50,  -- Approx. 600px
      side = "left",
      preserve_window_proportions = true,
    },
       filters = {
         custom = {".git"},
         exclude = {}
       },
       respect_buf_cwd = false,
     })
   end,
  },

  ---------------------------------------------------------------------------
  --  Telescope --------------------------------------------------------------
  ---------------------------------------------------------------------------
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = safe_require("telescope.builtin")
      if not builtin then return end
      local map = vim.keymap.set
      map("n", "<leader>ff", builtin.find_files, { desc = "Find Files"       })
      map("n", "<leader>fg", builtin.live_grep,  { desc = "Live Grep"        })
      map("n", "<leader>fb", builtin.buffers,    { desc = "Buffers"          })
      map("n", "<leader>fh", builtin.help_tags,  { desc = "Help Tags"        })
      map("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics"      })
      map("n", "<leader>fr", builtin.resume,      { desc = "Resume"           })
    end,
  },

  ---------------------------------------------------------------------------
  --  UI niceties ------------------------------------------------------------
  ---------------------------------------------------------------------------
  { "nvim-lualine/lualine.nvim",
    config = function()
      safe_require("lualine").setup({ options = { theme = "catppuccin" } })
    end,
  },
  { "lewis6991/gitsigns.nvim",  config = true },
  { "windwp/nvim-autopairs",    config = true },
  { "numToStr/Comment.nvim",    config = true },
  { "mg979/vim-visual-multi",   branch = "master" },
})



------------------------------------------------------------------------------
--  Options ------------------------------------------------------------------
-------------------------------------------------------------------------------
vim.opt.number       = true
vim.opt.cursorline   = true
vim.opt.ignorecase   = true
vim.opt.smartcase    = true
vim.opt.scrolloff    = 10
vim.opt.wildmenu     = true
vim.opt.wildmode     = "longest,list"
vim.opt.foldmethod   = "indent"
vim.opt.foldenable   = true
vim.opt.foldlevel    = 99
vim.opt.foldminlines = 5
vim.opt.clipboard    = "unnamedplus"
vim.opt.modeline     = false
-- vim.opt.wrap         = false
-------------------------------------------------------------------------------
--  Autocommands -------------------------------------------------------------
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local api = safe_require("nvim-tree.api")
    if api then api.tree.open() end
  end,
})

-------------------------------------------------------------------------------
--  Commands / keymaps / utilities unchanged below ---------------------------
-------------------------------------------------------------------------------
local function new_scratch()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
end

local map = vim.keymap.set
map("n", "<leader>x", new_scratch,                { desc = "New Scratch"      })
map("n", "\\rp",  ":w !python3 %<CR>",          { silent = true, desc = "Run Python" })
map("n", "\\rb",  ":w !bash %<CR>",             { silent = true, desc = "Run Bash"   })
map("n", "\\q",   ":q<CR>",                     { silent = true, desc = "Quit"       })
map("n", "\\qq",  ":q!<CR>",                    { silent = true, desc = "Force Quit" })
map("n", "\\w",   ":w<CR>",  { silent = true, desc = "Save" })

vim.api.nvim_set_keymap('n', '<leader>ai', [[<cmd>lua require'ai_ui'.set_last_buf()<CR><cmd>lua require'ai_ui'.open_ui()<CR>]], { noremap = true, silent = true })
-- Function to run pylint and filter output
local function run_pylint()
  vim.cmd('write')
  local filename = vim.fn.expand('%')
  local handle = io.popen('pylint "' .. filename .. '" 2>&1')
  if handle then
    local output = handle:read('*a')
    handle:close()

    local filtered_output = {}
    for line in output:gmatch('[^\r\n]+') do
      if line:match('^%S+:%d+:%d+: E') and not line:match('E0401') then
        table.insert(filtered_output, line)
      end
    end
    if #filtered_output== 0 then
      table.insert(filtered_output, "✅ No issues found!")
    end
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * 0.6)
    local height = math.floor(ui.height * 0.6)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, filtered_output)
    vim.api.nvim_open_win(bufnr, true, {
      style = "minimal",
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      border = "rounded"
    })
  else
    vim.notify("Failed to run pylint")
  end
end

-- Function to run golangci-lint and display filtered output
local function run_golint()
  vim.cmd('write')
  local filename = vim.fn.expand('%')
  local handle = io.popen('golangci-lint run "' .. filename .. '" 2>&1')
  if handle then
    local output = handle:read('*a')
    handle:close()

    local filtered_output = {}
    for line in output:gmatch('[^\r\n]+') do
      -- Example filter: only show issues with severity "error"
      if line:match(":%d+:%d+:") then
        table.insert(filtered_output, line)
      end
    end

    if #filtered_output == 0 then
      table.insert(filtered_output, "✅ No issues found!")
    end

    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * 0.6)
    local height = math.floor(ui.height * 0.6)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, filtered_output)
    vim.api.nvim_open_win(bufnr, true, {
      style = "minimal",
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      border = "rounded"
    })
  else
    vim.notify("Failed to run golangci-lint")
  end
end

-- Create the custom command :Wg
vim.api.nvim_create_user_command('Wg', run_golint, {})


-- Create the custom command :Wt
vim.api.nvim_create_user_command('Wt', run_pylint, {})

-- Function to run ShellCheck and show output in a floating window
local function run_shellcheck()
  vim.cmd('silent! write!')
  local filename = vim.fn.expand('%:p')  -- Full path to the current file
  local shellcheck_path = '/usr/bin/shellcheck'  -- Adjust if needed

  if vim.fn.executable(shellcheck_path) == 0 then
    vim.notify("ShellCheck not found at: " .. shellcheck_path, vim.log.levels.ERROR)
    return
  end

  local command = shellcheck_path .. ' --severity=info --enable=all "' .. filename .. '" 2>&1'
  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to run ShellCheck", vim.log.levels.ERROR)
    return
  end

  local output = handle:read('*a')
  handle:close()

  -- Split the full output string into lines
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  if #lines == 0 then
    table.insert(lines, "✅ No issues found by ShellCheck!")
  end

  -- Create a floating window to display the output
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.6)
  local height = math.floor(ui.height * 0.6)
  local col = math.floor((ui.width - width) / 2)
  local row = math.floor((ui.height - height) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.api.nvim_open_win(bufnr, true, {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded"
  })
end

vim.api.nvim_create_user_command('Wtsh', run_shellcheck, {})

-- Map <leader>b to :G blame using vim-fugitive
vim.keymap.set('n', '<leader>b', ':G blame<CR>', { noremap = true, silent = true, desc = 'Git Blame' })

-- Directional window navigation with Ctrl + Arrow keys
vim.keymap.set('n', '<C-Right>', '<C-w>l', { noremap = true, silent = true })  -- right
vim.keymap.set('n', '<C-Left>',  '<C-w>h', { noremap = true, silent = true })  -- left
vim.keymap.set('n', '<C-Down>',  '<C-w>j', { noremap = true, silent = true })  -- down
vim.keymap.set('n', '<C-Up>',    '<C-w>k', { noremap = true, silent = true })  -- up


-- Enable spellcheck with Australian English for a wide array of filetypes
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = {
    -- Original filetypes
    "markdown", "gitcommit", "text", "python",
    -- Extended: Text/markup/documentation
    "rst", "tex", "html", "xml", "json", "yaml", "toml", "mail", "help",
    -- Extended: Programming/scripting (including Go, useful for comments)
    "go", "lua", "vim", "javascript", "typescript", "css",
    "sh", "bash", "zsh", "c", "cpp", "java", "rust", "php", "ruby", "perl",
    -- Extended: Other common (e.g., config/build)
    "dockerfile", "make", "sql"
  },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_au"
  end,
})

-- Define and create the spell directory if it doesn't exist
local spell_dir = vim.fn.stdpath("config") .. "/spell"
if vim.fn.isdirectory(spell_dir) == 0 then
  vim.fn.mkdir(spell_dir, "p")
end

-- Set persistent spellfile
vim.opt.spellfile = spell_dir .. "/en.utf-8.add"

-- Map <leader>z to add word under cursor to spellfile
vim.keymap.set("n", "<leader>z", "zg", { desc = "Add word to dictionary" })
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.cmd("highlight SpellBad gui=undercurl guisp=Red")
  end,
})

-- Trigger immediately if a colourscheme is already set
vim.cmd("highlight SpellBad gui=undercurl guisp=Red")






-- local function show_spellcheck_issues_aligned()
--   local bufnr = vim.api.nvim_get_current_buf()
--   local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--   local total_lines = #lines
--
--   -- Prepare padded results for alignment
--   local padded_results = {}
--   for i = 1, total_lines do
--     padded_results[i] = ""
--   end
--
--   for i, line in ipairs(lines) do
--     local col = 0
--     while col < #line do
--       local spell_result = vim.fn.spellbadword(line:sub(col + 1))
--       local bad_word = spell_result[1]
--
--       if bad_word and bad_word ~= "" then
--         local rel_start = line:sub(col + 1):find(bad_word, 1, true)
--         if rel_start then
--           local abs_start = col + rel_start
--           padded_results[i] = string.format("Line %-4d | %-20s | %s", i, bad_word, line)
--           break  -- Only show first issue per line
--         else
--           col = col + 1
--         end
--       else
--         break
--       end
--     end
--   end
--
--   if vim.tbl_isempty(vim.tbl_filter(function(x) return x ~= "" end, padded_results)) then
--     vim.notify("No spelling issues found.", vim.log.levels.INFO)
--     return
--   end
--
--   -- Save current window ID
--   local main_win = vim.api.nvim_get_current_win()
--
--   -- Force split on the right
--   vim.cmd("rightbelow vsplit")
--
--   -- Create and assign new buffer to the right split
--   local split_buf = vim.api.nvim_create_buf(false, true)
--   local split_win = vim.api.nvim_get_current_win()
--   vim.api.nvim_win_set_buf(split_win, split_buf)
--
--   -- Set buffer content and options
--   vim.api.nvim_buf_set_lines(split_buf, 0, -1, false, padded_results)
--   vim.api.nvim_buf_set_option(split_buf, "bufhidden", "wipe")
--   vim.api.nvim_buf_set_option(split_buf, "filetype", "spellcheck")
--   vim.api.nvim_buf_set_option(split_buf, "modifiable", false)
--   vim.api.nvim_buf_set_option(split_buf, "readonly", true)
--   vim.api.nvim_buf_set_option(split_buf, "wrap", false)
--
--   -- Scroll synchronisation only
--   vim.api.nvim_win_set_option(main_win, "scrollbind", true)
--   vim.api.nvim_win_set_option(split_win, "scrollbind", true)
--
--   -- No cursorbind — we're aligning by line number only
--   vim.api.nvim_win_set_cursor(main_win, {1, 0})
--   vim.api.nvim_win_set_cursor(split_win, {1, 0})
-- end
--
-- vim.keymap.set("n", "<leader>sc", show_spellcheck_issues_aligned, {
--   desc = "Show spelling issues in aligned right split"
-- })


local function show_spellcheck_issues_aligned()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local total_lines = #lines

  -- Prepare padded results for alignment
  local padded_results = {}
  for i = 1, total_lines do
    padded_results[i] = ""
  end

  for i, line in ipairs(lines) do
    local col = 0
    while col < #line do
      local spell_result = vim.fn.spellbadword(line:sub(col + 1))
      local bad_word = spell_result[1]

      if bad_word and bad_word ~= "" then
        local rel_start = line:sub(col + 1):find(bad_word, 1, true)
        if rel_start then
          padded_results[i] = string.format("Line %-4d | %-20s | %s", i, bad_word, line)
          break -- Only show first issue per line
        else
          col = col + 1
        end
      else
        break
      end
    end
  end

  if vim.tbl_isempty(vim.tbl_filter(function(x) return x ~= "" end, padded_results)) then
    vim.notify("No spelling issues found.", vim.log.levels.INFO)
    return
  end

  -- Save current window ID
  local main_win = vim.api.nvim_get_current_win()

  -- Force split on the right
  vim.cmd("rightbelow vsplit")

  -- Create and assign new buffer to the right split
  local split_buf = vim.api.nvim_create_buf(false, true)
  local split_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(split_win, split_buf)

  -- Set buffer content and options
  vim.api.nvim_buf_set_lines(split_buf, 0, -1, false, padded_results)
  vim.api.nvim_buf_set_option(split_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(split_buf, "filetype", "spellcheck")
  vim.api.nvim_buf_set_option(split_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(split_buf, "readonly", true)
  vim.api.nvim_buf_set_option(split_buf, "wrap", false)

  -- Scroll synchronisation only
  vim.api.nvim_win_set_option(main_win, "scrollbind", true)
  vim.api.nvim_win_set_option(split_win, "scrollbind", true)

  -- Align both windows to top
  vim.api.nvim_win_set_cursor(main_win, {1, 0})
  vim.api.nvim_win_set_cursor(split_win, {1, 0})

  -- Switch focus back to main window
  vim.api.nvim_set_current_win(main_win)
end

vim.keymap.set("n", "<leader>sc", show_spellcheck_issues_aligned, {
  desc = "Show spelling issues in aligned right split"
})









-- Define a Neovim command :NSearch <phrase> to search ~/.config/nvim/nsearch.txt
vim.api.nvim_create_user_command("NSearch", function(opts)
  local search = table.concat(opts.fargs, " ")
  if search == "" then
    print("Usage: :NSearch <search_term>")
    return
  end

  local file = vim.fn.stdpath("config") .. "/nsearch.txt"
  local f = io.open(file, "r")
  if not f then
    print("Error: " .. file .. " not found!")
    return
  end

  local lines = {}
  for line in f:lines() do
    if line:lower():find(search:lower(), 1, true) then
      table.insert(lines, line)
    end
  end
  f:close()

  if #lines == 0 then
    print("No matches found for: " .. search)
    return
  end

  -- Helper: split and trim
  local function split(str, sep)
    local result = {}
    for token in string.gmatch(str, "([^" .. sep .. "]+)") do
      table.insert(result, vim.trim(token))
    end
    return result
  end

  -- Format: calculate max column widths
  local col_widths = {}
  local rows = {}
  for _, line in ipairs(lines) do
    local cols = split(line, "|")
    for i, col in ipairs(cols) do
      col_widths[i] = math.max(col_widths[i] or 0, #col)
    end
    table.insert(rows, cols)
  end

  -- Output neatly aligned
  for _, row in ipairs(rows) do
    local formatted = {}
    for i, col in ipairs(row) do
      table.insert(formatted, col .. string.rep(" ", col_widths[i] - #col))
    end
    print(table.concat(formatted, " | "))
  end
end, {
  nargs = "+",
  desc = "Search ~/.config/nvim/nsearch.txt (case-insensitive)",
})


-- Disable Copilot’s default Tab mapping
vim.g.copilot_no_tab_map = true

-- Map <C-b> to accept Copilot suggestion in insert mode
vim.api.nvim_set_keymap("i", "<C-b>", 'copilot#Accept("<CR>")', {
  expr = true,
  silent = true,
  noremap = true
})



vim.opt.list = true
vim.opt.listchars = {
  tab = '▸ ',       -- Shows tabs as ▸ followed by space
  trail = '·',      -- Shows trailing spaces as ·
  eol = '↴',        -- End-of-line marker
  extends = '❯',    -- Character to show when line is too long
  precedes = '❮',   -- Character to show before the beginning of line
  space = '·',      -- Optional: shows all spaces as ·
}


-- Ensure Treesitter highlights aren't overridden
vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = "#ff69b4" }) -- pink brackets
vim.api.nvim_set_hl(0, "@punctuation.delimiter", { fg = "#ff69b4" }) -- pink braces

-- Function to show TODOs in a popup
vim.api.nvim_create_user_command("Todo", function()
  require("telescope.builtin").live_grep({
    default_text = "TODO",
  })
end, {})


-- Highlight the cursor with a bright red background
-- This affects the visible cursor block/bar/underscore depending on mode
vim.cmd([[
  highlight Cursor guifg=NONE guibg=Gold gui=NONE ctermfg=NONE ctermbg=Yellow cterm=NONE
]])

-- Set the cursor shape and link it to the Cursor highlight group
-- Covers Normal, Visual, Command, Insert, Replace, and Operator-pending modes
vim.opt.guicursor = table.concat({
  "n-v-c:block-Cursor",      -- Normal, Visual, Command: block shape
  "i-ci-ve:ver25-Cursor",    -- Insert, Command-line Insert, Visual Exclusive: vertical bar
  "r-cr:hor20-Cursor",       -- Replace, Command-line Replace: horizontal underscore
  "o:hor50-Cursor",          -- Operator-pending mode: horizontal underscore
  "a:blinkon0"               -- Disable blinking
}, ",")



-- <leader> fg + search for text
vim.keymap.set("n", "<leader>gf", function()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    local query = "^(func|var|type|const) " .. word
    require("telescope.builtin").live_grep({ default_text = query })
  end
end, { noremap = true, silent = true })


vim.keymap.set("n", "<leader>gd", function()
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    local query = word .. "\\("
    require("telescope.builtin").live_grep({ default_text = query })
  end
end, { noremap = true, silent = true })

-- ai_ui.lua
vim.api.nvim_create_user_command("Models", function()
  require("ai_ui").show_models()
end, {})

vim.api.nvim_create_user_command("ChangeModel", function(opts)
  require("ai_ui").change_model(opts.args)
end, { nargs = 1 })


-- Multiple cursor mappings
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Add cursor above or below (requires visual-multi plugin)
map("n", "<A-Up>", "<Plug>(VM-Add-Cursor-Up)", {})
map("n", "<A-Down>", "<Plug>(VM-Add-Cursor-Down)", {})
map("i", "<A-Up>", "<Esc><Plug>(VM-Add-Cursor-Up)i", {})
map("i", "<A-Down>", "<Esc><Plug>(VM-Add-Cursor-Down)i", {})

-- Start multi-cursor mode with Alt+Click
vim.cmd([[
  let g:VM_mouse_mappings = 1
]])
vim.g.VM_show_insert_mode = 1
vim.g.VM_set_statusline = 0 -- Optional: prevents statusline override
vim.api.nvim_set_hl(0, 'VM_Cursor', { fg = '#FFD700', bg = 'NONE', underline = true })
vim.api.nvim_set_hl(0, 'VM_Insert', { fg = '#FFD700', bg = 'NONE', underline = true })
vim.api.nvim_set_hl(0, 'VM_Extend', { fg = '#FFD700', bg = 'NONE', underline = true })
vim.api.nvim_set_hl(0, 'VM_Mono',   { fg = '#FFD700', bg = 'NONE', underline = true })
vim.o.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
vim.o.guicursor = "n-v-c-sm:block,i-ci-ve:ver1,r-cr-o:hor20"

-- CTRL Select Navigate
local map = vim.keymap.set

-- Smart Ctrl+Right
map("n", "<C-Right>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local char = line:sub(col, col)

  if char:match("%s") then
    vim.cmd("normal! w")
  elseif char:match("%w") then
    if col == 1 or not line:sub(col - 1, col - 1):match("%w") then
      vim.cmd("normal! e") -- at start of word
    else
      vim.cmd("normal! w") -- at end or mid word
    end
  else
    vim.cmd("normal! w") -- symbol or anything else
  end
end, { noremap = true, silent = true })

-- Smart Ctrl+Left
map("n", "<C-Left>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local char = line:sub(col, col)

  if char:match("%s") then
    vim.cmd("normal! b")
  elseif char:match("%w") then
    if col > 1 and not line:sub(col - 1, col - 1):match("%w") then
      vim.cmd("normal! b") -- at start
    else
      vim.cmd("normal! ge") -- inside or at end
    end
  else
    vim.cmd("normal! b")
  end
end, { noremap = true, silent = true })
local map = vim.keymap.set

-- Ctrl + Shift + Right = select to next word end
local map = vim.keymap.set

-- Select word right
map({ "n", "v" }, "<C-S-Right>", function()
  if vim.fn.mode() == "n" then vim.cmd("normal! v") end
  vim.cmd("normal! e")
end, { noremap = true, silent = true })

-- Select word left
map({ "n", "v" }, "<C-S-Left>", function()
  if vim.fn.mode() == "n" then vim.cmd("normal! v") end
  vim.cmd("normal! b")
end, { noremap = true, silent = true })

-- Select line down
map({ "n", "v" }, "<C-S-Down>", function()
  if vim.fn.mode() == "n" then vim.cmd("normal! V") end
  vim.cmd("normal! j")
end, { noremap = true, silent = true })

-- Select line up
map({ "n", "v" }, "<C-S-Up>", function()
  if vim.fn.mode() == "n" then vim.cmd("normal! V") end
  vim.cmd("normal! k")
end, { noremap = true, silent = true })

``````


## Installation

1. **Clone or install** this repository into your Neovim configuration’s plug‑in manager directory (for example using `git clone`).  A typical location is `~/.config/nvim/lua/pack`.

2. Add the following entry to your `lazy.setup()` call in your `init.lua` (or wherever you configure `lazy.nvim`).  Replace `path/to/mutagenix-pack` with the actual path or GitHub location:

```lua
require("lazy").setup({
  -- … your other specs …
  { "path/to/mutagenix-pack", import = "mutagenix_pack" },
})
```

3. Restart Neovim.  The pack will load automatically (the core module runs on startup) and the plug‑ins will lazy‑load according to their configured events.

### Requirements

- Neovim 0.8 or later.
- [lazy.nvim](https://github.com/folke/lazy.nvim) installed and bootstrapped.
- For the custom lint commands to work you’ll need **pylint**, **golangci‑lint** and **shellcheck** installed on your system.
- Optional: [ai_ui](https://github.com) plug‑in if you wish to use the `:Models` and `:ChangeModel` commands.

## Usage

Once installed, the pack sets a variety of options and keybindings out of the box:

- Use `<leader>x` to open a new scratch buffer.
- Use `\rp` or `\rb` to run the current file with Python 3 or Bash.
- Navigate between splits with `Ctrl+Arrow` keys.
- Create multiple cursors with `Alt+Up/Down` or Alt+Click.
- Run `:Wt`, `:Wg`, or `:Wtsh` to lint Python, Go or shell scripts.
- Use `:NSearch <term>` to search a personal note file.
- Spell checking is enabled automatically for many filetypes using Australian English; add unknown words with `<leader>z`.

See the [core.lua](./lua/mutagenix_pack/core.lua) file for full details.

## Contributing

Feel free to open issues or pull requests if you spot any bugs or have suggestions.  This pack is meant as a starting point; adjust it to your workflow by forking or editing the files.
