require("cryptic/AccountServer");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Var");
require("cryptic/Test");

Test.Begin();

-- Test login to AS
AccountServer.Test.FailOnLoginFailure();

Test.Require(Var.Get(nil, "GetPurchaseLog_accountid"), "Please set the global variable "
	.. "\"GetPurchaseLog_accountid\" to an account id.");

local accountid = Var.Get(nil, "GetPurchaseLog_accountid");
local sinceSS2000 = Var.Default(nil, "PurchaseLog_SinceSS2000", 0);
local numofmaxresponses = Var.Default(nil, "PurchaseLog_NumofMaxResponses", 100);

-- #############################
-- MAIN SCRIPT
-- #############################

print("This test will run with the following parameters.");
print("Account ID:\t\t", accountid);
print("Time Since 2000:\t", sinceSS2000);
print("Number of Max Responses:", numofmaxresponses);

local callStatus, callReturnValue, purchaseLog = AccountServer.XMLRPC.GetPurchaseLogEx(sinceSS2000, numofmaxresponses, accountid);

if (callStatus) then
	for i, v in pairs(callReturnValue) do
		print(i, v);
	end;
else
	print("GetPurchaseLogEX() returned a fail/false");
end;

print("*********** START - Purchase Log *************");
Console.PrintTable(purchaseLog);
print("*********** STOP - Purchase Log *************");

Test.Succeed();