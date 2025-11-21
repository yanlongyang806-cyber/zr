--[[
	This script will permantly delete an account from the Account Server.

	GLOBAL VARIABLES
	Require:
		DeleteAccount_AccountList	- CSV file containing a list of accounts to process.
						- If the filename is "filename_1.csv", "filename_2.csv"
						- you must set this variable to "filename"
			acct_id			- Account ID
	Optional:
--]]

require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

-- #############################
-- VARIABLE DECLARATIONS 
-- #############################
-- Require a CSV name
Test.Require(Var.Get(nil, "DeleteAccounts_AccountList"), "Please set the global variable"
	.. " \"DeleteAccounts_AccountList\" to the filename that contains the list of accounts.");
Test.Require(Var.Get(nil, "DeleteAccounts_NumOfFiles"), "Please set the global variable"
	.. " \"DeleteAccounts_NumOfFiles\" to the number of files to process.");

local numOfFiles		= Var.Get(nil, "DeleteAccounts_NumOfFiles");
local fileLocation		= "/DeleteAccounts/";	-- CSVs containing the list of accounts should be located in 
							-- C:\Core\data\server\TestServer\scripts\General\DeleteAccounts
local garbageCollectMaxSize	= 102400;		-- 102400 KB = 100 MB
local accountSuccessCount	= 0;
local accountFailCount		= 0;
local fileCount			= 0;
local accountList		= {};
local accountListSuccess	= {};
local accountListFailure	= {};
local timeStamp			= string.gsub(os.date(), "[%s%p]", "_");

-- Last Account that updated succesfully / fail
-- In case of a crash, these files will help determine where the script left off
local exportLastAccountSuccessFile	= "LastAccountSuccess";
local exportLastAccountFailureFile	= "LastAccountFailure";
local lastAccountSuccessFileLocation;
local lastAccountFailureFileLocation;

-- #############################
-- FUNCTION DEFINITIONS
-- #############################
-- Delete User Account
function UserDelete(tableIndex, account)
	if tableIndex > 0 then
		local currentAccount = {};
		local response, result  = AccountServer.XMLRPC.UserDelete(account.accountID);
		local accountResult = {};
		local accountResult = {
			AccountID = account.accountID, 
			Result = result,
		};

		if response then
			-- Success
			table.insert(accountListSuccess, accountResult);
			table.insert(currentAccount, accountResult);
			Console.WriteCSVFile(lastAccountSuccessFileLocation, currentAccount);
			print(("%d\tSuccess - \tAccount ID: %d")
				:format(#accountListSuccess + #accountListFailure, account.accountID)); 
		else
			-- Fail
			table.insert(accountListFailure, accountResult);
			table.insert(currentAccount, accountResult);
			Console.WriteCSVFile(lastAccountFailureFileLocation, currentAccount);
			print(("%d\tFail - \t\tAccount ID: %d\n\t\t\tReason: %s")
				:format(#accountListSuccess + #accountListFailure, account.accountID, result)); 
		end;
	end;
end;

-- Get Account List Functions
function GetAccountList(CSVPath)
	accountList		= {};
	accountListSuccess	= {};
	accountListFailure	= {};

	if (collectgarbage("count") > garbageCollectMaxSize) then
		collectgarbage("collect");
	end
	
	accountList = Console.ReadCSVFile(CSVPath, "accountID");

	return;
end;

-- Delete Accounts
function DeleteAccounts(fileNumber)
	-- Account List  File
	local filename = Var.Get(nil, "DeleteAccounts_AccountList") .. "_" .. fileNumber;
	local CSVPath = Console.FilePathFromString(nil, fileLocation .. filename, "csv");

	-- Export Success Result file
	local exportSuccessFile		= Var.Get(nil, "DeleteAccounts_AccountList")
		.. "_" .. fileNumber .. "_".."SuccessResults" .."_"..timeStamp;
	local successFileLocation	= Console.FilePathFromString(nil, fileLocation
		.. exportSuccessFile, "csv");

	-- Export Fail Result file
	local exportFailureFile		= Var.Get(nil, "DeleteAccounts_AccountList")
		.. "_" .. fileNumber .. "_".."FailResults" .."_"..timeStamp;
	local failureFileLocation	= Console.FilePathFromString(nil, fileLocation
		.. exportFailureFile, "csv");

	-- Get all accounts from CSV
	print("\n\n##### Processing " .. fileNumber .. " of " .. numOfFiles .. " files. #####");
	print("Getting accounts to update...");
	GetAccountList(CSVPath);

	if accountList ~= nil then
		-- Delete Accounts
		Test.RepeatTable(UserDelete, accountList);

		-- Saving Success results
		print("\n\n########## SAVING RESULTS ##########");
		if #accountListSuccess > 0 then
			print("Saving list of successful updates ...");
			Console.WriteCSVFile(successFileLocation, accountListSuccess);
		else
			print("All accounts processed unsuccesfully.  Success list not created.");
		end

		-- Saving Fail results
		if #accountListFailure > 0 then
			print("Saving list of failed updates ...");
			Console.WriteCSVFile(failureFileLocation, accountListFailure);
		else
			print("All accounts processed succesfully.  Failure list not created.");
		end	

		-- Incrementing count for reporting
		fileCount = fileCount + 1;
		accountSuccessCount	= accountSuccessCount + #accountListSuccess;
		accountFailCount	= accountFailCount + #accountListFailure;
	else
		-- A text file will be created if a file fails to open or is empty.
		local failToOpen = Console.FilePathFromString(nil, fileLocation .. "ERROR_"
			.. filename, "txt");
		local errorMessage = "ERROR : Either the file \"" .. filename 
			.. "\" does not exist or it is empty.";
		local blankTable = {};

		Console.WriteTXTFile(failToOpen, blankTable , errorMessage);

		print("\n\n############\n");
		print(errorMessage);
		print("\n############\n\n");
	end

end;

-- #############################
-- MAIN SCRIPT
-- #############################
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("##### Starting Test #####");

print("\n\n##### WARNING #####");
print("You are about to permenantly remove accounts from the Account Server.");
print("Please shut down the TEST SERVER if you DO NOT wish to delete these accounts.");

for i=15, 1, -1 do
	print("The accounts will be deleted in:",i);
	Console.Wait(1);
end;

if type(numOfFiles) ~= "number" then
	print("\"DeleteAccounts_AccountList\" is not an integer.");
	Test.Fail("\"DeleteAccounts_AccountList\" is not an integer.");
end

lastAccountSuccessFileLocation	= Console.FilePathFromString(nil, fileLocation
	.. exportLastAccountSuccessFile, "csv");
lastAccountFailureFileLocation	= Console.FilePathFromString(nil, fileLocation
	.. exportLastAccountFailureFile, "csv");

-- Updating all accounts
Test.Repeat(DeleteAccounts, 1, numOfFiles, 1);
print("\n\n############# RESULTS ##############");
print("Total number of files processed : \t\t", fileCount );
print("Total number of accounts processed :\t\t", accountSuccessCount + accountFailCount);
print("Number of accounts successfully updated :\t", accountSuccessCount);
print("Number of accounts which failed to be updated :\t", accountFailCount);

print("##### Ending Test #####");
Test.Succeed();