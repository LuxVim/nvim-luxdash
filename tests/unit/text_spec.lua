-- Unit tests for utils/text.lua
local helpers = require('tests.helpers')

-- Setup plugin
helpers.setup_plugin()

local text_utils = require('luxdash.utils.text')

describe('text_utils', function()
  describe('get_padding', function()
    it('returns empty string for zero size', function()
      assert.equals('', text_utils.get_padding(0))
    end)

    it('returns correct padding for small sizes', function()
      assert.equals('   ', text_utils.get_padding(3))
      assert.equals('          ', text_utils.get_padding(10))
    end)

    it('returns correct padding for large sizes', function()
      local padding = text_utils.get_padding(250)
      assert.equals(250, #padding)
    end)
  end)

  describe('get_display_width', function()
    it('returns correct width for ASCII text', function()
      assert.equals(5, text_utils.get_display_width('hello'))
    end)

    it('handles empty strings', function()
      assert.equals(0, text_utils.get_display_width(''))
    end)

    it('converts numbers to strings', function()
      assert.equals(3, text_utils.get_display_width(123))
    end)
  end)

  describe('truncate', function()
    it('does not truncate text that fits', function()
      assert.equals('hello', text_utils.truncate('hello', 10))
    end)

    it('truncates text that exceeds width', function()
      local result = text_utils.truncate('hello world', 8)
      assert.equals('hello...', result)
    end)

    it('uses custom suffix', function()
      local result = text_utils.truncate('hello world', 8, { suffix = '~' })
      assert.equals('hello w~', result)
    end)

    it('handles very small widths', function()
      local result = text_utils.truncate('hello', 2)
      assert.equals('..', result)
    end)

    it('preserves basename for file paths', function()
      local result = text_utils.truncate('path/to/long/filename.lua', 15, {
        preserve_basename = true
      })
      assert.equals('...filename.lua', result)
    end)
  end)

  describe('pad_left', function()
    it('pads text on the left', function()
      assert.equals('     hello', text_utils.pad_left('hello', 10))
    end)

    it('does not pad if text is already wide enough', function()
      assert.equals('hello world', text_utils.pad_left('hello world', 5))
    end)

    it('uses custom padding character', function()
      assert.equals('*****hello', text_utils.pad_left('hello', 10, '*'))
    end)
  end)

  describe('pad_right', function()
    it('pads text on the right', function()
      assert.equals('hello     ', text_utils.pad_right('hello', 10))
    end)

    it('does not pad if text is already wide enough', function()
      assert.equals('hello world', text_utils.pad_right('hello world', 5))
    end)
  end)

  describe('pad_center', function()
    it('centers text with equal padding', function()
      local result = text_utils.pad_center('hi', 6)
      assert.equals('  hi  ', result)
    end)

    it('handles odd padding', function()
      local result = text_utils.pad_center('hi', 7)
      -- Left gets floor, right gets remainder
      assert.equals('  hi   ', result)
    end)
  end)

  describe('align', function()
    it('centers text by default', function()
      local result = text_utils.align('test', 10)
      assert.equals('   test   ', result)
    end)

    it('aligns left', function()
      local result = text_utils.align('test', 10, 'left')
      assert.equals('test      ', result)
    end)

    it('aligns right', function()
      local result = text_utils.align('test', 10, 'right')
      assert.equals('      test', result)
    end)

    it('truncates text that exceeds width', function()
      local result = text_utils.align('hello world', 8, 'left')
      assert.equals('hello...', result)
    end)
  end)

  describe('ensure_width', function()
    it('pads text to exact width', function()
      local result = text_utils.ensure_width('hi', 5)
      assert.equals(5, #result)
    end)

    it('truncates text to exact width', function()
      local result = text_utils.ensure_width('hello world', 5)
      assert.equals(5, #result)
    end)

    it('leaves text unchanged if already exact width', function()
      local result = text_utils.ensure_width('hello', 5)
      assert.equals('hello', result)
    end)
  end)

  describe('title_case', function()
    it('converts words to title case', function()
      assert.equals('Hello World', text_utils.title_case('hello world'))
      assert.equals('Test Case', text_utils.title_case('test case'))
    end)

    it('handles single words', function()
      assert.equals('Hello', text_utils.title_case('hello'))
    end)
  end)
end)
