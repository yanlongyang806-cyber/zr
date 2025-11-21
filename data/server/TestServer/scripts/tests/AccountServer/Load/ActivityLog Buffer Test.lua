require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Test");

Test.Begin();

--Vars
Var.Set(nil, "Test_IP", "RANDOM");
--Scope.Var.Default("AccountPrefix", "AccountLog");

local accounts		= {};
local pNoAssociate	= "PRD-NoAssociate";
local pAssociate1	= "PRD-Associate1";
local pAssociate2	= "PRD-Associate2";
local p_t		= {};
local ExpectedKeyValue	= 0;
local info		= {};

--Account Server Setup
--[[ Should b running one already
if AccountServer.loc == "localhost" then
	AccountServer.Kill();
	AccountServer.DefaultVersion("AS.213.20100621_1054.0");
	AccountServer.CleanDB();
	AccountServer.Patch();
	AccountServer.LaunchAndWait(300);
end
]]--

--Test functions
function BufferTest_CreateAccounts(i)
	table.insert(accounts, "BufferTest".."_"..string.format(i));
	local n = accounts[i];
	local r, t = nil;
	
	print("Creating Account:", n);
	r, t = AccountServer.XMLRPC.CreateNewAccount(n, n, n, n.."@crypticstudios.com", n, n);
	print("", r);
	BufferTest_VerifyAccounts();

	print("Adding product to:", n);
	r = AccountServer.XMLRPC.GiveProduct(n, pAssociate1);
	print("", r);
	BufferTest_VerifyAccounts();
end

function BufferTest_VerifyAccounts()
	print("Verifying accounts...");
	--Wait for activity log to write
	print("","Waiting for activitylogs...");
	Console.Wait(35);
	
	--Verify all accounts
	for i, v in ipairs(accounts) do
		print("","Verifying Account:", v);
	
		info = AccountServer.XMLRPC.UserInfo(v);
		--for x, y in pairs(info) do print("",x, y) end
		--for i, v in pairs(info["Activitylog"]) do print("","",i, v) end
		--print("---------"..#info["Activitylog"]);

		--Verify Account Info
		Test.Require(info["Loginname"], v, 
			"Loginname failed!");
		Test.Require(info["DisplayName"], v, 
			"DisplayName failed!");
		Test.Require(info["Email"], v.."@crypticstudios.com", 
			"Email failed!");
		Test.Require(info["Firstname"], v, 
			"Firstname failed!");
		Test.Require(info["Lastname"], v, 
			"Lastname failed!");
		
		--2 for account create, every 6 for product apply
		ExpectedKeyValue = ((#info["Activitylog"] - 2) / 6);

		--Verify key values
		if info["Keyvalues"] then
			for i, v in ipairs(info["Keyvalues"]) do
				if info["Keyvalues"][i]["Key"] == "Checksum" then
					Test.Require(info["Keyvalues"][i]["Value"], ExpectedKeyValue);
				end
				
				if info["Keyvalues"][i]["Key"] == "PRD-Associate1" then
					Test.Require(info["Keyvalues"][i]["Value"], "1");
				end
				
				if info["Keyvalues"][i]["Key"] == "PRD-Associate2" then
					Test.Require(info["Keyvalues"][i]["Value"], "1");
				end
			end
		end
	end
end

function BufferTest_ModifyAccounts(i)
	print("Adding Non associative product to:", accounts[i]);
	AccountServer.XMLRPC.GiveProduct(accounts[i], pNoAssociate);
	BufferTest_VerifyAccounts();
	
	print("Adding Non associative product to:", accounts[i]);
	AccountServer.XMLRPC.GiveProduct(accounts[i], pAssociate2);
	BufferTest_VerifyAccounts();
end

--Create Test Products
p_t = {
	name = pNoAssociate,
	keyValueChanges = "Checksum += 1, PRD-NoAssociate += 1",
	dontAssociate = 1,
};
AccountServer.Web.CreateOrEditProduct(p_t["name"], "StarTrek", p_t);

p_t = {
	name = pAssociate1,
	keyValueChanges = "Checksum += 1, PRD-Associate1 += 1",
	dontAssociate = 0,
	shards = "shardname1",
	permissions = "permissions1",
};
AccountServer.Web.CreateOrEditProduct(p_t["name"], "StarTrek", p_t);

p_t = {
	name = pAssociate2,
	keyValueChanges = "Checksum += 1, PRD-Associate2 += 1",
	dontAssociate = 0,
	shards = "shardname2",
	permissions = "permissions2",
};
AccountServer.Web.CreateOrEditProduct(p_t["name"], "StarTrek", p_t);

--Create Accounts and add product 1-11
	--11th should overwrite #1
print("---[Step 1: Creating accounts #1-11]---");
Test.Repeat(BufferTest_CreateAccounts, 1, 11);

--Modify 1st account
	--Should overwrite #2
print("---[Step 2: Modifying account #1]---");
BufferTest_ModifyAccounts(1);

--Modify 3-10
	--Should not overwite any
print("---[Step 3: Modifying accounts #3-10]---");
Test.Repeat(BufferTest_ModifyAccounts, 3, 10);

--Modify 2nd account
	--Should overwrite #11
print("---[Step 4: Modifying account #2]---");
BufferTest_ModifyAccounts(2);

--Modify 11th account
	--Should overwite #1
print("---[Final Step 5: Modifying account #11]---");
BufferTest_ModifyAccounts(11);

Test.Succeed();