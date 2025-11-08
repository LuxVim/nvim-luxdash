local M = {}
local constants = require('luxdash.constants')

M.config = {
  name = 'LuxDash',
  layout = 'horizontal',
  logo = {
    '',
    '⢠⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⣤⣤⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠛⠛⠛⠻⢿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠈⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠈⣿⣿⡀⠀⠀⠀⣰⣿⡿⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠈⣿⣿⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣤⠀⠀⠀⠀⣿⣿⣴⣿⣿⣿⣿⣶⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠈⣿⣿⡀⠀⣰⣿⡟⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⣾⣿⠋⠀⠀⠀⠙⣿⣷⠀⠀⠀⣿⣿⠁⠀⠀⠀⠻⣿⣧⠀⠀⠀⣿⣿⠋⠀⠀⠀⠙⣿⣷',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⢿⣿⣴⣿⠟⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣏⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⢀⣴⣿⣿⠿⠿⠿⣿⣿⠀⠀⠀⠀⠛⠿⣿⣿⣷⣦⣀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣾⣿⠻⣿⣆⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣸⣿⡟⠀⠀⠀⣿⣿⠁⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣧⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡀⠀⠀⠀⢀⣿⣿⠀⠀⠀⠀⣾⣿⠃⠀⠻⣿⣦⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣀⣴⣿⡟⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣠⣿⣿⠀⠀⠘⣿⣷⠀⠀⠀⠀⢀⣿⣿⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠈⣿⣿⣷⣶⣿⣿⢿⣿⠀⠀⢀⣿⣿⠃⠀⠀⠀⠹⣿⣧⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠹⣿⣿⣶⣶⣿⠿⣿⣿⠀⠀⠀⠙⣿⣿⣶⣶⣾⣿⡿⠁⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '',
  },
  logo_color = {
    row_gradient = {
      start = '#ff7801',
      bottom = '#db2dee'
    }
  },
  
  -- New modular section configuration
  sections = {
    -- Main section (logo area)
    main = {
      type = 'logo',
      config = {
        title = nil,
        show_title = false,
        show_underline = false,
        alignment = {
          horizontal = 'center',
          vertical = 'center'
        }
      }
    },
    -- Dynamic bottom sections
    bottom = {
      {
        id = 'actions',
        type = 'menu',
        title = '⚡ Actions',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'center'
          },
          padding = { left = 2, right = 2 },
          -- Menu-specific config
          menu_items = { 'newfile', 'backtrack', 'fzf', 'closelux' }
        }
      },
      {
        id = 'recent_files',
        type = 'recent_files',
        title = '📁 Recent Files',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'left'
          },
          padding = { left = 2, right = 2 },
          -- Recent files specific config
          max_files = 8
        }
      },
      {
        id = 'git_status',
        type = 'git_status',
        title = '🌿 Git Status',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'left'
          },
          padding = { left = 2, right = 2 }
        }
      }
    }
  },
  
  -- Layout configuration
  layout_config = {
    main_height_ratio = constants.LAYOUT.MAIN_HEIGHT_RATIO,
    bottom_sections_equal_width = true, -- Equal width for bottom sections
    section_spacing = constants.LAYOUT.SECTION_SPACING
  },

  float = {
    width = constants.WINDOW.DEFAULT_WIDTH,
    height = constants.WINDOW.DEFAULT_HEIGHT,
    border = 'rounded',
    title = ' LuxDash ',
    title_pos = 'center',
    hide_buffer = false
  },
  padding = {
    left = constants.PADDING.LEFT,
    right = constants.PADDING.RIGHT,
    top = constants.PADDING.TOP,
    bottom = constants.PADDING.BOTTOM
  }
}

--- Setup nvim-luxdash with optional user configuration
--- This function initializes the plugin, validates configuration, sets up highlights,
--- creates user commands, and registers autocmds
--- @param opts table|nil Optional user configuration to override defaults
function M.setup(opts)
  -- Validate user configuration before merging
  if opts then
    local validator = require('luxdash.config.validator')
    validator.validate_and_warn(opts)
  end

  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Invalidate all caches when configuration changes
  local cache = require('luxdash.core.cache')
  cache.invalidate_all()
  
  -- Clear color cache when configuration changes
  local colors = require('luxdash.rendering.colors')
  colors.clear_color_cache()
  
  -- Setup highlights
  local highlights = require('luxdash.rendering.highlights')
  highlights.setup()
  
  local float_manager = require('luxdash.ui.float_manager')
  float_manager.setup(M.config.float or {})
  
  vim.api.nvim_create_user_command('LuxDash', function()
    float_manager.toggle()
  end, { desc = 'Toggle LuxDash floating window' })
  
  -- Setup autocmds
  local autocmds = require('luxdash.events.autocmds')
  autocmds.setup()
end


--- Open the LuxDash dashboard
--- Creates and displays the floating window with dashboard content
function M.open()
    require('luxdash.core').open()
end

--- Toggle the LuxDash dashboard visibility
--- Opens the dashboard if closed, closes it if open
function M.toggle()
    local float_manager = require('luxdash.ui.float_manager')
    float_manager.toggle()
end

return M