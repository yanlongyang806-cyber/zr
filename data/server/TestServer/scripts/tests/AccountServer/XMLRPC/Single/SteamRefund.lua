require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Require(Var.Get(nil, "SteamRefund_accountName"), "Please set the global variable \"SteamRefund_accountName\" to the Account Name receiving the Steam refund.");
Test.Require(Var.Get(nil, "SteamRefund_orderID"), "Please set the global variable \"SteamRefund_orderID\" to the order id. [Set as a string]");

local accountName	= Var.Get(nil, "SteamRefund_accountName");
local orderID		= Var.Get(nil, "SteamRefund_orderID");
local source		= Var.Default(nil, "SteamRefund_source", "WebFC");

local XMLRPCSteamRefundRequest = {
	["accountName"]	= accountName,
	["orderID"]	= orderID,
	["source"]	= source
}

-- Begin Script
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

-- Getting Trans ID
local responseTable = AccountServer.XMLRPC.SteamRefund(accountName, orderID, source)

print("##### Starting Test #####");
print("Account Name:\t", accountName);
print("Order ID:\t", orderID);
print("Source:\t\t", source);
print("Trans ID:\t", responseTable["Transid"]);

-- Call TransView
print("\n\n##### Processing TransView #####");
local transViewResponse = AccountServer.XMLRPC.TransView(responseTable["Transid"]);

-- Trans View results
print("\n\n##### TransView Results #####");
if transViewResponse then
	print("TransID:\t", transViewResponse["Transid"]);
	print("PurchaseID:\t", transViewResponse["Purchaseid"]);
	print("UpendingactionID:\t", transViewResponse["Upendingactionid"]);
	print("Status:\t\t", transViewResponse["Status"]);
else
	print("TransView failed.", transViewResponse);
end;

Test.Succeed();