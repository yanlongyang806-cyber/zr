--[[
There are three possible return calls for UserDelete():
	1. success - The account has been successfully deleted.
	2. not_authorized - The account has been access since the
		account server has been started.  To reproduce this case, restart the account
		server and view the account on the AS's web interface.
	3. user_not_found - The user does not exist on the account server.

To use this script, please set UserDelete_accountID to the AccountID number 
	of the account you wish to delete.
--]]

require("cryptic/AccountServer");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Var");

Test.Require(Var.Get(nil, "UserDelete_accountID"), "Please set the global variable"
	.. "\"UserDelete_accountID\" to the account ID number you wish to delete.");

local accountID = Var.Get(nil, "UserDelete_accountID");

-- Begin Script
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("##### Starting Test #####");

print("\n\n##### WARNING #####");
print("The following account will be permenantly removed from the Account Server.");
print("Please shut down the TEST SERVER if you DO NOT wish to delete this account.");

print("\nAccountID:", accountID);
for i=15, 1, -1 do
	print("The account will be delete in:",i);
	Console.Wait(1);
end;

local response, result  = AccountServer.XMLRPC.UserDelete(accountID);
if response then
	print("\n\nAccount " .. accountID .. " has been successufully deleted.");
else
	print("\n\nAccount " .. accountID .. " has not been deleted.");
	print("Result:\t\t" .. result);
end;


print("##### Ending Test #####");
Test.Succeed();