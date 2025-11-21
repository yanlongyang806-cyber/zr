require("cryptic/AccountServer");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Metric");
require("cryptic/Test");
require("cryptic/Var");

local accounts = Var.Get(nil, "AccountServer_NumAccounts");
Var.Set(nil, "Test_IP", "RANDOM");
Metric.Clear(nil, "AccountLoad_Created");
Metric.Clear(nil, "AccountLoad_Existed");

function AccountLoad_CreateAccount(i)
	local n = "TestAccount4_"..string.format("%07d", i-1);
	local t_0 = ts.get_time();
	
	local s = AccountServer.XMLRPC.CreateNewAccount(n, n, n, n.."@crypticstudios.com");
		
	local t_1 = ts.get_time();
	
	if s == "user_update_ok" then
		Metric.Push(nil, "AccountLoad_Created", (t_1 - t_0), false);
		print("Created account:", n);
	else
		Test.Error({Account = n, Error = s});
		print("Failed to create account:", n, s);
	end
	
end

Test.Begin();
Test.Repeat(AccountLoad_CreateAccount, 1, accounts);

-- Verify number of accounts created
print(accounts)
Test.NoteIfNotEqual(AccountServer.GetNumAccounts(), accounts,
	"Not all accounts were created, or there were already accounts on this server.");

-- Restart the Account Server and re-verify
AccountServer.Kill();
AccountServer.LaunchAndWait();
Test.NoteIfNotEqual(AccountServer.GetNumAccounts(), accounts,
	"Not all accounts were loaded after restart, or there were already accounts on this server.");

local creation_time = Metric.Average(nil, "AccountLoad_Created");
Test.Succeed({
	["Created Per Second"] = 1.0 / creation_time
});
