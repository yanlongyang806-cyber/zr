require("cryptic/AccountServer");
require("cryptic/Console");
require("cryptic/Var");
require("xmlrpc.http");
require("ss2000");

AccountServer.XMLRPC = { };

-----Helper Functions-----
function AccountServer.XMLRPC.VerifyAuth(...)
	local t = {...};
	
	--Translates into "STRINGARRAY" for XMLRPC args
	local StringArrayType = xmlrpc.newArray("string");
	local StringArray = xmlrpc.newTypedValue(t, StringArrayType);

	return StringArray;
end

function AccountServer.XMLRPC.ToStringArray(...)
	local t = {...};
	
	--Translates into "STRINGARRAY" for XMLRPC args
	local StringArrayType = xmlrpc.newArray("string");
	local StringArray = xmlrpc.newTypedValue(t, StringArrayType);

	return StringArray;
end

function AccountServer.XMLRPC.ActivationKeys(...)
	return AccountServer.XMLRPC.ToStringArray(...);
end

function AccountServer.XMLRPC.ToIntArray(...)
	local t = {...};
	
	--Translates into "STRINGARRAY" for XMLRPC args
	local IntArrayType = xmlrpc.newArray("int");
	local IntArray = xmlrpc.newTypedValue(t, IntArrayType);

	return IntArray;
end

function AccountServer.XMLRPC.ProductId(...)
	return AccountServer.XMLRPC.ToIntArray(...);
end

function AccountServer.XMLRPC.VindiciaResponse(response)
	if response["Transid"] then
		--return response["Transid"];
		local vresponse = AccountServer.XMLRPC.TransView(response["Transid"]);
		return vresponse["Resultstring"], vresponse;
	elseif	response["Result"] then
		return true, response["Result"];
	elseif	response["Resultstring"] then
		return true, response["Resultstring"];
	else
		return false, response;
		--return response, response["Transid"];
	end
end

-- Test if a given IP address is on the banned list
function AccountServer.XMLRPC.IsIPBanned(ip)
	local response = AccountServer.XMLRPC.BlockedIPs();

	if response["Ipratelimit"] ~= nil then
		for _, v in pairs(response["Ipratelimit"]) do
			if  ip == v.Ipaddress then
				return true;
			end;
		end
	end

	return false;
end

-----XMLRPC Command Wrappers-----
function AccountServer.XMLRPC.SuperSubCreate(priv_n, subplan, activationkeys, paymentmethod, currency, ip, referrer, bankname)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/SuperSubCreate
	local XMLSuperSubCreateRequest = {
		["User"] 		= priv_n,
		["Subscription"] 	= subplan,
		["Activationkeys"] 	= activationkeys,
		["Paymentmethod"] 	= AccountServer.XMLRPC.PaymentMethod(paymentmethod),
		["Currency"] 		= AccountServer.XMLRPC.Currency(currency),
		["ip"] 			= AccountServer.XMLRPC.IP(ip),
		["Referrer"]		= referrer,
		["Bankname"]		= bankname,
	};
	
	local r, t = AccountServer.XMLRPCRequest("SuperSubCreate", XMLSuperSubCreateRequest);

	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.SubCancel(priv_n, vid, instant, merchantinitiated)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/SubCancel
	local XMLSubCancelParameters = {
		["User"]		= priv_n,
		["Vid"]			= vid,
		["Instant"]		= instant,
		["Merchantinitiated"]	= merchantinitiated,
	};
	
	local r, t = AccountServer.XMLRPCRequest("SubCancel", XMLSubCancelParameters);

	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.ChangePaymentMethod(priv_n, paymentmethod, ip, bankname)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/ChangePaymentMethod

	local XMLRPCChangePaymentMethodRequest = {
		["AccountName"]		= priv_n,
		["Paymentmethod"]	= paymentmethod,
		["ip"]			= AccountServer.XMLRPC.IP(ip),
		["Bankname"]		= bankname,
	};

	local r, t = AccountServer.XMLRPCRequest("ChangePaymentMethod", XMLRPCChangePaymentMethodRequest);
	
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.GiveProduct(priv_n, prod, key)
	return AccountServer.XMLRPCRequest("GiveProduct", priv_n, prod, key or "");
