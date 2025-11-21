require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Scope");

Test.Begin();

local fn = Scope.Var.Get("List");
Test.Require(fn, "Must provide a CSV file of accounts/passwords to unlock!");

AccountServer.Test.FailOnLoginFailure();

local t = Console.ReadCSVFile(fn, "a_name", "password");

function UnlockAccount(i, a)
	local a_name = a["a_name"];
	local pw = a["password"];
	
	print(a_name, pw);
	local req = {
		["AccountName"] = a_name,
		["Sha256password"] = pw,
	};
	local r, t = AccountServer.XMLRPCRequest("UpdateUser", req);

	if not r then
		Test.Error(("XMLRPC FAIL %s: %s"):format(a_name, pw));
	elseif t["UserStatus"] ~= "user_update_ok" then
		Test.Error(("AS FAIL %s: %s"):format(a_name, pw));
	else
		Test.Note(("%s: %s"):format(a_name, pw));
	end
end

math.randomseed(os.time());
Test.RepeatArray(UnlockAccount, t);
Test.Succeed();
