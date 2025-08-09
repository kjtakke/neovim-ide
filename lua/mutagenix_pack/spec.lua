-- lua/mutagenix_pack/spec.lua
local function safe_require(mod)
  local ok, pkg = pcall(require, mod)
  return ok and pkg or nil
end

local M = {}

-- 1) Core loader anchored to a real plugin so the spec is valid
M[#M+1] = {
  "nvim-lua/plenary.nvim",
  lazy = false,
  priority = 10000,
  init = function()
    require("mutagenix_pack.core").setup()
  end,
}

-- 2) todo-comments
M[#M+1] = {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    signs = true,
    highlight = { keyword = "bg", after = "fg" },
    search = {
      command = "rg",
      args = { "--color=never","--no-heading","--with-filename","--line-number","--column" },
      pattern = [[\b(KEYWORDS):]],
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
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO/FIX/WARN"  },
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Todos (Telescope)" },
    { "<leader>tq", "<cmd>TodoQuickFix<cr>",  desc = "Todos → Quickfix" },
    { "<leader>tl", "<cmd>TodoLocList<cr>",   desc = "Todos → Loclist"  },
    { "<leader>tt", "<cmd>TodoTrouble<cr>",   desc = "Todos (Trouble)"  },
  },
}

-- 3) Markdown preview
M[#M+1] = {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = "cd app && npm install",
  init = function()
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_command_for_global = 0
    vim.g.mkdp_open_to_the_world = 0
    vim.g.mkdp_open_ip = "127.0.0.1"
    vim.g.mkdp_port = "8080"
    vim.g.mkdp_theme = "dark"
  end,
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview (HTTP)" },
  },
}

-- 4) Colourscheme
M[#M+1] = {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local c = safe_require("catppuccin")
    if c then
      c.setup({ integrations = { telescope = true, nvimtree = true, cmp = true } })
      vim.cmd.colorscheme("catppuccin")
    end
  end,
}

-- 5) Copilot
M[#M+1] = { "github/copilot.vim", lazy = false }

-- 6) Visual Multi
M[#M+1] = { "mg979/vim-visual-multi", branch = "master" }

-- 7) LSP / Mason / Completion
M[#M+1] = { "neovim/nvim-lspconfig" }

M[#M+1] = {
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
  config = function()
    local mason = safe_require("mason")
    if mason then mason.setup() end
  end,
}

M[#M+1] = {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local m = safe_require("mason-lspconfig")
    if m then
      m.setup({
        ensure_installed = {
          -- Web
          "html","cssls","emmet_ls","vtsls","eslint","jsonls",
          -- Backend
          "pyright","bashls","lua_ls","gopls","rust_analyzer","clangd","dockerls","yamlls","graphql",
          -- JVM / XML / .NET-ish
          "jdtls","kotlin_language_server","lemminx","omnisharp",
          -- DB / Config
          "sqlls","taplo",
          -- Others
          "perlpls","powershell_es","ansiblels","terraformls",
          -- Docs
          "marksman","ltex",
        },
      })
    end
  end,
}

M[#M+1] = {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp, luasnip = safe_require("cmp"), safe_require("luasnip")
    if not (cmp and luasnip) then return end
    cmp.setup({
      snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"]      = cmp.mapping.confirm({ select = true }),
        ["<Tab>"]     = cmp.mapping.select_next_item(),
        ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
      }),
      sources = { { name = "nvim_lsp" }, { name = "luasnip" } },
    })
  end,
}

-- 8) Treesitter
M[#M+1] = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local ts = safe_require("nvim-treesitter.configs")
    if ts then
      ts.setup({
        ensure_installed = {
          -- Web
          "css","html","javascript","json","scss","typescript",
          -- Backend / General-purpose
          "bash","c","cpp","elixir","go","java","kotlin","lua","perl","php","python","ruby","rust",
          -- Infra / Scripting
          "dockerfile","make","terraform","toml","yaml",
          -- Docs
          "latex","markdown","markdown_inline",
          -- Other
          "graphql","regex","sql",
        },
        highlight = { enable = true },
      })
    end
  end,
}

-- 9) File explorer
M[#M+1] = {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" } },
  config = function()
    local t = safe_require("nvim-tree")
    if t then
      t.setup({
        view = { width = 50, side = "left", preserve_window_proportions = true },
        filters = { custom = { ".git" }, exclude = {} },
        respect_buf_cwd = false,
      })
    end
  end,
}

-- 10) Telescope
M[#M+1] = {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local builtin = safe_require("telescope.builtin")
    if not builtin then return end
    local map = vim.keymap.set
    map("n", "<leader>ff", builtin.find_files,  { desc = "Find Files" })
    map("n", "<leader>fg", builtin.live_grep,   { desc = "Live Grep"  })
    map("n", "<leader>fb", builtin.buffers,     { desc = "Buffers"    })
    map("n", "<leader>fh", builtin.help_tags,   { desc = "Help Tags"  })
    map("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics"})
    map("n", "<leader>fr", builtin.resume,      { desc = "Resume"     })
  end,
}

-- 11) UI niceties
M[#M+1] = {
  "nvim-lualine/lualine.nvim",
  config = function()
    local l = safe_require("lualine")
    if l then l.setup({ options = { theme = "catppuccin" } }) end
  end,
}
M[#M+1] = { "lewis6991/gitsigns.nvim",  config = true }
M[#M+1] = { "windwp/nvim-autopairs",    config = true }
M[#M+1] = { "numToStr/Comment.nvim",    config = true }

-- Optional: fugitive for <leader>b mapping in your core
M[#M+1] = { "tpope/vim-fugitive" }

return M
