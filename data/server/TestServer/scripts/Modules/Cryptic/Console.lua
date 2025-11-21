Console = { };

function Console.SplitFilePath(path)
	return path:match("^(.-)[/\\]?([%w%.]+)$");
end

function Console.Run(cmd)
	return app_run(cmd);
end

function Console.RunInWD(wd, cmd)
	local old_wd = nil;

	if wd then
		old_wd = get_cwd();
		set_cwd(wd);
	end

	local handle = Console.Run(cmd);

	if old_wd then
		set_cwd(old_wd);
	end

	return handle;
end

function Console.RunAndWaitInWD(wd, cmd, timeout)
	local handle = Console.RunInWD(wd, cmd)
	return Console.WaitFor(handle, timeout)
end

function Console.RunAndWait(cmd, timeout)
	local handle = Console.Run(cmd);
	return Console.WaitFor(handle, timeout);
end

function Console.RunApp(app, cmdline)
	local wd, name = Console.SplitFilePath(app);
	return Console.RunInWD(wd, name.." "..cmdline);
end

function Console.RunAppAndWait(app, cmdline, timeout)
	local handle = Console.RunApp(app, cmdline);
	return Console.WaitFor(handle, timeout);	
end

function Console.WaitFor(handle, timeout)
	local check = ts.get_time();
	local start = check;

	while ts.get_time() - check < 1.0 or not app_check(handle) do
		if timeout and ts.get_time() - start > timeout then
			Console.Kill(handle);
			return false;
		end

		if ts.get_time() - check >= 1.0 then
			check = ts.get_time();
		end
	end

	return true;
end

function Console.Close(handle)
	app_close(handle);
end

function Console.Kill(handle)
	app_kill(handle);
end

function Console.Remove(file)
	local wd, name = Console.SplitFilePath(file);
	local handle = Console.RunInWD(wd, "rm "..name);
	return Console.WaitFor(handle);
end

function Console.RemoveFilesFromTable(dir, table)
	local wd, name	= nil
	local handle	= nil
	local dir	= dir or "C:/Core/data/server/TestServer/scripts/General"

	for i, v in ipairs(table) do
		handle = Console.RunInWD(dir, "rm "..'"'..v..'"');

		if Console.WaitFor(handle) == false then
			return false
		end
	end
	return true
end

function Console.RemoveDir(dir)
	local wd, name = Console.SplitFilePath(dir);
	local handle = Console.RunInWD(wd, "rmdir /S /Q "..name);
	return Console.WaitFor(handle);
end

function Console.CopyPatchClientTo(loc)
	--Now an alias
	return Console.Patch.CopyPatchClientTo(loc)
end

function Console.ReadListFile(file)
	local t = { };
	local f = io.open(file);

	if not f then
		return nil;
	end

	for l in f:lines() do
		table.insert(t, l);
	end

	f:close();

	return t;
end

function Console.WriteListFile(file, t)
	local f = io.open(file, "w");

	if not f then
		return false;
	end

	for i, l in ipairs(t) do
		if i > 1 then
			f:write("\n");
		end

		f:write(l);
	end

	f:close();

	return true;
end

function Console.EscapeCSVLine(t)
	local esc_t = {};

	for k, v in pairs(t) do
		esc_t[k] = t[k];
		esc_t[k] = esc_t[k]:gsub("\"", "\"\"");
		
		if esc_t[k]:match("[\",]") then
			esc_t[k] = "\""..esc_t[k].."\"";
		end
	end

	return Console.Join(esc_t, ",");
end

function Console.UnescapeCSVLine(t)
	local count = #t;

	local i = 1;
	while i <= #t do
		local _, quotes = t[i]:gsub("\"", function() return nil end);
		if quotes % 2 == 1 then
			t[i] = t[i]..","..t[i+1];
			table.remove(t, i+1);
		else
			i = i + 1;
		end
	end

	for i, v in ipairs(t) do
		t[i] = v:match("^\"?(.-)\"?$");
		t[i] = t[i]:gsub("\"\"", "\"");
	end
end

