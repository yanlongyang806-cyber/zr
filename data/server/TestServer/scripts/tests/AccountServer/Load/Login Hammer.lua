--[[
	This script will hammer the Account Server with login attempts.  After reaching the
	token threshold, the IP address will be banned and all login attempts will fail.  At which
	point, the script will change its IP address and continue hammering the AS until
	numAttempts is reached.

	
	GLOBAL VARIABLES
	Require:
		AccountServer_User
		AccountServer_Password

	SCOPE VARIABLES
	Require:
		numAttempts			- Total number of login attempts
		failThreshold			- Number of failed login attempts before 
						- checking to see if the IP address is banned.
						- At which point the IP address will change.
		username			- User name of login account
		password			- Password of login account
--]]

require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

-- helper variables
local ipField1, ipField2, ipField3, ipField4;

-- #############################
-- VARIABLE DECLARATIONS 
-- #############################
local username = Scope.Var.Get("username");
Test.Require(username, "Please fill the scope variable \"username\" with the account name.");
local password = Scope.Var.Get("password");
Test.Require(password, "Please fill the scope variable \"password\" with the password of the account.");
local ipAddress = Scope.Var.Get("ipAddress");
Test.Require(ipAddress, "Please fill the scope variable \"ipAddress\" with the starting IP address.");
local numAttempts = Scope.Var.Get("numAttempts");
Test.Require(numAttempts, "Please fill the scope variable \"numAttempts\" with the total number of login attempts.");
local failThreshold = Scope.Var.Get("failThreshold");
Test.Require(failThreshold, "Please fill the scope variable \"failThreshold\" with the number of failed attempts before changing IP address.");


-- #############################
-- Functions
-- #############################
function InitializeIPAddress()
	-- IP Field 1
	local start = 1;
	local stop = string.find(ipAddress, "%.");
	local ipField1 = ipAddress:sub(start, stop-1) + 0;	-- "+ 0" converts the string return by sub()
								-- into an int
	-- IP Field 2
	start = stop+1
	stop = string.find(ipAddress, "%.", stop+1);
	local ipField2 = ipAddress:sub(start, stop-1) + 0;

	-- IP Field 3
	start = stop+1
	stop = string.find(ipAddress, "%.", stop+1);
	local ipField3 = ipAddress:sub(start, stop-1) + 0;

	-- IP Field 4
	start = stop+1
	stop = #ipAddress;
	local ipField4 = ipAddress:sub(start, stop) + 0;

	return ipField1, ipField2, ipField3, ipField4;
end

function IncrementIPField(ipField)
	if (ipField >= 255) then
		return 1, 1;
	else
		return 0, ipField + 1;
	end
end

-- This function doesn't guarantee a valid ip address, only ones that fall between 1-255
-- This would be much easier with bitwise operations, but LUA doesn't support it without an external library
function IncrementIPAddress()
	local ipAddressString = "";
	local carryOver;
	
	carryOver, ipField4 = IncrementIPField(ipField4);
	if carryOver == 1 then
		carryOver, ipField3 = IncrementIPField(ipField3);
	end
	
	if carryOver == 1 then
		carryOver, ipField2 = IncrementIPField(ipField2);
	end

	if carryOver == 1 then
		carryOver, ipField1 = IncrementIPField(ipField1);
	end

	ipAddressString = "" .. ipField1 .. "." .. ipField2 .. "." .. ipField3 .. "." .. ipField4;

	return ipAddressString;
end

-- #############################
-- MAIN SCRIPT
-- #############################
-- Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("This script will hammer the Account Server with login attempts.  After reaching");
print("the token threshold, the IP address will be banned and all login attempts will");
print("fail.  At which point, the script will change its IP address and continue");
print("hammering the AS until numAttempts is reached.");

print("\n##### Starting Test #####");

local result, resultTable;
local totalSuccessfulLogin, totalFailLogin, numFailLogin = 0, 0, 0;
local bannedList = {};
ipField1, ipField2, ipField3, ipField4 = InitializeIPAddress();

for i=1, numAttempts, 1 do
	-- Login attempt against the AS
	result, resultTable = AccountServer.XMLRPC.ValidateLoginEx(username, password, ipAddress, 0);

	if result == true then
		print(i .. "\tSuccessful\t" .. ipAddress);
		totalSuccessfulLogin = totalSuccessfulLogin + 1;
	else
		print(i .. "\tFail\t\t" .. ipAddress);
		numFailLogin = numFailLogin + 1;
	end

	-- Simulate an attack switching to another IP after several failed login attempts
	if numFailLogin >= failThreshold then 
		if AccountServer.XMLRPC.IsIPBanned(ipAddress) then
			print("The following IP Address has been banned:\t", ipAddress);
			table.insert(bannedList, ipAddress); 
			ipAddress = IncrementIPAddress();
			print("The following IP Address is now being used:\t", ipAddress);
			totalFailLogin = totalFailLogin + numFailLogin;
			numFailLogin = 0;
		else
			print("Something is wrong with your settings.\n"
				.. "The current number of failed attempts exceeds\n"
				.. "the specified threshold.");
			print("Fail Threshold:\t\t" .. failThreshold);
			print("Current Fail Login Count:\t" .. numFailLogin);
		end
	end
end

print("\n##### Banned IPs #####");
Console.PrintTable(bannedList);

print("##### Results #####");
print("Login Attempts:\t" .. totalSuccessfulLogin + totalFailLogin);
print("Successful Login:\t" .. totalSuccessfulLogin);
print("Failed Login:\t" .. totalFailLogin);
print("Ban IP Count:\t" .. #bannedList);
print("##### Ending Test #####");

Test.Succeed();