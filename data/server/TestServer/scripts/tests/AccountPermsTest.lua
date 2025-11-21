require("cryptic/AccountServer");
require("ltn12");

AccountServer.DefaultLocation("http://qa_02");
AccountServer.SetUser("lfalls");
AccountServer.SetPassword("password1");
local perms, alvl =
	AccountServer.GetAccountPermissionsForProduct("lfalls", "FightClub");
--[[print("Landon Falls owns the product PRD-CO-R: "
	..AccountServer.AccountOwnsProduct("lfalls", "PRD-CO-R"));
  --]]
local prod_perms = AccountServer.GetPermissionsForProduct("PRD-CO-R");
print("Key batch \"ACCESS LEVEL 1\" with prefix \"QAAL1\" grants product: "
	..AccountServer.GetProductForKeyBatch("QAAL1", "ACCESS LEVEL 1"));

for k,v in pairs(prod_perms) do
	if perms[k] ~= v then
		error("Permissions don't match up for key: "..k);
	end
end

print("All permissions match up for lfalls and PRD-CO-R!");
ts.done();