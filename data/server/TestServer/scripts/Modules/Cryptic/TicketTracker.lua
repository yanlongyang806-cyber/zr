require("cryptic/Console");
require("cryptic/Var");
require("socket.http");
require("xmlrpc.http");

TicketTracker = {
	loc = Var.Default(nil, "TicketTracker_Loc", "localhost"),
	port = Var.Default(nil, "TicketTracker_Port", 80);
	dir = Var.Default(nil, "TicketTracker_Dir", "C:/Infrastructure"),
	x64 = Var.Get(nil, "TicketTracker_UseX64"),
	version = Var.Get(nil, "TicketTracker_Version"),

	user = Var.Get(nil, "TicketTracker_User"),
	password = Var.Get(nil, "TicketTracker_Password"),
};

function TicketTracker.DefaultLocation(loc)
	TicketTracker.loc = Var.Default(nil, "TicketTracker_Loc", loc);
end

function TicketTracker.SetLocation(loc)
	TicketTracker.loc = Var.Set(nil, "TicketTracker_Loc", loc);
end

function TicketTracker.DefaultPort(port)
	TicketTracker.port = Var.Default(nil, "TicketTracker_Port", port);
end

function TicketTracker.SetPort(port)
	TicketTracker.port = Var.Set(nil, "TicketTracker_Port", port);
end

function TicketTracker.DefaultDir(dir)
	TicketTracker.dir = Var.Default(nil, "TicketTracker_Dir", dir);
end

function TicketTracker.SetDir(dir)
	TicketTracker.dir = Var.Set(nil, "TicketTracker_Dir", dir);
end

function TicketTracker.DefaultX64(x64)
	TicketTracker.x64 = Var.Default(nil, "TicketTracker_UseX64", x64);
end

function TicketTracker.SetX64(x64)
	TicketTracker.x64 = Var.Set(nil, "TicketTracker_UseX64", x64);
end

function TicketTracker.DefaultVersion(version)
	TicketTracker.version = Var.Default(nil, "TicketTracker_Version", version);
end

function TicketTracker.SetVersion(version)
	TicketTracker.version = Var.Set(nil, "TicketTracker_Version", version);
end

function TicketTracker.DefaultUser(user)
	TicketTracker.user = Var.Default(nil, "TicketTracker_User", user);
end

function TicketTracker.SetUser(user)
	TicketTracker.user = Var.Set(nil, "TicketTracker_User", user);
end

function TicketTracker.DefaultPassword(pass)
	TicketTracker.password = Var.Default(nil, "TicketTracker_Password", pass);
end

function TicketTracker.SetPassword(pass)
	TicketTracker.password = Var.Set(nil, "TicketTracker_Password", pass);
end

function TicketTracker.WebLoc()
	return "http://"..TicketTracker.loc..":81";
end

function TicketTracker.XMLRPCLoc()
	return "http://"..TicketTracker.loc..":8082/xmlrpc";
end

function TicketTracker.XMLRPCRequest(call, ...)
	if TicketTracker.user and TicketTracker.password then
		return xmlrpc.http.authcall(TicketTracker.XMLRPCLoc(),
			TicketTracker.user, TicketTracker.password, call, ...);
	else
		return xmlrpc.http.call(TicketTracker.XMLRPCLoc(), call, ...);
	end
end

function TicketTracker.GetExePath()
	local exe = TicketTracker.dir;
	
	if not exe:match("^.-[/\\]TicketTracker[/\\]?$") then
		exe = exe.."/TicketTracker";
	end

	exe = exe.."/CSRTicketTracker";

	if TicketTracker.x64 then
		exe = exe.."X64";
	end

	exe = exe..".exe";

	return exe;
end

function TicketTracker.CleanDB()
	Console.RemoveDir(TicketTracker.dir.."/TicketTracker/localdata");
end

function TicketTracker.Patch()
	Console.Patch(TicketTracker.dir, "TicketTracker", TicketTracker.version);
end

function TicketTracker.Launch()
	local exe = TicketTracker.GetExePath();
	local cmdline = "-allowcommandsinurl";
	local handle = Console.RunApp(exe, cmdline);
	Var.Set("TicketTracker", "Handle", handle);
end

