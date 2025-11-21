require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/Test");
require("cryptic/Var");
require("ss2000");

Var.Set(nil, "Test_IP", "RANDOM");

--Account Info
local TimeStamp		= string.gsub(os.date(), "[%s%p]", "_");
local Account1		= "SubLifetime1_"..TimeStamp;
local Account2		= "SubLifetime2_"..TimeStamp;
local Account3		= "SubLifetime3_"..TimeStamp;
local Account4		= "SubLifetime4_"..TimeStamp;
local EmailSuffix	= "@Subscriptions.com";
local Email1		= Account1..EmailSuffix;
local Email2		= Account2..EmailSuffix;
local Email3		= Account3..EmailSuffix;
local Email4		= Account4..EmailSuffix;
local Password		= "password1";
--Retail keys
local RetailKeys	= AccountServer.Web.GetUnusedKeysForBatch("SRGEN","STO Retail Generic");
Test.Require(RetailKeys[1], "Failed to get list of unused Retail keys!", "http://qa_02/legacy/keygroupView?prefix=SRGEN");
--GTCs
local GTCKeys		= AccountServer.Web.GetUnusedKeysForBatch("SGC6X","Game Card 60 Day");
Test.Require(GTCKeys[1], "Failed to get list of unused GTC keys!", "http://qa_02/legacy/keygroupView?prefix=SGC6X");
--Subscriptions
local UserSubscription	= nil;
local EntitlementEnd	= nil;
local InteralProduct	= "startrek";
local GTCSub		= "SP-STO-GameCard";
local Sub1Mo		= "SP-STO-R1Month";
local Sub3Mo		= "SP-STO-R3Month";
local Sub6Mo		= "SP-STO-R6Month";
local SubLifetime	= "SP-STO-Lifetime";
local ProdLifetime	= "PRD-STO-R-Lifetime"
local Prod12Mo		= "PRD-STO-R-12MonthPO"
local SS60Days		= 5184000; --60 days
local GracePeriod	= 86400; --24 hours
--Cryptic Points
local UserCrypticPoints = nil
local CrypticPoints	= 76


Test.Begin();
-----Create Account1
print("\nCreating account '"..Account1.."'...");
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account1, Password, Name, Email1), "user_update_ok");

--Apply Retail Key
--Add Lifetime with CC
print("\nApplying retail key and activating Lifetime sub...");
AccountServer.XMLRPC.SuperSubCreate(Account1, SubLifetime, AccountServer.XMLRPC.ActivationKeys(RetailKeys[1]));

UserSubscription = AccountServer.XMLRPC.GetUserInternalSubscriptionForProduct(Account1, InteralProduct);

Test.Verify(UserSubscription["Uproductid"], tonumber(AccountServer.Web.Legacy.GetProductID(ProdLifetime)));
Test.Verify(UserSubscription["Uexpiration"], 0);
Test.Verify(UserSubscription["Psubinternalname"], "S-STO");

-----Create Account2
print("\nCreating account '"..Account2.."'...");
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account2, Password, Name, Email2), "user_update_ok");

--Apply Retail Key
--Add 1 Mo Sub with CC
print("\nApplying retail key and activating 1 Mo sub...");
AccountServer.XMLRPC.SuperSubCreate(Account2, Sub1Mo, AccountServer.XMLRPC.ActivationKeys(RetailKeys[2]));

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account2, InteralProduct);
EntitlementEnd = UserSubscription["Entitlementendtimess2000"];

Test.Verify(UserSubscription["Name"], Sub1Mo);
Test.Verify(UserSubscription["Status"], "ACTIVE");
Test.Verify(UserSubscription["Entitled"], 1);

--Add Lifetime sub
print("\nApplying Lifetime sub, verifying Vindicia sub is cancelled...");
AccountServer.XMLRPC.SuperSubCreate(Account2, SubLifetime);

UserSubscription = AccountServer.XMLRPC.GetUserInternalSubscriptionForProduct(Account2, InteralProduct);

Test.Verify(UserSubscription["Uproductid"], tonumber(AccountServer.Web.Legacy.GetProductID(ProdLifetime)));
Test.Verify(UserSubscription["Uexpiration"], 0);
Test.Verify(UserSubscription["Psubinternalname"], "S-STO");

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account2, InteralProduct);
Test.Verify(UserSubscription["Name"], Sub1Mo);
Test.Verify(UserSubscription["Status"], "CANCELLED");

-----Create Account3
print("\nCreating account '"..Account3.."'...");
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account3, Password, Name, Email3), "user_update_ok");

--Apply Retail Key, Add GTC
print("\nApplying retail key and activating GTC...");
AccountServer.XMLRPC.SuperSubCreate(Account3, GTCSub, AccountServer.XMLRPC.ActivationKeys(RetailKeys[3], GTCKeys[1]));

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account3, InteralProduct);
EntitlementEnd = UserSubscription["Entitlementendtimess2000"];

Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "ACTIVE");
Test.Verify(UserSubscription["Entitled"], 1);


--Add Lifetime sub
print("\nApplying Lifetime sub...");
AccountServer.XMLRPC.SuperSubCreate(Account3, SubLifetime);

UserSubscription = AccountServer.XMLRPC.GetUserInternalSubscriptionForProduct(Account3, InteralProduct);

Test.Verify(UserSubscription["Uproductid"], tonumber(AccountServer.Web.Legacy.GetProductID(ProdLifetime)));
Test.Verify(UserSubscription["Uexpiration"], 0);
Test.Verify(UserSubscription["Psubinternalname"], "S-STO");

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account3, InteralProduct);
Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "CANCELLED");

Test.Succeed();