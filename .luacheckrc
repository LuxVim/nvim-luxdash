-- vim: ft=lua
-- Luacheck configuration for nvim-luxdash

-- Rerun tests only if their modification time changed
cache = true

ignore = {
  "212", -- Unused argument, for callbacks use _arg_name for clarity
  "631", -- Line too long
}

-- Global objects defined by Neovim
read_globals = {
  "vim",
}

std = "luajit"
