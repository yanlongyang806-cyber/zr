require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

-- #############################
-- MAIN SCRIPT
-- #############################
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("####################################");
print("\tBlocked IP Addresses");
print("####################################");

local response = AccountServer.XMLRPC.BlockedIPs();

if response["Ipratelimit"] ~= nil then
	for i,v in pairs(response["Ipratelimit"]) do
		print(("%d\tIP Address: %s\t Blocked Until: %s")
			:format(i, v.Ipaddress,
			SQLTimestampFromSS2000(v.Ublockeduntilss2000)));
	end
else
	print("The IP ban list is empty");
end

Test.Succeed();