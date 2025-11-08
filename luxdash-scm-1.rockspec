package = "luxdash"
version = "scm-1"

source = {
  url = "git://github.com/LuxVim/nvim-luxdash",
  branch = "main"
}

description = {
  summary = "A beautiful, modular Neovim dashboard plugin with floating window support",
  detailed = [[
    nvim-luxdash is a highly customizable Neovim dashboard plugin featuring:
    - Beautiful gradient-colored ASCII logo
    - Recent files with quick access (1-9 keybindings)
    - Real-time git repository status
    - Interactive menu with custom actions
    - Floating window interface with responsive layout
    - Multi-tier caching for performance
    - Modular architecture for easy extension
  ]],
  homepage = "https://github.com/LuxVim/nvim-luxdash",
  license = "MIT",
  maintainer = "LuxVim Team"
}

dependencies = {
  "lua >= 5.1, < 5.5"
}

external_dependencies = {
  NVIM = {
    program = "nvim"
  }
}

build = {
  type = "builtin",
  modules = {
    -- Core modules
    ["luxdash"] = "lua/luxdash/init.lua",
    ["luxdash.constants"] = "lua/luxdash/constants.lua",
    ["luxdash.health"] = "lua/luxdash/health.lua",

    -- Core functionality
    ["luxdash.core.core"] = "lua/luxdash/core/core.lua",
    ["luxdash.core.builder"] = "lua/luxdash/core/builder.lua",
    ["luxdash.core.renderer"] = "lua/luxdash/core/renderer.lua",
    ["luxdash.core.dashboard"] = "lua/luxdash/core/dashboard.lua",
    ["luxdash.core.cache"] = "lua/luxdash/core/cache.lua",
    ["luxdash.core.resizer"] = "lua/luxdash/core/resizer.lua",
    ["luxdash.core.debouncer"] = "lua/luxdash/core/debouncer.lua",
    ["luxdash.core.highlight_pool"] = "lua/luxdash/core/highlight_pool.lua",

    -- Rendering
    ["luxdash.rendering.colors"] = "lua/luxdash/rendering/colors.lua",
    ["luxdash.rendering.highlights"] = "lua/luxdash/rendering/highlights.lua",
    ["luxdash.rendering.section_renderer"] = "lua/luxdash/rendering/section_renderer.lua",
    ["luxdash.rendering.alignment"] = "lua/luxdash/rendering/alignment.lua",
    ["luxdash.rendering.line_utils"] = "lua/luxdash/rendering/line_utils.lua",

    -- Sections
    ["luxdash.sections.logo"] = "lua/luxdash/sections/logo.lua",
    ["luxdash.sections.menu"] = "lua/luxdash/sections/menu.lua",
    ["luxdash.sections.recent_files"] = "lua/luxdash/sections/recent_files.lua",
    ["luxdash.sections.git_status"] = "lua/luxdash/sections/git_status.lua",
    ["luxdash.sections.empty"] = "lua/luxdash/sections/empty.lua",

    -- UI
    ["luxdash.ui.float_manager"] = "lua/luxdash/ui/float_manager.lua",
    ["luxdash.ui.buffer_manager"] = "lua/luxdash/ui/buffer_manager.lua",

    -- Configuration
    ["luxdash.config.migration"] = "lua/luxdash/config/migration.lua",
    ["luxdash.config.validator"] = "lua/luxdash/config/validator.lua",

    -- Menu actions
    ["luxdash.menu.newfile"] = "lua/luxdash/menu/newfile.lua",
    ["luxdash.menu.backtrack"] = "lua/luxdash/menu/backtrack.lua",
    ["luxdash.menu.fzf"] = "lua/luxdash/menu/fzf.lua",
    ["luxdash.menu.closelux"] = "lua/luxdash/menu/closelux.lua",
    ["luxdash.menu.recent"] = "lua/luxdash/menu/recent.lua",
    ["luxdash.menu.search"] = "lua/luxdash/menu/search.lua",
    ["luxdash.menu.quit"] = "lua/luxdash/menu/quit.lua",
    ["luxdash.menu.new"] = "lua/luxdash/menu/new.lua",

    -- Utilities
    ["luxdash.utils.icons"] = "lua/luxdash/utils/icons.lua",
    ["luxdash.utils.width"] = "lua/luxdash/utils/width.lua",
    ["luxdash.utils.string"] = "lua/luxdash/utils/string.lua",
    ["luxdash.utils.math"] = "lua/luxdash/utils/math.lua",
    ["luxdash.utils.text"] = "lua/luxdash/utils/text.lua",
    ["luxdash.utils.window_tracker"] = "lua/luxdash/utils/window_tracker.lua",
    ["luxdash.utils.menu"] = "lua/luxdash/utils/menu.lua",

    -- Events
    ["luxdash.events.autocmds"] = "lua/luxdash/events/autocmds.lua",

    -- Layout
    ["luxdash.layout"] = "lua/luxdash/layout.lua",
  },
  copy_directories = {
    "plugin"
  }
}
