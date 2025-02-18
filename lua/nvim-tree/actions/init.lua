local a = vim.api

local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local util = require "nvim-tree.utils"

-- BEGIN_DEFAULT_MAPPINGS
local DEFAULT_MAPPINGS = {
  {
    key = { "<CR>", "o", "<2-LeftMouse>" },
    action = "edit",
    desc = "open a file or folder; root will cd to the above directory",
  },
  {
    key = "<C-e>",
    action = "edit_in_place",
    desc = "edit the file in place, effectively replacing the tree explorer",
  },
  {
    key = "O",
    action = "edit_no_picker",
    desc = "same as (edit) with no window picker",
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    action = "cd",
    desc = "cd in the directory under the cursor",
  },
  {
    key = "<C-v>",
    action = "vsplit",
    desc = "open the file in a vertical split",
  },
  {
    key = "<C-x>",
    action = "split",
    desc = "open the file in a horizontal split",
  },
  {
    key = "<C-t>",
    action = "tabnew",
    desc = "open the file in a new tab",
  },
  {
    key = "<",
    action = "prev_sibling",
    desc = "navigate to the previous sibling of current file/directory",
  },
  {
    key = ">",
    action = "next_sibling",
    desc = "navigate to the next sibling of current file/directory",
  },
  {
    key = "P",
    action = "parent_node",
    desc = "move cursor to the parent directory",
  },
  {
    key = "<BS>",
    action = "close_node",
    desc = "close current opened directory or parent",
  },
  {
    key = "<Tab>",
    action = "preview",
    desc = "open the file as a preview (keeps the cursor in the tree)",
  },
  {
    key = "K",
    action = "first_sibling",
    desc = "navigate to the first sibling of current file/directory",
  },
  {
    key = "J",
    action = "last_sibling",
    desc = "navigate to the last sibling of current file/directory",
  },
  {
    key = "I",
    action = "toggle_git_ignored",
    desc = "toggle visibility of files/folders hidden via |git.ignore| option",
  },
  {
    key = "H",
    action = "toggle_dotfiles",
    desc = "toggle visibility of dotfiles via |filters.dotfiles| option",
  },
  {
    key = "U",
    action = "toggle_custom",
    desc = "toggle visibility of files/folders hidden via |filters.custom| option",
  },
  {
    key = "R",
    action = "refresh",
    desc = "refresh the tree",
  },
  {
    key = "a",
    action = "create",
    desc = "add a file; leaving a trailing `/` will add a directory",
  },
  {
    key = "d",
    action = "remove",
    desc = "delete a file (will prompt for confirmation)",
  },
  {
    key = "D",
    action = "trash",
    desc = "trash a file via |trash| option",
  },
  {
    key = "r",
    action = "rename",
    desc = "rename a file",
  },
  {
    key = "<C-r>",
    action = "full_rename",
    desc = "rename a file and omit the filename on input",
  },
  {
    key = "x",
    action = "cut",
    desc = "add/remove file/directory to cut clipboard",
  },
  {
    key = "c",
    action = "copy",
    desc = "add/remove file/directory to copy clipboard",
  },
  {
    key = "p",
    action = "paste",
    desc = "paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation",
  },
  {
    key = "y",
    action = "copy_name",
    desc = "copy name to system clipboard",
  },
  {
    key = "Y",
    action = "copy_path",
    desc = "copy relative path to system clipboard",
  },
  {
    key = "gy",
    action = "copy_absolute_path",
    desc = "copy absolute path to system clipboard",
  },
  {
    key = "[e",
    action = "prev_diag_item",
    desc = "go to next diagnostic item",
  },
  {
    key = "[c",
    action = "prev_git_item",
    desc = "go to next git item",
  },
  {
    key = "]e",
    action = "next_diag_item",
    desc = "go to prev diagnostic item",
  },
  {
    key = "]c",
    action = "next_git_item",
    desc = "go to prev git item",
  },
  {
    key = "-",
    action = "dir_up",
    desc = "navigate up to the parent directory of the current file/directory",
  },
  {
    key = "s",
    action = "system_open",
    desc = "open a file with default system application or a folder with default file manager, using |system_open| option",
  },
  {
    key = "f",
    action = "live_filter",
    desc = "live filter nodes dynamically based on regex matching.",
  },
  {
    key = "F",
    action = "clear_live_filter",
    desc = "clear live filter",
  },
  {
    key = "q",
    action = "close",
    desc = "close tree window",
  },
  {
    key = "W",
    action = "collapse_all",
    desc = "collapse the whole tree",
  },
  {
    key = "E",
    action = "expand_all",
    desc = "expand the whole tree, stopping after expanding |actions.expand_all.max_folder_discovery| folders; this might hang neovim for a while if running on a big folder",
  },
  {
    key = "S",
    action = "search_node",
    desc = "prompt the user to enter a path and then expands the tree to match the path",
  },
  {
    key = ".",
    action = "run_file_command",
    desc = "enter vim command mode with the file the cursor is on",
  },
  {
    key = "<C-k>",
    action = "toggle_file_info",
    desc = "toggle a popup with file infos about the file under the cursor",
  },
  {
    key = "g?",
    action = "toggle_help",
    desc = "toggle help",
  },
  {
    key = "m",
    action = "toggle_mark",
    desc = "Toggle node in bookmarks",
  },
  {
    key = "bmv",
    action = "bulk_move",
    desc = "Move all bookmarked nodes into specified location",
  },
}
-- END_DEFAULT_MAPPINGS

