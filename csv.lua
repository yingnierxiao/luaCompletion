local csv= {}

local lpeg = require 'lpeg'
local C, Cs, Ct, P, S = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.P, lpeg.S

local eol = P'\r\n' + P'\n'
local quoted_field = '"' * Cs(((P(1) - '"') + P'""' / '"')^0) * '"'
local unquoted_field = C((1 - S',\r\n"')^0)
local field = quoted_field + unquoted_field
local record = Ct(field * (',' * field)^0)
local nonemptyrecord = #P(1 - eol) * record
local records = Ct((record * eol)^0 * nonemptyrecord^-1) * -1
local one_line_record = record * (eol + -1)

function csv.parse_line(line)
   assert(type(line) == 'string', 'bad argument #1 (expected string)')
   return lpeg.match(one_line_record, line)
end
-- parse renwu.csv  100 count 0.4s
-- public interface
function csv.parse(input)
   assert(type(input) == 'string', 'bad argument #1 (expected string)')
   return lpeg.match(records, input)
end

return csv