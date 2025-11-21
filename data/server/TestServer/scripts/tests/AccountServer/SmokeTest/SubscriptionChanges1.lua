require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/Test");
require("cryptic/Var");
require("ss2000");

Var.Set(nil, "Test_IP", "RANDOM");

--Account Info
local TimeStamp		= string.gsub(os.date(), "[%s%p]", "_");
local Account		= "Sub1_"..TimeStamp;
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
-----Create Account1
print("\nCreating account '"..Account.."'...");
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account, Password, Name, Email), "user_update_ok");

--Apply Retail Key
--Add 1 Mo Sub with CC
print("\nApplying retail key and activating 1 month sub...");
AccountServer.XMLRPC.SuperSubCreate(Account, Sub1Mo, AccountServer.XMLRPC.ActivationKeys(RetailKeys[1]));

UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);
EntitlementEnd = UserSubscription["Entitlementendtimess2000"];

Test.Verify(UserSubscription["Name"], Sub1Mo);
Test.Verify(UserSubscription["Status"], "ACTIVE");

--Cancel Sub (keep time)
print("\nCancelling subscription (keeping time)...")
AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 0, 0);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], Sub1Mo);
Test.Verify(UserSubscription["Status"], "CANCELLED");
Test.Verify(UserSubscription["Entitled"], 1);
Test.Verify(UserSubscription["Vindiciaentitled"], nil); --PLAT-1127
Test.Verify((UserSubscription["Entitlementendtimess2000"]), (EntitlementEnd - GracePeriod));

--Reactivate 3 Mo Sub with CC
print("\nActivating 3 month sub...");
AccountServer.XMLRPC.SuperSubCreate(Account, Sub3Mo);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], Sub3Mo);
Test.Verify(UserSubscription["Status"], "ACTIVE");

--Remove CC
print("\nRemoving payment method...");
AccountServer.XMLRPC.ChangePaymentMethod(Account, AccountServer.XMLRPC.PaymentMethod(nil, 0, UserSubscription["Paymentmethodvid"]));

local UserPaymentMethod = AccountServer.XMLRPC.GetUserPaymentMethod(Account, UserSubscription["Paymentmethodvid"])

Test.Verify(UserPaymentMethod, nil);

--Purchase Cryptic Points with CC
print("\nPurchasing Cryptic Points...");
AccountServer.XMLRPC.Purchase(Account, nil, CrypticPoints);

Test.Verify(("900"), AccountServer.XMLRPC.GetUserKeyValue(Account, "CrypticPoints"));

--Cancel Sub (lose time)
print("\nCancelling subscription (losing time)...");
AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 1, 0);

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.VerifyNote(UserSubscription["Name"], Sub3Mo); --http://code:8080/browse/PLAT-1096
Test.Verify(UserSubscription["Status"], "CANCELLED");
Test.VerifyNote(UserSubscription["Entitled"], 0); -- http://code:8080/browse/PLAT-16
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), 0); --http://code:8080/browse/PLAT-16

--Apply GTC
print("\nApplying game time card...");
AccountServer.XMLRPC.SuperSubCreate(Account, GTCSub, AccountServer.XMLRPC.ActivationKeys(GTCKeys[1]));

EntitlementEnd = UserSubscription["Entitlementendtimess2000"];
UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);

Test.Verify(UserSubscription["Name"], GTCSub);
Test.Verify(UserSubscription["Status"], "ACTIVE");
--print("\nNow: "..ToSS2000FromNow(), "\nCurrent: "..UserSubscription["Entitlementendtimess2000"], "\nPrevious: "..EntitlementEnd);
Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), (EntitlementEnd + SS60Days), "Failed to verify line 112 verifying GTC time"); --http://code:8080/browse/PLAT-1097

--Remove all payment methods
print("\nRemoving payment methods...");
AccountServer.XMLRPC.ChangePaymentMethod(Account, AccountServer.XMLRPC.PaymentMethod(nil, 0, UserSubscription["Paymentmethodvid"]));

UserPaymentMethod = AccountServer.XMLRPC.GetUserPaymentMethod(Account, UserSubscription["Paymentmethodvid"])

Test.Verify(UserPaymentMethod, nil);

Test.Succeed();
