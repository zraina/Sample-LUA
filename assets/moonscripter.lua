
--------------------------------------
package.preload['moonscript.version'] = function (...)

module("moonscript.version", package.seeall)

version = "0.2.4"
function print_version()
	print("MoonScript version "..version)
end

end

--------------------------------------
package.preload['moon.all'] = function (...)
local moon = require("moon")
for k, v in pairs(moon) do
  _G[k] = v
end
return moon

end

--------------------------------------
package.preload['moonscript.init'] = function (...)
do
  local _with_0 = require("moonscript.base")
  _with_0.insert_loader()
  return _with_0
end

end

--------------------------------------
package.preload['moonscript.base'] = function (...)
local compile = require("moonscript.compile")
local parse = require("moonscript.parse")
local concat, insert, remove
do
  local _obj_0 = table
  concat, insert, remove = _obj_0.concat, _obj_0.insert, _obj_0.remove
end
local split, dump, get_options, unpack
do
  local _obj_0 = require("moonscript.util")
  split, dump, get_options, unpack = _obj_0.split, _obj_0.dump, _obj_0.get_options, _obj_0.unpack
end
local lua = {
  loadstring = loadstring,
  load = load
}
local dirsep, line_tables, create_moonpath, to_lua, moon_loader, loadstring, loadfile, dofile, insert_loader, remove_loader
dirsep = "/"
line_tables = require("moonscript.line_tables")
create_moonpath = function(package_path)
  local paths = split(package_path, ";")
  for i, path in ipairs(paths) do
    local p = path:match("^(.-)%.lua$")
    if p then
      paths[i] = p .. ".moon"
    end
  end
  return concat(paths, ";")
end
to_lua = function(text, options)
  if options == nil then
    options = { }
  end
  if "string" ~= type(text) then
    local t = type(text)
    return nil, "expecting string (got " .. t .. ")", 2
  end
  local tree, err = parse.string(text)
  if not tree then
    return nil, err
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    return nil, compile.format_error(ltable, pos, text), 2
  end
  return code, ltable
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path
  local _list_0 = split(package.moonpath, ";")
  for _index_0 = 1, #_list_0 do
    local path = _list_0[_index_0]
    file_path = path:gsub("?", name_path)
    file = io.open(file_path)
    if file then
      break
    end
  end
  if file then
    local text = file:read("*a")
    file:close()
    return loadstring(text, file_path)
  else
    return nil, "Could not find moon file"
  end
end
loadstring = function(...)
  local options, str, chunk_name, mode, env = get_options(...)
  chunk_name = chunk_name or "=(moonscript.loadstring)"
  local code, ltable_or_err = to_lua(str, options)
  if not (code) then
    return nil, ltable_or_err
  end
  if chunk_name then
    line_tables[chunk_name] = ltable_or_err
  end
  return (lua.loadstring or lua.load)(code, chunk_name, unpack({
    mode,
    env
  }))
end
loadfile = function(fname, ...)
  local file, err = io.open(fname)
  if not (file) then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return loadstring(text, fname, ...)
end
dofile = function(...)
  local f = assert(loadfile(...))
  return f()
end
insert_loader = function(pos)
  if pos == nil then
    pos = 2
  end
  if not package.moonpath then
    package.moonpath = create_moonpath(package.path)
  end
  local loaders = package.loaders or package.searchers
  for _index_0 = 1, #loaders do
    local loader = loaders[_index_0]
    if loader == moon_loader then
      return false
    end
  end
  insert(loaders, pos, moon_loader)
  return true
end
remove_loader = function()
  local loaders = package.loaders or package.searchers
  for i, loader in ipairs(loaders) do
    if loader == moon_loader then
      remove(loaders, i)
      return true
    end
  end
  return false
end
return {
  _NAME = "moonscript",
  insert_loader = insert_loader,
  remove_loader = remove_loader,
  to_lua = to_lua,
  moon_chunk = moon_chunk,
  moon_loader = moon_loader,
  dirsep = dirsep,
  dofile = dofile,
  loadfile = loadfile,
  loadstring = loadstring
}

end

--------------------------------------
package.preload['moonscript.transform.destructure'] = function (...)
local ntype, mtype, build
do
  local _obj_0 = require("moonscript.types")
  ntype, mtype, build = _obj_0.ntype, _obj_0.mtype, _obj_0.build
end
local NameProxy
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy = _obj_0.NameProxy
end
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local unpack
do
  local _obj_0 = require("moonscript.util")
  unpack = _obj_0.unpack
end
local user_error
do
  local _obj_0 = require("moonscript.errors")
  user_error = _obj_0.user_error
end
local util = require("moonscript.util")
local join
join = function(...)
  do
    local out = { }
    local i = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local tbl = _list_0[_index_0]
      for _index_1 = 1, #tbl do
        local v = tbl[_index_1]
        out[i] = v
        i = i + 1
      end
    end
    return out
  end
end
local has_destructure
has_destructure = function(names)
  for _index_0 = 1, #names do
    local n = names[_index_0]
    if ntype(n) == "table" then
      return true
    end
  end
  return false
end
local extract_assign_names
extract_assign_names = function(name, accum, prefix)
  if accum == nil then
    accum = { }
  end
  if prefix == nil then
    prefix = { }
  end
  local i = 1
  local _list_0 = name[2]
  for _index_0 = 1, #_list_0 do
    local tuple = _list_0[_index_0]
    local value, suffix
    if #tuple == 1 then
      local s = {
        "index",
        {
          "number",
          i
        }
      }
      i = i + 1
      value, suffix = tuple[1], s
    else
      local key = tuple[1]
      local s
      if ntype(key) == "key_literal" then
        local key_name = key[2]
        if ntype(key_name) == "colon_stub" then
          s = key_name
        else
          s = {
            "dot",
            key_name
          }
        end
      else
        s = {
          "index",
          key
        }
      end
      value, suffix = tuple[2], s
    end
    suffix = join(prefix, {
      suffix
    })
    local t = ntype(value)
    if t == "value" or t == "chain" or t == "self" then
      insert(accum, {
        value,
        suffix
      })
    elseif t == "table" then
      extract_assign_names(value, accum, suffix)
    else
      user_error("Can't destructure value of type: " .. tostring(ntype(value)))
    end
  end
  return accum
end
local build_assign
build_assign = function(scope, destruct_literal, receiver)
  local extracted_names = extract_assign_names(destruct_literal)
  local names = { }
  local values = { }
  local inner = {
    "assign",
    names,
    values
  }
  local obj
  if scope:is_local(receiver) then
    obj = receiver
  else
    do
      obj = NameProxy("obj")
      inner = build["do"]({
        build.assign_one(obj, receiver),
        {
          "assign",
          names,
          values
        }
      })
      obj = obj
    end
  end
  for _index_0 = 1, #extracted_names do
    local tuple = extracted_names[_index_0]
    insert(names, tuple[1])
    insert(values, NameProxy.chain(obj, unpack(tuple[2])))
  end
  return build.group({
    {
      "declare",
      names
    },
    inner
  })
