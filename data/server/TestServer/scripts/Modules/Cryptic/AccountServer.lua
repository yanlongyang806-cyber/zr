require("cryptic/Console");
require("cryptic/Console.Patch");
require("cryptic/Var");
require("xmlrpc.http");

-------------------
--Local Variables--
-------------------
AccountServer = {
	loc = Var.Default(nil, "AccountServer_Loc", "localhost"),
	port = Var.Default(nil, "AccountServer_Port", 80),
	dir = Var.Default(nil, "AccountServer_Dir", "C:\\Infrastructure"),
	x64 = Var.Get(nil, "AccountServer_UseX64"),
	version = Var.Get(nil, "AccountServer_Version"),
	user = Var.Get(nil, "AccountServer_User"),
	password = Var.Get(nil, "AccountServer_Password"),
	billing = Var.Default("AccountServer", "Billing", false),
};

-------------------
--Setup Functions--
-------------------
function AccountServer.DefaultLocation(loc)
	AccountServer.loc = Var.Default(nil, "AccountServer_Loc", loc);
end

function AccountServer.SetLocation(loc)
	AccountServer.loc = Var.Set(nil, "AccountServer_Loc", loc);
end

function AccountServer.DefaultDir(dir)
	AccountServer.dir = Var.Default(nil, "AccountServer_Dir", dir);
end

function AccountServer.SetDir(dir)
	AccountServer.dir = Var.Set(nil, "AccountServer_Dir", dir);
end

function AccountServer.DefaultX64(x64)
	AccountServer.x64 = Var.Default(nil, "AccountServer_UseX64", x64);
end

function AccountServer.SetX64(x64)
	AccountServer.x64 = Var.Set(nil, "AccountServer_UseX64", x64);
end

function AccountServer.DefaultVersion(version)
	AccountServer.version = Var.Default(nil, "AccountServer_Version", version);
end

function AccountServer.SetVersion(version)
	AccountServer.version = Var.Set(nil, "AccountServer_Version", version);
end

function AccountServer.DefaultUser(user)
	AccountServer.user = Var.Default(nil, "AccountServer_User", user);
end

function AccountServer.SetUser(user)
	AccountServer.user = Var.Set(nil, "AccountServer_User", user);
end

function AccountServer.DefaultPassword(password)
	AccountServer.password = Var.Default(nil, "AccountServer_Password", password);
end

function AccountServer.SetPassword(password)
	AccountServer.password = Var.Set(nil, "AccountServer_Password", password);
end

function AccountServer.DefaultBilling(bill)
	AccountServer.billing = Var.Default("AccountServer", "Billing", bill);
end

function AccountServer.SetBilling(bill)
	AccountServer.billing = Var.Set("AccountServer", "Billing", bill);
end

function AccountServer.GetExePath()
	local exe = AccountServer.dir;
	
	if not exe:match("^.-[/\\]AccountServer[/\\]?$") then
		exe = exe.."/AccountServer";
	end

	exe = exe.."/AccountServer";

	if AccountServer.x64 then
		exe = exe.."X64";
	end

	exe = exe..".exe";

	return exe;
end

function AccountServer.CleanDB()
	Console.RemoveDir(AccountServer.dir.."/AccountServer/accountdb");
end

function AccountServer.Patch()
	Console.Patch.Patch(AccountServer.dir, "AccountServer",
		AccountServer.version);
end

function AccountServer.Launch(...)
	local exe = AccountServer.GetExePath();
	local cmdline = "-clienttimeout 86400 -allowcommandsinurl -newwebinterface";

	if not AccountServer.billing then
		cmdline = cmdline.." -billingenabled 0"
	end

	for _, v in ipairs({...}) do
		cmdline = cmdline.." -"..v;
	end

	local handle = Console.RunApp(exe, cmdline);
	Var.Set("AccountServer", "Handle", handle);
end

function AccountServer.LaunchAndWait(timeout, ...)
	AccountServer.Launch(...);
	local result = AccountServer.WaitFor(timeout, AccountServer.Poke);
	return result;
end

function AccountServer.LaunchKeyGenerating()
	local exe = AccountServer.GetExePath();
	local cmdline = "-mode KeyGenerating -httpport 81";
	cmdline = cmdline.." -setaccountserver localhost -keybatchsize 1000000";

	local handle = Console.RunApp(exe, cmdline);
	Var.Set("AccountServer", "HandleKeyGenerating", handle);