end

function AccountServer.XMLRPC.TakeProduct(priv_n, prod, key)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/TakeProduct
	return AccountServer.XMLRPCRequest("TakeProduct", priv_n, prod);
end

function AccountServer.XMLRPC.Purchase(priv_n, paymentmethod, productid, currency, ip, bankname)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/Purchase
	local XMLRPCPurchaseRequest = {
		["User"]		= priv_n,
		["Currency"]		= AccountServer.XMLRPC.Currency(currency),
		["Paymentmethod"]	= paymentmethod or AccountServer.XMLRPC.PaymentMethod(paymentmethod),
		["Productid"]		= AccountServer.XMLRPC.ProductId(productid),
		["ip"]			= AccountServer.XMLRPC.IP(ip),
		["Bankname"]		= bankname,
	};	
	
	local r, t = AccountServer.XMLRPCRequest("Purchase", XMLRPCPurchaseRequest);
	print(r, t);
	for k, v in pairs(t) do
		print("", k, v);
	end
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.PurchaseEX(priv_n, paymentmethod, productid, price, authonly, currency, ip, bankname, loccode, source, steamid)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/Purchaseex
	local XMLRPCPurchaseRequestEx = {
		["User"]		= priv_n,
		["Currency"]		= AccountServer.XMLRPC.Currency(currency),
		["Paymentmethod"]	= paymentmethod or AccountServer.XMLRPC.PaymentMethod("none"),
		["Items"]		= AccountServer.XMLRPC.Items(productid, price),
		["ip"]			= AccountServer.XMLRPC.IP(ip),
		["Bankname"]		= bankname,
		["Authonly"]		= authonly,
		["Loccode"]		= loccode,
		["Source"]		= source,
		["Steamid"]		= steamid,
	};

	local r, t = AccountServer.XMLRPCRequest("Purchaseex", XMLRPCPurchaseRequestEx);
	print(r, t)
	for k, v in pairs(t) do
		print("", k, v);
	end
	--Returning an array, its a lie
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.CompletePurchase(priv_n, purchaseid)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/completepurchase
	local XMLRPCCompletePurchaseRequest = {
		["User"]		= priv_n,
		["Purchaseid"]		= purchaseid,
	};	
	
	local r, t = AccountServer.XMLRPCRequest("completepurchase", XMLRPCCompletePurchaseRequest);
	print(r, t)
	for k, v in pairs(t) do
		print("", k, v);
	end
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.PurchaseEXComplete(priv_n, paymentmethod, productid, price, currency, ip, bankname)
	--Lazy function so I dont have to call each by themselves
	local r, purchaseid = nil
	r, kek = AccountServer.XMLRPC.PurchaseEX(priv_n, paymentmethod, productid, price, 1, currency, ip, bankname);
	print(r, kek["Purchaseid"]);
	AccountServer.XMLRPC.CompletePurchase(priv_n, kek["Purchaseid"]);
end

function AccountServer.XMLRPC.GetPurchaseLogEx(uSinceSS2000, uMaxResponses, uAccountID)
	local XMLGetPurchaseLogRequest = {
		["uSinceSS2000"] 	= uSinceSS2000,
		["uMaxResponses"] 	= uMaxResponses,
		["uAccountID"]		= uAccountID
	};
	
	local r, t = AccountServer.XMLRPCRequest("GetPurchaseLogEx", XMLGetPurchaseLogRequest);
	return r, t, t["Log"];
end

