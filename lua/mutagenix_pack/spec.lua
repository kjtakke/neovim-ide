-- Returns a list of Lazy.nvim plug‑in specifications plus a core pseudo‑plug‑in.

-- Safe require helper used in config functions; avoids throwing on missing modules.
local function safe_require(mod)
  local ok, pkg = pcall(require, mod)
  return ok and pkg or nil
end

local M = {}

-- Core pseudo‑plug‑in: runs our editor setup immediately (high priority)
M[1] = {
  name     = "mutagenix/core",
  priority = 10000,
  lazy     = false,
  config   = function()
    require("mutagenix_pack.core").setup()
  end,
}

-- todo-comments.nvim
table.insert(M, {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event        = { "BufReadPost", "BufNewFile" },
  opts         = {
    signs = true,
    highlight = {
      keyword = "bg",   -- highlight the whole keyword
      after   = "fg",   -- colour the text after the keyword
    },
    search = {
      command = "rg",
      args    = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
      pattern = [[\b(KEYWORDS):]],
    },
    keywords = {
      TODO  = { icon = " ", colour = "info" },
      FIX   = { icon = " ", colour = "error",  alt = { "FIXME", "BUG" } },
      WARN  = { icon = " ", colour = "warning", alt = { "WARNING" } },
      NOTE  = { icon = " ", colour = "hint",    alt = { "INFO" } },
      PERF  = { icon = " ", colour = "default", alt = { "PERFORMANCE" } },
      CHORE = { icon = " ", colour = "default" },
      IDEA  = { icon = "💡", colour = "hint" },
    },
  },
  keys = {
    { "]t",  function() require("todo-comments").jump_next() end, desc = "Next TODO/FIX/WARN" },
    { "[t",  function() require("todo-comments").jump_prev() end, desc = "Prev TODO/FIX/WARN"  },
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Todos (Telescope)" },
    { "<leader>tq", "<cmd>TodoQuickFix<cr>",  desc = "Todos → Quickfix" },
    { "<leader>tl", "<cmd>TodoLocList<cr>",   desc = "Todos → Loclist"  },
    { "<leader>tt", "<cmd>TodoTrouble<cr>",   desc = "Todos (Trouble)"  },
  },
})

-- Markdown preview
table.insert(M, {
  "iamcco/markdown-preview.nvim",
  ft    = { "markdown" },
  build = "cd app && npm install",
  init  = function()
    vim.g.mkdp_auto_start         = 0
    vim.g.mkdp_auto_close         = 1
    vim.g.mkdp_refresh_slow       = 0
    vim.g.mkdp_command_for_global = 0
    vim.g.mkdp_open_to_the_world  = 0
    vim.g.mkdp_open_ip            = "127.0.0.1"
    vim.g.mkdp_port               = "8080"
    vim.g.mkdp_theme              = "dark"
  end,
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview (HTTP)" },
  },
})

-- Colourscheme: catppuccin with integrations
table.insert(M, {
  "catppuccin/nvim",
  name     = "catppuccin",
  priority = 1000,
  config   = function()
    local cap = safe_require("catppuccin")
    if cap then
      cap.setup({
        integrations = {
          telescope = true,
          nvimtree  = true,
          cmp       = true,
        },
      })
    end
    vim.cmd.colorscheme("catppuccin")
  end,
})

-- GitHub Copilot client
table.insert(M, {
  "github/copilot.vim",
  lazy = false,
})

-- Visual Multi (multi‑cursor)
table.insert(M, {
  "mg979/vim-visual-multi",
  branch = "master",
})

-- LSP / Mason / Completion
table.insert(M, {
  "neovim/nvim-lspconfig",
})

table.insert(M, {
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
  config = function()
    local mason = safe_require("mason")
    if mason then mason.setup() end
  end,
})

table.insert(M, {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local mls = safe_require("mason-lspconfig")
    if mls then
      mls.setup({
        ensure_installed = {
          -- Web
          "html", "cssls", "emmet_ls", "vtsls", "eslint", "jsonls",
          -- Backend / general purpose
          "pyright", "bashls", "lua_ls", "gopls", "rust_analyzer", "clangd", "dockerls", "yamlls", "graphql",
          -- JVM / XML / .NET
          "jdtls", "kotlin_language_server", "lemminx", "omnisharp",
          -- DB / Configs
          "sqlls", "taplo",
          -- Others
          "perlpls", "powershell_es", "ansiblels", "terraformls",
          -- Docs / Markdown
          "marksman", "ltex",
        },
      })
    end
  end,
})

table.insert(M, {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp     = safe_require("cmp")
    local luasnip = safe_require("luasnip")
    if cmp and luasnip then
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
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
    end
  end,
})

-- Treesitter
table.insert(M, {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local ts = safe_require("nvim-treesitter.configs")
    if ts then
      ts.setup({
        ensure_installed = {
          -- Web
          "css", "html", "javascript", "json", "scss", "typescript",
          -- Backend / General purpose
          "bash", "c", "cpp", "elixir", "go", "java", "kotlin", "lua", "perl", "php", "python", "ruby", "rust",
          -- Infra / Scripting
          "dockerfile", "make", "terraform", "toml", "yaml",
          -- Markup / Docs
          "latex", "markdown", "markdown_inline",
          -- Other
          "graphql", "regex", "sql",
        },
        highlight = { enable = true },
      })
    end
  end,
})

-- File explorer
table.insert(M, {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" },
  },
  config = function()
    local nvtree = safe_require("nvim-tree")
    if nvtree then
      nvtree.setup({
        view = {
          width = 50,
          side  = "left",
          preserve_window_proportions = true,
        },
        filters = {
          custom  = { ".git" },
          exclude = {},
        },
        respect_buf_cwd = false,
      })
    end
  end,
})

-- Telescope
table.insert(M, {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local builtin = safe_require("telescope.builtin")
    if not builtin then return end
    local map = vim.keymap.set
    map("n", "<leader>ff", builtin.find_files,  { desc = "Find Files"       })
    map("n", "<leader>fg", builtin.live_grep,   { desc = "Live Grep"        })
    map("n", "<leader>fb", builtin.buffers,     { desc = "Buffers"          })
    map("n", "<leader>fh", builtin.help_tags,   { desc = "Help Tags"        })
    map("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics"      })
    map("n", "<leader>fr", builtin.resume,      { desc = "Resume"           })
  end,
})

-- UI niceties
table.insert(M, {
  "nvim-lualine/lualine.nvim",
  config = function()
    local line = safe_require("lualine")
    if line then
      line.setup({ options = { theme = "catppuccin" } })
    end
  end,
})
table.insert(M, { "lewis6991/gitsigns.nvim", config = true })
table.insert(M, { "windwp/nvim-autopairs",   config = true })
table.insert(M, { "numToStr/Comment.nvim",   config = true })

-- Optional: vim-fugitive for :G blame support
table.insert(M, { "tpope/vim-fugitive" })

return M
