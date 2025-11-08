--- Constants and configuration defaults for nvim-luxdash
--- This module centralizes all magic numbers and default values
--- to improve maintainability and make the codebase more self-documenting
local M = {}

-- Layout configuration
M.LAYOUT = {
  -- Main section takes 80% of total height by default
  MAIN_HEIGHT_RATIO = 0.8,

  -- Spacing between sections (in characters)
  SECTION_SPACING = 4,

  -- Maximum number of recent files to display (limited by available keybindings 1-9)
  MAX_RECENT_FILES = 9,
}

-- Cache configuration
M.CACHE = {
  -- Maximum size for pre-computed padding cache
  -- Padding strings from 1 to this size are pre-generated for performance
  MAX_PADDING_SIZE = 200,
}

-- Debouncing configuration (in milliseconds)
M.DEBOUNCE = {
  -- Debounce delay for window resize operations
  -- Prevents excessive redraws during terminal resizing
  RESIZE_MS = 50,

  -- Debounce delay for window dimension changes
  -- Used when tracking window size changes
  WINDOW_CHANGE_MS = 25,
}

-- Window configuration
M.WINDOW = {
  -- Default floating window dimensions (as ratio of screen size)
  DEFAULT_WIDTH = 0.9,   -- 90% of screen width
  DEFAULT_HEIGHT = 0.9,  -- 90% of screen height

  -- Z-index for floating window (higher = on top)
  ZINDEX = 100,

  -- Minimum padding around float window when using absolute dimensions
  MIN_PADDING = 4,
}

-- Padding defaults
M.PADDING = {
  -- Global padding around dashboard content
  LEFT = 2,
  RIGHT = 2,
  TOP = 1,
  BOTTOM = 1,
}

-- Git configuration
M.GIT = {
  -- Timeout for git commands (in milliseconds)
  -- Prevents hanging when git operations are slow
  COMMAND_TIMEOUT_MS = 5000,
}

-- Text formatting
M.TEXT = {
  -- Minimum width for truncated text with ellipsis
  MIN_ELLIPSIS_WIDTH = 3,

  -- Ellipsis character/string used for truncation
  ELLIPSIS = '...',
}

-- Section defaults
M.SECTION = {
  -- Default recent files to show (can be overridden by config)
  DEFAULT_MAX_FILES = 10,

  -- Minimum spacing between filename and key indicator
  MIN_FILENAME_KEY_SPACING = 2,

  -- Minimum width reserved for filename display
  MIN_FILENAME_WIDTH = 3,
}

-- Color presets for logo gradients
M.COLOR_PRESETS = {
  blue = {
    start = '#89b4fa',
    bottom = '#74c7ec'
  },
  green = {
    start = '#a6e3a1',
    bottom = '#94e2d5'
  },
  red = {
    start = '#f38ba8',
    bottom = '#eba0ac'
  },
  yellow = {
    start = '#f9e2af',
    bottom = '#fab387'
  },
  purple = {
    start = '#cba6f7',
    bottom = '#f5c2e7'
  },
  orange = {
    start = '#ff7801',
    bottom = '#db2dee'  -- Default LuxVim gradient
  },
  pink = {
    start = '#f5c2e7',
    bottom = '#f38ba8'
  },
  cyan = {
    start = '#89dceb',
    bottom = '#74c7ec'
  }
}

-- Highlight group names
M.HIGHLIGHTS = {
  -- Logo highlight
  LOGO = 'LuxDashLogo',

  -- Title and underline
  TITLE = 'LuxDashTitle',
  UNDERLINE = 'LuxDashUnderline',

  -- Menu section
  MENU_ICON = 'LuxDashMenuIcon',
  MENU_ITEM = 'LuxDashMenuItem',
  MENU_KEY = 'LuxDashMenuKey',

  -- Recent files section
  RECENT_ICON = 'LuxDashRecentIcon',
  RECENT_FILE = 'LuxDashRecentFile',
  RECENT_KEY = 'LuxDashRecentKey',

  -- Git status section
  GIT_BRANCH = 'LuxDashGitBranch',
  GIT_SYNC = 'LuxDashGitSync',
  GIT_DIFF = 'LuxDashGitDiff',
  GIT_COMMIT = 'LuxDashGitCommit',

  -- General
  COMMENT = 'LuxDashComment',
}

-- Namespace names for highlights
M.NAMESPACES = {
  LOGO = 'luxdash_logo',
  MENU = 'luxdash_menu',
  OTHER = 'luxdash_other',
}

-- Cache keys
M.CACHE_KEYS = {
  LAYOUT = 'layout',
  LOGO = 'logo',
  SECTIONS = 'sections',
  HIGHLIGHTS = 'highlights',
}

-- Minimum Neovim version required
M.MIN_NEOVIM_VERSION = {
  MAJOR = 0,
  MINOR = 9,
  PATCH = 0,
}

return M
