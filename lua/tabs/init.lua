--------------------------------------------- TABS.NVIM --------------------------------------------

local M = {}

---@class TabsNvimConfig
---@field default_name string default name for a new tabpage
---@field name_max_len integer maximum length (in characters) of a tabpage name
---@field allow_whitespace_in_name boolean whether whitespace is allowed in a tabpage name

---@class TabsNvimUserOpts
---@field default_name? string default name for a new tabpage
---@field name_max_len? integer maximum length (in characters) of a tabpage name
---@field allow_whitespace_in_name? boolean whether whitespace is allowed in a tabpage name

---set of default and currently active plugin configurations
---@type { active: TabsNvimConfig, default: TabsNvimConfig }
M.config = {
  active = {}, ---@diagnostic disable-line:missing-fields
  default = { default_name = 'newtab', name_max_len = 20, allow_whitespace_in_name = false },
}

---main plugin setup function
---@param opts TabsNvimUserOpts user configuration
function M.setup(opts) M.config.active = vim.tbl_deep_extend('force', M.config.default, opts) end

---rename current tabpage
---@param is_new_tab boolean is the current tabpage new or already existing
---@param new_name string (optional) new tabpage name
function M.set_name(is_new_tab, new_name)
  if is_new_tab then
    new_name = M.get_valid_name(M.config.active.default_name, 'New tabpage name: ')
  elseif new_name == '' or not M.is_valid_name(new_name) then
    new_name = M.get_valid_name(vim.t.tabs_nvim_name, 'Rename current tabpage: ')
  end

  vim.t.tabs_nvim_name = new_name
end

---@type string plugin related error message
M.message = ''

---checks if the given name is a valid tabpage name and returns error message
---@param name string tabpage name under validation
---@return boolean
function M.is_valid_name(name)
  if name == '' then
    M.message = '[tabs.nvim] Tabpage name should be non-empty.'
  elseif name:len() > M.config.active.name_max_len then
    M.message = ('[tabs.nvim] Tabpage name should not be longer than %d characters.'):format(
      M.config.active.name_max_len
    )
  elseif not M.config.active.allow_whitespace_in_name and name:find '%s' then
    M.message = '[tabs.nvim] Tabpage name should not contain whitespace.'
  else
    M.message = '' -- reset to default
    return true
  end

  return false
end

---get a (validated) tabpage name from the user
---@param current string existing tabpage name
---@param prompt string prompt message for user input
---@return string # validated tabpage name
function M.get_valid_name(current, prompt)
  local ret
  while not ret do
    -- display warning message (if any)
    vim.cmd 'redraw'
    -- TEST: dressing.nvim override of vim.ui functions
    vim.api.nvim_echo({ { M.message, 'Warn' } }, false, {})
    vim.ui.input({
      prompt = prompt,
      default = current,
      highlight = function(input)
        -- highlight characters beyond allowed length as an error
        if input:len() <= M.config.active.name_max_len then return {} end
        return { { M.config.active.name_max_len, input:len(), 'Error' } }
      end,
    }, function(input)
      if not input then
        ret = current
      elseif M.is_valid_name(input) then
        ret = input
      end
    end)
  end

  return ret
end

---statusline component displaying the tabpage names and current tabpage indicator
---@return string
-- PERF: implement either caching or debouncing for better performance
function M.status()
  local curr = vim.api.nvim_tabpage_get_number(0)
  local prev = vim.fn.tabpagenr '#'
  local ret = {}
  for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local name = vim.t[tabpage].tabs_nvim_name or ''
    local fmt = '  [%d] %s  '
    -- TODO: refactor highlight groups for user customization
    fmt = i == curr and '%%#TabLineSel# [%d] %s %%*' or fmt
    fmt = i == prev and '  [%d] %%#Underlined#%s%%*  ' or fmt
    table.insert(ret, fmt:format(i, name))
  end

  return table.concat(ret)
end

---save the current list of tabpage names to a global variable
function M.save_to_global()
  vim.g.TabsNvimNames = vim.json.encode(
    vim.tbl_map(function(v) return vim.t[v].tabs_nvim_name or '' end, vim.api.nvim_list_tabpages())
  )
end

---restore names for current tabpages from the saved global variable
function M.load_from_global()
  for tabpage, tabname in ipairs(vim.json.decode(vim.g.TabsNvimNames)) do
    vim.t[tabpage].tabs_nvim_name = tabname
  end
end

return M
