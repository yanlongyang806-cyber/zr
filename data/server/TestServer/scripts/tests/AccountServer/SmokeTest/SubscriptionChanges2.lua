require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/Test");
require("cryptic/Var");
require("ss2000");

Var.Set(nil, "Test_IP", "RANDOM");

--Account Info
local TimeStamp		= string.gsub(os.date(), "[%s%p]", "_");
local Account		= "Sub2_"..TimeStamp;
local EmailSuffix	= "@Subscriptions.com";
local Email		= Account..EmailSuffix;
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
local SS60Days		= 5184000; --60 days
local GracePeriod	= 86400; --24 hours
--Cryptic Points
local UserCrypticPoints = nil
local CrypticPoints	= 76


Test.Begin();
-----Create Account2
print("\nCreating account '"..Account.."'...");
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account, Password, Account, Email), "user_update_ok");

--Apply key
print("\nApplying retail key and activating GTC sub...");
AccountServer.XMLRPC.SuperSubCreate(Account, GTCSub, AccountServer.XMLRPC.ActivationKeys(RetailKeys[1], GTCKeys[1]));

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);
Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "ACTIVE");
Test.Verify(UserSubscription["Gamecard"], 1);

--Add GTC
print("\nApplying game time card...");
AccountServer.XMLRPC.SuperSubCreate(Account, GTCSub, AccountServer.XMLRPC.ActivationKeys(GTCKeys[2]));

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "ACTIVE");
Test.Verify(UserSubscription["Gamecard"], 1);
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), (EntitlementEnd + SS60Days)); --http://code:8080/browse/PLAT-1097

--Cancel Sub (lose time)
print("\nCancelling subscription (losing time)...");
AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 1, 0);

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "CANCELLED");
Test.VerifyNote(UserSubscription["Entitled"], 0); --http://code:8080/browse/PLAT-16
Test.VerifyNote(UserSubscription["Vindiciaentitled"], nil); --http://code:8080/browse/PLAT-16, --PLAT-1127
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), 0); --http://code:8080/browse/PLAT-16

--Reactivate 6 Mo sub
print("\nActivating 6 month sub...");
AccountServer.XMLRPC.SuperSubCreate(Account, Sub6Mo);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.VerifyNote(UserSubscription["Name"], Sub6Mo); --http://code:8080/browse/PLAT-1096
Test.Verify(UserSubscription["Status"], "ACTIVE");

--Remove CC
print("\nRemoving payment method...");
AccountServer.XMLRPC.ChangePaymentMethod(Account, AccountServer.XMLRPC.PaymentMethod(nil, 0, UserSubscription["Paymentmethodvid"]));

local UserPaymentMethod = AccountServer.XMLRPC.GetUserPaymentMethod(Account, UserSubscription["Paymentmethodvid"])

Test.Verify(UserPaymentMethod, nil);

--Purchase Cryptic Points
print("\nPurchasing Cryptic Points...");
AccountServer.XMLRPC.Purchase(Account, nil, CrypticPoints);

Test.Verify(("900"), AccountServer.XMLRPC.GetUserKeyValue(Account, "CrypticPoints"));

--Cancel Sub (keep time)
print("\nCancelling subscription (keeping time)...")
AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 0, 0);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.VerifyNote(UserSubscription["Name"], Sub6Mo); --http://code:8080/browse/PLAT-1096
Test.Verify(UserSubscription["Status"], "CANCELLED");
Test.VerifyNote(UserSubscription["Entitled"], 1); --http://code:8080/browse/PLAT-16
Test.VerifyNote(UserSubscription["Vindiciaentitled"], nil); --http://code:8080/browse/PLAT-16 --PLAT-1127
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), (EntitlementEnd - GracePeriod)); --http://code:8080/browse/PLAT-16

--Reactivate Sub with GTC
print("\nApplying game time card...");
AccountServer.XMLRPC.SuperSubCreate(Account, GTCSub, AccountServer.XMLRPC.ActivationKeys(GTCKeys[3]));

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "ACTIVE");
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), (EntitlementEnd + SS60Days)); --http://code:8080/browse/PLAT-1097

--Cancel Sub (lose time)
print("\nCancelling subscription (losing time)...");
AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 1, 0);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.VerifyNote(UserSubscription["Name"], GTCSub);--http://code:8080/browse/PLAT-1096
Test.Verify(UserSubscription["Status"], "CANCELLED");
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), 0); --http://code:8080/browse/PLAT-16

--Remove payment methods
print("\nRemoving payment methods...");
AccountServer.XMLRPC.ChangePaymentMethod(Account, AccountServer.XMLRPC.PaymentMethod(nil, 0, UserSubscription["Paymentmethodvid"]));

UserPaymentMethod = AccountServer.XMLRPC.GetUserPaymentMethod(Account, UserSubscription["Paymentmethodvid"])

Test.Verify(UserPaymentMethod, nil);

Test.Succeed();
