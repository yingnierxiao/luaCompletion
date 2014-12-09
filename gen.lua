local lpeg = require "lpeg"
local trace = require("trace")
local lfs = require("lfs")

local P = lpeg.P    --Matches string literally
local S = lpeg.S 	--Matches any character in string (Set)
local R = lpeg.R 	--Matches any character between x and y (Range)
local C = lpeg.C 	--the match for patt plus all captures made by patt
local Ct = lpeg.Ct 	--a table with all captures from patt
local Cg = lpeg.Cg 	--the values produced by patt, optionally tagged with name
local Cc = lpeg.Cc 	--the given values (matches the empty string)
local V = lpeg.V 	--代替传入名称的变量
local M = lpeg.match


local function count_lines(_,pos, parser_state)
	if parser_state.pos < pos then
		parser_state.line = parser_state.line + 1
		parser_state.pos = pos
	end
	-- print(parser_state.line)
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

local commentStart  = P"/*"*newline^0
local commentEnd  = newline^0*P"*/"
local comment       = commentStart * ((1 - commentEnd)*newline^0)^0 * commentEnd



local blank = S" \t" + newline + line_comment + include_comment+ include_comment2 +comment
local blank0 = blank ^ 0
local blanks = blank ^ 1
local alpha = R"az" + R"AZ" + "_"+"::"
local alnum = alpha + R"09"+P"-"+P"."
local word = alpha * alnum ^ 0  --可以有0个以上数字
local name = C(word)			--捕获单词

-- local number = {}

-- local digit = R("09")

-- -- Matches: 10, -10, 0
-- number.integer =(S("+-") ^ -1) * (digit   ^  1)

-- -- Matches: .6, .899, .9999873
-- number.fractional =	(P(".")   ) * (digit ^ 1)*S"f"^0

-- -- Matches: 55.97, -90.8, .9 
-- number.decimal =(number.integer *              -- Integer
-- 	(number.fractional ^ -1)) +    -- Fractional
-- 	(S("+-") * number.fractional)  -- Completely fractional number

-- -- Matches: 60.9e07, 9e-4, 681E09 
-- number.scientific = 
-- 	number.decimal * -- Decimal number
-- 	S("Ee") *        -- E or e
-- 	number.integer   -- Exponent

-- -- Matches all of the above
-- number.number =
-- 	number.decimal + number.scientific

local digit = R'09'
local hex = R('af', 'AF', '09')
local exp = S'eE' * S'+-'^-1 * digit^1
local fs = S'fFlL'
local is = S'uUlL'^0

local hexnum = P'0' * S'xX' * hex^1 * is^-1
local octnum = P'0' * digit^1 * is^-1
local decnum = digit^1 * is^-1
local integer =(S("+-") ^ -1) * (digit   ^  1)
local floatnum = digit^1 * exp * fs^-1 +
                 digit^0 * P'.' * digit^1 * exp^-1 * fs^-1 +
                 digit^1 * P'.' * digit^0 * exp^-1 * fs^-1
local numlit = hexnum + octnum + floatnum + decnum + integer

local defaultValue = name+numlit

local symbol = S"*&~"
local const = P("const")



--fun end type
local funStart = P"{"*newline^0
local funEnd = newline^0*P"}"
local funDump = (funStart * ((1 - funEnd)*newline^0)^0 * funEnd) + P";"

local functionHead =P"virtual"^0*blank0*P"const"^0*blank0

local datatype = ((P"unsigned"+P"long")*blanks)^0*name  --no super    long long used typedef int64 long long
local toluaGma = (P"@"*blank0*word*blank0)^0


local function multipat(pat)
	return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
end

local function namedpat(name, pat)
	return Ct(Cg(Cc(name), "type") * Cg(pat))
end

local extClass = (P":"*blank0*multipat(P("public")*blanks*name*blank0*P","^0))^0+blank0





local typedef = P{
	"ALL",
	DEFAULT_STRUCT=namedpat("define",(P"#define"* blanks*name*blanks*defaultValue)),
	ENUM_FIELD=namedpat("enum_field",name*blank0*(P"="*blank0*defaultValue*blank0)^0*(P",")^0),
	ENUM_STRUCT = namedpat("enum",(P"typedef"*blanks)^0*P"enum"*blank0*P(name)^0*blank0*P"{"*blank0*multipat(V"ENUM_FIELD")*blank0*P"}"*blank0*word^0*blank0*P";"),
	-- 											  classname      :			  public 		exclassname
	CLASS_STRUCT=namedpat("class",P"class"*blanks*name*blank0*extClass*P"{"*V("CLASS_BODY")*"}"*blank0*P";"),
	CLASS_BODY=blank0*multipat(V"PUBLIC_FIELD"+V"PUBLIC_STRUCT"+V"FUN_FIELD"+V"S_FUN_FIELD"+V"CONST_FUN_FIELD"+V"DCONST_FUN_FIELD")*blank0,
	PUBLIC_STRUCT=name*blank0*P":",
	CONST_FUN_FIELD=namedpat("cfun",name*blank0*V"PARAM_STRUCT"),
	DCONST_FUN_FIELD=namedpat("dfun",symbol*blank0*name*blank0*V"PARAM_STRUCT"),
	S_FUN_FIELD=namedpat("sfun",functionHead*P"static"*blanks*V"FUN_FIELD"),
	--                       函数修饰              datatype		*			funname            
	FUN_FIELD=namedpat("fun",functionHead*blank0*datatype*blank0*symbol^0*blank0*name*blank0*toluaGma*V"PARAM_STRUCT"),
	PUBLIC_FIELD=datatype*blanks*word*blank0*P";",

	PARAM_FIELD=namedpat("param",blank0*const^0*blank0*datatype*blank0*symbol^0*blank0*name*(blank0*P"="*blank0*defaultValue)^0*blank0*P","^0),
	PARAM_STRUCT=namedpat("params",P"("*blank0*multipat(V"PARAM_FIELD"+P"void")*blank0*P")"*blank0*const^0*blank0*funDump),
	ALL = multipat(V"ENUM_STRUCT"+V"CLASS_STRUCT"+V"DEFAULT_STRUCT"+V"FUN_FIELD"+V"S_FUN_FIELD"),
}




local filter =P".tolua"+P".pkg"+P".h"

local I = lpeg.Cp()
local function anywhere (p)
  return lpeg.P{ I * p * I + 1 * lpeg.V(1) }
end


local function readFile(filename)
	local proto = blank0 * typedef * blank0
	local state = { file = filename, pos = 0, line = 1 }
	local luafile = io.open(state.file, "r")
	local filecontent = luafile:read("*a")
	local r = lpeg.match(proto * -1 + exception , filecontent , 1, state )
	return r
end 

local function scanDir( path ,depth)
   for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
           	local dump =anywhere(filter):match(f)
			if attr.mode == "directory" and depth >0 then
               scanDir (f,depth-1)
            else
            	if dump then
            		readFile(f)
            	end
            end
        end
    end
end

scanDir(".",5)

local function get_snippet( content, trigger, description )
	local space = string.rep(" ", 4)
	local snippet = string.format("<snippet>\n%s\n%s\n%s\n%s\n</snippet>\n",
		space .. "<content>" .. content .. "</content>",
		space .. "<tabTrigger>" .. trigger .. "</tabTrigger>",
		space .. "<scope>source.lua</scope>",
		space .. "<description>" .. description .. "</description>")
	return snippet
end



