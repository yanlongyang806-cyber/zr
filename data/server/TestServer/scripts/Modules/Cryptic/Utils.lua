Utils = {};

function Utils.EscapeRegex(str)
	local tr = {
		["%"] = true,
		["*"] = true,
		["."] = true,
		["+"] = true,
		["-"] = true,
		["?"] = true,
		["("] = true,
		[")"] = true,
		["["] = true,
		["]"] = true,
	};
	
	return str:gsub(".", function(m)
		if tr[m] then
			return "%"..m;
		end
	end);
end