end

function AccountServer.LaunchKeyGeneratingAndWait(timeout)
	AccountServer.LaunchKeyGenerating();
	local result = AccountServer.WaitFor(timeout, AccountServer.PokeKeyGenerating);
	return result;
end

function AccountServer.Poke()
	local r, t = AccountServer.XMLRPCRequest("IsValidProductKey", "AFAKEKEYTHATHASBUT25CHARS");
	
	if not r and (t:match("timeout") or t:match("refused")) then
		return false;
	else
		return true;
	end
end

function AccountServer.PokeKeyGenerating()
	local r, c, _, _ = AccountServer.Web.Request("batchCreate", "prefix=test", 81);

	if c == 200 then
		return true;
	else
		return false;
	end
end

function AccountServer.WaitFor(timeout, func)
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

function AccountServer.Kill()
	local handle = Var.Clear("AccountServer", "Handle");

	if handle then
		Console.Close(handle);
	end
end

function AccountServer.KillKeyGenerating()
	local handle = Var.Clear("AccountServer", "HandleKeyGenerating");

	if handle then
		Console.Close(handle);
	end
end

function AccountServer.XMLRPCLoc()
	return "http://"..AccountServer.loc..":8081/xmlrpc";
end

function AccountServer.XMLRPCRequest(call, ...)
	if AccountServer.user and AccountServer.password then
		return xmlrpc.http.authcall(AccountServer.XMLRPCLoc(),
			AccountServer.user, AccountServer.password, call, ...);
	else
		return xmlrpc.http.call(AccountServer.XMLRPCLoc(), call, ...);
	end
end

-----------
--Actions--
-----------
function AccountServer.GetNumAccounts()
	local r, t = AccountServer.XMLRPCRequest("Stats");

	if not r then
		return 0;
	end

	return t["Stats"]["Numaccounts"];
end

function AccountServer.GetNumKeysByBatch(batch)
	local r, t = AccountServer.XMLRPCRequest("Stats");

	if not r then
		return 0;
	end

	for i,v in ipairs(t["Stats"]["Batchnames"]) do
		if v == batch then
			return t["Stats"]["Keycounts"][i+1]["Availablekeys"];
		end
	end

	return 0;
end

function AccountServer.ActivateAccount(priv_n, token)
	local r, t = AccountServer.XMLRPCRequest("ValidateAccountEmail", priv_n, token, 0);

	if not r then
		return t;
	end

	return t["UserStatus"];
end

function AccountServer.CreateAndActivateAccount(disp_n, priv_n, pw, email)
	local status, token = AccountServer.CreateAccount(disp_n, priv_n, pw, email);

	if status ~= "email_exists" then
		if status ~= "user_update_ok" or not token then
			return status;
		end

		status = AccountServer.ActivateAccount(priv_n, token);
	end

	return status;
end

function AccountServer.ActivateKey(priv_n, key)
	local r, t = AccountServer.XMLRPCRequest("ActivateProductKey", priv_n, key);

	if not r then
		return t;
	end

	return t["UserStatus"];
end

function AccountServer.AccountOwnsProduct(priv_n, prod)
	local prods = AccountServer.GetAccountProducts(priv_n);

	for _, v in ipairs(prods) do
		if v:lower() == prod:lower() then
			return true;
		end
	end

	return false;
end

function AccountServer.AccountHasPermission(priv_n, prod, shard)
	local r, t = AccountServer.XMLRPCRequest("UserInfo", priv_n, 1);

	if not r then
		return false;
	end

	for i, v in ipairs(t["Productpermissions"]) do
		if v["Product"] == prod and v["Permissions"]:match(shard) then
			return true;
		end
	end

	return false;
end

function AccountServer.ParsePermissionString(str)
	local perm_table = { };

	for ind_perm in str:gmatch("([^;]+)") do
		local key, value = ind_perm:match("(%w+): (%w+)");
		perm_table[key] = tonumber(value) or value;
	end

	return perm_table;
end

function AccountServer.GetAccountProducts(priv_n)
	local r, t = AccountServer.XMLRPCRequest("UserInfo", priv_n, 4);

	local prods = { };

	if r then
		if t["Products"] then
			for i, v in ipairs(t["Products"]) do
				table.insert(prods, v["Name"]);
			end
		end
	end

	return prods;
end
