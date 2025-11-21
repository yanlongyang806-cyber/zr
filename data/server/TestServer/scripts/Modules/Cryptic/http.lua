require("socket.http");
require("socket.url");
require("cryptic/Utils");

Http = {
	esc_table = {
		["\""] = "&quot;",
		["&"] = "&amp;",
		["'"] = "&apos;",
		["<"] = "&lt;",
		[">"] = "&gt;",
	},

	unesc_table = {
		quot = "\"",
		amp = "&",
		apos = "'",
		lt = "<",
		gt = ">",
		nbsp = " ",
	},
};

function Http.Request(url, body, port, user, password)
	local t = { };
	local reqt = {
		url = url,
		port = port,
		sink = ltn12.sink.table(t),
		headers = { },
	};

	if body then
		reqt.source = ltn12.source.string(body);
		reqt.headers = {
		    ["Content-Length"] = string.len(body),
		    ["Content-Type"] = "application/x-www-form-urlencoded"
		};
		reqt.method = "POST";
	end

	if user and password then
		reqt.user = user;
		reqt.password = password;
	end

	local _, code, headers, status = socket.http.request(reqt);
	return table.concat(t), code, headers, status;
end

function Http.CreateFormRequest(form_data)
	local body = nil;

	for k, v in pairs(form_data) do
		if body then
			body = body.."&";
		else
			body = "";
		end

		body = body..socket.url.escape(tostring(k)).."="..socket.url.escape(tostring(v));
	end

	return body or "";
end

function Http.ReadTable(body, name, keyed)
	local html_table = nil;
	if body then
		html_table = body:match(Utils.EscapeRegex(name or "")..".-".."<table[^>]->(.-)</table>");

	else
		return nil;
	end

	local h = { };
	local t = { };
	
	if keyed == nil then
		keyed = true;
	end

	if not html_table then
		return t;
	end

	local table_header = html_table:match("<thead>(.-)</thead>");
	local table_body = html_table:match("<tbody>(.-)</tbody>");

	if table_header then
		for table_column in table_header:gmatch("<th[^>]->(.-)</th>") do
			table.insert(h, table_column);
		end
	end

	if not table_body then
		table_body = html_table;
	end

	if not table_body:match("<tr[^>]->.-</tr>") then
		-- Special case stuff for if there aren't rows
		local i = 0;

		for table_entry in table_body:gmatch("<td[^>]->(.-)</td>") do
			i = i + 1;
			local real_table_entry = table_entry:match("<a[^>]->(.-)</a>") or table_entry;
			real_table_entry = Http.UnescapeString(real_table_entry);

			if real_table_entry:match("[^%s]") then
				table.insert(t, real_table_entry);
			end
		end
	else
		for table_row in table_body:gmatch("<tr[^>]->(.-)</tr>") do
			local i = 0;
			local sub_t = { };
			local key = nil;

			for table_entry in table_row:gmatch("<td[^>]->(.-)</td>") do
				i = i + 1;
				local real_table_entry = table_entry:match("<a[^>]->(.-)</a>") or table_entry;
				real_table_entry = Http.UnescapeString(real_table_entry);

				if keyed and i == 1 then
					key = real_table_entry;
				end

				if h[i] then
					sub_t[h[i]] = real_table_entry;
				else
					sub_t[i] = real_table_entry;
				end
			end
			
			if keyed then
				t[key] = sub_t;
			else
				table.insert(t, sub_t);
			end
		end
	end

	return t;
end

function Http.EscapeString(str)
	return str:gsub(".", Http.esc_table);
end

function Http.UnescapeString(str)
	return str:gsub("&(.-);", function(c)
		if c:sub(1, 1) == "#" then
			return ts.decode_utf8(tonumber(c:match("#(%d+)")));
		else
			return Http.unesc_table[c];
		end
	end);
end
