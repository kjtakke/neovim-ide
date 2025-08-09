local M = {}

-- Helper to load modules safely
local function safe_require(mod)
  local ok, pkg = pcall(require, mod)
  return ok and pkg or nil
end

-- Main setup function; applies options, keymaps, commands and utilities
function M.setup()
  -----------------------------------------------------------------------------
  -- Options ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Basic UI
  vim.opt.termguicolors = true
  vim.opt.number        = true
  vim.opt.cursorline    = true
  vim.opt.ignorecase    = true
  vim.opt.smartcase     = true
  vim.opt.scrolloff     = 10
  vim.opt.wildmenu      = true
  vim.opt.wildmode      = "longest,list"
  -- Folding
  vim.opt.foldmethod    = "indent"
  vim.opt.foldenable    = true
  vim.opt.foldlevel     = 99
  vim.opt.foldminlines  = 5
  -- Clipboard and modelines
  vim.opt.clipboard     = "unnamedplus"
  vim.opt.modeline      = false
  -- Listchars: show whitespace and EOL markers
  vim.opt.list          = true
  vim.opt.listchars = {
    tab      = '▸ ',
    trail    = '·',
    eol      = '↴',
    extends  = '❯',
    precedes = '❮',
    space    = '·',
  }
  -- Persistent spell file directory
  local spell_dir = vim.fn.stdpath("config") .. "/spell"
  if vim.fn.isdirectory(spell_dir) == 0 then
    vim.fn.mkdir(spell_dir, "p")
  end
  vim.opt.spellfile = spell_dir .. "/en.utf-8.add"

  -----------------------------------------------------------------------------
  -- Autocmds ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Open nvim-tree on VimEnter if available
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local api = safe_require("nvim-tree.api")
      if api then api.tree.open() end
    end,
  })
  -- Enable spellchecking (Australian English) for many filetypes
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = {
      -- Text/markup/documentation
      "markdown", "gitcommit", "text", "python", "rst", "tex", "html", "xml", "json", "yaml", "toml", "mail", "help",
      -- Programming/scripting
      "go", "lua", "vim", "javascript", "typescript", "css", "sh", "bash", "zsh", "c", "cpp", "java", "rust", "php", "ruby", "perl",
      -- Config/build
      "dockerfile", "make", "sql",
    },
    callback = function()
      vim.opt_local.spell     = true
      vim.opt_local.spelllang = "en_au"
    end,
  })
  -- Underline misspellings
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.cmd("highlight SpellBad gui=undercurl guisp=Red")
    end,
  })
  vim.cmd("highlight SpellBad gui=undercurl guisp=Red")

  -----------------------------------------------------------------------------
  -- Helper functions ----------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Create a new scratch buffer
  local function new_scratch()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
  end
  -- Show spelling issues aligned in a right split
  local function show_spellcheck_issues_aligned()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local total = #lines
    local out = {}
    for i = 1, total do out[i] = "" end
    for i, line in ipairs(lines) do
      local bad = vim.fn.spellbadword(line)[1]
      if bad and bad ~= "" then
        out[i] = string.format("Line %-4d | %-20s | %s", i, bad, line)
      end
    end
    local any = false
    for _, v in ipairs(out) do
      if v ~= "" then any = true; break end
    end
    if not any then
      vim.notify("No spelling issues found.", vim.log.levels.INFO)
      return
    end
    local main_win = vim.api.nvim_get_current_win()
    vim.cmd("rightbelow vsplit")
    local split_buf = vim.api.nvim_create_buf(false, true)
    local split_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(split_win, split_buf)
    vim.api.nvim_buf_set_lines(split_buf, 0, -1, false, out)
    vim.api.nvim_buf_set_option(split_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(split_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(split_buf, "readonly", true)
    vim.api.nvim_buf_set_option(split_buf, "wrap", false)
    vim.api.nvim_win_set_option(main_win, "scrollbind", true)
    vim.api.nvim_win_set_option(split_win, "scrollbind", true)
    vim.api.nvim_win_set_cursor(main_win, {1, 0})
    vim.api.nvim_win_set_cursor(split_win, {1, 0})
    vim.api.nvim_set_current_win(main_win)
  end
  -- Run pylint on current file
  local function run_pylint()
    vim.cmd('write')
    local filename = vim.fn.expand('%')
    local handle = io.popen('pylint "' .. filename .. '" 2>&1')
    if not handle then return vim.notify("Failed to run pylint") end
    local output = handle:read('*a')
    handle:close()
    local filtered = {}
    for line in output:gmatch('[^\r\n]+') do
      if line:match('^%S+:%d+:%d+: E') and not line:match('E0401') then
        table.insert(filtered, line)
      end
    end
    if #filtered == 0 then table.insert(filtered, "✅ No issues found!") end
    local ui = vim.api.nvim_list_uis()[1]
    local width  = math.floor(ui.width  * 0.6)
    local height = math.floor(ui.height * 0.6)
    local col    = math.floor((ui.width  - width)  / 2)
    local row    = math.floor((ui.height - height) / 2)
    local bufnr  = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, filtered)
    vim.api.nvim_open_win(bufnr, true, {
      style = "minimal", relative = "editor",
      width = width, height = height, col = col, row = row, border = "rounded"
    })
  end
  -- Run golangci‑lint on current file
  local function run_golint()
    vim.cmd('write')
    local filename = vim.fn.expand('%')
    local handle = io.popen('golangci-lint run "' .. filename .. '" 2>&1')
    if not handle then return vim.notify("Failed to run golangci-lint") end
    local output = handle:read('*a')
    handle:close()
    local filtered = {}
    for line in output:gmatch('[^\r\n]+') do
      if line:match(':%d+:%d+:') then table.insert(filtered, line) end
    end
    if #filtered == 0 then table.insert(filtered, "✅ No issues found!") end
    local ui = vim.api.nvim_list_uis()[1]
    local width  = math.floor(ui.width  * 0.6)
    local height = math.floor(ui.height * 0.6)
    local col    = math.floor((ui.width  - width)  / 2)
    local row    = math.floor((ui.height - height) / 2)
    local bufnr  = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, filtered)
    vim.api.nvim_open_win(bufnr, true, {
      style = "minimal", relative = "editor",
      width = width, height = height, col = col, row = row, border = "rounded"
    })
  end
  -- Run shellcheck on current file
  local function run_shellcheck()
    vim.cmd('silent! write!')
    local filename = vim.fn.expand('%:p')
    local shellcheck_path = '/usr/bin/shellcheck'
    if vim.fn.executable(shellcheck_path) == 0 then
      return vim.notify("ShellCheck not found at: " .. shellcheck_path, vim.log.levels.ERROR)
    end
    local handle = io.popen(shellcheck_path .. ' --severity=info --enable=all "' .. filename .. '" 2>&1')
    if not handle then return vim.notify("Failed to run ShellCheck", vim.log.levels.ERROR) end
    local output = handle:read('*a')
    handle:close()
    local lines = {}
    for line in output:gmatch("[^\r\n]+") do table.insert(lines, line) end
    if #lines == 0 then table.insert(lines, "✅ No issues found by ShellCheck!") end
    local ui = vim.api.nvim_list_uis()[1]
    local width  = math.floor(ui.width  * 0.6)
    local height = math.floor(ui.height * 0.6)
    local col    = math.floor((ui.width  - width)  / 2)
    local row    = math.floor((ui.height - height) / 2)
    local bufnr  = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_open_win(bufnr, true, {
      style = "minimal", relative = "editor",
      width = width, height = height, col = col, row = row, border = "rounded"
    })
  end
  -----------------------------------------------------------------------------
  -- Commands -----------------------------------------------------------------
  -----------------------------------------------------------------------------
  vim.api.nvim_create_user_command('Wg',   run_golint,    {})
  vim.api.nvim_create_user_command('Wt',   run_pylint,    {})
  vim.api.nvim_create_user_command('Wtsh', run_shellcheck,{})
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
    local function split(str, sep)
      local result = {}
      for token in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, vim.trim(token))
      end
      return result
    end
    local colw, rows = {}, {}
    for _, line in ipairs(lines) do
      local cols = split(line, "|")
      for i, c in ipairs(cols) do
        colw[i] = math.max(colw[i] or 0, #c)
      end
      table.insert(rows, cols)
    end
    for _, row in ipairs(rows) do
      local formatted = {}
      for i, c in ipairs(row) do
        table.insert(formatted, c .. string.rep(" ", colw[i] - #c))
      end
      print(table.concat(formatted, " | "))
    end
  end, {
    nargs = "+",
    desc  = "Search ~/.config/nvim/nsearch.txt (case-insensitive)",
  })
  vim.api.nvim_create_user_command("Todo", function()
    require("telescope.builtin").live_grep({ default_text = "TODO" })
  end, {})
  vim.api.nvim_create_user_command("Models", function()
    local ok, ui = pcall(require, "ai_ui")
    if ok then ui.show_models() end
  end, {})
  vim.api.nvim_create_user_command("ChangeModel", function(opts)
    local ok, ui = pcall(require, "ai_ui")
    if ok then ui.change_model(opts.args) end
  end, { nargs = 1 })
  -----------------------------------------------------------------------------
  -- Keymaps ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  local map = vim.keymap.set
  map("n", "<leader>x", new_scratch,                        { desc = "New Scratch" })
  map("n", "\\rp",  ":w !python3 %<CR>",                    { silent = true, desc = "Run Python" })
  map("n", "\\rb",  ":w !bash %<CR>",                       { silent = true, desc = "Run Bash"   })
  map("n", "\\q",   ":q<CR>",                            { silent = true, desc = "Quit"       })
  map("n", "\\qq",  ":q!<CR>",                           { silent = true, desc = "Force Quit" })
  map("n", "\\w",   ":w<CR>",                             { silent = true, desc = "Save"       })
  map("n", "<leader>z", "zg",                            { desc = "Add word to dictionary" })
  map("n", "<leader>sc", show_spellcheck_issues_aligned, { desc = "Show spelling issues (aligned)" })
  -- Git blame (requires vim-fugitive)
  map('n', '<leader>b', ':G blame<CR>', { noremap = true, silent = true, desc = 'Git Blame' })
  -- Window navigation with Ctrl + Arrow keys
  map('n', '<C-Right>', '<C-w>l', { noremap = true, silent = true })
  map('n', '<C-Left>',  '<C-w>h', { noremap = true, silent = true })
  map('n', '<C-Down>',  '<C-w>j', { noremap = true, silent = true })
  map('n', '<C-Up>',    '<C-w>k', { noremap = true, silent = true })
  -- Smart word navigation overrides basic Ctrl+Left/Right
  map("n", "<C-Right>", function()
    local col  = vim.fn.col('.')
    local line = vim.fn.getline('.')
    local char = line:sub(col, col)
    if char:match("%s") then
      vim.cmd("normal! w")
    elseif char:match("%w") then
      if col == 1 or not line:sub(col - 1, col - 1):match("%w") then
        vim.cmd("normal! e")
      else
        vim.cmd("normal! w")
      end
    else
      vim.cmd("normal! w")
    end
  end, { noremap = true, silent = true })
  map("n", "<C-Left>", function()
    local col  = vim.fn.col('.')
    local line = vim.fn.getline('.')
    local char = line:sub(col, col)
    if char:match("%s") then
      vim.cmd("normal! b")
    elseif char:match("%w") then
      if col > 1 and not line:sub(col - 1, col - 1):match("%w") then
        vim.cmd("normal! b")
      else
        vim.cmd("normal! ge")
      end
    else
      vim.cmd("normal! b")
    end
  end, { noremap = true, silent = true })
  -- Multi‑cursor mappings (vim-visual-multi)
  vim.g.VM_default_mappings = 0
  vim.cmd([[ let g:VM_mouse_mappings = 1 ]])
  vim.g.VM_show_insert_mode = 1
  vim.g.VM_set_statusline = 0
  vim.api.nvim_set_hl(0, 'VM_Cursor', { fg = '#FFD700', bg = 'NONE', underline = true })
  vim.api.nvim_set_hl(0, 'VM_Insert', { fg = '#FFD700', bg = 'NONE', underline = true })
  vim.api.nvim_set_hl(0, 'VM_Extend', { fg = '#FFD700', bg = 'NONE', underline = true })
  vim.api.nvim_set_hl(0, 'VM_Mono',   { fg = '#FFD700', bg = 'NONE', underline = true })
  vim.o.guicursor = "n-v-c-sm:block,i-ci-ve:ver1,r-cr-o:hor20"
  map('n', '<A-Up>',   '<Plug>(VM-Add-Cursor-Up)',   {})
  map('n', '<A-Down>', '<Plug>(VM-Add-Cursor-Down)', {})
  map('i', '<A-Up>',   '<Esc><Plug>(VM-Add-Cursor-Up)i',   {})
  map('i', '<A-Down>', '<Esc><Plug>(VM-Add-Cursor-Down)i', {})
  -- Selection with Ctrl+Shift arrows
  map({ "n", "v" }, "<C-S-Right>", function()
    if vim.fn.mode() == "n" then vim.cmd("normal! v") end
    vim.cmd("normal! e")
  end, { noremap = true, silent = true })
  map({ "n", "v" }, "<C-S-Left>", function()
    if vim.fn.mode() == "n" then vim.cmd("normal! v") end
    vim.cmd("normal! b")
  end, { noremap = true, silent = true })
  map({ "n", "v" }, "<C-S-Down>", function()
    if vim.fn.mode() == "n" then vim.cmd("normal! V") end
    vim.cmd("normal! j")
  end, { noremap = true, silent = true })
  map({ "n", "v" }, "<C-S-Up>", function()
    if vim.fn.mode() == "n" then vim.cmd("normal! V") end
    vim.cmd("normal! k")
  end, { noremap = true, silent = true })
  -- Telescope helpers
  map("n", "<leader>gf", function()
    local word = vim.fn.expand("<cword>")
    if word and word ~= "" then
      local query = "^(func|var|type|const) " .. word
      require("telescope.builtin").live_grep({ default_text = query })
    end
  end, { noremap = true, silent = true })
  map("n", "<leader>gd", function()
    local word = vim.fn.expand("<cword>")
    if word and word ~= "" then
      local query = word .. "\\("
      require("telescope.builtin").live_grep({ default_text = query })
    end
  end, { noremap = true, silent = true })
  -- AI UI keymap if installed
  pcall(function()
    vim.api.nvim_set_keymap('n', '<leader>ai',
      [[<cmd>lua require'ai_ui'.set_last_buf()<CR><cmd>lua require'ai_ui'.open_ui()<CR>]],
      { noremap = true, silent = true }
    )
  end)
  -----------------------------------------------------------------------------
  -- Highlights and cursor -----------------------------------------------------
  -----------------------------------------------------------------------------
  -- Pink punctuation for Treesitter
  vim.api.nvim_set_hl(0, "@punctuation.bracket",   { fg = "#ff69b4" })
  vim.api.nvim_set_hl(0, "@punctuation.delimiter", { fg = "#ff69b4" })
  -- Cursor highlight group
  vim.cmd([[ highlight Cursor guifg=NONE guibg=Gold gui=NONE ctermfg=NONE ctermbg=Yellow cterm=NONE ]])
  vim.opt.guicursor = table.concat({
    "n-v-c:block-Cursor",      -- Normal, Visual, Command
    "i-ci-ve:ver25-Cursor",    -- Insert & related modes
    "r-cr:hor20-Cursor",       -- Replace modes
    "o:hor50-Cursor",          -- Operator pending
    "a:blinkon0"               -- Disable blinking
  }, ",")
end

return M
