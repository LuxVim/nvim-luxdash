local M = {}
local width_utils = require('luxdash.utils.width')
local highlight_pool = require('luxdash.core.highlight_pool')

-- Reusable objects to reduce memory allocation
local temp_highlights = {}
local temp_parts = {}

function M.process_logo_line(line)
  local highlight_group = line[1][1]
  local content_text = line[2][2] or ''
  local winwidth = vim.api.nvim_win_get_width(0)
  
  local content_display_width = vim.fn.strdisplaywidth(content_text)
  local full_width_text
  
  if content_display_width > winwidth then
    full_width_text = M.trim_content_to_width(content_text, winwidth)
  else
    full_width_text = M.center_content_in_width(content_text, winwidth)
  end
  
  return full_width_text, {{
    start_col = 0,
    end_col = winwidth,
    hl_group = highlight_group
  }}
end

function M.trim_content_to_width(content_text, width)
  return width_utils.trim_text_for_logo(content_text, width)
end

function M.center_content_in_width(content_text, width)
  return width_utils.center_text_for_logo(content_text, width)
end

function M.combine_line_parts(parts)
  local combined_text = ''
  
  -- Clear and reuse highlights table to reduce allocation
  for i = #temp_highlights, 1, -1 do
    temp_highlights[i] = nil
  end
  
  local col_offset = 0
  
  for _, part in ipairs(parts) do
    if type(part) == 'table' then
      if #part >= 2 and type(part[1]) == 'string' then
        -- Simple format: {highlight, text}
        local part_text = tostring(part[2] or '')
        local part_hl = part[1]
        
        combined_text = combined_text .. part_text
        
        if part_hl and type(part_hl) == 'string' then
          local text_byte_len = vim.fn.strlen(part_text)
          table.insert(temp_highlights, {
            hl_group = part_hl,
            start_col = col_offset,
            end_col = col_offset + text_byte_len
          })
          col_offset = col_offset + text_byte_len
        else
          col_offset = col_offset + vim.fn.strlen(part_text)
        end
      elseif #part > 0 and type(part[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        for _, subpart in ipairs(part) do
          if type(subpart) == 'table' and #subpart >= 2 then
            local subpart_text = tostring(subpart[2] or '')
            local subpart_hl = subpart[1]
            
            combined_text = combined_text .. subpart_text
            
            if subpart_hl and type(subpart_hl) == 'string' then
              local text_byte_len = vim.fn.strlen(subpart_text)
              table.insert(temp_highlights, {
                hl_group = subpart_hl,
                start_col = col_offset,
                end_col = col_offset + text_byte_len
              })
              col_offset = col_offset + text_byte_len
            else
              col_offset = col_offset + vim.fn.strlen(subpart_text)
            end
          end
        end
      end
    else
      -- Plain text
      local part_text = tostring(part)
      combined_text = combined_text .. part_text
      col_offset = col_offset + vim.fn.strlen(part_text)
    end
  end
  
  if #temp_highlights > 0 then
    -- Return a copy of highlights to avoid mutation
    local highlights_copy = {}
    for i, hl in ipairs(temp_highlights) do
      highlights_copy[i] = hl
    end
    return {combined_text, highlights_copy}
  else
    return combined_text
  end
end

