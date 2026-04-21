-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

local ACC   = "#FD6AC0"
local GREY4 = "#444444"
local BG2   = "#2a2d36"

M.base46 = {
  theme = "aquarium",
  transparency = true,

  hl_override = {
    -- core
    CursorLineNr = { fg = ACC, bold = true },
    MatchParen   = { fg = ACC, bold = true },
    IncSearch    = { fg = "#161718", bg = ACC, bold = true },
    Search       = { fg = "#161718", bg = ACC },
    Directory    = { fg = ACC },
    Title        = { fg = ACC, bold = true },
    Visual       = { bg = BG2 },
    WinSeparator = { fg = GREY4 },
    FloatBorder  = { fg = ACC },

    St_file             = { fg = "#ffffff" },
    St_gitIcons         = { fg = ACC },
    St_pos_text         = { fg = "#ffffff" },
    St_pos_icon         = { bg = ACC },
    St_pos_sep          = { fg = ACC },
    St_cwd_text         = { fg = "#ffffff"},
    St_cwd_icon         = { bg = ACC },
    St_cwd_sep          = { fg = ACC },
    St_InsertMode       = { bg = ACC },
    St_InsertModeSep    = { fg = ACC },
    St_NormalMode       = { bg = ACC },
    St_NormalModeSep    = { fg = ACC },
    St_VisualMode       = { bg = ACC },
    St_VisualModeSep    = { fg = ACC },
    St_CommandMode      = { bg = ACC },
    St_CommandModeSep   = { fg = ACC },
    St_TerminalMode     = { bg = ACC },
    St_TerminalModeSep  = { fg = ACC },
    St_NTerminalMode    = { bg = ACC },
    St_NTerminalModeSep = { fg = ACC },
    St_SelectMode       = { bg = ACC },
    St_SelectModeSep    = { fg = ACC },
    St_ReplaceMode      = { bg = ACC },
    St_ReplaceModeSep   = { fg = ACC },

    -- diagnostics
    DiagnosticSignWarn  = { bg = ACC },

    -- Telescope
    TelescopeBorder        = { fg = ACC },
    TelescopePromptBorder  = { fg = ACC },
    TelescopeResultsBorder = { fg = GREY4 },
    TelescopePreviewBorder = { fg = GREY4 },
    TelescopeTitle         = { fg = "#161718", bg = ACC, bold = true },
    TelescopeSelection     = { fg = "#000000", bg = ACC },
    TelescopePromptTitle   = { bg = ACC },

    -- NvimTree
    NvimTreeFolderIcon        = { fg = ACC },
    NvimTreeWinSeparator      = { fg = GREY4 },

    -- Completion popup
    PmenuSel = { bg = ACC, fg = "#161718" },
    Pmenu    = { bg = BG2 },

    -- dashboard
    NvDashAscii = { fg = "#1dbc60" },
    NvDashFooter = { fg = ACC },
  },

  -- OPTIONAL: define new groups some plugins link to
  hl_add = {
    TelescopePromptTitle = { fg = "#161718", bg = ACC, bold = true },
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    " ▄▄▄▄    ▒█████   ███▄ ▄███▓ ▄▄▄▄    ▄▄▄      ",
    "▓█████▄ ▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▒████▄    ",
    "▒██▒ ▄██▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██  ▀█▄  ",
    "▒██░█▀  ▒██   ██░▒██    ▒██ ▒██░█▀  ░██▄▄▄▄██ ",
    "░▓█  ▀█▓░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓ ▓█   ▓██▒",
    "░▒▓███▀▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒ ▒▒   ▓▒█░",
    "▒░▒   ░   ░ ▒ ▒░ ░  ░      ░▒░▒   ░   ▒   ▒▒ ░",
    " ░    ░ ░ ░ ░ ▒  ░      ░    ░    ░   ░   ▒   ",
    " ░          ░ ░         ░    ░            ░  ░",
    "      ░                           ░           ",
    "",
    "",
  }
}

M.ui = {
  statusline = {
    theme = "default",
    separator_style = "round",
  }
}

return M
