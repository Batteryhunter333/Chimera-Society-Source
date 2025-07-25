local module = {}

function module.Find(a, tbl)
	for _, a_ in ipairs(tbl) do
		if a_ == a then
			return true
		end
	end

	return nil
end

function module.Difference(a, b)
	local ret = {}
	for _, v in ipairs(a) do
		if not module.Find(v, b) then
			table.insert(ret, v)
		end
	end

	return ret
end

local suffixes = {
	"",
	"K",
	"M",
	"B",
	"T",
	"QA",
	"QI",
	"SX",
	"SP",
	"OC",
	"NO",
	"DC",
	"UD",
	"DD",
	"TD",
	"QAD",
	"QID",
	"SXD",
	"SPD",
	"OCD",
	"NOD",
	"VG",
	"UVG",
}
function module.TruncateNumber(n)
	local s = tostring(math.floor(n))
	local shortened = string.sub(s, 1, ((#s - 1) % 3) + 1)

	if #s > 3 then
		shortened = shortened .. "." .. string.sub(s, 3, 3)
	end

	return shortened .. (suffixes)[math.floor((#s - 1) / 3) + 1]
end

return module
