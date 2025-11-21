--[[
	GLOBAL VARIABLES
	Require:
		FixCurrency_AccountList		- CSV file containing a list of accounts to process.  If the filename is "filename_1.csv", "filename_2.csv"
							- you must set this variable to "filename"
			acct_name			- Account Name
			acct_name			- Account Name
		FixCurrecny_NumOfFiles		- Integer representing the number of CSV to process.
							- This script can handle multiple CSVs in sequential order. ie. filename_1.csv, filename_2.csv, etc...
							- If only one file is used then it muse be named filename_1.csv
	Optional:
		FixCurrency_MoveReason		- Reason to run the script.  Will default to generic message if not specify
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
Test.Require(Var.Get(nil, "FixCurrency_AccountList"), "Please set the global variable \"FixCurrency_AccountList\" to the filename that contains the list of accounts.");
Test.Require(Var.Get(nil, "FixCurrency_NumOfFiles"), "Please set the global variable \"FixCurrency_NumOfFiles\" to the number of files to process.");

local numOfFiles			= Var.Get(nil, "FixCurrency_NumOfFiles");
local fileLocation			= "/FixCurrency/";	
local timeStamp				= string.gsub(os.date(), "[%s%p]", "_");
local garbageCollectMaxSize		= 102400;				-- 102400 KB = 100 MB
local accountSuccessCount		= 0;
local accountFailCount			= 0;
local fileCount				= 0;
local accountList			= {};
local accountListSuccess		= {};
local accountListFailure		= {};
local waitTime				= .25;					-- Time specified in seconds

-- Last Account that updated succesfully / fail
-- In case of a crash, these files will help determine where the script left off
local exportLastAccountSuccessFile	= "LastAccountSuccess";
local exportLastAccountFailureFile	= "LastAccountFailure";
local lastAccountSuccessFileLocation;
local lastAccountFailureFileLocation;

function Sleep(length)
	local start = os.clock();
	while os.clock() - start < length do end;

	return;
end;

-- Set Currency Functions
function SetCurrency(tableIndex, account)
	if tableIndex > 0 then
		local currentAccount = {};
		local keyValueResponse = AccountServer.XMLRPC.SetKeyValueEX(account.acct_name, account.key_value, account.amount, 1, "Fix PTS Currency Amount")

		if keyValueResponse == "key_set" then
			-- Success
			table.insert(accountListSuccess, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountSuccessFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tSuccess - \tName: " .. account.acct_name .. "\tKey Value: " .. account.key_value .. "\tAmount: " .. account.amount);
		else
			-- Fail
			table.insert(accountListFailure, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountFailureFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tFail - \t\tName: " .. account.acct_name .. "\tKey Value: " .. account.key_value .. "\tAmount: " .. account.amount);
		end

		Sleep(waitTime);
	end
end;

-- Get Account List Functions
function GetAccountList(CSVPath)
	accountList		= {};
	accountListSuccess	= {};
	accountListFailure	= {};

	if (collectgarbage("count") > garbageCollectMaxSize) then
		collectgarbage("collect");
	end
	
	accountList = Console.ReadCSVFile(CSVPath,"acct_name","key_value","amount");

	return;
end;

-- Grab accounts and update
function UpdateAccounts(fileNumber)
	-- Account List  File
	local filename = Var.Get(nil, "FixCurrency_AccountList") .. "_" .. fileNumber;
	local CSVPath = Console.FilePathFromString(nil, fileLocation .. filename, "csv");

	-- Export Success Result file
	local exportSuccessFile		= Var.Get(nil, "FixCurrency_AccountList").. "_" .. fileNumber .. "_".."SuccessResults" .."_"..timeStamp;
	local successFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportSuccessFile, "csv");

	-- Export Fail Result file
	local exportFailureFile		= Var.Get(nil, "FixCurrency_AccountList").. "_" .. fileNumber .. "_".."FailResults" .."_"..timeStamp;
	local failureFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportFailureFile, "csv");

	-- Get all accounts from CSV
	print("\n\n##### Processing " .. fileNumber .. " of " .. numOfFiles .. " files. #####");
	print("Getting accounts to update...");
	GetAccountList(CSVPath);

	if accountList ~= nil then
		-- Update Currency Balance
		Test.RepeatTable(SetCurrency, accountList);

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
		local failToOpen = Console.FilePathFromString(nil, fileLocation .. "ERROR_" .. filename, "txt");
		local errorMessage = "ERROR : Either the file \"" .. filename .. "\" does not exist or it is empty.";
		local blankTable = {};

		Console.WriteTXTFile(failToOpen, blankTable , errorMessage);

		print("\n\n############\n\n");
		print(errorMessage);
		print("\n\n############\n\n");
	end

end;

-- #############################
-- MAIN SCRIPT
-- #############################
Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

if type(numOfFiles)		~= "number" then
	print("\"FixCurrency_NumOfFiles\" is not an integer.");
	Test.Fail("\"FixCurrency_NumOfFiles\" is not an integer.");
end

lastAccountSuccessFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportLastAccountSuccessFile, "csv");
lastAccountFailureFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportLastAccountFailureFile, "csv");

-- Updating all accounts
Test.Repeat(UpdateAccounts, 1, numOfFiles, 1);
print("\n\n############# RESULTS ##############");
print("Total number of files processed : \t\t", fileCount );
print("Total number of accounts processed :\t\t", accountSuccessCount + accountFailCount);
print("Number of accounts successfully updated :\t", accountSuccessCount);
print("Number of accounts which failed to be updated :\t", accountFailCount);

Test.Succeed();