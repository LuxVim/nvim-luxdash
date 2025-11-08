--- Health check module for nvim-luxdash
--- Provides diagnostic information to help users troubleshoot issues
--- Run with :checkhealth luxdash
local M = {}

local constants = require('luxdash.constants')

--- Main health check function called by Neovim's health system
function M.check()
  -- Use vim.health if available (Neovim 0.10+), otherwise use older API
  local health = vim.health or require('health')

  health.start('nvim-luxdash')

  -- Check Neovim version
  M.check_neovim_version(health)

  -- Check dependencies
  M.check_git(health)

  -- Check terminal capabilities
  M.check_terminal(health)

  -- Check configuration
  M.check_config(health)

  -- Check file system
  M.check_filesystem(health)
end

--- Check if Neovim version meets minimum requirements
function M.check_neovim_version(health)
  health.start('Neovim Version')

  local version = vim.version()
  local required = constants.MIN_NEOVIM_VERSION

  local meets_requirement = (
    version.major > required.MAJOR or
    (version.major == required.MAJOR and version.minor >= required.MINOR)
  )

  if meets_requirement then
    health.ok(string.format(
      'Neovim %d.%d.%d (required: %d.%d.%d)',
      version.major, version.minor, version.patch,
      required.MAJOR, required.MINOR, required.PATCH
    ))
  else
    health.error(
      string.format(
        'Neovim %d.%d.%d is too old',
        version.major, version.minor, version.patch
      ),
      {
        string.format(
          'Upgrade to Neovim %d.%d.%d or newer',
          required.MAJOR, required.MINOR, required.PATCH
        )
      }
    )
  end
end

--- Check git availability for git status section
function M.check_git(health)
  health.start('Git Integration')

  if vim.fn.executable('git') == 1 then
    -- Git is available, check version
    local git_version = vim.fn.system('git --version')
    if vim.v.shell_error == 0 then
      git_version = vim.trim(git_version)
      health.ok('git executable found: ' .. git_version)

      -- Check if we're in a git repository
      local git_dir = vim.fn.system('git rev-parse --git-dir 2>/dev/null')
      if vim.v.shell_error == 0 then
        health.ok('Current directory is a git repository')
      else
        health.info('Not in a git repository (git status section will show "Not a git repo")')
      end
    else
      health.warn('git found but unable to get version')
    end
  else
    health.warn(
      'git executable not found',
      {
        'Git status section will not work',
        'Install git to enable repository information display',
        'On most systems: sudo apt install git (Debian/Ubuntu) or brew install git (macOS)'
      }
    )
  end
end

--- Check terminal capabilities
function M.check_terminal(health)
  health.start('Terminal Capabilities')

  -- Check for true color support
  if vim.fn.has('termguicolors') == 1 and vim.o.termguicolors then
    health.ok('True color (24-bit) support enabled')
  else
    health.warn(
      'True color support not enabled',
      {
        'Logo gradients may not display correctly',
        'Add "set termguicolors" to your config',
        'Or call vim.o.termguicolors = true in init.lua'
      }
    )
  end

  -- Check terminal size
  local ui = vim.api.nvim_list_uis()[1]
  if ui then
    local min_width = 80
    local min_height = 24

    if ui.width >= min_width and ui.height >= min_height then
      health.ok(string.format('Terminal size: %dx%d (adequate)', ui.width, ui.height))
    else
      health.warn(
        string.format('Terminal size: %dx%d (small)', ui.width, ui.height),
        {
          string.format('Recommended minimum: %dx%d', min_width, min_height),
          'Dashboard may not display correctly in small terminals',
          'Resize your terminal for best experience'
        }
      )
    end
  else
    health.warn('No UI detected (running headless?)')
  end

  -- Check for Nerd Font (icons)
  local has_nerd_font = vim.g.have_nerd_font or false
  if has_nerd_font then
    health.ok('Nerd Font support detected (icons will display)')
  else
    health.info(
      'Nerd Font not detected',
      {
        'Icons may not display correctly',
        'Install a Nerd Font: https://www.nerdfonts.com/',
        'Set vim.g.have_nerd_font = true in your config if you have one installed'
      }
    )
  end
end

--- Check configuration validity
function M.check_config(health)
  health.start('Configuration')

  local ok, luxdash = pcall(require, 'luxdash')
  if not ok then
    health.error('Unable to load luxdash module')
    return
  end

  local config = luxdash.config

  -- Check float configuration
  if config.float then
    if config.float.width and type(config.float.width) == 'number' then
      if config.float.width > 0 and config.float.width <= 1 then
        health.ok(string.format('Float width: %.0f%% of screen', config.float.width * 100))
      elseif config.float.width > 1 and config.float.width < 1000 then
        health.ok(string.format('Float width: %d characters (absolute)', config.float.width))
      else
        health.warn('Float width value seems unusual: ' .. config.float.width)
      end
    end

    if config.float.height and type(config.float.height) == 'number' then
      if config.float.height > 0 and config.float.height <= 1 then
        health.ok(string.format('Float height: %.0f%% of screen', config.float.height * 100))
      elseif config.float.height > 1 and config.float.height < 1000 then
        health.ok(string.format('Float height: %d characters (absolute)', config.float.height))
      else
        health.warn('Float height value seems unusual: ' .. config.float.height)
      end
    end
  end

  -- Check sections configuration
  if config.sections then
    local section_count = 0
    if config.sections.main then
      section_count = section_count + 1
    end
    if config.sections.bottom and type(config.sections.bottom) == 'table' then
      section_count = section_count + #config.sections.bottom
    end

    health.ok(string.format('Configured sections: %d', section_count))
  else
    health.warn('No sections configured')
  end

  -- Check for conflicting plugins
  M.check_plugin_conflicts(health)
end

--- Check for conflicting dashboard plugins
function M.check_plugin_conflicts(health)
  local conflicting_plugins = {
    'alpha',
    'dashboard',
    'startup'
  }

  local conflicts = {}
  for _, plugin in ipairs(conflicting_plugins) do
    if pcall(require, plugin) then
      table.insert(conflicts, plugin)
    end
  end

  if #conflicts > 0 then
    health.warn(
      'Other dashboard plugins detected: ' .. table.concat(conflicts, ', '),
      {
        'Multiple dashboard plugins may conflict',
        'Consider disabling other dashboards to avoid issues'
      }
    )
  else
    health.ok('No conflicting dashboard plugins detected')
  end
end

--- Check filesystem access for recent files
function M.check_filesystem(health)
  health.start('File System')

  -- Check oldfiles availability
  local oldfiles = vim.v.oldfiles or {}
  if #oldfiles > 0 then
    health.ok(string.format('Recent files available: %d total', #oldfiles))

    -- Check how many are readable from current directory
    local cwd = vim.fn.getcwd()
    local cwd_files = 0
    for _, file in ipairs(oldfiles) do
      if vim.startswith(file, cwd) and vim.fn.filereadable(file) == 1 then
        cwd_files = cwd_files + 1
      end
    end

    if cwd_files > 0 then
      health.ok(string.format('Recent files in current directory: %d', cwd_files))
    else
      health.info('No recent files in current directory (recent files section will be empty)')
    end
  else
    health.info('No recent files yet (open some files to populate the list)')
  end

  -- Check cache directory
  local cache_dir = vim.fn.stdpath('cache') .. '/luxdash'
  if vim.fn.isdirectory(cache_dir) == 1 then
    health.ok('Cache directory exists: ' .. cache_dir)
  else
    health.info('Cache directory will be created on first use')
  end
end

return M
