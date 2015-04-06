-- Copyright 2015 Boundary
-- @brief convenience variables and functions for Lua scripts
-- @file boundary.lua
local fs = require('fs')
local json = require('json')

local boundary = {argv = nil, param = nil}
local plugin_basedir = "."

-- create table of cmdline args (boundary.argv)
boundary.argv = process.argv or nil
if boundary.argv ~= nil then
  -- if '--plguin-basedir' is present as the first arg, use its value as the path
  -- to the param.json file and remove it from the arg table
  if boundary.argv[1] == '--plugin-basedir' then
    plugin_basedir = boundary.argv[2]
    table.remove(boundary.argv, 1)
    table.remove(boundary.argv, 1)
  end
end

-- import param.json data into a Lua table (boundary.param)
local json_blob
if (pcall(function () json_blob = fs.readFileSync(plugin_basedir.."/param.json") end)) then
  pcall(function () boundary.param = json.parse(json_blob) end)
end

return boundary
