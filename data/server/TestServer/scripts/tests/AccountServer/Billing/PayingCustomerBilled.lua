-- This script will mark accounts as billed given a list of accounts (CSV)
-- The CSV should contain two columns labeled acct_id and acct_name

require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "MarkAccountBilled_AccountList"), "Please set the global variable \"MarkAccountBilled_AccountList\" to the filename that contains the list of accounts.");

local filename		= Var.Get(nil, "MarkAccountBilled_AccountList");
local AccountList	= {};
local CSVPath		= Console.FilePathFromString(nil, filename, "csv");		-- File should be located in C:\Core\data\server\TestServer\scripts\General
local callStatus, callReturnValue, markAccountBilledResponse;

-- Export Success Result file
local AccountListSuccess	= {};
local TimeStamp			= string.gsub(os.date(), "[%s%p]", "_");
local ExportSuccessFile		= Var.Get(nil, "MarkAccountBilled_AccountList").."_".."SuccessResults" .."_"..TimeStamp;
local SuccessFileLocation	= Console.FilePathFromString(nil,ExportSuccessFile, "csv");

-- Export Fail Result file
local AccountListFailure	= {};
local ExportFailureFile		= Var.Get(nil, "MarkAccountBilled_AccountList").."_".."FailResults" .."_"..TimeStamp;
local FailureFileLocation	= Console.FilePathFromString(nil,ExportFailureFile, "csv");

-- Get all accounts from CSV
print("Getting accounts to update...");
AccountList = Console.ReadCSVFile(CSVPath, "acct_id", "acct_name");
Test.Require(AccountList, "The file " ..filename .."was not found at: " ..CSVPath);

-- Marking all accounts as billed
print("Marking account as billed...");
for i, _ in ipairs(AccountList) do
	callStatus, callReturnValue, callResponse =  AccountServer.XMLRPC.MarkAccountBilled(AccountList[i].acct_name);

	if callStatus and callResponse == "success" then
		-- Success
		table.insert(AccountListSuccess, AccountList[i]);
		print(#AccountListSuccess + #AccountListFailure .. "\tSuccess - \tAccountID: " .. AccountList[i].acct_id .. "\tAccountName: " .. AccountList[i].acct_name);
	else
		-- Fail
		table.insert(AccountListFailure, AccountList[i]);
		print(#AccountListSuccess + #AccountListFailure .. "\tFail - \t\tAccountID: " .. AccountList[i].acct_id .. "\tAccountName: " .. AccountList[i].acct_name);
	end;
end

-- Saving Success results
print("\n\n########## SAVING RESULTS ##########");
if #AccountListSuccess > 0 then
	print("Saving list of successful updates ...");
	Console.WriteCSVFile(SuccessFileLocation, AccountListSuccess);
else
	print("All accounts processed unsuccesfully.  Success list not processed.");
end;

-- Saving Fail results
if #AccountListFailure > 0 then
	print("Saving list of failed updates ...");
	Console.WriteCSVFile(FailureFileLocation, AccountListFailure);
else
	print("All accounts processed succesfully.  Failure list not processed.");
end;	

print("\n\n########## RESULTS ##########");
print("Total number of accounts processed :\t\t", #AccountListSuccess + #AccountListFailure);
print("Number of accounts successfully marked as billed :", #AccountListSuccess);
print("Number of accounts which failed to be updated :\t", #AccountListFailure);

Test.Succeed();