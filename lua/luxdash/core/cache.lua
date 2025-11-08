--- Multi-tier caching system for nvim-luxdash
--- Provides caching for layouts, logos, sections, and highlights
--- Uses a lazy invalidation strategy with dirty flags for performance
local M = {}

-- Cache keys for different content types
local CACHE_KEYS = {
  LAYOUT = 'layout',
  LOGO = 'logo',
  SECTIONS = 'sections',
  HIGHLIGHTS = 'highlights'
}

-- Global cache storage
local cache = {}

-- Cache invalidation flags
local cache_dirty = {}

--- Generate a cache key from type and additional parameters
--- @param cache_type string Type of cached content
--- @param ... any Additional parameters to include in key
--- @return string cache_key Composite cache key
function M.get_cache_key(cache_type, ...)
  local parts = {cache_type, ...}
  return table.concat(parts, '_')
end

--- Retrieve a value from cache
--- Automatically clears dirty cache entries before returning
--- @param cache_type string Type of cached content
--- @param ... any Additional parameters for cache key
--- @return any|nil cached_value The cached value or nil if not cached/dirty
function M.get(cache_type, ...)
  local key = M.get_cache_key(cache_type, ...)
  if cache_dirty[key] then
    cache[key] = nil
    cache_dirty[key] = nil
  end
  return cache[key]
end

--- Store a value in cache
--- Clears dirty flag for this cache key
--- @param cache_type string Type of cached content
--- @param value any Value to cache
--- @param ... any Additional parameters for cache key
--- @return any value The cached value (passed through for convenience)
function M.set(cache_type, value, ...)
  local key = M.get_cache_key(cache_type, ...)
  cache[key] = value
  cache_dirty[key] = nil
  return value
end

--- Mark a specific cache entry as dirty (to be cleared on next access)
--- @param cache_type string Type of cached content
--- @param ... any Additional parameters for cache key
function M.invalidate(cache_type, ...)
  local key = M.get_cache_key(cache_type, ...)
  cache_dirty[key] = true
end

--- Mark all cache entries as dirty
--- Called when configuration changes or window resizes
function M.invalidate_all()
  for key in pairs(cache) do
    cache_dirty[key] = true
  end
end

--- Completely clear the cache (remove all entries)
--- This is more aggressive than invalidate_all and frees memory
function M.clear()
  cache = {}
  cache_dirty = {}
end

-- Layout-specific caching
--- Get cached layout data
--- @param width number Window width
--- @param height number Window height
--- @param config_hash string Hash of configuration
--- @return table|nil layout_data Cached layout or nil
function M.get_layout(width, height, config_hash)
  return M.get(CACHE_KEYS.LAYOUT, width, height, config_hash)
end

--- Cache layout data
--- @param layout_data table Layout data to cache
--- @param width number Window width
--- @param height number Window height
--- @param config_hash string Hash of configuration
--- @return table layout_data The cached layout data
function M.set_layout(layout_data, width, height, config_hash)
  return M.set(CACHE_KEYS.LAYOUT, layout_data, width, height, config_hash)
end

--- Invalidate all layout cache entries
function M.invalidate_layout()
  M.invalidate(CACHE_KEYS.LAYOUT)
end

-- Logo-specific caching
--- Get cached processed logo
--- @param logo_hash string Hash of logo content
--- @param color_hash string Hash of color configuration
--- @param width number Window width
--- @return table|nil logo_lines Cached logo or nil
function M.get_logo(logo_hash, color_hash, width)
  return M.get(CACHE_KEYS.LOGO, logo_hash, color_hash, width)
end

--- Cache processed logo
--- @param processed_logo table Processed logo lines
--- @param logo_hash string Hash of logo content
--- @param color_hash string Hash of color configuration
--- @param width number Window width
--- @return table processed_logo The cached logo
function M.set_logo(processed_logo, logo_hash, color_hash, width)
  return M.set(CACHE_KEYS.LOGO, processed_logo, logo_hash, color_hash, width)
end

--- Invalidate all logo cache entries
function M.invalidate_logo()
  M.invalidate(CACHE_KEYS.LOGO)
end

-- Section-specific caching
--- Get cached section content
--- @param section_type string Type of section
--- @param config_hash string Hash of section configuration
--- @param width number Section width
--- @param height number Section height
--- @return table|nil section_content Cached content or nil
function M.get_section(section_type, config_hash, width, height)
  return M.get(CACHE_KEYS.SECTIONS, section_type, config_hash, width, height)
end

--- Cache section content
--- @param section_content table Section content to cache
--- @param section_type string Type of section
--- @param config_hash string Hash of section configuration
--- @param width number Section width
--- @param height number Section height
--- @return table section_content The cached content
function M.set_section(section_content, section_type, config_hash, width, height)
  return M.set(CACHE_KEYS.SECTIONS, section_content, section_type, config_hash, width, height)
end

--- Invalidate all section cache entries
function M.invalidate_sections()
  M.invalidate(CACHE_KEYS.SECTIONS)
end

-- Hash generation utilities
--- Generate a deterministic hash string from a table
--- Recursively traverses the table and creates a stable string representation
--- @param tbl table|any Table to hash (or any value)
--- @return string hash Hash string representation
function M.hash_table(tbl)
  if type(tbl) ~= 'table' then
    return tostring(tbl)
  end

  local parts = {}
  local function traverse(t, path)
    for k, v in pairs(t) do
      local key_path = path and (path .. '.' .. tostring(k)) or tostring(k)
      if type(v) == 'table' then
        traverse(v, key_path)
      else
        table.insert(parts, key_path .. '=' .. tostring(v))
      end
    end
  end

  traverse(tbl)
  table.sort(parts)
  return table.concat(parts, '|')
end

return M