function Console.ReadCSVLineInternal(t, r)
	local p = ipairs(r);
	local i = 0;
	t[#t+1] = {};

	for _, entry in p, r, 0 do
		if not t[0][i+1] or t[0][i+1] == "" then
			break;
		end

		i = i + 1;
		t[#t][t[0][i]] = entry;
	end

	for j, entry in p, r, i do
		t[#t][j-i] = entry;
	end
end

function Console.ReadCSVFile(file, ...)
	local t = { };
	local f = io.open(file);

	if not f then
		return nil;
	end

	local lines = f:lines();
	local l = lines();
	t[0] = Console.Split(l, ",");
	Console.UnescapeCSVLine(t[0]);

	for i, h in ipairs({...}) do
		if t[0][i] ~= h then
			local temp_t = t[0];
			t[0] = {...};
			Console.ReadCSVLineInternal(t, temp_t);
			break;
		end
	end

	for l in lines do
		local temp_t = Console.Split(l, ",");
		Console.UnescapeCSVLine(temp_t);
		Console.ReadCSVLineInternal(t, temp_t);
	end

	f:close();

	return t;
end

function Console.TrimTable(t)
	
	if t ~= nil then
		for _, v in pairs(t) do
			v = Console.Trim(v);
		end
	end

	return t;
end

-- Currently, this function can not handle tables that are index by integers.
-- The table index must be a string.
function Console.WriteCSVFile(file, t)
	local f = io.open(file, "w");

	if not f then
		return nil;
	end

	local h = t[0];

	if not h then
		h = {};
		local h_x = {};

		for i, _ in ipairs(t) do
			for k, v in pairs(t[i]) do
				if type(k) ~= "number" and not h_x[k] then
					table.insert(h, k);
					h_x[k] = true;
				end
			end
		end
	end

	f:write(Console.EscapeCSVLine(h));

	for _, v in ipairs(t) do
		local sub_t = {};

		f:write("\n");

		for _, w in ipairs(h) do
			table.insert(sub_t, v[w] or "");
		end

		for _, w in ipairs(v) do
			table.insert(sub_t, w);
		end

		f:write(Console.EscapeCSVLine(sub_t));
	end

	f:close();

	return true;
end

function Console.WriteTXTFile(file, t, header)
	local f = io.open(file, "w");

	if not f then
		return nil;
	end
	
	if header then
		f:write(header);
	end

	if t then
		for _, v in pairs(t) do
		
		f:write("\n"..v);
		end
	end
	
	f:close();

	return true;
end

function Console.Split(str, sep)
	local t = { };
	local pos = 1;

	if string.find("", sep) then
		return t;
	end

	while true do
		local first, last = string.find(str, sep, pos);
		if first then
			table.insert(t, string.sub(str, pos, first-1));
			pos = last + 1;
		else
			table.insert(t, string.sub(str, pos));
			break;
		end
	end

	return t;
end

function Console.Join(t, join)
	local p = ipairs(t);
	local _, v = p(t, 0);
	local str = v;
	join = join or "";

	for _, v in p, t, 1 do
		str = str..join..v;
	end

	return str;
end

function Console.JoinTables(t1, t2)
	local t = t1;
	for k, v in pairs(t2) do
		t[k] = v;
	end
	return t;
end

function Console.AppendTable(t1, t2)
	local t = t1;
	for k, v in ipairs(t2) do
		table.insert(t, v);
	end
	return t;
end

function Console.FilePathFromString(dir, fn, fileformat)
	local path = "";

	if not fn:match("%.%w%w?%w?%w?%w?$") and fileformat then
		fileformat = fileformat:match("^%.?([^%.]*)$");

		if fileformat then
			fn = fn.."."..fileformat;
		end
	end

	if fn:find(":") then
		-- fn is an absolute path, so we don't care about dir
		path = fn;
	else
		if dir then
			-- Change everything to forward slashes
			dir = dir:gsub("/", "\\");
			-- Chop leading and trailing slashes from dir
			dir = dir:match("^\\*(.-)\\*$");
		end

		if not dir or not dir:match(":") then
			-- dir is a path relative to our predefined root
			path = "C:\\Core\\data\\server\\TestServer\\scripts\\General\\";
		end

		if dir then
			path = path..dir.."\\";
		end

		path = path..fn;
	end
	
	return path;
end

function Console.Trim(s)
	if type(s) == "string" then
		return s:match("^%s*(.-)%s*$");
	else
		return s;
	end
end

-- Wait time has to be an integer >= 1
function Console.Wait(s)
	local time = 1;
	while (time <= s) do
		os.execute("sleep 1");
		time = (time + 1);
	end
	return
end

-- Sleep can handle time < 1 second
function Console.Sleep(s)
	local time = os.clock();
	while os.clock() - time < s do end;

	return;
end;

function Console.ZipFiles(dir, zipname, password, ...)
	--7z a -p{password here} filename.zip {filenames}
	local cmd = "7z a"
	local dir = dir or "C:/Core/data/server/TestServer/scripts/General"
	
	if password then
		cmd = cmd.." -p"..password
	end

	cmd = cmd..' "'..zipname..'.zip"'
	
	for i, v in ipairs({...}) do
		cmd = cmd..' "'..v..'"'
	end

	return Console.RunAndWaitInWD(dir, cmd, 60)
end

function Console.ZipFilesFromTable(dir, zipname, password, table)
	local cmd = "7z a"
	local dir = dir or "C:/Core/data/server/TestServer/scripts/General"
	
	if password then
		cmd = cmd.." -p"..password
	end

	cmd = cmd..' "'..zipname..'.zip"'

	for i, v in ipairs(table) do
		cmd = cmd..' "'..v..'"'
	end
	
	return Console.RunAndWaitInWD(dir, cmd, 60)
end

-- Recursively prints out the content of a generic table
Console.PrintTable = { };
Console.PrintTable = function (kvtable, numoftabs)
	numoftabs = numoftabs or 0;
	local tabs = string.rep("\t", numoftabs);	-- Used for formatting

	for i, v in pairs(kvtable) do
		if (type(v) == "table") then
			print(tabs, i);
			Console.PrintTable(v, numoftabs+1);
		else
			print(tabs, i, v);
		end;
	end;
	print("");

	return;
end