require("cryptic/Console");
require("cryptic/Scope");
require("cryptic/Test");
require("xmlrpc.http");

function Wait(timeout)
	local t = ts.get_time();

	while ts.get_time() - t < timeout do
	end
end

Test.Begin();

local shard = Scope.Var.Get("Shard");
Test.Require(shard, "Please specify the target shard in the variable \"RenameGuilds:Shard\".");

local user = Scope.Var.Get("User");
Test.Require(user, "Please specify your Cryptic account name in the variable \"RenameGuilds:User\".");

local pass = Scope.Var.Get("Password");
Test.Require(pass, "Please specify your Cryptic account password in the variable \"RenameGuilds:Password\".");

local path = Scope.Var.Get("ImportFile");
Test.Require(path, "Please specify the full path to the fixup CSV in \"RenameGuilds:ImportFile\".");

function WebRequestXMLRPC(call, ...)
	return xmlrpc.http.authcall(("http://%s/xmlrpc/WebRequestServer[0]"):format(shard), user, pass, call, ...);
end

function FixupGuild(i, guild)
	time_print("Fixing up guild: "..guild.id);

	local r, t = WebRequestXMLRPC("GuildCSR_SetNameByID", guild.char, guild.id, guild.rename);
	if not r then
		Test.Error("GUILD ERROR "..i..": "..guild.id.." - "..t);
	end
	Wait(0.4);
end

local start_time = ts.get_time();

-- Read in a CSV containing rows specifying the guilds to fix up
local guilds = Console.ReadCSVFile(path, "id", "name", "rename", "ts", "char");

time_print("Beginning fixup.");
Test.RepeatArray(FixupGuild, guilds);

local finish_time = ts.get_time();
local elapsed = finish_time - start_time;

time_print(("Done performing fixup! (%0.2f s)"):format(elapsed));
time_print("Check the report for any errors.");

Test.Succeed();