function AccountServer.XMLRPC.GetTransactionLogEx(uSinceSS2000, uMaxResponses, uAccountID)
	local XMLGetTransactionLogRequest = {
		["uSinceSS2000"] 	= uSinceSS2000,
		["uMaxResponses"] 	= uMaxResponses,
		["uAccountID"]		= uAccountID
	};
	
	local r, t  = AccountServer.XMLRPCRequest("GetTransactionLogEx", XMLGetTransactionLogRequest);
	return r, t, t["Log"];
end

function AccountServer.XMLRPC.ArchiveSubHistory(priv_n, starttime, endtime, prodinternal, subinternal, subvid, source, problem)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/ArchiveSubHistory
	prodinternal = prodinternal or Var.Get(nil, "Test_InternalProduct") or "startrek";
	
	if string.lower(prodinternal) == "startrek" then
		subinternal = subinternal or "S-STO";
	elseif string.lower(prodinternal) == "fightclub" then
		subinternal = subinternal or "S-CO";
	end

	local XMLArchiveSubHistoryRequest = {
		["AccountName"]		= priv_n,
		["Productinternalname"]	= prodinternal,
		["Subinternalname"]	= subinternal,
		["Subvid"]		= subvid,
		["StartTime"]		= ToSS2000FromTimestamp(starttime) or ToSS2000FromDatestamp(starttime) or starttime,
		["EndTime"]		= ToSS2000FromTimestamp(endtime) or ToSS2000FromDatestamp(endtime) or endtime,
		["Subtimesource"]	= source or 2,
		["Problemflags"]	= problem,
	};
	--for k, v in pairs(XMLArchiveSubHistoryRequest) do print(k, v) end
	local r, t = AccountServer.XMLRPCRequest("ArchiveSubHistory", XMLArchiveSubHistoryRequest);
	
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.ChangeSubCreatedTime(priv_n, subvid, newcreatedtime)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/ChangeSubCreatedTime
	local XMLRPCPurchaseRequest = {
		["AccountName"]		= priv_n,
		["Subvid"]		= subvid,
		["Newcreatedtime"]	= ToSS2000FromTimestamp(newcreatedtime) or ToSS2000FromDatestamp(newcreatedtime) or newcreatedtime,
	};	
	
	local r, t = AccountServer.XMLRPCRequest("ChangeSubCreatedTime", XMLRPCPurchaseRequest);
	
	return AccountServer.XMLRPC.VindiciaResponse(t);
end

function AccountServer.XMLRPC.TransView(transid)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/TransView
	print("Getting Transaction:", transid);
	local time = 1;
	while (time <= 60) do
		local r, t = AccountServer.XMLRPCRequest("TransView", transid);
		
		if (t ~= "Could not find command: transid") then
			if (t["Status"] ~= "PROCESS") then
				print("", time.."s", "Transaction Finshed!");
				for x, y in pairs(t) do
					print("", "", x, y);
				end
				return t;
			end
		end
		
		if (time % 5) == 0 then
			print("", time.."s", "Transaction Status: "..t["Status"]);
		end

		os.execute("sleep 1");
		time = (time + 1);
	end

	return t;
end

function AccountServer.XMLRPC.SetKeyValue(priv_n, key, value)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/SetKeyValue
	value = value or "(null)";
	
	local r, t = AccountServer.XMLRPCRequest("SetKeyValue", priv_n, key, tostring(value));
	
	if t["Result"] == "key_set" then
		return t["Result"];
	else
		return nil;
	end
end

function AccountServer.XMLRPC.SetKeyValueEX(priv_n, key, value, increment, reason, transaction_type)
	--Same as SetKeyValue, only its in a struct and you can specify a reason
	--and a transaction type.
	value = value or "(null)";
	
	local XMLRPCSetKeyValueRequest = {
		["AccountName"]	= priv_n,
		["Key"]		= key,
		["Value"] 	= tostring(value),
		["Increment"]	= increment,
		["Reason"]	= reason,
		["Type"]	= transaction_type,
	};

	local r, t = AccountServer.XMLRPCRequest("SetKeyValueEX", XMLRPCSetKeyValueRequest);

	if t["Result"] == "key_set" then
		return t["Result"];
	else
		return nil;
	end
