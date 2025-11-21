require("cryptic/AccountServer");
require("cryptic/Console");
require("cryptic/Test");

local KeyList = {};
local Product = "";
local TimeStamp = string.gsub(os.date(), "[%s%p]", "_");
local KeyGroups = AccountServer.GetKeyGroups();

Test.Begin();
--Iterate for each Prefix
for k, v in pairs(KeyGroups) do
	print(tostring(k));
	print(tostring(v));
	Products = AccountServer.GetProductsForKeyGroup(k);
	KeyList = AccountServer.GetKeyList(k);
	
	if Products then
		for i, w in ipairs(Products) do
			InternalProductName, ProdPermissions = AccountServer.GetPermissionsForProduct(w);
		end
	end

	--Iterate for each Key in the Prefix
	for i, Key in ipairs(KeyList) do
		AccountName = Key;
		Email = string.format("%s@%s.com", Key, Prefix);
		AccountResult = "";
		KeyResult = "";
				
		--Create account
		AccountResult = AccountServer.CreateAccount(AccountName, AccountName, "password1", Email);
		Test.ErrorUnless((AccountResult == "user_update_ok"), 
			"Account was not created!", AccountName, AccountResult);
		
		--Apply Key
		KeyResult = AccountServer.ActivateKey(AccountName, KeyList[i]);
		
		--Verify Key, Product and Permissions
		Test.ErrorUnless((KeyResult == "user_update_ok"), 
			"Key was not applied!", AccountName, Key, KeyResult);
		
		--Verify Product
		Test.ErrorUnless((AccountServer.AccountOwnsProduct(AccountName, Product) == 1),
			"Product was not applied!", AccountName, Product, Key);

		--Verify Permisssions
		AccountPermissions = AccountServer.GetAccountPermissionsForProduct(AccountName, InternalProductName);
		--for k, Permission in pairs(ProdPermissions) do
		Test.RepeatStepsArray(ProdPermissions,
			Test.ErrorUnless((Permission == AccountPermissions[v]),
				"Permissions did not match!", Product, k, Permissions, AccountPermissions[v])
		);

	end
end

Test.Succeed({
	["Error List"] = Test.Error,
});

--Create an account for each key batch
for i, Batch in ipairs(BatchList) do
  Name = string.format("%s_%s", Batch, TimeStamp);
  Email = string.format("%s@%s.com", Name, Name);
  AccountList[i] = Name
  Test.Require((AccountServer.CreateAccount(Name, Name, "password1", Email) == "user_update_ok"),
    "Account was not created!");
end

-- Activate a key from each batch
for i, Account in ipairs(AccountList) do
  VerifyKeyActivate = nil;
  VerifyPermissions = nil;
  Product = nil;
  Permissions = nil;
  --Activate Key
  Test.Require(AccountServer.ActivateKey(Account, KeyList[i]),
    "A key failed to verify!");
  --Setup Verify Data
  Product = AccountServer.GetProductForKeyBatch(BatchList[i], BatchNameList[i]);
  if not Product then
    table.insert(errors, {"Failed to find a batch!", BatchList[i], BatchNameList[i]});
  else
    InternalProductName, ProdPermissions = AccountServer.GetPermissionsForProduct(Product);
    if Debug == 1 then
      print("ProdPermissions--");
      for k, Value in pairs(ProdPermissions) do
        print(k,Value);
      end
    end
    AccountPermissions = AccountServer.GetAccountPermissionsForProduct(Account, InternalProductName);
    --Verify Product Applied
    if not AccountServer.AccountOwnsProduct(Account, Product) then
      table.insert(errors, {"The account did not get assigned the product!", Account, Product});
    else
      --Verify All Permissions for Prod and Account Match
      for k, Permission in pairs(ProdPermissions) do
        if Permission ~= AccountPermissions[k] then
          table.insert(errors, {"Permissions did not match!", Product, k, Permissions, AccountPermissions[k]});
        end
      end
    end
  end
end

Test.Succeed({
	["Verified Batches"] = BatchList,
  ["Accounts Created"] = AccountList,
  ["Keys Used"] = KeyList,
  ["Errors"] = errors,
	});