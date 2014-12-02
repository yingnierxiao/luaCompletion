local lpeg = require 'lpeg'

local P = lpeg.P
local C = lpeg.C
local Ct = lpeg.Ct

local luafile = io.open("gen.lua", "r")

local filecontent = luafile:read("*a")

local Any             = lpeg.P(1)
local Newline         = lpeg.P("\n")
local Whitespace      = lpeg.S(" \t\n")
local OptionalSpace   = Whitespace^0
local Space           = Whitespace^1
local Semicolon       = lpeg.P(";")
local DefineSeparator = lpeg.P("\\")

-- c enum
local braceStart = P("{")
local braceEnd = P("}")

local enumStart = P("enum")

local splitEnum = P(",")+Newline


local split = function (s, sep)
  sep = P(sep)
  local st = C(enumStart+braceStart+Newline)
  local e = C(Newline+braceEnd)
  local elem = C((1 - sep)^0)
  local p = st+(elem * (sep * elem)^0)
  return lpeg.match(p, s)
end

local test1str = [[

enum 
{ 
wxUNKNOWN_PLATFORM, 
wxCURSES, 
wxXVIEW_X, 
wxMOTIF_X, 
wxCOSE_X, 
wxNEXTSTEP, 
wxMAC, 
wxMAC_DARWIN, 
wxBEOS, 
wxGTK, 
wxGTK_WIN32, 
wxGTK_OS2, 
wxGTK_BEOS, 
wxGEOS, 
wxOS2_PM, 
wxWINDOWS, 
wxMICROWINDOWS, 
wxPENWINDOWS, 
wxWINDOWS_NT, 
wxWIN32S, 
wxWIN95, 
wxWIN386, 
wxWINDOWS_CE, 
wxWINDOWS_POCKETPC, 
wxWINDOWS_SMARTPHONE, 
wxMGL_UNIX, 
wxMGL_X, 
wxMGL_WIN32, 
wxMGL_OS2, 
wxMGL_DOS, 
wxWINDOWS_OS2, 
wxUNIX, 
wxX11, 
wxPALMOS, 
wxDOS 
}; 

]]

print(split(test1str,splitEnum))
-- print(lpeg.match(C(enumStart*Newline*braceStart),test1str))