end

-- Effect of this call
-- destinationKey = destinationKey + sourceKey then sourceKey = 0;
function AccountServer.XMLRPC.MoveKeyValue(accountName, sourceKey, destinationKey, reason)
	local XMLRPCSetKeyValueRequest = {
		["AccountName"]		= accountName,
		["Source"]		= sourceKey,
		["Destination"] 	= destinationKey,
		["Reason"]		= reason
	};
	local response, responseTable = AccountServer.XMLRPCRequest("MoveKeyValue", XMLRPCSetKeyValueRequest);

	if responseTable["Result"] == "key_set" then
		return responseTable["Result"];
	else
		return nil;
	end;
end;

-- Effect of this call
-- destinationKey = destinationKey + sourceKey
function AccountServer.XMLRPC.DuplicateKeyValue(accountName, sourceKey, destinationKey, reason)
	local XMLRPCSetKeyValueRequest = {
		["AccountName"]		= accountName,
		["Source"]		= sourceKey,
		["Destination"] 	= destinationKey,
		["Reason"]		= reason
	};
	local response, responseTable = AccountServer.XMLRPCRequest("DuplicateKeyValue", XMLRPCSetKeyValueRequest);

	if responseTable["Result"] == "key_set" then
		return responseTable["Result"];
	else
		return nil;
	end;
end;

function AccountServer.XMLRPC.ValidateLoginEx(priv_n, password, ip, flag, md5Password, location, referrer, clientVersion, note)
	local XMLRPCValidateLoginExRequest = {
		["AccountName"]		= priv_n,
		["sha256Password"]	= ts.sha_256(password),
		["IPs"] 		= AccountServer.XMLRPC.ToStringArray(AccountServer.XMLRPC.IP(ip)),
		--Nothing else required
		["Flags"]		= flag or 16777215,	-- Magic number to return everything
		["md5Password"]		= md5Password,
		["Location"]		= location,
		["Referrer"]		= referrer,
		["ClientVersion"]	= clientVersion,
		["Note"]		= note,
	};

	local response, resultTable = AccountServer.XMLRPCRequest("ValidateLoginEx", XMLRPCValidateLoginExRequest);
	
	if response then 
		if resultTable["UserStatus"] == "user_login_ok" then
			return true, resultTable;
		else
			return false, resultTable;
		end
	end

	return nil;
end

function AccountServer.XMLRPC.CreateNewAccount(priv_n, password, disp_n, email, first, last, key, referrer)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/CreateNewAccount
	local XMLRPCCreateAccountRequest = {
		["AccountName"]		= priv_n,
		["Passwordhash"]	= ts.sha_256(password),
		["DisplayName"] 	= disp_n,
		["Email"]		= email,
		--Nothing else required
		["Firstname"]		= first or "First",
		["Lastname"] 		= last or "Last",
		["Productkey"] 		= key,
		["Defaultcurrency"] 	= AccountServer.XMLRPC.Currency(currency),
		["Defaultlocale"] 	= "US",
		["Year"] 		= 1969,
		["Month"] 		= 7,
		["Day"] 		= 11,
		["Uflags"] 		= 0,
		["Questionsanswers"] 	= nil,
		["Ips"] 		= AccountServer.XMLRPC.ToStringArray(AccountServer.XMLRPC.IP(ip)),
		["Referrer"] 		= nil,
	};

	local r, t = AccountServer.XMLRPCRequest("CreateNewAccount", XMLRPCCreateAccountRequest);
	
	if not r then
		return t;
	end

	return t["UserStatus"], t["Validateemailtoken"];
end

