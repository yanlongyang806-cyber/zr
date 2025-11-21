-- This script should be run after the successful completion of the scriptSteaGetUerInfo.lua
require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Require(Var.Get(nil, "SteamCompletePurchase_purchaseID"), "Please set the global" ..
	" variable\"SteamCompletePurchase_purchaseID\". [String]");
local accountName		= Var.Default(nil, "SteamGetUserInfo_accountName", "stevesteamgold");

-- Begin Script
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

local _, completePurchaseReponse	= AccountServer.XMLRPC.CompletePurchase(accountName,
	Var.Get(nil, "SteamCompletePurchase_purchaseID"));

Console.PrintTable(completePurchaseReponse);

print("Verify the purchase by looking at the AS web interface for your account. There should be" ..
	" a corresponding transaction in your purchase history, and your point total should have" ..
	" increased appropriately.");
Test.Succeed();