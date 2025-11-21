require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/AccountServer/Test");
require("cryptic/Test");
require("cryptic/Var");


Var.Set(nil, "Test_IP", "RANDOM");
local Loop	= Var.Get(nil, "Test_Loop") or 1;
local Account	= ""
--Retail keys
local RetailPrefix	= Var.Get(nil, "Test_RetailBatchPrefix") or "SRGEN"
local RetailBatchName	= Var.Get(nil, "Test_RetailBatchName") or "STO Retail Generic"
local RetailKeys	= AccountServer.Web.GetUnusedKeysForBatch(RetailPrefix,RetailBatchName);Test.Require(RetailKeys[1], "Failed to get list of unused Retail keys!", "http://qa_02/legacy/keygroupView?prefix=SRGEN");
--GTCs
local GTCPrefix		= Var.Get(nil, "Test_GTCBatchPrefix") or "SGC6X"
local GTCBatchName	= Var.Get(nil, "Test_GTCBatchName") or "Game Card 60 Day"
local GTCKeys		= AccountServer.Web.GetUnusedKeysForBatch(GTCPrefix,GTCBatchName);Test.Require(GTCKeys[1], "Failed to get list of unused GTC keys!", "http://qa_02/legacy/keygroupView?prefix=SGC6X");
--Subscriptions
local UserSubscription	= nil;
local InteralProduct	= "startrek";
local GTCSub		= "SP-STO-GameCard";
local Sub1Mo		= "SP-STO-R1Month";
local Sub3Mo		= "SP-STO-R3Month";
local Sub6Mo		= "SP-STO-R6Month";
local SubLifetime	= "SP-STO-Lifetime";
local ProdLifetime	= "PRD-STO-R-Lifetime"
local Prod12Mo		= "PRD-STO-R-12MonthPO"

Test.Begin();
local i = 1;
while i <= Loop do
	print("---Loop: ", i);
	-----Create Account1
	Account = AccountServer.Test.CreateAccount()

	--Apply Retail Key
	--Add 1 Mo Sub with CC
	AccountServer.Test.SubscribeAccount(Account, Sub1Mo, InteralProduct, RetailKeys[i])

	--Cancel Sub
	AccountServer.Test.CancelSubAccount(Account, InteralProduct)

	--Reactivate 3 Mo Sub with CC
	AccountServer.Test.SubscribeAccount(Account, Sub3Mo, InteralProduct)

	--Remove CC
	AccountServer.Test.RemovePaymentMethod(Account, InteralProduct)

	--Purchase Cryptic Points with CC
	AccountServer.Test.PurchasePoints(Account)

	--Cancel Sub
	AccountServer.Test.CancelSubAccount(Account, InteralProduct)

	--Apply GTC
	AccountServer.Test.SubscribeAccount(Account, GTCSub, InteralProduct, GTCKeys[i])

	--Remove all payment methods
	AccountServer.Test.RemovePaymentMethod(Account, InteralProduct)
	
	i = i+1
end

Test.Succeed();
