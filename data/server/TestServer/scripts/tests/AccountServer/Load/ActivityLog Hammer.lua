require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Metric");

Test.Begin();

--Vars
Var.Set(nil, "Test_IP", "RANDOM");

local accounts		= {};
local LogProduct	= "PRD-Log";
local p_t		= {};
local ExpectedKeyValue	= 0;
local info		= {};
local t_0		= 0;
local t_1		= 0;
local t_2		= 0;
local NumAccounts	= 1000;

--Account Server Setup
if AccountServer.loc == "localhost" then
	AccountServer.Kill();
	AccountServer.DefaultVersion("AS.217.20101025_0747.0");
	AccountServer.CleanDB();
	AccountServer.Patch();
	AccountServer.LaunchAndWait(300);
end

--Test functions
function LogTest_CreateAccounts(i)
	table.insert(accounts, "LogTest".."_"..string.format(i));
	local n = accounts[i];
	local r, t = nil;
	
	print("Creating Account:", n);
	r, t = AccountServer.XMLRPC.CreateNewAccount(n, n, n, n.."@crypticstudios.com", n, n);
	print("", r);
end

function LogTest_VerifyAccounts()
	print("Verifying accounts...");
	--Wait for activity log to write
	print("","Waiting for activitylogs...");
	Console.Wait(35);
	t_0 = ts.get_time()
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
			end
		end
		
	end
	print("", "Total time to complete:", (ts.get_time() - t_0));
end

function LogTest_ModifyAccounts(i)
	local n = 0
	t_0 = ts.get_time()
	print("Adding 500 products to:", accounts[i]);
	print("", "Time to complete:");

	while n < 500 do
		--t_1 = ts.get_time()
		AccountServer.XMLRPC.GiveProduct(accounts[i], LogProduct);
		n = n+1;
		--t_2 = ts.get_time();
		--print("", "", t_2 - t_1);
	end
	print("", "Total time to complete:", (ts.get_time() - t_0));
end

--Create Test Products
p_t = {
	name = LogProduct,
	keyValueChanges = "Checksum += 1, PRD-Log == 1",
	dontAssociate = 1,
};
AccountServer.Web.CreateOrEditProduct(p_t["name"], "StarTrek", p_t);


--Create Account(s)
print("---[Step 1: Creating accounts(s)]---");
Test.Repeat(LogTest_CreateAccounts, 1, NumAccounts);
LogTest_VerifyAccounts();

--Modify 1st account
print("---[Step 2: Overloading account(s)]---");
z = 1;
while z < NumAccounts do
	LogTest_ModifyAccounts(z);
	z = z + 1
end
LogTest_VerifyAccounts();

--Kill server and reverify
print("---[Step 3: Killing server and reverifying]---");
if AccountServer.loc == "localhost" then
	AccountServer.Kill();
	AccountServer.LaunchAndWait(300);
end
LogTest_VerifyAccounts();

Test.Succeed();