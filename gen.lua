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
	error(string.format("syntax error at [%s] line (%d) pos %d", parser_state.file or "", parser_state.line,pos))
	return pos
end)

local eof = P(-1)				--结束
local newline = lpeg.Cmt((P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)
local line_comment = "//" * (1 - newline) ^0 * (newline + eof)
local include_comment = "$" * (1 - newline) ^0 * (newline + eof)
local include_comment2 = "#include" * (1 - newline) ^0 * (newline + eof)

local blank = S" \t" + newline + line_comment + include_comment+ include_comment2
local blank0 = blank ^ 0
local blanks = blank ^ 1
local alpha = R"az" + R"AZ" + "_"+"::"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0  --可以有0个以上数字
local name = C(word)			--捕获单词
local defaultValue = name+C(R"09")

local symbol = S"*&~"
local const = P("const")

local functionHead =(P"virtual"+P"const")^0

local datatype = name  --no super    long long used typedef int64 long long

--
local toluaGma = (P"@"*blank0*word*blank0)^0

local function multipat(pat)
	return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
end

local function namedpat(name, pat)
	return Ct(Cg(Cc(name), "type") * Cg(pat))
end


local typedef = P{
	"ALL",
	DEFAULT_STRUCT=namedpat("define",(P"#define"* blanks*name*blanks*defaultValue)),
	ENUM_FIELD=namedpat("enum_field",name*blank0*(P",")^0),
	ENUM_STRUCT = namedpat("enum",P"enum"*blank0*P(name)^0*blank0*P"{"*blank0*multipat(V"ENUM_FIELD")*blank0*P"}"*blank0*P";"),
	CLASS_STRUCT=namedpat("class",P"class"*blanks*name*blank0*(P":"*blank0*P("public")*blanks*name*blank0)^0*P"{"*V("CLASS_BODY")*"}"*blank0*P";"),
	CLASS_BODY=blank0*multipat(V"PUBLIC_STRUCT"+V"FUN_FIELD"+V"S_FUN_FIELD"+V"CONST_FUN_FIELD"+V"DCONST_FUN_FIELD")*blank0,
	PUBLIC_STRUCT=name*blank0*P":",
	CONST_FUN_FIELD=namedpat("cfun",name*blank0*V"PARAM_STRUCT"),
	DCONST_FUN_FIELD=namedpat("dfun",symbol*blank0*name*blank0*V"PARAM_STRUCT"),
	S_FUN_FIELD=namedpat("sfun",P"static"*blanks*V"FUN_FIELD"),
	--                       函数修饰              datatype		*			funname            
	FUN_FIELD=namedpat("fun",functionHead*blank0*datatype*blank0*symbol^0*blank0*name*blank0*toluaGma*V"PARAM_STRUCT"),
	--                                 
	PARAM_FIELD=namedpat("param",blank0*const^0*blank0*name*blank0*symbol^0*blank0*name*(blank0*P"="*blank0*defaultValue)^0*P","^0),
	PARAM_STRUCT=namedpat("params",P"("*blank0*multipat(V"PARAM_FIELD"+P"void")*blank0*P")"*blank0*const^0*blank0*(P";"+P"{}")),
	ALL = multipat(V"ENUM_STRUCT"+V"CLASS_STRUCT"+V"DEFAULT_STRUCT"),
}

-- local luafile = io.open("gen.h", "r")
local luafile = io.open("cocos2dx_ext_luabinding.tolua", "r")
local filecontent = luafile:read("*a")

local proto = blank0 * typedef * blank0
local state = { file = nil, pos = 0, line = 1 }
local r = lpeg.match(proto * -1 + exception , filecontent , 1, state )

trace(r,"",10)