local M = {
  mappings = {},
  custom_keypress_funcs = {},
}

local function set_map_for(bufnr)
  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }
  return function(mode, rhs)
    return function(lhs)
      vim.keymap.set(mode or "n", lhs, rhs, opts)
    end
  end
end

local function run_dispatch(action)
  return function()
    require("nvim-tree.actions.dispatch").dispatch(action)
  end
end

function M.apply_mappings(bufnr)
  local setter_for = set_map_for(bufnr)
  for _, b in pairs(M.mappings) do
    local rhs = b.cb or run_dispatch(b.action)
    if rhs then
      local setter = setter_for(b.mode, rhs)

      local keys = type(b.key) == "table" and b.key or { b.key }
      for _, key in pairs(keys) do
        setter(key)
      end
    end
  end
end

local function merge_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.mappings
  end

  local function is_empty(s)
    return s == ""
  end

  local user_keys = {}
  local removed_keys = {}
  -- remove default mappings if action is a empty string
  for _, map in pairs(user_mappings) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        table.insert(user_keys, key)
        if is_empty(map.action) then
          table.insert(removed_keys, key)
        end
      end
    else
      table.insert(user_keys, map.key)
      if is_empty(map.action) then
        table.insert(removed_keys, map.key)
      end
    end

    if map.action and type(map.action_cb) == "function" then
      if not is_empty(map.action) then
        M.custom_keypress_funcs[map.action] = map.action_cb
      else
        util.notify.warn "action can't be empty if action_cb provided"
      end
    end
  end

  local default_map = vim.tbl_filter(function(map)
    if type(map.key) == "table" then
      local filtered_keys = {}
      for _, key in pairs(map.key) do
        if not vim.tbl_contains(user_keys, key) and not vim.tbl_contains(removed_keys, key) then
          table.insert(filtered_keys, key)
        end
      end
      map.key = filtered_keys
      return not vim.tbl_isempty(map.key)
    else
      return not vim.tbl_contains(user_keys, map.key) and not vim.tbl_contains(removed_keys, map.key)
    end
  end, M.mappings)

  local user_map = vim.tbl_filter(function(map)
    return not is_empty(map.action)
  end, user_mappings)

  return vim.fn.extend(default_map, user_map)
end

local function copy_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.mappings
  end

  for _, map in pairs(user_mappings) do
    if map.action and type(map.action_cb) == "function" then
      M.custom_keypress_funcs[map.action] = map.action_cb
    end
  end

  return user_mappings
end

local function cleanup_existing_mappings()
  local bufnr = view.get_bufnr()
  if bufnr == nil or not a.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, b in pairs(M.mappings) do
    local keys = type(b.key) == "table" and b.key or { b.key }
    for _, key in pairs(keys) do
      vim.keymap.del(b.mode or "n", key, { buffer = bufnr })
    end
  end
end

local DEFAULT_MAPPING_CONFIG = {
  custom_only = false,
  list = {},
}

function M.setup(opts)
  require("nvim-tree.actions.fs.trash").setup(opts)
  require("nvim-tree.actions.node.system-open").setup(opts)
  require("nvim-tree.actions.node.open-file").setup(opts)
  require("nvim-tree.actions.root.change-dir").setup(opts)
  require("nvim-tree.actions.fs.create-file").setup(opts)
  require("nvim-tree.actions.fs.rename-file").setup(opts)
  require("nvim-tree.actions.fs.remove-file").setup(opts)
  require("nvim-tree.actions.fs.copy-paste").setup(opts)
  require("nvim-tree.actions.tree-modifiers.expand-all").setup(opts)

  cleanup_existing_mappings()
  M.mappings = vim.deepcopy(DEFAULT_MAPPINGS)

  local user_map_config = (opts.view or {}).mappings or {}
  local options = vim.tbl_deep_extend("force", DEFAULT_MAPPING_CONFIG, user_map_config)
  if options.custom_only then
    M.mappings = copy_mappings(options.list)
  else
    M.mappings = merge_mappings(options.list)
  end

  require("nvim-tree.actions.dispatch").setup(M.custom_keypress_funcs)

  log.line("config", "active mappings")
  log.raw("config", "%s\n", vim.inspect(M.mappings))
end

return M
