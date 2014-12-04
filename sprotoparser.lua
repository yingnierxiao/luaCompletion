local lpeg = require "lpeg"

local P = lpeg.P    --Matches string literally
local S = lpeg.S 	--Matches any character in string (Set)
local R = lpeg.R 	--Matches any character between x and y (Range)
local C = lpeg.C 	--the match for patt plus all captures made by patt
local Ct = lpeg.Ct 	--a table with all captures from patt
local Cg = lpeg.Cg 	--the values produced by patt, optionally tagged with name
local Cc = lpeg.Cc 	--the given values (matches the empty string)
local V = lpeg.V 	--代替传入名称的变量

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

local eof = P(-1)				--结束
local newline = lpeg.Cmt((P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)
local line_comment = "#" * (1 - newline) ^0 * (newline + eof)
local blank = S" \t" + newline + line_comment
local blank0 = blank ^ 0			--可以有0个或多个
local blanks = blank ^ 1			--最少有个一个空格
local alpha = R"az" + R"AZ" + "_"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0  	--可以有0个以上数字
local name = C(word)				--捕获单词
local typename = C(word * ("." * word) ^ 0)	--   单词  或点开头0个以上的
local tag = R"09" ^ 1 / tonumber  --捕获标签  转化为数字

local function multipat(pat)
	return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
end

local function namedpat(name, pat)
	return Ct(Cg(Cc(name), "type") * Cg(pat))
end

local typedef = P { 	--If the argument is a table, it is interpreted as a grammar
	"ALL",
	FIELD = namedpat("field", (name * blanks * tag * blank0 * ":" * blank0 * (C"*")^0 * typename)),
	STRUCT = P"{" * multipat(V"FIELD" + V"TYPE") * P"}", 						--{}内的结构    存在字段或者类型 用+   
	TYPE = namedpat("type", P"." * name * blank0 * V"STRUCT" ),   				--捕获类型
	SUBPROTO = Ct((C"request" + C"response") * blanks * (name + V"STRUCT")),
	PROTOCOL = namedpat("protocol", name * blanks * tag * blank0 * P"{" * multipat(V"SUBPROTO") * P"}"),
	ALL = multipat(V"TYPE" + V"PROTOCOL"),
}

local proto = blank0 * typedef * blank0


local function parser(text,filename)
	local state = { file = filename, pos = 0, line = 1 }
	local r = lpeg.match(proto * -1 + exception , text , 1, state )
	return r
end

local sparser = {}

function sparser.parse(text, name)
	local r = parser(text, name or "=text")
	-- local data = encodeall(r)
	return r
end

return sparser
