local lpeg = require "lpeg"
local trace = require("trace")

local P = lpeg.P    --Matches string literally
local S = lpeg.S 	--Matches any character in string (Set)
local R = lpeg.R 	--Matches any character between x and y (Range)
local C = lpeg.C 	--the match for patt plus all captures made by patt
local Ct = lpeg.Ct 	--a table with all captures from patt
local Cg = lpeg.Cg 	--the values produced by patt, optionally tagged with name
local Cc = lpeg.Cc 	--the given values (matches the empty string)
local V = lpeg.V 	--代替传入名称的变量


local function count_lines(_,pos, parser_state)
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

local eof = P(-1)				--结束
local newline = lpeg.Cmt((P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)
local line_comment = "//" * (1 - newline) ^0 * (newline + eof)
local blank = S" \t" + newline + line_comment
local blank0 = blank ^ 0
local blanks = blank ^ 1
local alpha = R"az" + R"AZ" + "_"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0  --可以有0个以上数字
local name = C(word)			--捕获单词


local function multipat(pat)
	return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
end

local function namedpat(name, pat)
	return Ct(Cg(Cc(name), "type") * Cg(pat))
end


local typedef = P{
	"ALL",
	ENUM_FIELD=namedpat("ENUM_FIELD",name*blank0*(P",")^0),
	ENUM_STRUCT = namedpat("enum",P"enum"*blank0*P(name)^0*blank0*P"{"*blank0*multipat(V"ENUM_FIELD")*blank0*P"}"*blank0*P";"),
	ALL = multipat(V"ENUM_STRUCT"),
}

local luafile = io.open("gen.h", "r")
local filecontent = luafile:read("*a")

local proto = blank0 * typedef * blank0
local state = { file = nil, pos = 0, line = 1 }
local r = lpeg.match(proto * -1 + exception , filecontent , 1, state )

trace(r)



