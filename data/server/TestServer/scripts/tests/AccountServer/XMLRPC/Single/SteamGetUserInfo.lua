-- Steve Yuong's Steam ID 76561198043104958
-- Tung Vu's Steam ID 76561198033444102

require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Require(Var.Get(nil, "SteamGetUserInfo_steamID"), "Please set the global variable" ..
	" \"SteamRefund_accountName\" to the account's steamID64. [String]");

local steamID			= Var.Get(nil, "SteamGetUserInfo_steamID");
local ipAddress			= Var.Default(nil, "SteamGetUserInfo_IP", "127.0.0.1");
local source			= Var.Default(nil, "SteamGetUserInfo_source", "WebFC");
local accountName		= Var.Default(nil, "SteamGetUserInfo_accountName", "stevesteamgold");
local currency			= Var.Default(nil, "SteamGetUserInfo_currency", "USD");
local paymentMethod		= Var.Default(nil, "SteamGetUserInfo_paymentMethod", nil);
local price			= Var.Default(nil, "SteamGetUserInfo_price", nil);
local bankName			= Var.Default(nil, "SteamGetUserInfo_bankName", "Cryptic Bank");
local authonly			= Var.Default(nil, "SteamGetUserInfo_authOnly", 1);
local locCode			= Var.Default(nil, "SteamGetUserInfo_locCode", "EN");
local purchaseItemList		= Var.Default(nil, "SteamGetUserInfo_ProductID", 1067);		-- PRD-PaidCrypticPoints-500-Steam

local XMLRPCSteamGetUserInfoRequest = {
	["steamID"]		= steamID,
	["ip"]			= ipAddress,
	["source"]		= source
};

-- Begin Script
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

-- Getting Trans ID
local steamGetUserInfoReponseTable = AccountServer.XMLRPC.SteamGetUserInfo(steamID, ipAddress, source);

print("##### Starting Test #####");
print("SteamID64:\t", steamID);
print("ID Address:\t", ipAddress);
print("Source:\t\t", source);
print("Trans ID:\t", steamGetUserInfoReponseTable["Transid"]);

-- Call TransView #1
print("\n\n##### Processing TransView 1 #####");
local transViewResponse1	= AccountServer.XMLRPC.TransView(
	steamGetUserInfoReponseTable["Transid"]);

-- Testing Return values
if transViewResponse1["Status"] ~= "SUCCESS" then
	Test.Fail("Calling SteamGetUserInfo() did not return a SUCCESS");
end

if transViewResponse1["Steamcountry"] == "US" then
	print("Steam Country:\t", transViewResponse1["Steamcountry"]);
else
	Test.Fail("Calling SteamGetUserInfo() did not return Steamcountry == US");
end

if transViewResponse1["Steamcurrency"] == "USD" then
	print("Steam Currency:\t", transViewResponse1["Steamcurrency"]);
else
	Test.Fail("Calling SteamGetUserInfo() did not return Steamcurrency == USD");
end

if transViewResponse1["Steamstatus"] == "Active" then
	print("Steam Status:\t", transViewResponse1["Steamstatus"]);
else
	Test.Fail("Calling SteamGetUserInfo() did not return Steamstatus == Active");
end

-- Call PurchaseEX
print("Calling TransView - Successful");
print("\n\n##### Processing PurchaseEX #####");
local _, purchaseEXResponse = AccountServer.XMLRPC.PurchaseEX(accountName, paymentMethod,
	purchaseItemList, price, authonly, currency, ipAddress, bankName, locCode, source, steamID);

if purchaseEXResponse["Status"] ~= "SUCCESS" then
	Test.Fail("Calling PurchaseEX() did not return a SUCCESS");
end;

-- Call TransView #2
print("\n\n##### Processing TransView 2 #####");
local transViewResponse2	= AccountServer.XMLRPC.TransView(purchaseEXResponse["Transid"]);
local redirectURL		= transViewResponse2["Redirecturl"];
local purchaseID		= transViewResponse2["Purchaseid"];

-- Testing Return value
if transViewResponse2["Status"] ~= "SUCCESS" then
	Test.Fail("Calling TransView for PurchaseEX() did not return a SUCCESS");
end

-- Display intructions to complete the test.
print("Please open a web broswer and load the following URL\n\n");
print(redirectURL .. "?returnurl=http://www.champions-online.com");
print("\n\nOnce the page loads, please log into the Steam site and approve the sandbox transaction.");
print("Once approved, please run the script \"SteamCompletePurchase.lua\"");
print("Please set the global variable \"SteamCompletePurchase_purchaseID\" to " .. 
	purchaseID .. " [Integer]");

Test.Succeed();