end
local split_assign
split_assign = function(scope, assign)
  local names, values = unpack(assign, 2)
  local g = { }
  local total_names = #names
  local total_values = #values
  local start = 1
  for i, n in ipairs(names) do
    if ntype(n) == "table" then
      if i > start then
        local stop = i - 1
        insert(g, {
          "assign",
          (function()
            local _accum_0 = { }
            local _len_0 = 1
            for i = start, stop do
              _accum_0[_len_0] = names[i]
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(),
          (function()
            local _accum_0 = { }
            local _len_0 = 1
            for i = start, stop do
              _accum_0[_len_0] = values[i]
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)()
        })
      end
      insert(g, build_assign(scope, n, values[i]))
      start = i + 1
    end
  end
  if total_names >= start or total_values >= start then
    local name_slice
    if total_names < start then
      name_slice = {
        "_"
      }
    else
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_names do
          _accum_0[_len_0] = names[i]
          _len_0 = _len_0 + 1
        end
        name_slice = _accum_0
      end
    end
    local value_slice
    if total_values < start then
      value_slice = {
        "nil"
      }
    else
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = start, total_values do
          _accum_0[_len_0] = values[i]
          _len_0 = _len_0 + 1
        end
        value_slice = _accum_0
      end
    end
    insert(g, {
      "assign",
      name_slice,
      value_slice
    })
  end
  return build.group(g)
end
return {
  has_destructure = has_destructure,
  split_assign = split_assign,
  build_assign = build_assign
}

end

--------------------------------------
package.preload['moonscript.compile'] = function (...)
local util = require("moonscript.util")
local dump = require("moonscript.dump")
local transform = require("moonscript.transform")
local NameProxy, LocalName
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName
end
local Set
do
  local _obj_0 = require("moonscript.data")
  Set = _obj_0.Set
end
local ntype, has_value
do
  local _obj_0 = require("moonscript.types")
  ntype, has_value = _obj_0.ntype, _obj_0.has_value
end
local statement_compilers
do
  local _obj_0 = require("moonscript.compile.statement")
  statement_compilers = _obj_0.statement_compilers
end
local value_compilers
do
  local _obj_0 = require("moonscript.compile.value")
  value_compilers = _obj_0.value_compilers
end
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local pos_to_line, get_closest_line, trim, unpack
pos_to_line, get_closest_line, trim, unpack = util.pos_to_line, util.get_closest_line, util.trim, util.unpack
local mtype = util.moon.type
local indent_char = "  "
local Line, DelayedLine, Lines, Block, RootBlock
do
  local _base_0 = {
    mark_pos = function(self, pos, line)
      if line == nil then
        line = #self
      end
      if not (self.posmap[line]) then
        self.posmap[line] = pos
      end
    end,
    add = function(self, item)
      local _exp_0 = mtype(item)
      if Line == _exp_0 then
        item:render(self)
      elseif Block == _exp_0 then
        item:render(self)
      else
        self[#self + 1] = item
      end
      return self
    end,
    flatten_posmap = function(self, line_no, out)
      if line_no == nil then
        line_no = 0
      end
      if out == nil then
        out = { }
      end
      local posmap = self.posmap
      for i, l in ipairs(self) do
        local _exp_0 = mtype(l)
        if "string" == _exp_0 or DelayedLine == _exp_0 then
          line_no = line_no + 1
          out[line_no] = posmap[i]
        elseif Lines == _exp_0 then
          local _
          _, line_no = l:flatten_posmap(line_no, out)
        else
          error("Unknown item in Lines: " .. tostring(l))
        end
      end
      return out, line_no
    end,
    flatten = function(self, indent, buffer)
      if indent == nil then
        indent = nil
      end
      if buffer == nil then
        buffer = { }
      end
      for i = 1, #self do
        local l = self[i]
        local t = mtype(l)
        if t == DelayedLine then
          l = l:render()
          t = "string"
        end
        local _exp_0 = t
        if "string" == _exp_0 then
          if indent then
            insert(buffer, indent)
          end
          insert(buffer, l)
          if "string" == type(self[i + 1]) then
            local lc = l:sub(-1)
            if (lc == ")" or lc == "]") and self[i + 1]:sub(1, 1) == "(" then
              insert(buffer, ";")
            end
          end
          insert(buffer, "\n")
          local last = l
        elseif Lines == _exp_0 then
          l:flatten(indent and indent .. indent_char or indent_char, buffer)
        else
          error("Unknown item in Lines: " .. tostring(l))
        end
      end
      return buffer
    end,
    __tostring = function(self)
      local strip
      strip = function(t)
        if "table" == type(t) then
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #t do
            local v = t[_index_0]
            _accum_0[_len_0] = strip(v)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        else
          return t
        end
      end
      return "Lines<" .. tostring(util.dump(strip(self)):sub(1, -2)) .. ">"
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.posmap = { }
    end,
    __base = _base_0,
    __name = "Lines"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Lines = _class_0
end
do
  local _base_0 = {
    pos = nil,
    _append_single = function(self, item)
      if Line == mtype(item) then
        if not (self.pos) then
          self.pos = item.pos
        end
        for _index_0 = 1, #item do
          local value = item[_index_0]
          self:_append_single(value)
        end
      else
        insert(self, item)
      end
      return nil
    end,
    append_list = function(self, items, delim)
      for i = 1, #items do
        self:_append_single(items[i])
        if i < #items then
          insert(self, delim)
        end
      end
      return nil
    end,
    append = function(self, ...)
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local item = _list_0[_index_0]
        self:_append_single(item)
      end
      return nil
    end,
    render = function(self, buffer)
      local current = { }
      local add_current
      add_current = function()
        buffer:add(concat(current))
        return buffer:mark_pos(self.pos)
      end
      for _index_0 = 1, #self do
        local chunk = self[_index_0]
        local _exp_0 = mtype(chunk)
        if Block == _exp_0 then
          local _list_0 = chunk:render(Lines())
          for _index_1 = 1, #_list_0 do
            local block_chunk = _list_0[_index_1]
            if "string" == type(block_chunk) then
              insert(current, block_chunk)
            else
              add_current()
              buffer:add(block_chunk)
              current = { }
            end
          end
        else
          insert(current, chunk)
        end
      end
      if #current > 0 then
        add_current()
      end
      return buffer
    end,
    __tostring = function(self)
      return "Line<" .. tostring(util.dump(self):sub(1, -2)) .. ">"
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Line"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Line = _class_0
end
do
  local _base_0 = {
    prepare = function() end,
    render = function(self)
      self:prepare()
      return concat(self)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.prepare = fn
    end,
    __base = _base_0,
    __name = "DelayedLine"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DelayedLine = _class_0
end
do
  local _base_0 = {
    header = "do",
    footer = "end",
    export_all = false,
    export_proper = false,
    __tostring = function(self)
      local h
      if "string" == type(self.header) then
        h = self.header
      else
        h = unpack(self.header:render({ }))
      end
      return "Block<" .. tostring(h) .. "> <- " .. tostring(self.parent)
    end,
    set = function(self, name, value)
      self._state[name] = value
    end,
    get = function(self, name)
      return self._state[name]
    end,
    get_current = function(self, name)
      return rawget(self._state, name)
    end,
    listen = function(self, name, fn)
      self._listeners[name] = fn
    end,
    unlisten = function(self, name)
      self._listeners[name] = nil
    end,
    send = function(self, name, ...)
      do
        local fn = self._listeners[name]
        if fn then
          return fn(self, ...)
        end
      end
    end,
    declare = function(self, names)
      local undeclared
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local _continue_0 = false
          repeat
            local name = names[_index_0]
            local is_local = false
            local real_name
            local _exp_0 = mtype(name)
            if LocalName == _exp_0 then
              is_local = true
              real_name = name:get_name(self)
            elseif NameProxy == _exp_0 then
              real_name = name:get_name(self)
            elseif "string" == _exp_0 then
              real_name = name
            end
            if not (is_local or real_name and not self:has_name(real_name, true)) then
              _continue_0 = true
              break
            end
            self:put_name(real_name)
            if self:name_exported(real_name) then
              _continue_0 = true
              break
            end
            local _value_0 = real_name
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        undeclared = _accum_0
      end
      return undeclared
    end,
    whitelist_names = function(self, names)
      self._name_whitelist = Set(names)
    end,
    name_exported = function(self, name)
      if self.export_all then
        return true
      end
      if self.export_proper and name:match("^%u") then
        return true
      end
    end,
    put_name = function(self, name, ...)
      local value = ...
      if select("#", ...) == 0 then
        value = true
      end
      if NameProxy == mtype(name) then
        name = name:get_name(self)
      end
      self._names[name] = value
    end,
    has_name = function(self, name, skip_exports)
      if not skip_exports and self:name_exported(name) then
        return true
      end
      local yes = self._names[name]
      if yes == nil and self.parent then
        if not self._name_whitelist or self._name_whitelist[name] then
          return self.parent:has_name(name, true)
        end
      else
        return yes
      end
    end,
    is_local = function(self, node)
      local t = mtype(node)
      if t == "string" then
        return self:has_name(node, false)
      end
      if t == NameProxy or t == LocalName then
        return true
      end
      if t == "table" and node[1] == "chain" and #node == 2 then
        return self:is_local(node[2])
      end
      return false
    end,
    free_name = function(self, prefix, dont_put)
      prefix = prefix or "moon"
      local searching = true
      local name, i = nil, 0
      while searching do
        name = concat({
          "",
          prefix,
          i
        }, "_")
        i = i + 1
        searching = self:has_name(name, true)
      end
      if not dont_put then
        self:put_name(name)
      end
      return name
    end,
    init_free_var = function(self, prefix, value)
      local name = self:free_name(prefix, true)
      self:stm({
        "assign",
        {
          name
        },
        {
          value
        }
      })
      return name
    end,
    add = function(self, item)
      self._lines:add(item)
      return item
    end,
    render = function(self, buffer)
      buffer:add(self.header)
      buffer:mark_pos(self.pos)
      if self.next then
        buffer:add(self._lines)
        self.next:render(buffer)
      else
        if #self._lines == 0 and "string" == type(buffer[#buffer]) then
          buffer[#buffer] = buffer[#buffer] .. (" " .. (unpack(Lines():add(self.footer))))
        else
          buffer:add(self._lines)
          buffer:add(self.footer)
          buffer:mark_pos(self.pos)
        end
      end
      return buffer
    end,
    block = function(self, header, footer)
      return Block(self, header, footer)
    end,
    line = function(self, ...)
      do
        local _with_0 = Line()
        _with_0:append(...)
        return _with_0
      end
    end,
    is_stm = function(self, node)
      return statement_compilers[ntype(node)] ~= nil
    end,
    is_value = function(self, node)
      local t = ntype(node)
      return value_compilers[t] ~= nil or t == "value"
    end,
    name = function(self, node, ...)
      return self:value(node, ...)
    end,
    value = function(self, node, ...)
      node = self.transform.value(node)
      local action
      if type(node) ~= "table" then
        action = "raw_value"
      else
        action = node[1]
      end
      local fn = value_compilers[action]
      if not fn then
        error("Failed to compile value: " .. dump.value(node))
      end
      local out = fn(self, node, ...)
      if type(node) == "table" and node[-1] then
        if type(out) == "string" then
          do
            local _with_0 = Line()
            _with_0:append(out)
            out = _with_0
          end
        end
        out.pos = node[-1]
      end
      return out
    end,
    values = function(self, values, delim)
      delim = delim or ', '
      do
        local _with_0 = Line()
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #values do
            local v = values[_index_0]
            _accum_0[_len_0] = self:value(v)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)(), delim)
        return _with_0
      end
    end,
    stm = function(self, node, ...)
      if not node then
        return 
      end
      node = self.transform.statement(node)
      local result
      do
        local fn = statement_compilers[ntype(node)]
        if fn then
          result = fn(self, node, ...)
        else
          if has_value(node) then
            result = self:stm({
              "assign",
              {
                "_"
              },
              {
                node
              }
            })
          else
            result = self:value(node)
          end
        end
      end
      if result then
        if type(node) == "table" and type(result) == "table" and node[-1] then
          result.pos = node[-1]
        end
        self:add(result)
      end
      return nil
    end,
    stms = function(self, stms, ret)
      if ret then
        error("deprecated stms call, use transformer")
      end
      local current_stms, current_stm_i
      current_stms, current_stm_i = self.current_stms, self.current_stm_i
      self.current_stms = stms
      for i = 1, #stms do
        self.current_stm_i = i
        self:stm(stms[i])
      end
      self.current_stms = current_stms
      self.current_stm_i = current_stm_i
      return nil
    end,
    splice = function(self, fn)
      local lines = {
        "lines",
        self._lines
      }
      self._lines = Lines()
      return self:stms(fn(lines))
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, parent, header, footer)
      self.parent, self.header, self.footer = parent, header, footer
      self._lines = Lines()
      self._names = { }
      self._state = { }
      self._listeners = { }
      do
        self.transform = {
          value = transform.Value:bind(self),
          statement = transform.Statement:bind(self)
        }
      end
      if self.parent then
        self.root = self.parent.root
        self.indent = self.parent.indent + 1
        setmetatable(self._state, {
          __index = self.parent._state
        })
        return setmetatable(self._listeners, {
          __index = self.parent._listeners
        })
      else
        self.indent = 0
      end
    end,
    __base = _base_0,
    __name = "Block"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Block = _class_0
end
do
  local _parent_0 = Block
  local _base_0 = {
    __tostring = function(self)
      return "RootBlock<>"
    end,
    root_stms = function(self, stms)
      if not (self.options.implicitly_return_root == false) then
        stms = transform.Statement.transformers.root_stms(self, stms)
      end
      return self:stms(stms)
    end,
    render = function(self)
      local buffer = self._lines:flatten()
      if buffer[#buffer] == "\n" then
        buffer[#buffer] = nil
      end
      return table.concat(buffer)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, options)
      self.options = options
      self.root = self
      return _parent_0.__init(self)
    end,
    __base = _base_0,
    __name = "RootBlock",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RootBlock = _class_0
end
local format_error
format_error = function(msg, pos, file_str)
  local line = pos_to_line(file_str, pos)
  local line_str
  line_str, line = get_closest_line(file_str, line)
  line_str = line_str or ""
  return concat({
    "Compile error: " .. msg,
    (" [%d] >>    %s"):format(line, trim(line_str))
  }, "\n")
end
local value
value = function(value)
  local out = nil
  do
    local _with_0 = RootBlock()
    _with_0:add(_with_0:value(value))
    out = _with_0:render()
  end
  return out
end
local tree
tree = function(tree, options)
  if options == nil then
    options = { }
  end
  assert(tree, "missing tree")
  local scope = (options.scope or RootBlock)(options)
  local runner = coroutine.create(function()
    return scope:root_stms(tree)
  end)
  local success, err = coroutine.resume(runner)
  if not success then
    local error_msg
    if type(err) == "table" then
      local error_type = err[1]
      if error_type == "user-error" then
        error_msg = err[2]
      else
        error_msg = error("Unknown error thrown", util.dump(error_msg))
      end
    else
      error_msg = concat({
        err,
        debug.traceback(runner)
      }, "\n")
    end
    return nil, error_msg, scope.last_pos
  else
    local lua_code = scope:render()
    local posmap = scope._lines:flatten_posmap()
    return lua_code, posmap
  end
end
do
  local data = require("moonscript.data")
  for name, cls in pairs({
    Line = Line,
    Lines = Lines,
    DelayedLine = DelayedLine
  }) do
    data[name] = cls
  end
end
return {
  tree = tree,
  value = value,
  format_error = format_error,
  Block = Block,
  RootBlock = RootBlock
}

end

--------------------------------------
package.preload['moonscript.dump'] = function (...)
local flat_value
flat_value = function(op, depth)
  if depth == nil then
    depth = 1
  end
  if type(op) == "string" then
    return '"' .. op .. '"'
  end
  if type(op) ~= "table" then
    return tostring(op)
  end
  local items
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #op do
      local item = op[_index_0]
      _accum_0[_len_0] = flat_value(item, depth + 1)
      _len_0 = _len_0 + 1
    end
    items = _accum_0
  end
  local pos = op[-1]
  return "{" .. (pos and "[" .. pos .. "] " or "") .. table.concat(items, ", ") .. "}"
end
local value
value = function(op)
  return flat_value(op)
end
local tree
tree = function(block)
  local _list_0 = block
  for _index_0 = 1, #_list_0 do
    value = _list_0[_index_0]
    print(flat_value(value))
  end
end
return {
  value = value,
  tree = tree
}

end

--------------------------------------
package.preload['moonscript.compile.value'] = function (...)
local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype
do
  local _obj_0 = require("moonscript.types")
  ntype = _obj_0.ntype
end
local user_error
do
  local _obj_0 = require("moonscript.errors")
  user_error = _obj_0.user_error
end
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local unpack
unpack = util.unpack
local table_delim = ","
local string_chars = {
  ["\r"] = "\\r",
  ["\n"] = "\\n"
}
local value_compilers = {
  exp = function(self, node)
    local _comp
    _comp = function(i, value)
      if i % 2 == 1 and value == "!=" then
        value = "~="
      end
      return self:value(value)
    end
    do
      local _with_0 = self:line()
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for i, v in ipairs(node) do
          if i > 1 then
            _accum_0[_len_0] = _comp(i, v)
            _len_0 = _len_0 + 1
          end
        end
        return _accum_0
      end)(), " ")
      return _with_0
    end
  end,
  explist = function(self, node)
    do
      local _with_0 = self:line()
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 2, #node do
          local v = node[_index_0]
          _accum_0[_len_0] = self:value(v)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
      return _with_0
    end
  end,
  parens = function(self, node)
    return self:line("(", self:value(node[2]), ")")
  end,
  string = function(self, node)
    local _, delim, inner = unpack(node)
    local end_delim = delim:gsub("%[", "]")
    if delim == "'" or delim == '"' then
      inner = inner:gsub("[\r\n]", string_chars)
    end
    return delim .. inner .. end_delim
  end,
  chain = function(self, node)
    local callee = node[2]
    if callee == -1 then
      callee = self:get("scope_var")
      if not callee then
        user_error("Short-dot syntax must be called within a with block")
      end
    end
    local sup = self:get("super")
    if callee == "super" and sup then
      return self:value(sup(self, node))
    end
    local chain_item
    chain_item = function(node)
      local t, arg = unpack(node)
      if t == "call" then
        return "(", self:values(arg), ")"
      elseif t == "index" then
        return "[", self:value(arg), "]"
      elseif t == "dot" then
        return ".", tostring(arg)
      elseif t == "colon" then
        return ":", arg, chain_item(node[3])
      elseif t == "colon_stub" then
        return user_error("Uncalled colon stub")
      else
        return error("Unknown chain action: " .. t)
      end
    end
    local t = ntype(callee)
    if (t == "self" or t == "self_class") and node[3] and ntype(node[3]) == "call" then
      callee[1] = t .. "_colon"
    end
    local callee_value = self:value(callee)
    if ntype(callee) == "exp" then
      callee_value = self:line("(", callee_value, ")")
    end
    local actions
    do
      local _with_0 = self:line()
      for _index_0 = 3, #node do
        local action = node[_index_0]
        _with_0:append(chain_item(action))
      end
      actions = _with_0
    end
    return self:line(callee_value, actions)
  end,
  fndef = function(self, node)
    local _, args, whitelist, arrow, block = unpack(node)
    local default_args = { }
    local self_args = { }
    local arg_names
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #args do
        local arg = args[_index_0]
        local name, default_value = unpack(arg)
        if type(name) == "string" then
          name = name
        else
          if name[1] == "self" or name[1] == "self_class" then
            insert(self_args, name)
          end
          name = name[2]
        end
        if default_value then
          insert(default_args, arg)
        end
        local _value_0 = name
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
      end
      arg_names = _accum_0
    end
    if arrow == "fat" then
      insert(arg_names, 1, "self")
    end
    do
      local _with_0 = self:block()
      if #whitelist > 0 then
        _with_0:whitelist_names(whitelist)
      end
      for _index_0 = 1, #arg_names do
        local name = arg_names[_index_0]
        _with_0:put_name(name)
      end
      for _index_0 = 1, #default_args do
        local default = default_args[_index_0]
        local name, value = unpack(default)
        if type(name) == "table" then
          name = name[2]
        end
        _with_0:stm({
          'if',
          {
            'exp',
            name,
            '==',
            'nil'
          },
          {
            {
              'assign',
              {
                name
              },
              {
                value
              }
            }
          }
        })
      end
      local self_arg_values
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #self_args do
          local arg = self_args[_index_0]
          _accum_0[_len_0] = arg[2]
          _len_0 = _len_0 + 1
        end
        self_arg_values = _accum_0
      end
      if #self_args > 0 then
        _with_0:stm({
          "assign",
          self_args,
          self_arg_values
        })
      end
      _with_0:stms(block)
      if #args > #arg_names then
        do
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #args do
            local arg = args[_index_0]
            _accum_0[_len_0] = arg[1]
            _len_0 = _len_0 + 1
          end
          arg_names = _accum_0
        end
      end
      _with_0.header = "function(" .. concat(arg_names, ", ") .. ")"
      return _with_0
    end
  end,
  table = function(self, node)
    local _, items = unpack(node)
    do
      local _with_0 = self:block("{", "}")
      local format_line
      format_line = function(tuple)
        if #tuple == 2 then
          local key, value = unpack(tuple)
          if ntype(key) == "key_literal" and data.lua_keywords[key[2]] then
            key = {
              "string",
              '"',
              key[2]
            }
          end
          local assign
          if ntype(key) == "key_literal" then
            assign = key[2]
          else
            assign = self:line("[", _with_0:value(key), "]")
          end
          _with_0:set("current_block", key)
          local out = self:line(assign, " = ", _with_0:value(value))
          _with_0:set("current_block", nil)
          return out
        else
          return self:line(_with_0:value(tuple[1]))
        end
      end
      if items then
        local count = #items
        for i, tuple in ipairs(items) do
          local line = format_line(tuple)
          if not (count == i) then
            line:append(table_delim)
          end
          _with_0:add(line)
        end
      end
      return _with_0
    end
  end,
  minus = function(self, node)
    return self:line("-", self:value(node[2]))
  end,
  temp_name = function(self, node, ...)
    return node:get_name(self, ...)
  end,
  number = function(self, node)
    return node[2]
  end,
  length = function(self, node)
    return self:line("#", self:value(node[2]))
  end,
  ["not"] = function(self, node)
    return self:line("not ", self:value(node[2]))
  end,
  self = function(self, node)
    return "self." .. self:value(node[2])
  end,
  self_class = function(self, node)
    return "self.__class." .. self:value(node[2])
  end,
  self_colon = function(self, node)
    return "self:" .. self:value(node[2])
  end,
  self_class_colon = function(self, node)
    return "self.__class:" .. self:value(node[2])
  end,
  raw_value = function(self, value)
    local sup = self:get("super")
    if value == "super" and sup then
      return self:value(sup(self))
    end
    if value == "..." then
      self:send("varargs")
    end
    return tostring(value)
  end
}
return {
  value_compilers = value_compilers
}

end

--------------------------------------
package.preload['moon'] = function (...)
return require "moon.init"

end

--------------------------------------
package.preload['moon.init'] = function (...)
local util = require("moonscript.util")
local lua = {
  debug = debug,
  type = type
}
local dump, p, is_object, type, debug, run_with_scope, bind_methods, defaultbl, extend, copy, mixin, mixin_object, mixin_table, fold
dump = util.dump
p = function(...)
  return print(dump(...))
end
is_object = function(value)
  return lua.type(value) == "table" and value.__class
end
type = function(value)
  local base_type = lua.type(value)
  if base_type == "table" then
    local cls = value.__class
    if cls then
      return cls
    end
  end
  return base_type
end
debug = setmetatable({
  upvalue = function(fn, k, v)
    local upvalues = { }
    local i = 1
    while true do
      local name = lua.debug.getupvalue(fn, i)
      if name == nil then
        break
      end
      upvalues[name] = i
      i = i + 1
    end
    if not upvalues[k] then
      error("Failed to find upvalue: " .. tostring(k))
    end
    if not v then
      local _, value = lua.debug.getupvalue(fn, upvalues[k])
      return value
    else
      return lua.debug.setupvalue(fn, upvalues[k], v)
    end
  end
}, {
  __index = lua.debug
})
run_with_scope = function(fn, scope, ...)
  local old_env = getfenv(fn)
  local env = setmetatable({ }, {
    __index = function(self, name)
      local val = scope[name]
      if val ~= nil then
        return val
      else
        return old_env[name]
      end
    end
  })
  setfenv(fn, env)
  return fn(...)
end
bind_methods = function(obj)
  return setmetatable({ }, {
    __index = function(self, name)
      local val = obj[name]
      if val and lua.type(val) == "function" then
        local bound
        bound = function(...)
          return val(obj, ...)
        end
        self[name] = bound
        return bound
      else
        return val
      end
    end
  })
end
defaultbl = function(t, fn)
  if not fn then
    fn = t
    t = { }
  end
  return setmetatable(t, {
    __index = function(self, name)
      local val = fn(self, name)
      rawset(self, name, val)
      return val
    end
  })
end
extend = function(...)
  local tbls = {
    ...
  }
  if #tbls < 2 then
    return 
  end
  for i = 1, #tbls - 1 do
    local a = tbls[i]
    local b = tbls[i + 1]
    setmetatable(a, {
      __index = b
    })
  end
  return tbls[1]
end
copy = function(self)
  local _tbl_0 = { }
  for key, val in pairs(self) do
    _tbl_0[key] = val
  end
  return _tbl_0
end
mixin = function(self, cls, ...)
  for key, val in pairs(cls.__base) do
    if not key:match("^__") then
      self[key] = val
    end
  end
  return cls.__init(self, ...)
end
mixin_object = function(self, object, methods)
  for _index_0 = 1, #methods do
    local name = methods[_index_0]
    self[name] = function(parent, ...)
      return object[name](object, ...)
    end
  end
end
mixin_table = function(self, tbl, keys)
  if keys then
    for _index_0 = 1, #keys do
      local key = keys[_index_0]
      self[key] = tbl[key]
    end
  else
    for key, val in pairs(tbl) do
      self[key] = val
    end
  end
end
fold = function(items, fn)
  local len = #items
  if len > 1 then
    local accum = fn(items[1], items[2])
    for i = 3, len do
      accum = fn(accum, items[i])
    end
    return accum
  else
    return items[1]
  end
end
return {
  dump = dump,
  p = p,
  is_object = is_object,
  type = type,
  debug = debug,
  run_with_scope = run_with_scope,
  bind_methods = bind_methods,
  defaultbl = defaultbl,
  extend = extend,
  copy = copy,
  mixin = mixin,
  mixin_object = mixin_object,
  mixin_table = mixin_table,
  fold = fold
}

end

--------------------------------------
package.preload['moonscript.compile.statement'] = function (...)
local util = require("moonscript.util")
local data = require("moonscript.data")
local reversed, unpack
reversed, unpack = util.reversed, util.unpack
local ntype
do
  local _obj_0 = require("moonscript.types")
  ntype = _obj_0.ntype
end
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local statement_compilers = {
  raw = function(self, node)
    return self:add(node[2])
  end,
  lines = function(self, node)
    local _list_0 = node[2]
    for _index_0 = 1, #_list_0 do
      local line = _list_0[_index_0]
      self:add(line)
    end
  end,
  declare = function(self, node)
    local names = node[2]
    local undeclared = self:declare(names)
    if #undeclared > 0 then
      do
        local _with_0 = self:line("local ")
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #undeclared do
            local name = undeclared[_index_0]
            _accum_0[_len_0] = self:name(name)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)(), ", ")
        return _with_0
      end
    end
  end,
  declare_with_shadows = function(self, node)
    local names = node[2]
    self:declare(names)
    do
      local _with_0 = self:line("local ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local name = names[_index_0]
          _accum_0[_len_0] = self:name(name)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
      return _with_0
    end
  end,
  assign = function(self, node)
    local _, names, values = unpack(node)
    local undeclared = self:declare(names)
    local declare = "local " .. concat(undeclared, ", ")
    local has_fndef = false
    local i = 1
    while i <= #values do
      if ntype(values[i]) == "fndef" then
        has_fndef = true
      end
      i = i + 1
    end
    do
      local _with_0 = self:line()
      if #undeclared == #names and not has_fndef then
        _with_0:append(declare)
      else
        if #undeclared > 0 then
          self:add(declare)
        end
        _with_0:append_list((function()
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #names do
            local name = names[_index_0]
            _accum_0[_len_0] = self:value(name)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)(), ", ")
      end
      _with_0:append(" = ")
      _with_0:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #values do
          local v = values[_index_0]
          _accum_0[_len_0] = self:value(v)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
      return _with_0
    end
  end,
  ["return"] = function(self, node)
    return self:line("return ", (function()
      if node[2] ~= "" then
        return self:value(node[2])
      end
    end)())
  end,
  ["break"] = function(self, node)
    return "break"
  end,
  ["if"] = function(self, node)
    local cond, block = node[2], node[3]
    local root
    do
      local _with_0 = self:block(self:line("if ", self:value(cond), " then"))
      _with_0:stms(block)
      root = _with_0
    end
    local current = root
    local add_clause
    add_clause = function(clause)
      local type = clause[1]
      local i = 2
      local next
      if type == "else" then
        next = self:block("else")
      else
        i = i + 1
        next = self:block(self:line("elseif ", self:value(clause[2]), " then"))
      end
      next:stms(clause[i])
      current.next = next
      current = next
    end
    for _index_0 = 4, #node do
      cond = node[_index_0]
      add_clause(cond)
    end
    return root
  end,
  ["repeat"] = function(self, node)
    local cond, block = unpack(node, 2)
    do
      local _with_0 = self:block("repeat", self:line("until ", self:value(cond)))
      _with_0:stms(block)
      return _with_0
    end
  end,
  ["while"] = function(self, node)
    local _, cond, block = unpack(node)
    do
      local _with_0 = self:block(self:line("while ", self:value(cond), " do"))
      _with_0:stms(block)
      return _with_0
    end
  end,
  ["for"] = function(self, node)
    local _, name, bounds, block = unpack(node)
    local loop = self:line("for ", self:name(name), " = ", self:value({
      "explist",
      unpack(bounds)
    }), " do")
    do
      local _with_0 = self:block(loop)
      _with_0:declare({
        name
      })
      _with_0:stms(block)
      return _with_0
    end
  end,
  foreach = function(self, node)
    local _, names, exps, block = unpack(node)
    local loop
    do
      local _with_0 = self:line()
      _with_0:append("for ")
      loop = _with_0
    end
    do
      local _with_0 = self:block(loop)
      loop:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local name = names[_index_0]
          _accum_0[_len_0] = _with_0:name(name, false)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
      loop:append(" in ")
      loop:append_list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #exps do
          local exp = exps[_index_0]
          _accum_0[_len_0] = self:value(exp)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ",")
      loop:append(" do")
      _with_0:declare(names)
      _with_0:stms(block)
      return _with_0
    end
  end,
  export = function(self, node)
    local _, names = unpack(node)
    if type(names) == "string" then
      if names == "*" then
        self.export_all = true
      elseif names == "^" then
        self.export_proper = true
      end
    else
      self:declare(names)
    end
    return nil
  end,
  run = function(self, code)
    code:call(self)
    return nil
  end,
  group = function(self, node)
    return self:stms(node[2])
  end,
  ["do"] = function(self, node)
    do
      local _with_0 = self:block()
      _with_0:stms(node[2])
      return _with_0
    end
  end,
  noop = function(self) end
}
return {
  statement_compilers = statement_compilers
}

end

--------------------------------------
package.preload['moonscript.parse'] = function (...)

local util = require"moonscript.util"

local lpeg = require"lpeg"

local debug_grammar = false

local data = require"moonscript.data"
local types = require"moonscript.types"

local ntype = types.ntype

local dump = util.dump
local trim = util.trim

local getfenv = util.getfenv
local setfenv = util.setfenv
local unpack = util.unpack

local Stack = data.Stack

local function count_indent(str)
	local sum = 0
	for v in str:gmatch("[\t ]") do
		if v == ' ' then sum = sum + 1 end
		if v == '\t' then sum = sum + 4 end
	end
	return sum
end

local R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Ct, Cmt, Cg, Cb, Cc = lpeg.C, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc

lpeg.setmaxstack(10000)

local White = S" \t\r\n"^0
local _Space = S" \t"^0
local Break = P"\r"^-1 * P"\n"
local Stop = Break + -1
local Indent = C(S"\t "^0) / count_indent

local Comment = P"--" * (1 - S"\r\n")^0 * #Stop
local Space = _Space * Comment^-1
local SomeSpace = S" \t"^1 * Comment^-1

local SpaceBreak = Space * Break
local EmptyLine = SpaceBreak

local AlphaNum = R("az", "AZ", "09", "__")

local _Name = C(R("az", "AZ", "__") * AlphaNum^0)
local Name = Space * _Name

local Num = P"0x" * R("09", "af", "AF")^1 +
	(
		R"09"^1 * (P"." * R"09"^1)^-1 +
		P"." * R"09"^1
	) * (S"eE" * P"-"^-1 * R"09"^1)^-1

Num = Space * (Num / function(value) return {"number", value} end)

local FactorOp = Space * C(S"+-")
local TermOp = Space * C(S"*/%^")

local Shebang = P"#!" * P(1 - Stop)^0

-- can't have P(false) because it causes preceding patterns not to run
local Cut = P(function() return false end)

local function ensure(patt, finally)
	return patt * finally + finally * Cut
end

-- auto declare Proper variables with lpeg.V
local function wrap_env(fn)
	local env = getfenv(fn)
	local wrap_name = V

	if debug_grammar then
		local indent = 0
		local indent_char = "  "

		local function iprint(...)
			local args = {...}
			for i=1,#args do
				args[i] = tostring(args[i])
			end

			io.stdout:write(indent_char:rep(indent) .. table.concat(args, ", ") .. "\n")
		end

		wrap_name = function(name)
			local v = V(name)
			v = Cmt("", function()
				iprint("* " .. name)
				indent = indent + 1
				return true
			end) * Cmt(v, function(str, pos, ...)
				iprint(name, true)
				indent = indent - 1
				return true, ...
			end) + Cmt("", function()
				iprint(name, false)
				indent = indent - 1
				return false
			end)
			return v
		end
	end

	return setfenv(fn, setmetatable({}, {
		__index = function(self, name)
			local value = env[name]
			if value ~= nil then return value end

			if name:match"^[A-Z][A-Za-z0-9]*$" then
				local v = wrap_name(name)
				rawset(self, name, v)
				return v
			end
			error("unknown variable referenced: "..name)
		end
	}))
end

local function extract_line(str, start_pos)
	str = str:sub(start_pos)
	m = str:match"^(.-)\n"
	if m then return m end
	return str:match"^.-$"
end

local function mark(name)
	return function(...)
		return {name, ...}
	end
end

local function insert_pos(pos, value)
    if type(value) == "table" then
        value[-1] = pos
    end
    return value
end

local function pos(patt)
	return (lpeg.Cp() * patt) / insert_pos
end

local function got(what)
	return Cmt("", function(str, pos, ...)
		local cap = {...}
		print("++ got "..what, "["..extract_line(str, pos).."]")
		return true
	end)
end

local function flatten(tbl)
	if #tbl == 1 then
		return tbl[1]
	end
	return tbl
end

local function flatten_or_mark(name)
	return function(tbl)
		if #tbl == 1 then return tbl[1] end
		table.insert(tbl, 1, name)
		return tbl
	end
end

-- makes sure the last item in a chain is an index
local _chain_assignable = { index = true, dot = true, slice = true }

local function is_assignable(node)
	local t = ntype(node)
	return t == "self" or t == "value" or t == "self_class" or
		t == "chain" and _chain_assignable[ntype(node[#node])] or
		t == "table"
end

local function check_assignable(str, pos, value)
	if is_assignable(value) then
		return true, value
	end
	return false
end

local flatten_explist = flatten_or_mark"explist"
local function format_assign(lhs_exps, assign)
	if not assign then
		return flatten_explist(lhs_exps)
	end

	for _, assign_exp in ipairs(lhs_exps) do
		if not is_assignable(assign_exp) then
			error {assign_exp, "left hand expression is not assignable"}
		end
	end

	local t = ntype(assign)
	if t == "assign" then
		return {"assign", lhs_exps, unpack(assign, 2)}
	elseif t == "update" then
		return {"update", lhs_exps[1], unpack(assign, 2)}
	end

	error "unknown assign expression"
end

-- the if statement only takes a single lhs, so we wrap in table to git to
-- "assign" tuple format
local function format_single_assign(lhs, assign)
	if assign then
		return format_assign({lhs}, assign)
	end
	return lhs
end

local function sym(chars)
	return Space * chars
end

local function symx(chars)
	return chars
end

local function simple_string(delim, allow_interpolation)
	local inner = P('\\'..delim) + "\\\\" + (1 - P(delim))
	if allow_interpolation then
		inter = symx"#{" * V"Exp" * sym"}"
		inner = (C((inner - inter)^1) + inter / mark"interpolate")^0
	else
		inner = C(inner^0)
	end

	return C(symx(delim)) *
		inner * sym(delim) / mark"string"
end

local function wrap_func_arg(value)
	return {"call", {value}}
end

-- DOCME
local function flatten_func(callee, args)
	if #args == 0 then return callee end

	args = {"call", args}
	if ntype(callee) == "chain" then
		-- check for colon stub that needs arguments
		if ntype(callee[#callee]) == "colon_stub" then
			local stub = callee[#callee]
			stub[1] = "colon"
			table.insert(stub, args)
		else
			table.insert(callee, args)
		end

		return callee
	end

	return {"chain", callee, args}
end

local function flatten_string_chain(str, chain, args)
	if not chain then return str end
	return flatten_func({"chain", str, unpack(chain)}, args)
end

-- transforms a statement that has a line decorator
local function wrap_decorator(stm, dec)
	if not dec then return stm end
	return { "decorated", stm, dec }
end

-- wrap if statement if there is a conditional decorator
local function wrap_if(stm, cond)
	if cond then
		local pass, fail = unpack(cond)
		if fail then fail = {"else", {fail}} end
		return {"if", cond[2], {stm}, fail}
	end
	return stm
end

local function check_lua_string(str, pos, right, left)
	return #left == #right
end

-- :name in table literal
local function self_assign(name)
	return {{"key_literal", name}, name}
end

local err_msg = "Failed to parse:%s\n [%d] >>    %s"

local build_grammar = wrap_env(function()
	local _indent = Stack(0) -- current indent
	local _do_stack = Stack(0)

	local last_pos = 0 -- used to know where to report error
	local function check_indent(str, pos, indent)
		last_pos = pos
		return _indent:top() == indent
	end

	local function advance_indent(str, pos, indent)
		local top = _indent:top()
		if top ~= -1 and indent > _indent:top() then
			_indent:push(indent)
			return true
		end
	end

	local function push_indent(str, pos, indent)
		_indent:push(indent)
		return true
	end

	local function pop_indent(str, pos)
		if not _indent:pop() then error("unexpected outdent") end
		return true
	end


	local function check_do(str, pos, do_node)
		local top = _do_stack:top()
		if top == nil or top then
			return true, do_node
		end
		return false
	end

	local function disable_do(str_pos)
		_do_stack:push(false)
		return true
	end

	local function enable_do(str_pos)
		_do_stack:push(true)
		return true
	end

	local function pop_do(str, pos)
		if nil == _do_stack:pop() then error("unexpected do pop") end
		return true
	end

	local DisableDo = Cmt("", disable_do)
	local EnableDo = Cmt("", enable_do)
	local PopDo = Cmt("", pop_do)

	local keywords = {}
	local function key(chars)
		keywords[chars] = true
		return Space * chars * -AlphaNum
	end

	local function op(word)
		local patt = Space * C(word)
		if word:match("^%w*$") then
			keywords[word] = true
			patt = patt * -AlphaNum
		end
		return patt
	end

	-- make sure name is not a keyword
	local Name = Cmt(Name, function(str, pos, name)
		if keywords[name] then return false end
		return true
	end) / trim

	local SelfName = Space * "@" * (
		"@" * (_Name / mark"self_class" + Cc"self.__class") +
		_Name / mark"self" + Cc"self")

	local KeyName = SelfName + Space * _Name / mark"key_literal"

	local Name = SelfName + Name + Space * "..." / trim

	local g = lpeg.P{
		File,
		File = Shebang^-1 * (Block + Ct""),
		Block = Ct(Line * (Break^1 * Line)^0),
		CheckIndent = Cmt(Indent, check_indent), -- validates line is in correct indent
		Line = (CheckIndent * Statement + Space * #Stop),

		Statement = pos(
				Import + While + With + For + ForEach + Switch + Return +
				Local + Export + BreakLoop +
				Ct(ExpList) * (Update + Assign)^-1 / format_assign
			) * Space * ((
				-- statement decorators
				key"if" * Exp * (key"else" * Exp)^-1 * Space / mark"if" +
				key"unless" * Exp / mark"unless" +
				CompInner / mark"comprehension"
			) * Space)^-1 / wrap_decorator,

		Body = Space^-1 * Break * EmptyLine^0 * InBlock + Ct(Statement), -- either a statement, or an indented block

		Advance = #Cmt(Indent, advance_indent), -- Advances the indent, gives back whitespace for CheckIndent
		PushIndent = Cmt(Indent, push_indent),
		PreventIndent = Cmt(Cc(-1), push_indent),
		PopIndent = Cmt("", pop_indent),
		InBlock = Advance * Block * PopIndent,

		Local = key"local" * ((op"*" + op"^") / mark"declare_glob" + Ct(NameList) / mark"declare_with_shadows"),

		Import = key"import" * Ct(ImportNameList) * SpaceBreak^0 * key"from" * Exp / mark"import",
		ImportName = (sym"\\" * Ct(Cc"colon_stub" * Name) + Name),
		ImportNameList = SpaceBreak^0 * ImportName * ((SpaceBreak^1 + sym"," * SpaceBreak^0) * ImportName)^0,

		NameList = Name * (sym"," * Name)^0,

		BreakLoop = Ct(key"break"/trim) + Ct(key"continue"/trim),

		Return = key"return" * (ExpListLow/mark"explist" + C"") / mark"return",

		WithExp = Ct(ExpList) * Assign^-1 / format_assign,
		With = key"with" * DisableDo * ensure(WithExp, PopDo) * key"do"^-1 * Body / mark"with",

		Switch = key"switch" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Space^-1 * Break * SwitchBlock / mark"switch",

		SwitchBlock = EmptyLine^0 * Advance * Ct(SwitchCase * (Break^1 * SwitchCase)^0 * (Break^1 * SwitchElse)^-1) * PopIndent,
		SwitchCase = key"when" * Ct(ExpList) * key"then"^-1 * Body / mark"case",
		SwitchElse = key"else" * Body / mark"else",

		IfCond = Exp * Assign^-1 / format_single_assign,

		If = key"if" * IfCond * key"then"^-1 * Body *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"elseif" * pos(IfCond) * key"then"^-1 * Body / mark"elseif")^0 *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"else" * Body / mark"else")^-1 / mark"if",

		Unless = key"unless" * IfCond * key"then"^-1 * Body *
			((Break * CheckIndent)^-1 * EmptyLine^0 * key"else" * Body / mark"else")^-1 / mark"unless",

		While = key"while" * DisableDo * ensure(Exp, PopDo) * key"do"^-1 * Body / mark"while",

		For = key"for" * DisableDo * ensure(Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1), PopDo) *
			key"do"^-1 * Body / mark"for",

		ForEach = key"for" * Ct(AssignableNameList) * key"in" * DisableDo * ensure(Ct(sym"*" * Exp / mark"unpack" + ExpList), PopDo) * key"do"^-1 * Body / mark"foreach",

		Do = key"do" * Body / mark"do",

		Comprehension = sym"[" * Exp * CompInner * sym"]" / mark"comprehension",

		TblComprehension = sym"{" * Ct(Exp * (sym"," * Exp)^-1) * CompInner * sym"}" / mark"tblcomprehension",

		CompInner = Ct((CompForEach + CompFor) * CompClause^0),
		CompForEach = key"for" * Ct(NameList) * key"in" * (sym"*" * Exp / mark"unpack" + Exp) / mark"foreach",
		CompFor = key "for" * Name * sym"=" * Ct(Exp * sym"," * Exp * (sym"," * Exp)^-1) / mark"for",
		CompClause = CompFor + CompForEach + key"when" * Exp / mark"when",

		Assign = sym"=" * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark"assign",
		Update = ((sym"..=" + sym"+=" + sym"-=" + sym"*=" + sym"/=" + sym"%=" + sym"or=" + sym"and=") / trim) * Exp / mark"update",

		-- we can ignore precedence for now
		OtherOps = op"or" + op"and" + op"<=" + op">=" + op"~=" + op"!=" + op"==" + op".." + op"<" + op">",

		Assignable = Cmt(DotChain + Chain, check_assignable) + Name,
		AssignableList = Assignable * (sym"," * Assignable)^0,

		Exp = Ct(Value * ((OtherOps + FactorOp + TermOp) * Value)^0) / flatten_or_mark"exp",

		-- Exp = Ct(Factor * (OtherOps * Factor)^0) / flatten_or_mark"exp",
		-- Factor = Ct(Term * (FactorOp * Term)^0) / flatten_or_mark"exp",
		-- Term = Ct(Value * (TermOp * Value)^0) / flatten_or_mark"exp",

		SimpleValue =
			If + Unless +
			Switch +
			With +
			ClassDecl +
			ForEach + For + While +
			Cmt(Do, check_do) +
			sym"-" * -SomeSpace * Exp / mark"minus" +
			sym"#" * Exp / mark"length" +
			key"not" * Exp / mark"not" +
			TblComprehension +
			TableLit +
			Comprehension +
			FunLit +
			Num,

		ChainValue = -- a function call or an object access
			StringChain +
			((Chain + DotChain + Callable) * Ct(InvokeArgs^-1)) / flatten_func,

		Value = pos(
			SimpleValue +
			Ct(KeyValueList) / mark"table" +
			ChainValue),

		SliceValue = SimpleValue + ChainValue,

		StringChain = String *
			(Ct((ColonCall + ColonSuffix) * ChainTail^-1) * Ct(InvokeArgs^-1))^-1 / flatten_string_chain,

		String = Space * DoubleString + Space * SingleString + LuaString,
		SingleString = simple_string("'"),
		DoubleString = simple_string('"', true),

		LuaString = Cg(LuaStringOpen, "string_open") * Cb"string_open" * Break^-1 *
			C((1 - Cmt(C(LuaStringClose) * Cb"string_open", check_lua_string))^0) *
			LuaStringClose / mark"string",

		LuaStringOpen = sym"[" * P"="^0 * "[" / trim,
		LuaStringClose = "]" * P"="^0 * "]",

		Callable = Name + Parens / mark"parens",
		Parens = sym"(" * Exp * sym")",

		FnArgs = symx"(" * Ct(ExpList^-1) * sym")" + sym"!" * -P"=" * Ct"",

		ChainTail = ChainItem^1 * ColonSuffix^-1 + ColonSuffix,

		-- a list of funcalls and indexes on a callable
		Chain = Callable * ChainTail / mark"chain",

		-- shorthand dot call for use in with statement
		DotChain =
			(sym"." * Cc(-1) * (_Name / mark"dot") * ChainTail^-1) / mark"chain" +
			(sym"\\" * Cc(-1) * (
				(_Name * Invoke / mark"colon") * ChainTail^-1 +
				(_Name / mark"colon_stub")
			)) / mark"chain",

		ChainItem =
			Invoke +
			Slice +
			symx"[" * Exp/mark"index" * sym"]" +
			symx"." * _Name/mark"dot" +
			ColonCall,

		Slice = symx"[" * (SliceValue + Cc(1)) * sym"," * (SliceValue + Cc"")  *
			(sym"," * SliceValue)^-1 *sym"]" / mark"slice",

		ColonCall = symx"\\" * (_Name * Invoke) / mark"colon",
		ColonSuffix = symx"\\" * _Name / mark"colon_stub",

		Invoke = FnArgs/mark"call" +
			SingleString / wrap_func_arg +
			DoubleString / wrap_func_arg,

		TableValue = KeyValue + Ct(Exp),

		TableLit = sym"{" * Ct(
				TableValueList^-1 * sym","^-1 *
				(SpaceBreak * TableLitLine * (sym","^-1 * SpaceBreak * TableLitLine)^0 * sym","^-1)^-1
			) * White * sym"}" / mark"table",

		TableValueList = TableValue * (sym"," * TableValue)^0,
		TableLitLine = PushIndent * ((TableValueList * PopIndent) + (PopIndent * Cut)) + Space,

		-- the unbounded table
		TableBlockInner = Ct(KeyValueLine * (SpaceBreak^1 * KeyValueLine)^0),
		TableBlock = SpaceBreak^1 * Advance * ensure(TableBlockInner, PopIndent) / mark"table",

		ClassDecl = key"class" * -P":" * (Assignable + Cc(nil)) * (key"extends" * PreventIndent * ensure(Exp, PopIndent) + C"")^-1 * (ClassBlock + Ct("")) / mark"class",

		ClassBlock = SpaceBreak^1 * Advance *
			Ct(ClassLine * (SpaceBreak^1 * ClassLine)^0) * PopIndent,
		ClassLine = CheckIndent * ((
				KeyValueList / mark"props" +
				Statement / mark"stm" +
				Exp / mark"stm"
			) * sym","^-1),

		Export = key"export" * (
			Cc"class" * ClassDecl +
			op"*" + op"^" +
			Ct(NameList) * (sym"=" * Ct(ExpListLow))^-1) / mark"export",

		KeyValue = (sym":" * -SomeSpace *  Name) / self_assign + Ct((KeyName + sym"[" * Exp * sym"]" + DoubleString + SingleString) * symx":" * (Exp + TableBlock)),
		KeyValueList = KeyValue * (sym"," * KeyValue)^0,
		KeyValueLine = CheckIndent * KeyValueList * sym","^-1,

		FnArgsDef = sym"(" * Ct(FnArgDefList^-1) *
			(key"using" * Ct(NameList + Space * "nil") + Ct"") *
			sym")" + Ct"" * Ct"",

		FnArgDefList = FnArgDef * (sym"," * FnArgDef)^0,
		FnArgDef = Ct(Name * (sym"=" * Exp)^-1),

		FunLit = FnArgsDef *
			(sym"->" * Cc"slim" + sym"=>" * Cc"fat") *
			(Body + Ct"") / mark"fndef",

		NameList = Name * (sym"," * Name)^0,
		NameOrDestructure = Name + TableLit,
		AssignableNameList = NameOrDestructure * (sym"," * NameOrDestructure)^0,

		ExpList = Exp * (sym"," * Exp)^0,
		ExpListLow = Exp * ((sym"," + sym";") * Exp)^0,

		InvokeArgs = -P"-" * (ExpList * (sym"," * (TableBlock + SpaceBreak * Advance * ArgBlock * TableBlock^-1) + TableBlock)^-1 + TableBlock),
		ArgBlock = ArgLine * (sym"," * SpaceBreak * ArgLine)^0 * PopIndent,
		ArgLine = CheckIndent * ExpList
	}

	return {
		_g = White * g * White * -1,
		match = function(self, str, ...)

			local pos_to_line = function(pos)
				return util.pos_to_line(str, pos)
			end

			local get_line = function(num)
				return util.get_line(str, num)
			end

			local tree
			local pass, err = pcall(function(...)
				tree = self._g:match(str, ...)
			end, ...)

			-- regular error, let it bubble up
			if type(err) == "string" then
				error(err)
			end

			if not tree then
				local pos = last_pos
				local msg

				if err then
					local node
					node, msg = unpack(err)
					msg = msg and " " .. msg
					pos = node[-1]
				end

				local line_no = pos_to_line(pos)
				local line_str = get_line(line_no) or ""

				return nil, err_msg:format(msg or "", line_no, trim(line_str))
			end
			return tree
		end
	}
end)

return {
	extract_line = extract_line,

	-- parse a string
	-- returns tree, or nil and error message
	string = function (str)
		local g = build_grammar()
		return g:match(str)
	end
}


end

--------------------------------------
package.preload['moonscript'] = function (...)
return require "moonscript.init"

end

--------------------------------------
package.preload['moonscript.transform.names'] = function (...)
local build
do
  local _obj_0 = require("moonscript.types")
  build = _obj_0.build
end
local unpack
do
  local _obj_0 = require("moonscript.util")
  unpack = _obj_0.unpack
end
local LocalName
do
  local _base_0 = {
    get_name = function(self)
      return self.name
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name)
      self.name = name
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "LocalName"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  LocalName = _class_0
end
local NameProxy
do
  local _base_0 = {
    get_name = function(self, scope, dont_put)
      if dont_put == nil then
        dont_put = true
      end
      if not self.name then
        self.name = scope:free_name(self.prefix, dont_put)
      end
      return self.name
    end,
    chain = function(self, ...)
      local items
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local i = _list_0[_index_0]
          if type(i) == "string" then
            _accum_0[_len_0] = {
              "dot",
              i
            }
          else
            _accum_0[_len_0] = i
          end
          _len_0 = _len_0 + 1
        end
        items = _accum_0
      end
      return build.chain({
        base = self,
        unpack(items)
      })
    end,
    index = function(self, key)
      return build.chain({
        base = self,
        {
          "index",
          key
        }
      })
    end,
    __tostring = function(self)
      if self.name then
        return ("name<%s>"):format(self.name)
      else
        return ("name<prefix(%s)>"):format(self.prefix)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, prefix)
      self.prefix = prefix
      self[1] = "temp_name"
    end,
    __base = _base_0,
    __name = "NameProxy"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  NameProxy = _class_0
end
return {
  NameProxy = NameProxy,
  LocalName = LocalName
}

end

--------------------------------------
package.preload['moonscript.util'] = function (...)
local concat
do
  local _obj_0 = table
  concat = _obj_0.concat
end
local unpack = unpack or table.unpack
local type = type
local moon = {
  is_object = function(value)
    return type(value) == "table" and value.__class
  end,
  is_a = function(thing, t)
    if not (type(thing) == "table") then
      return false
    end
    local cls = thing.__class
    while cls do
      if cls == t then
        return true
      end
      cls = cls.__parent
    end
    return false
  end,
  type = function(value)
    local base_type = type(value)
    if base_type == "table" then
      local cls = value.__class
      if cls then
        return cls
      end
    end
    return base_type
  end
}
local pos_to_line
pos_to_line = function(str, pos)
  local line = 1
  for _ in str:sub(1, pos):gmatch("\n") do
    line = line + 1
  end
  return line
end
local trim
trim = function(str)
  return str:match("^%s*(.-)%s*$")
end
local get_line
get_line = function(str, line_num)
  for line in str:gmatch("([^\n]*)\n?") do
    if line_num == 1 then
      return line
    end
    line_num = line_num - 1
  end
end
local get_closest_line
get_closest_line = function(str, line_num)
  local line = get_line(str, line_num)
  if (not line or trim(line) == "") and line_num > 1 then
    return get_closest_line(str, line_num - 1)
  else
    return line, line_num
  end
end
local reversed
reversed = function(seq)
  return coroutine.wrap(function()
    for i = #seq, 1, -1 do
      coroutine.yield(i, seq[i])
    end
  end)
end
local split
split = function(str, delim)
  if str == "" then
    return { }
  end
  str = str .. delim
  local _accum_0 = { }
  local _len_0 = 1
  for m in str:gmatch("(.-)" .. delim) do
    _accum_0[_len_0] = m
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local dump
dump = function(what)
  local seen = { }
  local _dump
  _dump = function(what, depth)
    if depth == nil then
      depth = 0
    end
    local t = type(what)
    if t == "string" then
      return '"' .. what .. '"\n'
    elseif t == "table" then
      if seen[what] then
        return "recursion(" .. tostring(what) .. ")...\n"
      end
      seen[what] = true
      depth = depth + 1
      local lines
      do
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in pairs(what) do
          _accum_0[_len_0] = (" "):rep(depth * 4) .. "[" .. tostring(k) .. "] = " .. _dump(v, depth)
          _len_0 = _len_0 + 1
        end
        lines = _accum_0
      end
      seen[what] = false
      return "{\n" .. concat(lines) .. (" "):rep((depth - 1) * 4) .. "}\n"
    else
      return tostring(what) .. "\n"
    end
  end
  return _dump(what)
end
local debug_posmap
debug_posmap = function(posmap, moon_code, lua_code)
  local tuples
  do
    local _accum_0 = { }
    local _len_0 = 1
    for k, v in pairs(posmap) do
      _accum_0[_len_0] = {
        k,
        v
      }
      _len_0 = _len_0 + 1
    end
    tuples = _accum_0
  end
  table.sort(tuples, function(a, b)
    return a[1] < b[1]
  end)
  local lines
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #tuples do
      local pair = tuples[_index_0]
      local lua_line, pos = unpack(pair)
      local moon_line = pos_to_line(moon_code, pos)
      local lua_text = get_line(lua_code, lua_line)
      local moon_text = get_closest_line(moon_code, moon_line)
      local _value_0 = tostring(pos) .. "\t " .. tostring(lua_line) .. ":[ " .. tostring(trim(lua_text)) .. " ] >> " .. tostring(moon_line) .. ":[ " .. tostring(trim(moon_text)) .. " ]"
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    lines = _accum_0
  end
  return concat(lines, "\n")
end
local setfenv = setfenv or function(fn, env)
  local name
  local i = 1
  while true do
    name = debug.getupvalue(fn, i)
    if not name or name == "_ENV" then
      break
    end
    i = i + 1
  end
  if name then
    debug.upvaluejoin(fn, i, (function()
      return env
    end), 1)
  end
  return fn
end
local getfenv = getfenv or function(fn)
  local i = 1
  while true do
    local name, val = debug.getupvalue(fn, i)
    if not (name) then
      break
    end
    if name == "_ENV" then
      return val
    end
    i = i + 1
  end
  return nil
end
local get_options
get_options = function(...)
  local count = select("#", ...)
  local opts = select(count, ...)
  if type(opts) == "table" then
    return opts, unpack({
      ...
    }, nil, count - 1)
  else
    return { }, ...
  end
end
return {
  moon = moon,
  pos_to_line = pos_to_line,
  get_closest_line = get_closest_line,
  get_line = get_line,
  reversed = reversed,
  trim = trim,
  split = split,
  dump = dump,
  debug_posmap = debug_posmap,
  getfenv = getfenv,
  setfenv = setfenv,
  get_options = get_options,
  unpack = unpack
}

end

--------------------------------------
package.preload['moonscript.types'] = function (...)
local util = require("moonscript.util")
local Set
do
  local _obj_0 = require("moonscript.data")
  Set = _obj_0.Set
end
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local unpack
unpack = util.unpack
local manual_return = Set({
  "foreach",
  "for",
  "while",
  "return"
})
local cascading = Set({
  "if",
  "unless",
  "with",
  "switch",
  "class",
  "do"
})
local ntype
ntype = function(node)
  local _exp_0 = type(node)
  if "nil" == _exp_0 then
    return "nil"
  elseif "table" == _exp_0 then
    return node[1]
  else
    return "value"
  end
end
local mtype
do
  local moon_type = util.moon.type
  mtype = function(val)
    local mt = getmetatable(val)
    if mt and mt.smart_node then
      return "table"
    end
    return moon_type(val)
  end
end
local has_value
has_value = function(node)
  if ntype(node) == "chain" then
    local ctype = ntype(node[#node])
    return ctype ~= "call" and ctype ~= "colon"
  else
    return true
  end
end
local is_value
is_value = function(stm)
  local compile = require("moonscript.compile")
  local transform = require("moonscript.transform")
  return compile.Block:is_value(stm) or transform.Value:can_transform(stm)
end
local comprehension_has_value
comprehension_has_value = function(comp)
  return is_value(comp[2])
end
local value_is_singular
value_is_singular = function(node)
  return type(node) ~= "table" or node[1] ~= "exp" or #node == 2
end
local is_slice
is_slice = function(node)
  return ntype(node) == "chain" and ntype(node[#node]) == "slice"
end
local t = { }
local node_types = {
  class = {
    {
      "name",
      "Tmp"
    },
    {
      "body",
      t
    }
  },
  fndef = {
    {
      "args",
      t
    },
    {
      "whitelist",
      t
    },
    {
      "arrow",
      "slim"
    },
    {
      "body",
      t
    }
  },
  foreach = {
    {
      "names",
      t
    },
    {
      "iter"
    },
    {
      "body",
      t
    }
  },
  ["for"] = {
    {
      "name"
    },
    {
      "bounds",
      t
    },
    {
      "body",
      t
    }
  },
  ["while"] = {
    {
      "cond",
      t
    },
    {
      "body",
      t
    }
  },
  assign = {
    {
      "names",
      t
    },
    {
      "values",
      t
    }
  },
  declare = {
    {
      "names",
      t
    }
  },
  ["if"] = {
    {
      "cond",
      t
    },
    {
      "then",
      t
    }
  }
}
local build_table
build_table = function()
  local key_table = { }
  for node_name, args in pairs(node_types) do
    local index = { }
    for i, tuple in ipairs(args) do
      local prop_name = tuple[1]
      index[prop_name] = i + 1
    end
    key_table[node_name] = index
  end
  return key_table
end
local key_table = build_table()
local make_builder
make_builder = function(name)
  local spec = node_types[name]
  if not spec then
    error("don't know how to build node: " .. name)
  end
  return function(props)
    if props == nil then
      props = { }
    end
    local node = {
      name
    }
    for i, arg in ipairs(spec) do
      local key, default_value = unpack(arg)
      local val
      if props[key] then
        val = props[key]
      else
        val = default_value
      end
      if val == t then
        val = { }
      end
      node[i + 1] = val
    end
    return node
  end
end
local build = nil
build = setmetatable({
  group = function(body)
    if body == nil then
      body = { }
    end
    return {
      "group",
      body
    }
  end,
  ["do"] = function(body)
    return {
      "do",
      body
    }
  end,
  assign_one = function(name, value)
    return build.assign({
      names = {
        name
      },
      values = {
        value
      }
    })
  end,
  table = function(tbl)
    if tbl == nil then
      tbl = { }
    end
    for _index_0 = 1, #tbl do
      local tuple = tbl[_index_0]
      if type(tuple[1]) == "string" then
        tuple[1] = {
          "key_literal",
          tuple[1]
        }
      end
    end
    return {
      "table",
      tbl
    }
  end,
  block_exp = function(body)
    return {
      "block_exp",
      body
    }
  end,
  chain = function(parts)
    local base = parts.base or error("expecting base property for chain")
    local node = {
      "chain",
      base
    }
    for _index_0 = 1, #parts do
      local part = parts[_index_0]
      insert(node, part)
    end
    return node
  end
}, {
  __index = function(self, name)
    self[name] = make_builder(name)
    return rawget(self, name)
  end
})
local smart_node_mt = setmetatable({ }, {
  __index = function(self, node_type)
    local index = key_table[node_type]
    local mt = {
      smart_node = true,
      __index = function(node, key)
        if index[key] then
          return rawget(node, index[key])
        elseif type(key) == "string" then
          return error("unknown key: `" .. key .. "` on node type: `" .. ntype(node) .. "`")
        end
      end,
      __newindex = function(node, key, value)
        if index[key] then
          key = index[key]
        end
        return rawset(node, key, value)
      end
    }
    self[node_type] = mt
    return mt
  end
})
local smart_node
smart_node = function(node)
  return setmetatable(node, smart_node_mt[ntype(node)])
end
return {
  ntype = ntype,
  smart_node = smart_node,
  build = build,
  is_value = is_value,
  is_slice = is_slice,
  manual_return = manual_return,
  cascading = cascading,
  value_is_singular = value_is_singular,
  comprehension_has_value = comprehension_has_value,
  has_value = has_value,
  mtype = mtype
}

end

--------------------------------------
package.preload['moonscript.line_tables'] = function (...)
return { }

end

--------------------------------------
package.preload['moonscript.data'] = function (...)
local concat, remove, insert
do
  local _obj_0 = table
  concat, remove, insert = _obj_0.concat, _obj_0.remove, _obj_0.insert
end
local Set
Set = function(items)
  local self = { }
  for _index_0 = 1, #items do
    local key = items[_index_0]
    self[key] = true
  end
  return self
end
local Stack
do
  local _base_0 = {
    __tostring = function(self)
      return "<Stack {" .. concat(self, ", ") .. "}>"
    end,
    pop = function(self)
      return remove(self)
    end,
    push = function(self, value)
      insert(self, value)
      return value
    end,
    top = function(self)
      return self[#self]
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, ...)
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local v = _list_0[_index_0]
        self:push(v)
      end
      return nil
    end,
    __base = _base_0,
    __name = "Stack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Stack = _class_0
end
local lua_keywords = Set({
  'and',
  'break',
  'do',
  'else',
  'elseif',
  'end',
  'false',
  'for',
  'function',
  'if',
  'in',
  'local',
  'nil',
  'not',
  'or',
  'repeat',
  'return',
  'then',
  'true',
  'until',
  'while'
})
return {
  Set = Set,
  Stack = Stack,
  lua_keywords = lua_keywords
}

end

--------------------------------------
package.preload['moonscript.errors'] = function (...)
local util = require("moonscript.util")
local lpeg = require("lpeg")
local concat, insert
do
  local _obj_0 = table
  concat, insert = _obj_0.concat, _obj_0.insert
end
local split, pos_to_line
split, pos_to_line = util.split, util.pos_to_line
local user_error
user_error = function(...)
  return error({
    "user-error",
    ...
  })
end
local lookup_line
lookup_line = function(fname, pos, cache)
  if not cache[fname] then
    do
      local _with_0 = io.open(fname)
      cache[fname] = _with_0:read("*a")
      _with_0:close()
    end
  end
  return pos_to_line(cache[fname], pos)
end
local reverse_line_number
reverse_line_number = function(fname, line_table, line_num, cache)
  for i = line_num, 0, -1 do
    if line_table[i] then
      return lookup_line(fname, line_table[i], cache)
    end
  end
  return "unknown"
end
local truncate_traceback
truncate_traceback = function(traceback, chunk_func)
  if chunk_func == nil then
    chunk_func = "moonscript_chunk"
  end
  traceback = split(traceback, "\n")
  local stop = #traceback
  while stop > 1 do
    if traceback[stop]:match(chunk_func) then
      break
    end
    stop = stop - 1
  end
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _max_0 = stop
    for _index_0 = 1, _max_0 < 0 and #traceback + _max_0 or _max_0 do
      local t = traceback[_index_0]
      _accum_0[_len_0] = t
      _len_0 = _len_0 + 1
    end
    traceback = _accum_0
  end
  local rep = "function '" .. chunk_func .. "'"
  traceback[#traceback] = traceback[#traceback]:gsub(rep, "main chunk")
  return concat(traceback, "\n")
end
local rewrite_traceback
rewrite_traceback = function(text, err)
  local line_tables = require("moonscript.line_tables")
  local V, S, Ct, C
  V, S, Ct, C = lpeg.V, lpeg.S, lpeg.Ct, lpeg.C
  local header_text = "stack traceback:"
  local Header, Line = V("Header"), V("Line")
  local Break = lpeg.S("\n")
  local g = lpeg.P({
    Header,
    Header = header_text * Break * Ct(Line ^ 1),
    Line = "\t" * C((1 - Break) ^ 0) * (Break + -1)
  })
  local cache = { }
  local rewrite_single
  rewrite_single = function(trace)
    local fname, line, msg = trace:match('^%[string "(.-)"]:(%d+): (.*)$')
    local tbl = line_tables[fname]
    if fname and tbl then
      return concat({
        fname,
        ":",
        reverse_line_number(fname, tbl, line, cache),
        ": ",
        "(",
        line,
        ") ",
        msg
      })
    else
      return trace
    end
  end
  err = rewrite_single(err)
  local match = g:match(text)
  if not (match) then
    return nil
  end
  for i, trace in ipairs(match) do
    match[i] = rewrite_single(trace)
  end
  return concat({
    "moon: " .. err,
    header_text,
    "\t" .. concat(match, "\n\t")
  }, "\n")
end
return {
  rewrite_traceback = rewrite_traceback,
  truncate_traceback = truncate_traceback,
  user_error = user_error,
  reverse_line_number = reverse_line_number
}

end

--------------------------------------
package.preload['moonscript.transform'] = function (...)
local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local reversed, unpack
reversed, unpack = util.reversed, util.unpack
local ntype, mtype, build, smart_node, is_slice, value_is_singular
ntype, mtype, build, smart_node, is_slice, value_is_singular = types.ntype, types.mtype, types.build, types.smart_node, types.is_slice, types.value_is_singular
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local NameProxy, LocalName
do
  local _obj_0 = require("moonscript.transform.names")
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName
end
local destructure = require("moonscript.transform.destructure")
local NOOP = {
  "noop"
}
local Run, apply_to_last, is_singular, extract_declarations, expand_elseif_assign, constructor_name, with_continue_listener, Transformer, construct_comprehension, Statement, Accumulator, default_accumulator, implicitly_return, Value
do
  local _base_0 = {
    call = function(self, state)
      return self.fn(state)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self[1] = "run"
    end,
    __base = _base_0,
    __name = "Run"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Run = _class_0
end
apply_to_last = function(stms, fn)
  local last_exp_id = 0
  for i = #stms, 1, -1 do
    local stm = stms[i]
    if stm and mtype(stm) ~= Run then
      last_exp_id = i
      break
    end
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i, stm in ipairs(stms) do
      if i == last_exp_id then
        _accum_0[_len_0] = {
          "transform",
          stm,
          fn
        }
      else
        _accum_0[_len_0] = stm
      end
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
is_singular = function(body)
  if #body ~= 1 then
    return false
  end
  if "group" == ntype(body) then
    return is_singular(body[2])
  else
    return body[1]
  end
end
extract_declarations = function(self, body, start, out)
  if body == nil then
    body = self.current_stms
  end
  if start == nil then
    start = self.current_stm_i + 1
  end
  if out == nil then
    out = { }
  end
  for i = start, #body do
    local _continue_0 = false
    repeat
      local stm = body[i]
      if stm == nil then
        _continue_0 = true
        break
      end
      stm = self.transform.statement(stm)
      body[i] = stm
      local _exp_0 = stm[1]
      if "assign" == _exp_0 or "declare" == _exp_0 then
        local _list_0 = stm[2]
        for _index_0 = 1, #_list_0 do
          local name = _list_0[_index_0]
          if type(name) == "string" then
            insert(out, name)
          end
        end
      elseif "group" == _exp_0 then
        extract_declarations(self, stm[2], 1, out)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return out
end
expand_elseif_assign = function(ifstm)
  for i = 4, #ifstm do
    local case = ifstm[i]
    if ntype(case) == "elseif" and ntype(case[2]) == "assign" then
      local split = {
        unpack(ifstm, 1, i - 1)
      }
      insert(split, {
        "else",
        {
          {
            "if",
            case[2],
            case[3],
            unpack(ifstm, i + 1)
          }
        }
      })
      return split
    end
  end
  return ifstm
end
constructor_name = "new"
with_continue_listener = function(body)
  local continue_name = nil
  return {
    Run(function(self)
      return self:listen("continue", function()
        if not (continue_name) then
          continue_name = NameProxy("continue")
          self:put_name(continue_name)
        end
        return continue_name
      end)
    end),
    build.group(body),
    Run(function(self)
      if not (continue_name) then
        return 
      end
      self:put_name(continue_name, nil)
      return self:splice(function(lines)
        return {
          {
            "assign",
            {
              continue_name
            },
            {
              "false"
            }
          },
          {
            "repeat",
            "true",
            {
              lines,
              {
                "assign",
                {
                  continue_name
                },
                {
                  "true"
                }
              }
            }
          },
          {
            "if",
            {
              "not",
              continue_name
            },
            {
              {
                "break"
              }
            }
          }
        }
      end)
    end)
  }
end
do
  local _base_0 = {
    transform_once = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      local transformer = self.transformers[ntype(node)]
      if transformer then
        return transformer(scope, node, ...) or node
      else
        return node
      end
    end,
    transform = function(self, scope, node, ...)
      if self.seen_nodes[node] then
        return node
      end
      self.seen_nodes[node] = true
      while true do
        local transformer = self.transformers[ntype(node)]
        local res
        if transformer then
          res = transformer(scope, node, ...) or node
        else
          res = node
        end
        if res == node then
          return node
        end
        node = res
      end
      return node
    end,
    bind = function(self, scope)
      return function(...)
        return self:transform(scope, ...)
      end
    end,
    __call = function(self, ...)
      return self:transform(...)
    end,
    can_transform = function(self, node)
      return self.transformers[ntype(node)] ~= nil
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, transformers)
      self.transformers = transformers
      self.seen_nodes = setmetatable({ }, {
        __mode = "k"
      })
    end,
    __base = _base_0,
    __name = "Transformer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Transformer = _class_0
end
construct_comprehension = function(inner, clauses)
  local current_stms = inner
  for _, clause in reversed(clauses) do
    local t = clause[1]
    local _exp_0 = t
    if "for" == _exp_0 then
      local name, bounds
      _, name, bounds = clause[1], clause[2], clause[3]
      current_stms = {
        "for",
        name,
        bounds,
        current_stms
      }
    elseif "foreach" == _exp_0 then
      local names, iter
      _, names, iter = clause[1], clause[2], clause[3]
      current_stms = {
        "foreach",
        names,
        {
          iter
        },
        current_stms
      }
    elseif "when" == _exp_0 then
      local cond
      _, cond = clause[1], clause[2]
      current_stms = {
        "if",
        cond,
        current_stms
      }
    else
      current_stms = error("Unknown comprehension clause: " .. t)
    end
    current_stms = {
      current_stms
    }
  end
  return current_stms[1]
end
Statement = Transformer({
  transform = function(self, tuple)
    local _, node, fn
    _, node, fn = tuple[1], tuple[2], tuple[3]
    return fn(node)
  end,
  root_stms = function(self, body)
    return apply_to_last(body, implicitly_return(self))
  end,
  ["return"] = function(self, node)
    node[2] = Value:transform_once(self, node[2])
    if "block_exp" == ntype(node[2]) then
      local block_exp = node[2]
      local block_body = block_exp[2]
      local idx = #block_body
      node[2] = block_body[idx]
      block_body[idx] = node
      return build.group(block_body)
    end
    return node
  end,
  declare_glob = function(self, node)
    local names = extract_declarations(self)
    if node[2] == "^" then
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #names do
          local _continue_0 = false
          repeat
            local name = names[_index_0]
            if not (name:match("^%u")) then
              _continue_0 = true
              break
            end
            local _value_0 = name
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        names = _accum_0
      end
    end
    return {
      "declare",
      names
    }
  end,
  assign = function(self, node)
    local names, values = unpack(node, 2)
    local num_values = #values
    local num_names = #values
    if num_names == 1 and num_values == 1 then
      local first_value = values[1]
      local first_name = names[1]
      local _exp_0 = ntype(first_value)
      if "block_exp" == _exp_0 then
        local block_body = first_value[2]
        local idx = #block_body
        block_body[idx] = build.assign_one(first_name, block_body[idx])
        return build.group({
          {
            "declare",
            {
              first_name
            }
          },
          {
            "do",
            block_body
          }
        })
      elseif "comprehension" == _exp_0 or "tblcomprehension" == _exp_0 or "foreach" == _exp_0 or "for" == _exp_0 or "while" == _exp_0 then
        return build.assign_one(first_name, Value:transform_once(self, first_value))
      end
    end
    local transformed
    if num_values == 1 then
      local value = values[1]
      local t = ntype(value)
      if t == "decorated" then
        value = self.transform.statement(value)
        t = ntype(value)
      end
      if types.cascading[t] then
        local ret
        ret = function(stm)
          if types.is_value(stm) then
            return {
              "assign",
              names,
              {
                stm
              }
            }
          else
            return stm
          end
        end
        transformed = build.group({
          {
            "declare",
            names
          },
          self.transform.statement(value, ret, node)
        })
      end
    end
    node = transformed or node
    if destructure.has_destructure(names) then
      return destructure.split_assign(self, node)
    end
    return node
  end,
  continue = function(self, node)
    local continue_name = self:send("continue")
    if not (continue_name) then
      error("continue must be inside of a loop")
    end
    return build.group({
      build.assign_one(continue_name, "true"),
      {
        "break"
      }
    })
  end,
  export = function(self, node)
    if #node > 2 then
      if node[2] == "class" then
        local cls = smart_node(node[3])
        return build.group({
          {
            "export",
            {
              cls.name
            }
          },
          cls
        })
      else
        return build.group({
          {
            "export",
            node[2]
          },
          build.assign({
            names = node[2],
            values = node[3]
          })
        })
      end
    else
      return nil
    end
  end,
  update = function(self, node)
    local _, name, op, exp = unpack(node)
    local op_final = op:match("^(.+)=$")
    if not op_final then
      error("Unknown op: " .. op)
    end
    if not (value_is_singular(exp)) then
      exp = {
        "parens",
        exp
      }
    end
    return build.assign_one(name, {
      "exp",
      name,
      op_final,
      exp
    })
  end,
  import = function(self, node)
    local _, names, source = unpack(node)
    local table_values
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #names do
        local name = names[_index_0]
        local dest_val
        if ntype(name) == "colon_stub" then
          dest_val = name[2]
        else
          dest_val = name
        end
        local _value_0 = {
          {
            "key_literal",
            name
          },
          dest_val
        }
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
      end
      table_values = _accum_0
    end
    local dest = {
      "table",
      table_values
    }
    return {
      "assign",
      {
        dest
      },
      {
        source
      },
      [-1] = node[-1]
    }
  end,
  comprehension = function(self, node, action)
    local _, exp, clauses = unpack(node)
    action = action or function(exp)
      return {
        exp
      }
    end
    return construct_comprehension(action(exp), clauses)
  end,
  ["do"] = function(self, node, ret)
    if ret then
      node[2] = apply_to_last(node[2], ret)
    end
    return node
  end,
  decorated = function(self, node)
    local stm, dec = unpack(node, 2)
    local wrapped
    local _exp_0 = dec[1]
    if "if" == _exp_0 then
      local cond, fail = unpack(dec, 2)
      if fail then
        fail = {
          "else",
          {
            fail
          }
        }
      end
      wrapped = {
        "if",
        cond,
        {
          stm
        },
        fail
      }
    elseif "unless" == _exp_0 then
      wrapped = {
        "unless",
        dec[2],
        {
          stm
        }
      }
    elseif "comprehension" == _exp_0 then
      wrapped = {
        "comprehension",
        stm,
        dec[2]
      }
    else
      wrapped = error("Unknown decorator " .. dec[1])
    end
    if ntype(stm) == "assign" then
      wrapped = build.group({
        build.declare({
          names = (function()
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = stm[2]
            for _index_0 = 1, #_list_0 do
              local name = _list_0[_index_0]
              if type(name) == "string" then
                _accum_0[_len_0] = name
                _len_0 = _len_0 + 1
              end
            end
            return _accum_0
          end)()
        }),
        wrapped
      })
    end
    return wrapped
  end,
  unless = function(self, node)
    return {
      "if",
      {
        "not",
        {
          "parens",
          node[2]
        }
      },
      unpack(node, 3)
    }
  end,
  ["if"] = function(self, node, ret)
    if ntype(node[2]) == "assign" then
      local _, assign, body = unpack(node)
      if destructure.has_destructure(assign[2]) then
        local name = NameProxy("des")
        body = {
          destructure.build_assign(self, assign[2][1], name),
          build.group(node[3])
        }
        return build["do"]({
          build.assign_one(name, assign[3][1]),
          {
            "if",
            name,
            body,
            unpack(node, 4)
          }
        })
      else
        local name = assign[2][1]
        return build["do"]({
          assign,
          {
            "if",
            name,
            unpack(node, 3)
          }
        })
      end
    end
    node = expand_elseif_assign(node)
    if ret then
      smart_node(node)
      node['then'] = apply_to_last(node['then'], ret)
      for i = 4, #node do
        local case = node[i]
        local body_idx = #node[i]
        case[body_idx] = apply_to_last(case[body_idx], ret)
      end
    end
    return node
  end,
  with = function(self, node, ret)
    local exp, block = unpack(node, 2)
    local copy_scope = true
    local scope_name, named_assign
    if ntype(exp) == "assign" then
      local names, values = unpack(exp, 2)
      local first_name = names[1]
      if ntype(first_name) == "value" then
        scope_name = first_name
        named_assign = exp
        exp = values[1]
        copy_scope = false
      else
        scope_name = NameProxy("with")
        exp = values[1]
        values[1] = scope_name
        named_assign = {
          "assign",
          names,
          values
        }
      end
    elseif self:is_local(exp) then
      scope_name = exp
      copy_scope = false
    end
    scope_name = scope_name or NameProxy("with")
    return build["do"]({
      Run(function(self)
        return self:set("scope_var", scope_name)
      end),
      copy_scope and build.assign_one(scope_name, exp) or NOOP,
      named_assign or NOOP,
      build.group(block),
      (function()
        if ret then
          return ret(scope_name)
        end
      end)()
    })
  end,
  foreach = function(self, node, _)
    smart_node(node)
    local source = unpack(node.iter)
    local destructures = { }
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, name in ipairs(node.names) do
        if ntype(name) == "table" then
          do
            local proxy = NameProxy("des")
            insert(destructures, destructure.build_assign(self, name, proxy))
            _accum_0[_len_0] = proxy
          end
        else
          _accum_0[_len_0] = name
        end
        _len_0 = _len_0 + 1
      end
      node.names = _accum_0
    end
    if next(destructures) then
      insert(destructures, build.group(node.body))
      node.body = destructures
    end
    if ntype(source) == "unpack" then
      local list = source[2]
      local index_name = NameProxy("index")
      local list_name = self:is_local(list) and list or NameProxy("list")
      local slice_var = nil
      local bounds
      if is_slice(list) then
        local slice = list[#list]
        table.remove(list)
        table.remove(slice, 1)
        if self:is_local(list) then
          list_name = list
        end
        if slice[2] and slice[2] ~= "" then
          local max_tmp_name = NameProxy("max")
          slice_var = build.assign_one(max_tmp_name, slice[2])
          slice[2] = {
            "exp",
            max_tmp_name,
            "<",
            0,
            "and",
            {
              "length",
              list_name
            },
            "+",
            max_tmp_name,
            "or",
            max_tmp_name
          }
        else
          slice[2] = {
            "length",
            list_name
          }
        end
        bounds = slice
      else
        bounds = {
          1,
          {
            "length",
            list_name
          }
        }
      end
      return build.group({
        list_name ~= list and build.assign_one(list_name, list) or NOOP,
        slice_var or NOOP,
        build["for"]({
          name = index_name,
          bounds = bounds,
          body = {
            {
              "assign",
              node.names,
              {
                NameProxy.index(list_name, index_name)
              }
            },
            build.group(node.body)
          }
        })
      })
    end
    node.body = with_continue_listener(node.body)
  end,
  ["while"] = function(self, node)
    smart_node(node)
    node.body = with_continue_listener(node.body)
  end,
  ["for"] = function(self, node)
    smart_node(node)
    node.body = with_continue_listener(node.body)
  end,
  switch = function(self, node, ret)
    local _, exp, conds = unpack(node)
    local exp_name = NameProxy("exp")
    local convert_cond
    convert_cond = function(cond)
      local t, case_exps, body = unpack(cond)
      local out = { }
      insert(out, t == "case" and "elseif" or "else")
      if t ~= "else" then
        local cond_exp = { }
        for i, case in ipairs(case_exps) do
          if i == 1 then
            insert(cond_exp, "exp")
          else
            insert(cond_exp, "or")
          end
          if not (value_is_singular(case)) then
            case = {
              "parens",
              case
            }
          end
          insert(cond_exp, {
            "exp",
            case,
            "==",
            exp_name
          })
        end
        insert(out, cond_exp)
      else
        body = case_exps
      end
      if ret then
        body = apply_to_last(body, ret)
      end
      insert(out, body)
      return out
    end
    local first = true
    local if_stm = {
      "if"
    }
    for _index_0 = 1, #conds do
      local cond = conds[_index_0]
      local if_cond = convert_cond(cond)
      if first then
        first = false
        insert(if_stm, if_cond[2])
        insert(if_stm, if_cond[3])
      else
        insert(if_stm, if_cond)
      end
    end
    return build.group({
      build.assign_one(exp_name, exp),
      if_stm
    })
  end,
  class = function(self, node, ret, parent_assign)
    local _, name, parent_val, body = unpack(node)
    if parent_val == "" then
      parent_val = nil
    end
    local statements = { }
    local properties = { }
    for _index_0 = 1, #body do
      local item = body[_index_0]
      local _exp_0 = item[1]
      if "stm" == _exp_0 then
        insert(statements, item[2])
      elseif "props" == _exp_0 then
        for _index_1 = 2, #item do
          local tuple = item[_index_1]
          if ntype(tuple[1]) == "self" then
            insert(statements, build.assign_one(unpack(tuple)))
          else
            insert(properties, tuple)
          end
        end
      end
    end
    local constructor
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #properties do
        local _continue_0 = false
        repeat
          local tuple = properties[_index_0]
          local key = tuple[1]
          local _value_0
          if key[1] == "key_literal" and key[2] == constructor_name then
            constructor = tuple[2]
            _continue_0 = true
            break
          else
            _value_0 = tuple
          end
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      properties = _accum_0
    end
    local parent_cls_name = NameProxy("parent")
    local base_name = NameProxy("base")
    local self_name = NameProxy("self")
    local cls_name = NameProxy("class")
    if not (constructor) then
      if parent_val then
        constructor = build.fndef({
          args = {
            {
              "..."
            }
          },
          arrow = "fat",
          body = {
            build.chain({
              base = "super",
              {
                "call",
                {
                  "..."
                }
              }
            })
          }
        })
      else
        constructor = build.fndef()
      end
    end
    local real_name = name or parent_assign and parent_assign[2][1]
    local _exp_0 = ntype(real_name)
    if "chain" == _exp_0 then
      local last = real_name[#real_name]
      local _exp_1 = ntype(last)
      if "dot" == _exp_1 then
        real_name = {
          "string",
          '"',
          last[2]
        }
      elseif "index" == _exp_1 then
        real_name = last[2]
      else
        real_name = "nil"
      end
    elseif "nil" == _exp_0 then
      real_name = "nil"
    else
      real_name = {
        "string",
        '"',
        real_name
      }
    end
    local cls = build.table({
      {
        "__init",
        constructor
      },
      {
        "__base",
        base_name
      },
      {
        "__name",
        real_name
      },
      parent_val and {
        "__parent",
        parent_cls_name
      } or nil
    })
    local class_index
    if parent_val then
      local class_lookup = build["if"]({
        cond = {
          "exp",
          "val",
          "==",
          "nil"
        },
        ["then"] = {
          parent_cls_name:index("name")
        }
      })
      insert(class_lookup, {
        "else",
        {
          "val"
        }
      })
      class_index = build.fndef({
        args = {
          {
            "cls"
          },
          {
            "name"
          }
        },
        body = {
          build.assign_one(LocalName("val"), build.chain({
            base = "rawget",
            {
              "call",
              {
                base_name,
                "name"
              }
            }
          })),
          class_lookup
        }
      })
    else
      class_index = base_name
    end
    local cls_mt = build.table({
      {
        "__index",
        class_index
      },
      {
        "__call",
        build.fndef({
          args = {
            {
              "cls"
            },
            {
              "..."
            }
          },
          body = {
            build.assign_one(self_name, build.chain({
              base = "setmetatable",
              {
                "call",
                {
                  "{}",
                  base_name
                }
              }
            })),
            build.chain({
              base = "cls.__init",
              {
                "call",
                {
                  self_name,
                  "..."
                }
              }
            }),
            self_name
          }
        })
      }
    })
    cls = build.chain({
      base = "setmetatable",
      {
        "call",
        {
          cls,
          cls_mt
        }
      }
    })
    local value = nil
    do
      local out_body = {
        Run(function(self)
          if name then
            self:put_name(name)
          end
          return self:set("super", function(block, chain)
            if chain then
              local slice
              do
                local _accum_0 = { }
                local _len_0 = 1
                for _index_0 = 3, #chain do
                  local item = chain[_index_0]
                  _accum_0[_len_0] = item
                  _len_0 = _len_0 + 1
                end
                slice = _accum_0
              end
              local new_chain = {
                "chain",
                parent_cls_name
              }
              local head = slice[1]
              if head == nil then
                return parent_cls_name
              end
              local _exp_1 = head[1]
              if "call" == _exp_1 then
                local calling_name = block:get("current_block")
                slice[1] = {
                  "call",
                  {
                    "self",
                    unpack(head[2])
                  }
                }
                if ntype(calling_name) == "key_literal" then
                  insert(new_chain, {
                    "dot",
                    calling_name[2]
                  })
                else
                  insert(new_chain, {
                    "index",
                    calling_name
                  })
                end
              elseif "colon" == _exp_1 then
                local call = head[3]
                insert(new_chain, {
                  "dot",
                  head[2]
                })
                slice[1] = {
                  "call",
                  {
                    "self",
                    unpack(call[2])
                  }
                }
              end
              for _index_0 = 1, #slice do
                local item = slice[_index_0]
                insert(new_chain, item)
              end
              return new_chain
            else
              return parent_cls_name
            end
          end)
        end),
        {
          "declare_glob",
          "*"
        },
        parent_val and build.assign_one(parent_cls_name, parent_val) or NOOP,
        build.assign_one(base_name, {
          "table",
          properties
        }),
        build.assign_one(base_name:chain("__index"), base_name),
        parent_val and build.chain({
          base = "setmetatable",
          {
            "call",
            {
              base_name,
              build.chain({
                base = parent_cls_name,
                {
                  "dot",
                  "__base"
                }
              })
            }
          }
        }) or NOOP,
        build.assign_one(cls_name, cls),
        build.assign_one(base_name:chain("__class"), cls_name),
        build.group((function()
          if #statements > 0 then
            return {
              build.assign_one(LocalName("self"), cls_name),
              build.group(statements)
            }
          end
        end)()),
        parent_val and build["if"]({
          cond = {
            "exp",
            parent_cls_name:chain("__inherited")
          },
          ["then"] = {
            parent_cls_name:chain("__inherited", {
              "call",
              {
                parent_cls_name,
                cls_name
              }
            })
          }
        }) or NOOP,
        build.group((function()
          if name then
            return {
              build.assign_one(name, cls_name)
            }
          end
        end)()),
        (function()
          if ret then
            return ret(cls_name)
          end
        end)()
      }
      value = build.group({
        build.group((function()
          if ntype(name) == "value" then
            return {
              build.declare({
                names = {
                  name
                }
              })
            }
          end
        end)()),
        build["do"](out_body)
      })
    end
    return value
  end
})
do
  local _base_0 = {
    body_idx = {
      ["for"] = 4,
      ["while"] = 3,
      foreach = 4
    },
    convert = function(self, node)
      local index = self.body_idx[ntype(node)]
      node[index] = self:mutate_body(node[index])
      return self:wrap(node)
    end,
    wrap = function(self, node, group_type)
      if group_type == nil then
        group_type = "block_exp"
      end
      return build[group_type]({
        build.assign_one(self.accum_name, build.table()),
        build.assign_one(self.len_name, 1),
        node,
        group_type == "block_exp" and self.accum_name or NOOP
      })
    end,
    mutate_body = function(self, body)
      local single_stm = is_singular(body)
      local val
      if single_stm and types.is_value(single_stm) then
        body = { }
        val = single_stm
      else
        body = apply_to_last(body, function(n)
          if types.is_value(n) then
            return build.assign_one(self.value_name, n)
          else
            return build.group({
              {
                "declare",
                {
                  self.value_name
                }
              },
              n
            })
          end
        end)
        val = self.value_name
      end
      local update = {
        build.assign_one(NameProxy.index(self.accum_name, self.len_name), val),
        {
          "update",
          self.len_name,
          "+=",
          1
        }
      }
      insert(body, build.group(update))
      return body
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, accum_name)
      self.accum_name = NameProxy("accum")
      self.value_name = NameProxy("value")
      self.len_name = NameProxy("len")
    end,
    __base = _base_0,
    __name = "Accumulator"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Accumulator = _class_0
end
default_accumulator = function(self, node)
  return Accumulator():convert(node)
end
implicitly_return = function(scope)
  local is_top = true
  local fn
  fn = function(stm)
    local t = ntype(stm)
    if t == "decorated" then
      stm = scope.transform.statement(stm)
      t = ntype(stm)
    end
    if types.cascading[t] then
      is_top = false
      return scope.transform.statement(stm, fn)
    elseif types.manual_return[t] or not types.is_value(stm) then
      if is_top and t == "return" and stm[2] == "" then
        return NOOP
      else
        return stm
      end
    else
      if t == "comprehension" and not types.comprehension_has_value(stm) then
        return stm
      else
        return {
          "return",
          stm
        }
      end
    end
  end
  return fn
end
Value = Transformer({
  ["for"] = default_accumulator,
  ["while"] = default_accumulator,
  foreach = default_accumulator,
  ["do"] = function(self, node)
    return build.block_exp(node[2])
  end,
  decorated = function(self, node)
    return self.transform.statement(node)
  end,
  class = function(self, node)
    return build.block_exp({
      node
    })
  end,
  string = function(self, node)
    local delim = node[2]
    local convert_part
    convert_part = function(part)
      if type(part) == "string" or part == nil then
        return {
          "string",
          delim,
          part or ""
        }
      else
        return build.chain({
          base = "tostring",
          {
            "call",
            {
              part[2]
            }
          }
        })
      end
    end
    if #node <= 3 then
      return (function()
        if type(node[3]) == "string" then
          return node
        else
          return convert_part(node[3])
        end
      end)()
    end
    local e = {
      "exp",
      convert_part(node[3])
    }
    for i = 4, #node do
      insert(e, "..")
      insert(e, convert_part(node[i]))
    end
    return e
  end,
  comprehension = function(self, node)
    local a = Accumulator()
    node = self.transform.statement(node, function(exp)
      return a:mutate_body({
        exp
      })
    end)
    return a:wrap(node)
  end,
  tblcomprehension = function(self, node)
    local _, explist, clauses = unpack(node)
    local key_exp, value_exp = unpack(explist)
    local accum = NameProxy("tbl")
    local inner
    if value_exp then
      local dest = build.chain({
        base = accum,
        {
          "index",
          key_exp
        }
      })
      inner = {
        build.assign_one(dest, value_exp)
      }
    else
      local key_name, val_name = NameProxy("key"), NameProxy("val")
      local dest = build.chain({
        base = accum,
        {
          "index",
          key_name
        }
      })
      inner = {
        build.assign({
          names = {
            key_name,
            val_name
          },
          values = {
            key_exp
          }
        }),
        build.assign_one(dest, val_name)
      }
    end
    return build.block_exp({
      build.assign_one(accum, build.table()),
      construct_comprehension(inner, clauses),
      accum
    })
  end,
  fndef = function(self, node)
    smart_node(node)
    node.body = apply_to_last(node.body, implicitly_return(self))
    node.body = {
      Run(function(self)
        return self:listen("varargs", function() end)
      end),
      unpack(node.body)
    }
    return node
  end,
  ["if"] = function(self, node)
    return build.block_exp({
      node
    })
  end,
  unless = function(self, node)
    return build.block_exp({
      node
    })
  end,
  with = function(self, node)
    return build.block_exp({
      node
    })
  end,
  switch = function(self, node)
    return build.block_exp({
      node
    })
  end,
  chain = function(self, node)
    local stub = node[#node]
    for i = 3, #node do
      local part = node[i]
      if ntype(part) == "dot" and data.lua_keywords[part[2]] then
        node[i] = {
          "index",
          {
            "string",
            '"',
            part[2]
          }
        }
      end
    end
    if ntype(node[2]) == "string" then
      node[2] = {
        "parens",
        node[2]
      }
    elseif type(stub) == "table" and stub[1] == "colon_stub" then
      table.remove(node, #node)
      local base_name = NameProxy("base")
      local fn_name = NameProxy("fn")
      local is_super = node[2] == "super"
      return self.transform.value(build.block_exp({
        build.assign({
          names = {
            base_name
          },
          values = {
            node
          }
        }),
        build.assign({
          names = {
            fn_name
          },
          values = {
            build.chain({
              base = base_name,
              {
                "dot",
                stub[2]
              }
            })
          }
        }),
        build.fndef({
          args = {
            {
              "..."
            }
          },
          body = {
            build.chain({
              base = fn_name,
              {
                "call",
                {
                  is_super and "self" or base_name,
                  "..."
                }
              }
            })
          }
        })
      }))
    end
  end,
  block_exp = function(self, node)
    local _, body = unpack(node)
    local fn = nil
    local arg_list = { }
    fn = smart_node(build.fndef({
      body = {
        Run(function(self)
          return self:listen("varargs", function()
            insert(arg_list, "...")
            insert(fn.args, {
              "..."
            })
            return self:unlisten("varargs")
          end)
        end),
        unpack(body)
      }
    }))
    return build.chain({
      base = {
        "parens",
        fn
      },
      {
        "call",
        arg_list
      }
    })
  end
})
return {
  Statement = Statement,
  Value = Value,
  Run = Run
}

end
-----------------------------------------------
 
do
  if not package.__loadfile then
    local original_loadfile = loadfile
    local function lf (file)
      local hndl = file:gsub( "%.lua$", "" )
                       :gsub( "/", "." )
                       :gsub( "\\", "." )
                       :gsub( "%.init$", "" )
      return package.preload[hndl] or original_loadfile( name )
    end
 
    function dofile (name)
      return lf( name )()
    end
 
    loadfile, package.__loadfile = lf, loadfile
  end
end

return require 'moonscript.init'