function TicketTracker.LaunchAndWait(timeout)
	TicketTracker.Launch();
	local result = TicketTracker.WaitFor(timeout, TicketTracker.Poke);
	return result;
end

function TicketTracker.Poke()
	local _, c, _, _ = socket.http.request(TicketTracker.WebLoc());

	if tonumber(c) == 200 then
		return true;
	else
		return false;
	end
end

function TicketTracker.WaitFor(timeout, func)
	local check = ts.get_time();
	local start = check;

	while ts.get_time() - check < 1.0 or not func() do
		if timeout and ts.get_time() - start > timeout then
			return false;
		end

		if ts.get_time() - check >= 1.0 then
			check = ts.get_time();
		end
	end

	return true;
end

function TicketTracker.Kill()
	local handle = Var.Clear("TicketTracker", "Handle");

	if handle then
		Console.Close(handle);
	end
end

function TicketTracker.UnBase64(t)
	if t.Puserdescription then
		t.Puserdescription = ts.decode_64(t.Puserdescription);
	end

	if t.Psummary then
		t.Psummary = ts.decode_64(t.Psummary);
	end
end

function TicketTracker.CreateTicket(tbl)
	local ticket_data = {
		Platformname = tbl.platform or "Win32",
		Productname = tbl.product or "FightClub",
		Versionstring = tbl.version or TicketTracker.version,
		Accountname = tbl.priv_n,
		Displayname = tbl.disp_n,
		Charactername = tbl.character,
		Maincategory = tbl.main_category or
			"CBug.CategoryMain.GameSupport",
		Category = tbl.category,
		Summary = tbl.summary,
		Userdescription = tbl.desc,
		Productionmode = tbl.prod_mode or 1,
		Visibility = tbl.visibility or "Ticket.Visibility.Public",
		Language = 1
	};

	local r, t = TicketTracker.XMLRPCRequest("TT_CreateTicket", "Test Server", ticket_data, 0, "");

	if r then
		TicketTracker.UnBase64(t);
	end

	return r, t;
end

function TicketTracker.GetNumTickets(cat, sub_cat)

	local r, t = TicketTracker.XMLRPCRequest("TT_GetTicketCount", cat, sub_cat or "");

	if not r then
		return 0;
	end

	return tonumber(t);
end

function TicketTracker.GetNumPrivateTickets(cat, subcat, count, offset, vis)
	if not vis then
		vis = 1;
	end

	if type(subcat) == "number" then
		offset = count;
		count = subcat;
		subcat = nil;
	end

	local sd = {
		MainCategory = cat,
		Category = subcat,
		AdminSearch = 2,
		Limit = count,
		Offset = offset,
		Visible = vis,
	};
	local r, t = TicketTracker.XMLRPCRequest("TT_SearchTickets", "Test Server", sd);

	if not r then
		return 0
	end

	return t.Numberofresults;
end

function TicketTracker.GetTickets(cat, subcat, count, offset, vis)
	if not vis then
		vis = 1;
	end

	if type(subcat) == "number" then
		offset = count;
		count = subcat;
		subcat = nil;
	end

	local sd = {
		MainCategory = cat,
		Category = subcat,
		AdminSearch = 2,
		Limit = count,
		Offset = offset,
		Visible = vis,
	};
	local r, t = TicketTracker.XMLRPCRequest("TT_SearchTickets", "Test Server", sd);

	if not r then
		return nil;
	end

	return t;
end

function TicketTracker.BatchListFromSearch(sd)
	local ids = {};
	for _, v in ipairs(sd.Sortedentries) do
		table.insert(ids, {id = v.UID});
	end
	local array_type = xmlrpc.newArray("table");
	return {list = xmlrpc.newTypedValue(ids, array_type)};
end

function TicketTracker.BatchHide(list)
	acts = {
		Visibility = "Ticket.Visibility.Hidden",
	};
	local r, t = TicketTracker.XMLRPCRequest("TT_BatchAction", "Test Server", list, acts);
	return r and t;
end

function TicketTracker.BatchResolve(list)
	acts = {
		Status = "Ticket.Status.Resolved",
		Visibility = "Ticket.Visibility.Hidden",
	};
	local r, t = TicketTracker.XMLRPCRequest("TT_BatchAction", "Test Server", list, acts);
	return r and t;
end