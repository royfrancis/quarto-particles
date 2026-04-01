--- @module config
--- Configuration merge and shortcode override helpers.

local utils = require("pandoc.utils")
local codec = require(quarto.utils.resolve_path("_modules/codec.lua"):gsub("%.lua$", ""))

--- Deep-clone a table.
--- @param source table
--- @return table
local function clone_table(source)
  local result = {}
  for key, value in pairs(source) do
    if type(value) == "table" then
      result[key] = clone_table(value)
    else
      result[key] = value
    end
  end
  return result
end

--- Detect whether a table behaves like an array.
--- @param tbl table
--- @return boolean
local function is_array(tbl)
  local count = 0
  for key, _ in pairs(tbl) do
    if type(key) ~= "number" then
      return false
    end
    count = count + 1
  end
  return count == #tbl
end

--- Merge an override table into a base table in-place.
--- Arrays are replaced, object-like tables are recursively merged.
--- @param base table
--- @param override table
local function merge_tables(base, override)
  for key, value in pairs(override) do
    if type(value) == "table" and type(base[key]) == "table" and not is_array(value) and not is_array(base[key]) then
      merge_tables(base[key], value)
    else
      base[key] = value
    end
  end
end

--- Split a dotted key (for example: a.b.c) into path segments.
--- @param key string
--- @return table
local function split_key(key)
  local parts = {}
  for part in key:gmatch("[^%.]+") do
    parts[#parts + 1] = part
  end
  return parts
end

--- Set a nested key path into a target table.
--- Numeric path segments are treated as array indices.
--- @param target table
--- @param keys table
--- @param value any
local function set_nested(target, keys, value)
  local key = table.remove(keys, 1)
  if key == nil then
    return
  end

  local numeric_key = tonumber(key)
  local final_key = numeric_key or key

  if #keys == 0 then
    target[final_key] = value
    return
  end

  local next_target = target[final_key]
  if type(next_target) ~= "table" then
    next_target = {}
    target[final_key] = next_target
  end

  set_nested(next_target, keys, value)
end

--- Apply dotted-path overrides from keyword arguments.
--- @param config table
--- @param kwargs table
--- @param reserved_keys table<string, boolean>
local function apply_kwargs_overrides(config, kwargs, reserved_keys)
  for key, raw_value in pairs(kwargs) do
    local key_string = tostring(key)
    if not reserved_keys[key_string] then
      local parsed_value = codec.parse_value(raw_value)
      local path = split_key(key_string)
      if #path > 0 then
        set_nested(config, path, parsed_value)
      end
    end
  end
end

--- Apply dotted-path overrides from positional args in key=value form.
--- @param config table
--- @param args table|nil
--- @param reserved_keys table<string, boolean>
local function apply_args_overrides(config, args, reserved_keys)
  if type(args) ~= "table" then
    return
  end

  for _, entry in ipairs(args) do
    local text = utils.stringify(entry)
    local name, value = text:match("^([^=]+)%s*=%s*(.+)$")
    if name and value then
      name = codec.trim(name)
      local parsed_value = codec.parse_value(value)
      if not reserved_keys[name] then
        local path = split_key(name)
        if #path > 0 then
          set_nested(config, path, parsed_value)
        end
      end
    end
  end
end

--- Build the final particles.js config from defaults and shortcode inputs.
--- @param defaults table
--- @param kwargs table
--- @param args table|nil
--- @param reserved_keys table<string, boolean>
--- @return table
local function build(defaults, kwargs, args, reserved_keys)
  local config = clone_table(defaults)

  local config_string = codec.get_kwarg(kwargs, "config")
  local config_mode = codec.get_kwarg(kwargs, "config-mode") or codec.get_kwarg(kwargs, "config_mode") or "merge"
  local parsed_config = codec.decode_json(config_string)
  if parsed_config then
    if config_mode == "replace" then
      config = parsed_config
    else
      merge_tables(config, parsed_config)
    end
  end

  apply_kwargs_overrides(config, kwargs, reserved_keys)
  apply_args_overrides(config, args, reserved_keys)
  return config
end

return {
  build = build
}
