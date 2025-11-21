-- This script will lock all the keyValues associated with a currency chain
require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

local ipAddress			= Var.Default(nil, "IP", "127.0.0.1");
local source			= Var.Default(nil, "source", "MyProxyServer");
local accountName		= Var.Default(nil, "accountName", "tvu_as_20111127_01");
local currency			= Var.Default(nil, "currency", "_ChampionsChain");
local paymentMethod		= Var.Default(nil, "paymentMethod", nil);
local price			= Var.Default(nil, "price", nil);
local bankName			= Var.Default(nil, "bankName", "Cryptic Bank");
local authonly			= Var.Default(nil, "authOnly", 1);
local locCode			= Var.Default(nil, "locCode", "EN");
local purchaseItemList		= Var.Default(nil, "productID", 120);		-- PRD-CO-M-AF-Submarine

-- Begin Script
Test.Begin();

-- Call PurchaseEX
print("\n\n##### Processing PurchaseEX #####");
local _, purchaseEXResponse = AccountServer.XMLRPC.PurchaseEX(accountName, paymentMethod,
	purchaseItemList, price, authonly, currency, ipAddress, bankName, locCode, source, steamID);

if purchaseEXResponse["Status"] ~= "SUCCESS" then
	Test.Fail("Calling PurchaseEX() did not return a SUCCESS");
end;

Console.PrintTable(purchaseEXResponse);

Test.Succeed();