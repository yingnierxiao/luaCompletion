local lpeg = require 'lpeg'

local DocParser = {}

local function count_lines(_,pos, parser_state)
  print("line:"..parser_state.line)
  if parser_state.pos < pos then
    parser_state.line = parser_state.line + 1
    parser_state.pos = pos

  end
  return pos
end


local exception = lpeg.Cmt( lpeg.Carg(1) , function ( _ , pos, parser_state)
  error(string.format("syntax error at [%s] line (%d)", parser_state.file or "", parser_state.line))
  return pos
end)

-- Common Lexical Elements
local Any             = lpeg.P(1)
local Newline         = lpeg.Cmt((lpeg.P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)--lpeg.P("\n")
local Whitespace      = lpeg.S(" \t\n")+Newline
local OptionalSpace   = Whitespace^0
local Space           = Whitespace^1
local Semicolon       = lpeg.P(";")
local DefineSeparator = lpeg.P("\\")

-- Lexical Elements of Lua
local LuaLongCommentStart  = lpeg.P("--[[")
local LuaLongCommentEnd    = lpeg.P("]]")
local LuaLongComment       = lpeg.Cc("long comment") *
                             lpeg.C(LuaLongCommentStart *
                                    (Any - LuaLongCommentEnd)^0 *
                                    LuaLongCommentEnd)
local LuaShortCommentStart = lpeg.P("--")
local LuaShortCommentEnd   = Newline
local LuaShortCommentLine  = OptionalSpace * LuaShortCommentStart *
                             lpeg.C((Any - LuaShortCommentEnd)^0) *
                             LuaShortCommentEnd
local LuaShortComment      = lpeg.Cc("comment") * LuaShortCommentLine^1
local LuaOptionalComment   = LuaShortComment +
                             lpeg.Cc("comment") * lpeg.Cc("undefined")
local LuaCommentStart      = LuaLongCommentStart + LuaShortCommentStart
local LuaEnd               = lpeg.P("end")
local LuaLocalFunction    =  lpeg.P("local") * OptionalSpace *
                             lpeg.P("function") * OptionalSpace *
                             lpeg.P(Any - lpeg.P("("))^1 *
                             lpeg.P("(") * (Any - lpeg.P(")"))^0 *
                             lpeg.P(")")
local LuaGlobalFunction    = -lpeg.P("local") * OptionalSpace *
                             lpeg.C(lpeg.P("function")) * OptionalSpace *
                             lpeg.Cc("") * lpeg.C(lpeg.P(Any - lpeg.P("("))^1) *
                             lpeg.P("(") * lpeg.C((Any - lpeg.P(")"))^0) *
                             lpeg.P(")")
local ExportLuaMethod      = lpeg.Ct(LuaOptionalComment * LuaGlobalFunction)
local CodeStop             = LuaCommentStart + LuaLocalFunction + LuaGlobalFunction
local LuaCode              = lpeg.Cc("code") * lpeg.C((Any - CodeStop)^1)

-- Lexical Elements of (Lua) C
local Character      = lpeg.R("AZ", "az") + lpeg.R("09") + lpeg.P("_") +
                       lpeg.P("*")
local CCommentStart  = lpeg.P("/*")
local CCommentEnd    = lpeg.P("*/")
local ExportLuaCComment = CCommentStart * lpeg.P(" exports the ") *
                          lpeg.Ct(lpeg.Cc("class") * lpeg.C(Character^1)) *
                          (Any - lpeg.P("to Lua:"))^1 *
                          lpeg.P("to Lua:") * ExportLuaMethod^0 *
                          (Any - CCommentEnd)^0 * CCommentEnd
local CComment       = CCommentStart * (Any - CCommentEnd)^0 * CCommentEnd
local CCode          = (Any - CCommentStart)^1

-- Lexical Elements of (pure) C
local Ifndef = lpeg.P("#ifndef") * Whitespace * Character^1 * Newline
local Define = lpeg.P("#define") * Whitespace * Character^1 * Newline
local Endif = lpeg.P("#endif") * Newline^0
local Include = lpeg.P("#include") * (Any - Newline)^1 * Newline
local ClassTypedef = lpeg.Ct(lpeg.Cc("class") *
                             (CCommentStart * lpeg.C((Any - CCommentEnd)^0) *
                               CCommentEnd)^0 * Newline^0 *
                             ((lpeg.P("typedef") * Space *
                               (lpeg.P("struct") + lpeg.P("enum")) * Space *
                               Character^1 * Space * lpeg.C(Character^1)) +
                              (lpeg.P("typedef") * Space * lpeg.P("char*") *
                               Space * lpeg.C(lpeg.P("GtTagValueMap")))) *
                              OptionalSpace * Semicolon)
local FunctionTypedef = lpeg.Ct(lpeg.Cc("funcdef") *
                                (CCommentStart * lpeg.C((Any - CCommentEnd)^0) *
                                CCommentEnd) * Newline^0 *
                                lpeg.P("typedef") * Space *
                                lpeg.C((Any - Semicolon)^1) * Semicolon)
local TypedefStruct = lpeg.P("typedef struct") * (Any - Semicolon)^1 * Semicolon
local OptionalWord = (Character^1 * Space)^-1
local Function = lpeg.Cc("function") *
                 lpeg.C(Character^1 * Space * OptionalWord * OptionalWord *
                        OptionalWord ) *
                 lpeg.C(lpeg.P(Any - lpeg.S("(;"))^1) * lpeg.P("(") *
                 lpeg.C((Any - lpeg.S(");"))^1) * lpeg.P(")") *
                 (Any - Semicolon)^0 * Semicolon
local FunctionPtr = lpeg.Cc("functionptr") *
                 lpeg.P("typedef") * Space *
                 lpeg.C(Character^1 * Space * OptionalWord * OptionalWord *
                        OptionalWord ) * OptionalSpace * lpeg.P("(") * lpeg.P("*") *
                 lpeg.C(lpeg.P(Any - lpeg.S("()"))^1) * lpeg.P(")") * lpeg.P("(") *
                 lpeg.C((Any - lpeg.P(")"))^1) * lpeg.P(")") *
                 (Any - Semicolon)^0 * Semicolon
local Variable = lpeg.Cc("variable") *
                 lpeg.C(lpeg.P("extern") * Space * Character^1 *Space*
                        OptionalWord * OptionalWord * OptionalWord) *
                 lpeg.C((Any - lpeg.S("();"))^0) * Semicolon
local ExportedComment = lpeg.Cc("comment") * CCommentStart *
                        lpeg.C((Any - CCommentEnd)^0) * CCommentEnd
local ExportedDefine = lpeg.Cc("function") * lpeg.C("#define") * Space *
                       lpeg.C(lpeg.P(Any - lpeg.P("("))^1) * lpeg.P("(") *
                       lpeg.C((Any - lpeg.P(")"))^1) * lpeg.P(")") *
                       OptionalSpace * DefineSeparator
local ExportedPlainDefine = lpeg.Cc("function") * lpeg.C("#define") * Space *
                            lpeg.C(lpeg.P(Any - (DefineSeparator + Space))^1) *
                            OptionalSpace * DefineSeparator
local ExportCMethod = lpeg.Ct(ExportedComment * Newline^0 * (Function + FunctionPtr + Variable))
local ExportCDefine = lpeg.Ct(ExportedComment * Newline^0 *
                              (ExportedDefine+ ExportedPlainDefine))
local ModuleDef = lpeg.Ct(lpeg.Cc("module") * CCommentStart * Space *
                          lpeg.C(Character^1) * Space * lpeg.P("module") *
                          Space * CCommentEnd)

-- Lua Grammar
local Elem, Start = lpeg.V"Elem", lpeg.V"Start"
local LuaGrammar = lpeg.P{ Start,
  Start = lpeg.Ct(Elem^0);
  Elem  = ExportLuaMethod + LuaLongComment + LuaShortComment + Space +
          LuaLocalFunction + LuaCode;
}
LuaGrammar = LuaGrammar * -1

-- Lua C Grammar
local LuaCGrammar = lpeg.P{ Start,
 Start = lpeg.Ct(Elem^0);
 Elem  = lpeg.Ct(ExportLuaCComment) + CComment + Space + CCode;
}
LuaCGrammar = LuaCGrammar * -1

-- C Grammar
local CGrammar = lpeg.P{ Start,
  -- Start = lpeg.Ct(CComment * Newline^0 * Ifndef * Define * Elem^0 * Endif);
  Start = lpeg.Ct(CComment * Newline^0 * Ifndef * Define * Elem^0);
  Elem = ClassTypedef + ModuleDef + ExportCDefine + ExportCMethod + Space +
         Include + lpeg.C(TypedefStruct) + FunctionTypedef + CCode + CComment;
}
CGrammar = CGrammar * -1

DocParser.__index = DocParser

function DocParser.new()
  local o = {}
  o.lua_c_pattern = LuaCGrammar
  o.lua_pattern = LuaGrammar
  o.c_pattern = CGrammar
  return setmetatable(o, DocParser)
end

function DocParser:parse(filename, iscpp)
  assert(filename)
  local file, err = io.open(filename, "r")
  assert(file, err)
  local filecontent = file:read("*a")
  local state = { file = filename, pos = 0, line = 1 }
  if iscpp then
  --   if is_lua then
  --     return lpeg.match(self.lua_c_pattern, filecontent)
  --   else
      return lpeg.match(self.c_pattern+exception, filecontent,1,state)
  --   end
  else
    return lpeg.match(self.lua_pattern+exception, filecontent,1,state)
  end
end

local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep

local trace =function (root)
    if root ==nil then
        print("...")
        return
    end
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
            else
                tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return tconcat(temp,"\n"..space)
    end
    print(_dump(root, "",""))
end
local parse = DocParser.new()
local data = parse:parse("gen.lua",false)

-- local data = parse:parse("dfont.h",true)


trace(data)
