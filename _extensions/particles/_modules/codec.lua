--- @module codec
--- String, value, JSON, and attribute encoding helpers.

local utils = require("pandoc.utils")
local has_json, json = pcall(require, "pandoc.json")

--- Trim leading and trailing whitespace.
--- @param text any
--- @return string
local function trim(text)
  return tostring(text or ""):match("^%s*(.-)%s*$") or ""
end

--- Escape a Lua string for JSON output.
--- @param str string
--- @return string
local function escape_json_string(str)
  local replacements = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
  }
  return str:gsub('[\0-\31\\"]', function(char)
    return replacements[char] or string.format("\\u%04x", char:byte())
  end)
end

--- Detect whether a table is an array-like sequence.
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

--- Encode a Lua value as JSON text.
--- Falls back to a pure Lua encoder when pandoc.json.encode is unavailable.
--- @param value any
--- @return string
local function json_encode(value)
  local value_type = type(value)
  if value_type == "table" then
    if is_array(value) then
      local items = {}
      for index = 1, #value do
        items[#items + 1] = json_encode(value[index])
      end
      return "[" .. table.concat(items, ",") .. "]"
    end
    local items = {}
    for key, val in pairs(value) do
      items[#items + 1] = '"' .. escape_json_string(tostring(key)) .. '":' .. json_encode(val)
    end
    return "{" .. table.concat(items, ",") .. "}"
  elseif value_type == "string" then
    return '"' .. escape_json_string(value) .. '"'
  elseif value_type == "number" then
    return tostring(value)
  elseif value_type == "boolean" then
    return value and "true" or "false"
  else
    return "null"
  end
end

--- Convert a raw shortcode value into typed Lua values.
--- Supports booleans, numbers, null, and JSON objects/arrays.
--- @param raw any
--- @return any
local function parse_value(raw)
  if raw == nil then
    return nil
  end

  local raw_type = type(raw)
  if raw_type == "boolean" or raw_type == "number" then
    return raw
  end

  local string_value
  if raw_type == "table" or raw_type == "userdata" then
    local ok, text = pcall(utils.stringify, raw)
    string_value = ok and trim(text) or trim(tostring(raw))
  else
    string_value = trim(tostring(raw))
  end

  if string_value == "" then
    return ""
  end
  if string_value == "true" then
    return true
  end
  if string_value == "false" then
    return false
  end
  if string_value == "null" or string_value == "~" then
    return nil
  end

  local numeric = tonumber(string_value)
  if numeric then
    return numeric
  end

  if has_json and (string_value:sub(1, 1) == "{" or string_value:sub(1, 1) == "[") then
    local ok, decoded = pcall(json.decode, string_value)
    if ok then
      return decoded
    end
  end

  return string_value
end

--- Get a keyword argument as a trimmed string.
--- @param kwargs table
--- @param key string
--- @return string|nil
local function get_kwarg(kwargs, key)
  local value = kwargs[key]
  if value == nil then
    return nil
  end

  local value_type = type(value)
  if value_type == "boolean" or value_type == "number" then
    return tostring(value)
  end

  local text
  if value_type == "string" then
    text = value
  else
    local ok, rendered = pcall(utils.stringify, value)
    text = ok and rendered or tostring(value)
  end

  local trimmed = trim(text)
  if trimmed == "" then
    return nil
  end

  return trimmed
end

--- Escape text for safe inclusion in HTML attributes.
--- @param value string
--- @return string
local function escape_attr(value)
  local replacements = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;"
  }
  return (value:gsub('[&<>"\']', replacements))
end

--- Decode a JSON string if pandoc.json is available.
--- @param raw string|nil
--- @return table|nil
local function decode_json(raw)
  if not raw or not has_json then
    return nil
  end
  local ok, decoded = pcall(json.decode, raw)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return nil
end

return {
  trim = trim,
  parse_value = parse_value,
  get_kwarg = get_kwarg,
  escape_attr = escape_attr,
  json_encode = json_encode,
  decode_json = decode_json
}
