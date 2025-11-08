# Changelog

All notable changes to nvim-luxdash will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### BREAKING CHANGES
- **Removed legacy configuration migration layer**
  - Deleted `lua/luxdash/config/migration.lua`
  - Removed automatic conversion of old config format
  - Users must use the new modular section configuration format
  - No longer supports `bottom_sections` array format
- **Removed legacy highlight groups**
  - Removed `LuxDashSectionTitle` (use `LuxDashSubTitle` or `LuxDashMainTitle`)
  - Removed `LuxDashSectionSeparator` (use `LuxDashSubSeparator` or `LuxDashMainSeparator`)
- **Removed deprecated text utilities**
  - Removed `truncate_filename()` from `utils/text.lua`
  - Use `truncate_path_smart()` or `truncate_with_ellipsis()` instead
- **Removed menu config string array support**
  - Menu items must be pre-processed objects, not string arrays
  - Use `require('luxdash.utils.menu').options()` to convert if needed

**Migration Guide:**
If upgrading from a previous version, you must:
1. Update configuration to use `sections.bottom` array format (see README)
2. Replace any custom highlight groups using old names
3. Update any direct usage of removed utility functions

### Added
- Comprehensive README with installation instructions, configuration examples, and troubleshooting
- Health check module (`:checkhealth luxdash`) for diagnosing common issues
  - Neovim version validation
  - Git availability check
  - Terminal capability detection (true color, size, Nerd Fonts)
  - Configuration validation
  - Plugin conflict detection
  - File system access verification
- Constants module (`lua/luxdash/constants.lua`) for centralized configuration
  - Eliminates magic numbers throughout codebase
  - Provides color presets for logo gradients
  - Defines highlight group names and namespaces
  - Documents all default values and their purposes

### Changed
- **SECURITY**: Fixed command injection vulnerability in recent files section
  - Now uses `vim.api.nvim_cmd()` instead of `vim.cmd()` for file opening
  - Prevents potential command injection through malicious filenames
- Refactored magic numbers to use constants module
  - `debouncer.lua` now uses `constants.DEBOUNCE.*` values
  - `width.lua` now uses `constants.CACHE.MAX_PADDING_SIZE`
  - `init.lua` now uses constants for default configuration values
- Improved error handling for file operations with user notifications

### Fixed
- Better error messages when file opening fails

### Documentation
- Created comprehensive README with:
  - Feature overview with emoji icons
  - Installation instructions for multiple plugin managers
  - Quick start guide
  - Complete keybinding reference
  - Configuration examples (basic, custom logo, custom sections)
  - Customization guide for highlight groups
  - Architecture overview
  - Advanced usage examples
  - Troubleshooting section
  - Contributing guidelines
- Added CHANGELOG to track project evolution

## [0.1.0] - 2025-01-XX (Estimated from git history)

### Added
- Floating window dashboard with customizable dimensions
- Modular section architecture
- Logo section with gradient color support
- Recent files section with 1-9 keybindings
- Git status section showing:
  - Branch name and remote tracking
  - Ahead/behind commits
  - File changes (added, modified, deleted)
  - Diff statistics (insertions/deletions)
  - Last commit message, author, and date
- Interactive menu with actions:
  - New file creation
  - Backtrack navigation
  - FZF integration
  - Close dashboard
- Multi-tier caching system:
  - Layout caching by window dimensions
  - Logo gradient caching
  - Section content caching
- Performance optimizations:
  - Pre-computed padding strings (0-200 characters)
  - Debounced resize handling (50ms)
  - Debounced window change tracking (25ms)
- Responsive layout system:
  - Configurable main/bottom section ratio
  - Equal width distribution for bottom sections
  - Automatic window size adaptation
- UTF-8 and wide character support
- Display width vs byte width handling
- Extensive icon support for file types

### Features by Commit

#### [26094e1] - Fix for floating windows over luxdash (#5)
- Fixed z-index and window stacking issues
- Improved float window positioning

#### [ffb5ce5] - Feature/git update (#4)
- Comprehensive git status display (504 additions)
- Added git branch, remote, file changes, diff stats
- Commit message, author, and date formatting
- Icon support for git elements
- Multiple highlight groups for visual distinction

#### [7311f5c] - Feature/recent file update (#3)
- Recent files section improvements
- File icon mapping by extension
- Smart filename truncation
- Numeric keybindings (1-9) for file opening
- Complex line format with multi-part highlights

#### [d7bf218] - Remove legacy implementations
- Code cleanup and refactoring
- Removed deprecated code paths

#### [39bcb27] - LuxDash - Dashboard Layout Optimization (#1)
- Initial major version with modular layout
- Three-tier layout system (main + bottom sections)
- Configurable section spacing and padding
- Horizontal section distribution

#### [182f0e3] - Dashboard modular alignment fixes
- Fixed alignment issues in modular sections
- Improved text centering

#### [068cf68] - Gradient highlighting for logo
- Implemented row-by-row gradient interpolation
- Color blending for smooth transitions
- Support for custom start/end colors

#### [0d0dbfe] - Content alignment fix and padding
- Fixed content alignment in sections
- Added configurable padding per section

## [Unreleased Features - Future Roadmap]

### Planned
- Async git operations to prevent UI blocking
- Configuration validation on setup
- Function documentation with LuaCATS annotations
- Unit test suite with plenary.nvim
- CI/CD pipeline with GitHub Actions
- Custom section registration API
- Session persistence for dashboard state
- Multiple fuzzy finder backend support (Telescope, FZF, fzf-lua)
- Bookmarks/pinned files section
- Interactive git branch switcher
- Project selector for quick navigation
- Debug mode with performance metrics
- Hot reload for configuration changes

### Under Consideration
- Multiple dashboard layouts (vertical, grid)
- Widget system for extensibility
- Theme/colorscheme integration
- Startup time optimization
- LSP status section
- Task/TODO integration
- Calendar/date section
- Fortune/quote section

---

## Version History Summary

| Version | Date | Key Features |
|---------|------|--------------|
| Unreleased | TBD | Health check, constants module, security fixes, comprehensive docs |
| 0.1.0 | 2025-01 | Initial release with floating dashboard, git integration, recent files |

---

**Note**: This project is under active development. Version numbers and dates will be formalized as releases are tagged.

## Migration Guide

### Upgrading from Pre-Breaking Change Version

**Important:** This version removes backwards compatibility. You must update your configuration.

**Old format (no longer supported):**
```lua
require('luxdash').setup({
  bottom_sections = { 'menu', 'recent_files', 'git_status' },
  section_configs = {
    menu = { title = 'Actions' }
  }
})
```

**New format (required):**
```lua
require('luxdash').setup({
  sections = {
    main = {
      type = 'logo',
      config = {}
    },
    bottom = {
      {
        id = 'actions',
        type = 'menu',
        title = '⚡ Actions',
        config = {
          menu_items = { 'newfile', 'backtrack', 'fzf', 'closelux' }
        }
      },
      {
        id = 'recent_files',
        type = 'recent_files',
        title = '📁 Recent Files',
        config = { max_files = 8 }
      },
      {
        id = 'git_status',
        type = 'git_status',
        title = '🌿 Git Status',
        config = {}
      }
    }
  }
})
```

See README.md for complete configuration examples.

---

For detailed commit history, see: https://github.com/LuxVim/nvim-luxdash/commits/main
