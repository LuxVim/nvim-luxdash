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

function M.get_cache_key(cache_type, ...)
  local parts = {cache_type, ...}
  return table.concat(parts, '_')
end

function M.get(cache_type, ...)
  local key = M.get_cache_key(cache_type, ...)
  if cache_dirty[key] then
    cache[key] = nil
    cache_dirty[key] = nil
  end
  return cache[key]
end

function M.set(cache_type, value, ...)
  local key = M.get_cache_key(cache_type, ...)
  cache[key] = value
  cache_dirty[key] = nil
  return value
end

function M.invalidate(cache_type, ...)
  local key = M.get_cache_key(cache_type, ...)
  cache_dirty[key] = true
end

function M.invalidate_all()
  for key in pairs(cache) do
    cache_dirty[key] = true
  end
end

function M.clear()
  cache = {}
  cache_dirty = {}
end

-- Layout-specific caching
function M.get_layout(width, height, config_hash)
  return M.get(CACHE_KEYS.LAYOUT, width, height, config_hash)
end

function M.set_layout(layout_data, width, height, config_hash)
  return M.set(CACHE_KEYS.LAYOUT, layout_data, width, height, config_hash)
end

function M.invalidate_layout()
  M.invalidate(CACHE_KEYS.LAYOUT)
end

-- Logo-specific caching
function M.get_logo(logo_hash, color_hash, width)
  return M.get(CACHE_KEYS.LOGO, logo_hash, color_hash, width)
end

function M.set_logo(processed_logo, logo_hash, color_hash, width)
  return M.set(CACHE_KEYS.LOGO, processed_logo, logo_hash, color_hash, width)
end

function M.invalidate_logo()
  M.invalidate(CACHE_KEYS.LOGO)
end

-- Section-specific caching
function M.get_section(section_type, config_hash, width, height)
  return M.get(CACHE_KEYS.SECTIONS, section_type, config_hash, width, height)
end

function M.set_section(section_content, section_type, config_hash, width, height)
  return M.set(CACHE_KEYS.SECTIONS, section_content, section_type, config_hash, width, height)
end

function M.invalidate_sections()
  M.invalidate(CACHE_KEYS.SECTIONS)
end

-- Hash generation utilities
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