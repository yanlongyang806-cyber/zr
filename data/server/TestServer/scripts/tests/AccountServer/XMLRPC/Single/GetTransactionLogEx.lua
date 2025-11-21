require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Var");
require("cryptic/Test");

Test.Begin();

Test.Require(Var.Get(nil, "GetTransactionLog_accountid"), "Please set the global variable "
	.. "\"GetTransactionLog_accountid\" to an account id.");

local accountid = Var.Get(nil, "GetTransactionLog_accountid");
local sinceSS2000 = Var.Default(nil, "TransactionLog_sinceSS2000", 0);
local numofmaxresponses = Var.Default(nil, "TransactionLog_Numofmaxresponses", 100);

-- #############################
-- MAIN SCRIPT
-- #############################

-- Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("This test will run with the following parameters.");
print("Account ID:\t\t", accountid);
print("Time Since 2000:\t", sinceSS2000);
print("Number of Max Responses:", numofmaxresponses);

local callStatus, callReturnValue, transactionLog = AccountServer.XMLRPC.GetTransactionLogEx(sinceSS2000, numofmaxresponses, accountid);

if (callStatus) then
	for i, v in pairs(callReturnValue) do
		print(i, v);
	end;
else
	print("GetTransactionLogEX() returned a fail/false");
end;

print("\n\n*********** START - Transaction Log *************");
Console.PrintTable(transactionLog);
print("*********** STOP - Transaction Log *************");

Test.Succeed();