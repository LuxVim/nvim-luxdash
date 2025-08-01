local M = {}

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
    preset = 'blue',
    gradient = nil
  },
  -- Legacy options for menu section - kept for backward compatibility
  options = { 'newfile', 'backtrack', 'fzf', 'closelux' },
  extras = {},
  
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
        title = 'Actions',
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
          menu_items = nil, -- Will use options/extras for backward compatibility
          extras = nil
        }
      },
      {
        id = 'recent_files',
        type = 'recent_files',
        title = '󰋚 Recent Files',
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
          max_files = 10
        }
      },
      {
        id = 'git_status',
        type = 'git_status',
        title = '󰊢 Git Status',
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
    main_height_ratio = 0.8, -- Main section takes 80% of height
    bottom_sections_equal_width = true, -- Equal width for bottom sections
    section_spacing = 4 -- Total spacing between sections
  },
  
  -- Legacy configs - kept for backward compatibility
  section_configs = {},
  alignment = {
    logo = { horizontal = 'center', vertical = 'center' },
    menu = { horizontal = 'center', vertical = 'center' }
  },
  float = {
    width = 0.9,
    height = 0.9,
    border = 'rounded',
    title = ' LuxDash ',
    title_pos = 'center',
    hide_buffer = false
  },
  padding = {
    left = 2,
    right = 2,
    top = 1,
    bottom = 1
  }
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Migrate legacy configuration to new format if needed
  local migration = require('luxdash.config.migration')
  M.config = migration.migrate_legacy_config(M.config)
  
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


function M.open()
    require('luxdash.core').open()
end

function M.toggle()
    local float_manager = require('luxdash.ui.float_manager')
    float_manager.toggle()
end

return M