function M.process_line_for_rendering(line, pad_left)
  if type(line) == 'table' then
    -- Check if it's a complex multi-highlight structure
    if #line > 0 and type(line[1]) == 'table' then
      -- Check if this is a full-row highlight line (3 parts: left padding, content, right padding)
      if #line == 3 and 
         type(line[1]) == 'table' and type(line[2]) == 'table' and type(line[3]) == 'table' and
         line[1][2] == '' and line[3][2] == '' and 
         line[1][1] and line[1][1]:match('^LuxDashLogo') then
        
        return M.process_logo_line(line)
      else
        -- Regular complex format: {{highlight, text}, {highlight, text}, ...}
        local combined = M.combine_line_parts({line})
        local text = combined[1] or combined
        local highlights = type(combined) == 'table' and combined[2] or {}
        local padded_text = width_utils.get_padding(pad_left) .. text
        
        local processed_highlights = {}
        if type(highlights) == 'table' then
          for _, hl in ipairs(highlights) do
            if hl.hl_group and type(hl.hl_group) == 'string' then
              local adjusted_end_col = pad_left + hl.end_col
              
              -- For logo highlights, create full-width highlight and text
              if hl.hl_group:match('^LuxDashLogo') then
                local winwidth = vim.api.nvim_win_get_width(0)
                
                -- For logo lines in complex format, we need to recreate the full line
                -- Extract the text content from the combined line
                local text_content = combined[1] or combined
                local content_display_width = vim.fn.strdisplaywidth(text_content)
                local total_padding_needed = winwidth - content_display_width
                local left_pad_size = math.max(0, math.floor(total_padding_needed / 2))
                local right_pad_size = math.max(0, total_padding_needed - left_pad_size)
                
                -- Create full-width text
                local left_spaces = width_utils.get_padding(left_pad_size)
                local right_spaces = width_utils.get_padding(right_pad_size)
                padded_text = left_spaces .. text_content .. right_spaces
                
                -- Ensure exact window width
                local current_width = vim.fn.strwidth(padded_text)
                if current_width < winwidth then
                  padded_text = padded_text .. width_utils.get_padding(winwidth - current_width)
                elseif current_width > winwidth then
                  padded_text = padded_text:sub(1, winwidth)
                end
                
                -- Highlight spans the entire row
                adjusted_end_col = winwidth
              end
              
              -- For logo highlights, start from column 0 for full-row highlighting
              local start_col = hl.hl_group:match('^LuxDashLogo') and 0 or (pad_left + hl.start_col)
              
              table.insert(processed_highlights, {
                start_col = start_col,
                end_col = adjusted_end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
        
        return padded_text, processed_highlights
      end
    elseif line[2] then
      -- Detect format: {highlight, text} vs {text, highlights}
      local text, highlight_group, processed_highlights
      if type(line[1]) == 'string' and type(line[2]) == 'string' then
        -- Format: {highlight, text}
        highlight_group = line[1]
        text = line[2]
      else
        -- Format: {text, highlights}
        text = line[1]
        local highlights = line[2]
        if type(highlights) == 'table' then
          processed_highlights = {}
          for _, hl in ipairs(highlights) do
            if hl.hl_group and type(hl.hl_group) == 'string' then
              local adjusted_end_col = pad_left + hl.end_col
              table.insert(processed_highlights, {
                start_col = pad_left + hl.start_col,
                end_col = adjusted_end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
      end
      
      local padded_text = width_utils.get_padding(pad_left) .. tostring(text)
      
      -- For logo highlights in processed_highlights, extend to cover full width
      if processed_highlights then
        for _, hl in ipairs(processed_highlights) do
          if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
            local winwidth = vim.api.nvim_win_get_width(0)
            
            -- For logo highlights, recreate the padded_text to span full width
            local original_text = tostring(text)
            local winwidth = vim.api.nvim_win_get_width(0)
            local content_display_width = vim.fn.strdisplaywidth(original_text)
            local total_padding_needed = winwidth - content_display_width
            local left_pad_size = math.max(0, math.floor(total_padding_needed / 2))
            local right_pad_size = math.max(0, total_padding_needed - left_pad_size)
            
            -- Create full-width text
            local left_spaces = width_utils.get_padding(left_pad_size)
            local right_spaces = width_utils.get_padding(right_pad_size)
            padded_text = left_spaces .. original_text .. right_spaces
            
            -- Ensure exact window width
            local current_width = vim.fn.strwidth(padded_text)
            if current_width < winwidth then
              padded_text = padded_text .. width_utils.get_padding(winwidth - current_width)
            elseif current_width > winwidth then
              padded_text = padded_text:sub(1, winwidth)
            end
            
            -- Highlight spans the entire row
            hl.end_col = winwidth
            hl.start_col = 0  -- Start from beginning of line for full-width highlighting
          end
        end
      end
      
      if highlight_group and type(highlight_group) == 'string' then
        local text_width = vim.fn.strwidth(tostring(text))
        local end_col = pad_left + text_width
        
        -- For logo highlights, create full-width highlight and text
        if highlight_group:match('^LuxDashLogo') then
          local winwidth = vim.api.nvim_win_get_width(0)
          
          -- STEP 1: First determine highlight range (always full window width for logo)
          local highlight_start = 0
          local highlight_end = winwidth
          
          -- STEP 2: Then create content to match the highlight range
          local content_text = tostring(text)
          local content_display_width = vim.fn.strdisplaywidth(content_text)
          
          if content_display_width > highlight_end then
            -- Content is wider than highlight range - center by trimming
            local excess_chars = content_display_width - highlight_end
            local trim_left = math.floor(excess_chars / 2)
            
            -- Simple string trimming for ASCII content
            local trimmed_text = content_text:sub(trim_left + 1)
            if #trimmed_text > highlight_end then
              trimmed_text = trimmed_text:sub(1, highlight_end)
            end
            
            padded_text = trimmed_text
            -- Pad to exact highlight width
            local current_width = vim.fn.strwidth(padded_text)
            if current_width < highlight_end then
              padded_text = padded_text .. width_utils.get_padding(highlight_end - current_width)
            end
          else
            -- Content fits within highlight range - center with padding
            local total_padding_needed = highlight_end - content_display_width
            local left_pad_size = math.max(0, math.floor(total_padding_needed / 2))
            local right_pad_size = math.max(0, total_padding_needed - left_pad_size)
            
            local left_spaces = width_utils.get_padding(left_pad_size)
            local right_spaces = width_utils.get_padding(right_pad_size)
            padded_text = left_spaces .. content_text .. right_spaces
            
            -- Ensure exact highlight width
            local current_width = vim.fn.strwidth(padded_text)
            if current_width < highlight_end then
              padded_text = padded_text .. width_utils.get_padding(highlight_end - current_width)
            elseif current_width > highlight_end then
              padded_text = padded_text:sub(1, highlight_end)
            end
          end
          
          -- STEP 3: Set highlight to match the content we created
          end_col = highlight_end
        end
        
        -- For logo highlights, start from column 0 for full-row highlighting
        local start_col = highlight_group:match('^LuxDashLogo') and 0 or pad_left
        
        processed_highlights = {{
          start_col = start_col,
          end_col = end_col,
          hl_group = highlight_group
        }}
      end
      
      return padded_text, processed_highlights or {}
    else
      -- Fallback to string representation
      local line_text = tostring(line)
      return width_utils.get_padding(pad_left) .. line_text, {}
    end
  else
    local line_text = tostring(line or '')
    return width_utils.get_padding(pad_left) .. line_text, {}
  end
end

function M.ensure_logo_line_coverage(lines, line_idx, line_text)
  local actual_winwidth = vim.api.nvim_win_get_width(0)
  local line_byte_length = vim.fn.strlen(line_text)
  local line_display_width = vim.fn.strdisplaywidth(line_text)
  
  if line_display_width < actual_winwidth then
    local padding_needed = actual_winwidth - line_display_width
    lines[line_idx + 1] = lines[line_idx + 1] .. width_utils.get_padding(padding_needed)
    line_byte_length = vim.fn.strlen(lines[line_idx + 1])
  end
  
  return line_byte_length
end

function M.apply_highlights(highlights, lines)
  -- Use consolidated highlight pool instead of custom logic
  highlight_pool.batch_apply_highlights(highlights, lines)
end

return M