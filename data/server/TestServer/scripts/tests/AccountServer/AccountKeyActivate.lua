require("cryptic/AccountServer");
require("cryptic/AccountServer.Web");
require("cryptic/Console");
require("cryptic/Metric");
require("cryptic/Test");
require("cryptic/Var");

local accounts = Var.Get(nil, "AccountServer_NumAccounts");
Metric.Clear(nil, "AccountKeyActivate_Metric");

function AccountKeyActivate_ActivateKey(i, key)
	if not key then
		Test.Fail("Not enough keys!");
	end

	local n = "TestAccount4_"..string.format("%07d", i-1);
	local t_0 = ts.get_time();
	local s = AccountServer.ActivateKey(n, key);
	local t_1 = ts.get_time();

	if s == "user_update_ok" then
		Metric.Push(nil, "AccountKeyActivate_Metric", (t_1 - t_0));
	else
		Test.Error({Account = n, Error = s});
	end
end

Test.Begin();
local keys = AccountServer.Web.GetKeyList("TESTP");
Test.Require(keys, "Failed to get list of unused keys!");

-- Activate the keys, one by one
Test.RepeatArray(AccountKeyActivate_ActivateKey, keys);

-- Restart the Account Server and verify key activation
AccountServer.Kill();
AccountServer.LaunchAndWait();
local verify = math.floor(math.sqrt(accounts) * 5); -- Verify only some
for i = 1, verify do
	local n = "TestAccount4_"..string.format("%07d", math.random(0, accounts-1));
	Test.Require(AccountServer.AccountOwnsProduct(n, "TestProduct"),
		"Found an account that didn't own the product!", n);
	Test.Require(AccountServer.AccountHasPermission(n, "FightClub", "all"),
		"Found an account that didn't have permission!", n);
end

local activate_time = Metric.Average(nil, "AccountKeyActivate_Metric");
Test.Succeed({
	["Activated Per Second"] = 1.0 / activate_time
});