function AccountServer.XMLRPC.ValidateEmail(priv_n, token)
	local r, t = AccountServer.XMLRPCRequest("ValidateAccountEmail", priv_n, token, 0);

	if not r then
		return t;
	end

	return t["UserStatus"];
end

function AccountServer.XMLRPC.UserInfo(priv_n)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/UserInfo
	--16777215 is the magic number to get everything
	local r, t = AccountServer.XMLRPCRequest("UserInfo", priv_n, 16777215);
	
	if t["UserStatus"] == "user_exists" then
		if t["Keyvalues"] then
			t["Keyvalues"] = t["Keyvalues"]["List"];
		end
	
		if t["Subscriptions"] then
			t["Subscriptions"] = t["Subscriptions"]["List"];
		end
		--[[ Relevent Data Structures
		for i, v in pairs(y<Thing Below>) do print(k, v) end
		IE: t["Paymentmethods"][i]["CreditCard"]["Lastdigits"]

		t["Paymentmethods"][i]		
			["Type"]
			["AccountName"]
			["Vid"]
			["CreditCard"]
				["Lastdigits"]
		t["Subscriptions"][i]
			["Internalname"]
			["Entitled"]
			["Status"]
		t["Access"][i]
			["Product"]
			["Shardcategory"]
		t["Keyvalues"][i]
			["Key"]
			["Value"]
		t["Activitylog][i]
			["Account created."]
			["8456"]
			["330477178"]
		t["Products"][i]
			["Name"]
			["ID"]
		]]--
		
		return t;
	else
		return t["UserStatus"];
	end
end

function AccountServer.XMLRPC.GetUserSubscriptionForProduct(priv_n, internal)
	local t = AccountServer.XMLRPC.UserInfo(priv_n);
	local sub = nil;
	local internal = internal or "S-STO";

	if string.lower(internal) == "fightclub" then
		internal = "S-CO";
	elseif string.lower(internal) == "startrek" then
		internal = "S-STO";
	end
	
	if t["Subscriptions"] then
		for i, v in ipairs(t["Subscriptions"]) do
			if t["Subscriptions"][i]["Internalname"] == internal then
				sub = t["Subscriptions"][i];
			end
		end
	end

	return sub;
end

function AccountServer.XMLRPC.GetUserInternalSubscriptionForProduct(priv_n, internal)
	local t = AccountServer.XMLRPC.UserInfo(priv_n);
	local sub = nil;
	local internal = internal or "S-STO";

	if string.lower(internal) == "fightclub" then
		internal = "S-CO";
	elseif string.lower(internal) == "startrek" then
		internal = "S-STO";
	end
	
	if t["Internalsubscriptions"] then
		for i, v in ipairs(t["Internalsubscriptions"]) do
			if t["Internalsubscriptions"][i]["Psubinternalname"] == internal then
				sub = t["Internalsubscriptions"][i];
				
				--[[
				Uaccountid 131413
				Uproductid 673
				Ucreated 331253801
				Psubinternalname S-STO
				Uexpiration 0
				UID 97
				]]--
			end
		end
	end

	return sub;
end

function AccountServer.XMLRPC.GetUserPaymentMethod(priv_n, vid)
	local t = AccountServer.XMLRPC.UserInfo(priv_n);
	local paymentmethod = nil;
	
	if t["Paymentmethods"] ~= nil then
		for i, v in ipairs(t["Paymentmethods"]) do
			if t["Paymentmethods"][i]["Vid"] == vid then
				paymentmethod = t["Paymentmethods"][i];
			end
		end
	end
	
	return paymentmethod;
end

function AccountServer.XMLRPC.GetUserKeyValue(priv_n, key)
	local t = AccountServer.XMLRPC.UserInfo(priv_n);
	local value = nil;
	
	for i, v in ipairs(t["Keyvalues"]) do
		if string.lower(t["Keyvalues"][i]["Key"]) == string.lower(key) then
			value = t["Keyvalues"][i]["Value"];
		end
	end
	
	return string.lower(tostring(value));
end

function AccountServer.XMLRPC.Stats()
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/Stats
	local r, t = AccountServer.XMLRPCRequest("Stats");

	return t, r;
end

function AccountServer.XMLRPC.GetUserPermissions(priv_n)
	local t = AccountServer.XMLRPC.UserInfo(priv_n);
	
	--[[
	t["Fullproductpermissions"][i]
		["Permissions"]
		["Product"]
	]]--

	return t["Fullproductpermissions"];
end

function AccountServer.XMLRPC.MarkAccountBilled(accountname)
	local XMLRPCMarkAccountBilledRequest = {
		["Accountname"]	= accountname
	};

	local r, t = AccountServer.XMLRPCRequest("MarkAccountBilled", XMLRPCMarkAccountBilledRequest);
	
	return r, t, t["Result"];
end

function AccountServer.XMLRPC.MarkRecruitBilled(recruiter, recruit, prodinternal)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/MarkRecruitBilled
	--This will only succeed if the status of the recruit is at "Upgraded"

	local XMLRPCMarkRecruitBilledRequest = {
		["Recruiteraccountname"]	= recruiter,
		["Recruitaccountname"]		= recruit,
		["Productinternalname"] 	= prodinternal,
	};

	local r, t = AccountServer.XMLRPCRequest("MarkRecruitBilled", XMLRPCMarkRecruitBilledRequest);
	
	return t["Result"], r;
end

function AccountServer.XMLRPC.RecruitmentOffered(recruitemail, key)
	--http://qa.fightclub/admin/game/wgsCommandLookup/AccountServer/RecruitmentOffered
	--This will only succeed if the status of the recruit is at "Upgraded"

	local XMLRecruitmentOfferedRequest = {
		["AccountName"]		= recruitemail,
		["Productkey"]		= key,
	};

	local r, t = AccountServer.XMLRPCRequest("RecruitmentOffered", XMLRecruitmentOfferedRequest);
	
	return t["Result"], r;
end

function AccountServer.XMLRPC.SetSpendingCap(priv_n, currency, cap)
	local XMLSpendingCapRequest = {
		["AccountName"]	= priv_n,
		["Currency"]	= currency,
		["Amount"]	= cap,
	};

	local r, t = AccountServer.XMLRPCRequest("SetSpendingCap", XMLSpendingCapRequest);
	
	return r, t, t["Result"];
end

function AccountServer.XMLRPC.UpdateUser(a_name, pw, email)
	local XMLUpdateUserRequest = {
		["AccountName"] = a_name,
		["Email"] = email,
		["Sha256password"] = ts.sha_256(pw),
	};

	local r, t = AccountServer.XMLRPCRequest("UpdateUser", XMLUpdateUserRequest);

	return r, t;
end

function AccountServer.XMLRPC.TransactionFetchDelta(starttime, endtime, filters)
	filters = filters or 0;

	local XMLTransactionFetchDeltaRequest = {
		["Startss2000"] = ToSS2000FromTimestamp(starttime) or starttime,
		["Endss2000"] = ToSS2000FromTimestamp(endtime) or endtime,
		["Filters"] = filters,
	};

	local r, t = AccountServer.XMLRPCRequest("TransactionFetchDelta", XMLTransactionFetchDeltaRequest);
	return r, t;
end

function AccountServer.XMLRPC.Error()
	local r, t = nil;
	r, t = AccountServer.XMLRPCRequest("Error");
	return r, t;
end

function AccountServer.XMLRPC.Version()
	local r, t = nil;
	r, t = AccountServer.XMLRPCRequest("version");
	return r, t;
end

-----XMLRPC Objects-----
function AccountServer.XMLRPC.PaymentMethod(creditcard, active, vid, currency)
	--if active == 0 will remove the payment method from AS when updating
	--if we want NO paymant info, for PurchaseEX
	if creditcard == "none" then
		return nil;
	end

	local paymentmethod = {
		["Vid"]			= vid,
		["Active"]		= active or 1,
		["Accountholdername"] 	= "Mr Test Server",
		["Customerspecifiedtype"] = nil,
		["Customerdescription"] = nil,
		["Currency"] 		= AccountServer.XMLRPC.Currency(currency),
		["Addressname"] 	= "My House",
		["Addr1"] 		= "123 Fake St",
		["Addr2"] 		= nil,
		["City"] 		= "Fakesville",
		["County"] 		= nil,
		["District"] 		= nil,
		["Postalcode"] 		= "55555",
		["Country"] 		= "US",
		["Phone"] 		= "555-555-5555",
		["Paypal"] 		= nil,
		["Creditcard"] 		= AccountServer.XMLRPC.CreditCard(creditcard),
		["Directdebit"] 	= nil,
	};

	return paymentmethod;
end

function AccountServer.XMLRPC.CreditCard(cardnumber)
	--http://crypticwiki:8081/display/OPS/Prodtest+Credit+Card+Test+Numbers
	--378282246310005
	cardnumber = Var.Get(nil, "Test_CC") or cardnumber  or "374245455400001";
	
	local creditcard = {
		["Cvv2"] 		= "1234",
		["Account"] 		= cardnumber,
		["Expirationdate"]	= "201205",
	};

	return creditcard;
end

function AccountServer.XMLRPC.IP(ip)
	ip = Var.Get(nil, "Test_IP") or ip or "101.101.101.101";

	if ip == ("RANDOM") then
		ip = Console.Join({math.random(1, 255), math.random(1, 255), math.random(1, 255), math.random(1, 255)}, ".");
	end
	
	return ip;
end

function AccountServer.XMLRPC.BlockedIPs()
	local response, responseTable = AccountServer.XMLRPCRequest("BlockedIPs");

	if response then
		return responseTable;
	else
		return nil;
	end
end

function AccountServer.XMLRPC.Currency(currency)
	currency = Var.Get(nil, "Test_Currency") or currency or "USD";
	return currency;
end

function AccountServer.XMLRPC.Items(productid, price)
	local array_type = xmlrpc.newArray("table")
	local items = xmlrpc.newTypedValue({
		{
			["Productid"] 	= productid,
			["Price"] 	= price or "13.37",
		},
	}, array_type);

	return items;
end

function AccountServer.XMLRPC.UserDelete(uID)
	local response, responseTable = AccountServer.XMLRPCRequest("UserDelete", uID);

	-- There are three possible return values for responseTable["Result"]
	-- Result == "success", "not_authorized" and "user_not_found"
	-- Only "success" will return a true.
	if responseTable["Result"] == "success" then
		return true, responseTable["Result"], responseTable;
	else
		return false, responseTable["Result"], responseTable;
	end;
end

-----Steam-----
function AccountServer.XMLRPC.SteamRefund(accountName, orderID, source)
	local XMLRPCSteamRefundRequest	= {
		["accountName"]		= accountName,
		["orderID"]		= orderID,
		["source"]		= source
	}

	local response, responseTable = AccountServer.XMLRPCRequest("SteamRefund", XMLRPCSteamRefundRequest);

	if responseTable["Result"] == "success" then
		return responseTable;
	else
		return nil;
	end;
end

function AccountServer.XMLRPC.SteamGetUserInfo(steamID, ipAddress, source)
	local XMLRPCSteamGetUserInfoRequest	= {
		["steamid"]		= steamID,
		["ip"]			= ipAddress,
		["source"]		= source
	}

	local response, responseTable = AccountServer.XMLRPCRequest("SteamGetUserInfo", XMLRPCSteamGetUserInfoRequest);

	if responseTable["Result"] == "success" then
		return responseTable;
	else
		return nil;
	end;
end

-----Eden APIs-----
function AccountServer.XMLRPC.EdenValidateLoginByGuid(Accountguid, Sha256password)
	local XMLRPCRequest = {
		["Accountguid"]	= Accountguid,
		["Accountguid"]	= ts.sha_256(Sha256password),
	};

	local r, t = AccountServer.XMLRPCRequest("Eden::ValidateLoginByGuid", XMLRPCRequest);
	
	return r, t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenTokenQueryByAccount(Accountguid, Tokentype)
	local XMLRPCRequest = {
		["Accountguid"]	= Accountguid,
		["Tokentype"]	= Tokentype,
	};

	local r, t = AccountServer.XMLRPCRequest("Eden::TokenQueryByAccount", 
		XMLRPCRequest);
	
	return r, t["Tokenbalance"], t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenTokenSpendAuthorize(Accountguid, Tokenamount, Tokentype)
	local XMLRPCRequest = {
		["Accountguid"]	= Accountguid,
		["Tokenamount"]	= Tokenamount,
		["Tokentype"]	= Tokentype,
	};

	local r, t = AccountServer.XMLRPCRequest("Eden::TokenSpendAuthorize", XMLRPCRequest);
	
	--[[	Resultcode
		0x0000=WAITING_CONFIRM 
		0X0001=NO_PAYMENT_METHOD 
		0x0002=BAD_PAYMENT_METHOD 
	]]--
	return t, t["Tokentranspassword"], t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenTokenSpendCapture(Accountguid, Tokentranspassword, Tokentype)
	local XMLRPCRequest = {
		["Accountguid"]		= Accountguid,
		["Tokentranspassword"]	= Tokentranspassword,
		["Tokentype"]	= Tokentype,
	};

	local r, t  = AccountServer.XMLRPCRequest("Eden::TokenSpendCapture", XMLRPCRequest);
	
	--[[	Resultcode
		0x0000=TRANSACTION_DONE 
		0x0001=TRANSACTION_FAILED 
	]]--

	return r, t["Tokenbalance"], t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenTokenSpendVoid(Accountguid, Tokentranspassword, Tokentype)
	local XMLRPCRequest = {
		["Accountguid"]		= Accountguid,
		["Tokentranspassword"]	= Tokentranspassword,
		["Tokentype"]	= Tokentype,
	};

	local r, t  = AccountServer.XMLRPCRequest("Eden::TokenSpendVoid", XMLRPCRequest);
	
	--[[	Resultcode
		0x0000=TRANSACTION_DONE 
		0x0001=TRANSACTION_FAILED 
	]]--

	return r, t["Tokenbalance"], t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenProfileLinkToAccount(Accountguid, Gameid, Profileid, Platformid)
	local XMLRPCRequest = {
		["Accountguid"]	= Accountguid,
		["Gameid"]	= Gameid,
		["Profileid"]	= Profileid,
		["Platformid"]	= Platformid,
	};

	local r, t  = AccountServer.XMLRPCRequest("Eden::ProfileLinkToAccount", XMLRPCRequest);
	
	--[[	Resultcode
		0x0000=OK
	]]--

	return r, t["Resultstring"], t["Resultcode"];
end

function AccountServer.XMLRPC.EdenProfileLookUpAccount(Gameid, Profileid, Platformid)
	local XMLRPCRequest = {
		["Gameid"]	= Gameid,
		["Profileid"]	= Profileid,
		["Platformid"]	= Platformid,
	};

	local r, t  = AccountServer.XMLRPCRequest("Eden::ProfileLookUpAccount", XMLRPCRequest);
	
	--[[	Resultcode
		0x0000=OK 
		0x0001=NO_ACCOUNT_FOUND 
	]]--
	for a, b in pairs(t) do
		print(a, b)
	end
	return r, t, t["Accountguid"] , t["Country"], t["Dlcodes"], t["Resultstring"], t["Resultcode"];
end
