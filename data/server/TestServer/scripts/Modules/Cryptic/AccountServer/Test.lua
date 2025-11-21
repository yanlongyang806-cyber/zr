require("cryptic/AccountServer");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/Test");
require("ss2000");

AccountServer.Test = {
	InteralProduct		= "startrek",
	CrypticPointsProduct	= 76,
	GTCSub			= "SP-STO-GameCard",
	Sub1Mo			= "SP-STO-R1Month",
	Sub3Mo			= "SP-STO-R3Month",
	Sub6Mo			= "SP-STO-R6Month",
	SS60Days		= 5184000, --60 days
	SSGracePeriod		= 86400, --24 hours
	};

-----Helper Functions-----
function AccountServer.Test.CheckLogin()
	if AccountServer.user == nil then
		local message = "Please set the global variable \"AccountServer_User\" to the username you want to use!";
		print(message);
		Test.Require(false,message);
	end
	if AccountServer.password == nil then
		local message = "Please set the global variable \"AccountServer_Password\" to the password for "..AccountServer.user.."!";
		print(message);
		Test.Require(false,message);
	end
	
	local authed, version = AccountServer.XMLRPC.Version();

	print("--------------");
	print("Connecting to: " ..AccountServer.loc);
	print("Username:      " ..AccountServer.user);
	if AccountServer.password then
		print("Password:      xxxxx");
	else
		print("Password:      nil");
	end
	print("Authenticated: " ..tostring(authed));
	print("AS Version:    "..version:match("[^%s]+"));
	print("--------------");
	
	return authed;
end

function AccountServer.Test.FailOnLoginFailure()
	if not AccountServer.Test.CheckLogin() then
		print("Account Server authentication failed - aborting script!");
		Test.Fail("Failed to authenticate against Account Server: "..(AccountServer.user or "no username"));
	end
end

-----Testcase Actions-----
function AccountServer.Test.CreateAccount(Account)
	local TimeStamp		= string.gsub(os.date(), "[%s%p]", "_");
	Account		= Account or "Test_"..TimeStamp;
	
	print("\nCreating account '"..Account.."'...");
	Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Account, "password1", Account.."_D", Account.."@Automation.com"), "user_update_ok");

	return Account;
end

function AccountServer.Test.SubscribeAccount(Account, Sub, InteralProduct, ...)
	print("\nActivating subscription "..Sub.."...");
	local UserSubscription	= {}
	local InternalSub	= {}

	AccountServer.XMLRPC.SuperSubCreate(Account, Sub, AccountServer.XMLRPC.ActivationKeys(...));
	UserSubscription	= AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);
	InternalSub		= AccountServer.XMLRPC.GetUserInternalSubscriptionForProduct(Account, InteralProduct);
	if InternalSub then
		--Too hardcoded atm, should lookup product info
		Test.Verify(InternalSub["Uproductid"], tonumber(AccountServer.Web.Legacy.GetProductID("PRD-STO-R-Lifetime")));
		Test.Verify(InternalSub["Uexpiration"], 0);
		Test.Verify(InternalSub["Psubinternalname"], "S-STO");
		
		--Check that any Vindicia subs are cancelled
		if UserSubscription then
			Test.Verify(UserSubscription["Status"], "CANCELLED")
		end
	elseif UserSubscription then
		Test.Verify(UserSubscription["Name"], Sub);
		Test.Verify(UserSubscription["Status"], "ACTIVE");
	else
		Test.Require(false, "A valid subscription was not found for this account!");
	end	

	return UserSubscription, InternalSub;
end

function AccountServer.Test.CancelSubAccount(Account, InteralProduct)
	print("\nCancelling subscription...");
	local UserSubscription = {}
	
	UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);
	AccountServer.XMLRPC.SubCancel(Account, UserSubscription["Vindiciaid"], 1, 0);

	UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);	
	Test.Verify(UserSubscription["Status"], "CANCELLED");
	Test.VerifyNote(UserSubscription["Entitled"], 0); --http://code:8080/browse/PLAT-16
	Test.VerifyNote(UserSubscription["Vindiciaentitled"], nil); --http://code:8080/browse/PLAT-16, --PLAT-1127
	Test.VerifyNote((UserSubscription["Entitlementendtimess2000"]), 0); --http://code:8080/browse/PLAT-16
	
	return UserSubscription;
end

function AccountServer.Test.RemovePaymentMethod(Account, InteralProduct)
	print("\nRemoving payment method...");
	local UserPaymentMethod = {};
	
	UserSubscription = AccountServer.XMLRPC.GetUserSubscriptionForProduct(Account, InteralProduct);
	AccountServer.XMLRPC.ChangePaymentMethod(Account, AccountServer.XMLRPC.PaymentMethod(nil, 0, UserSubscription["Paymentmethodvid"]));

	UserPaymentMethod = AccountServer.XMLRPC.GetUserPaymentMethod(Account, UserSubscription["Paymentmethodvid"])
	Test.Verify(UserPaymentMethod, nil);
end

function AccountServer.Test.PurchasePoints(Account, PointPackageid, PointPackageValue, PointKeyValue)
	local PointPackageid	= PointPackageid or 76
	local PointPackageValue	= PointPackageValue or 500
	local PointKeyValue	= PointKeyValue or "CrypticPoints"
	print("\nPurchasing "..PointKeyValue.."...");

	local AccountPoints	= AccountServer.XMLRPC.GetUserKeyValue(Account, PointKeyValue)

	AccountServer.XMLRPC.Purchase(Account, nil, PointPackageid);

	Test.Verify((tonumber(AccountPoints) + tonumber(PointPackageValue)), tonumber(AccountServer.XMLRPC.GetUserKeyValue(Account, PointKeyValue)));
end
