--[[
	This script will move or duplicate an account balance from one currency (CurrencySplit_SourceCurrency) to another (CurrencySplit_DestinationCurrency).

	GLOBAL VARIABLES
	Require:
		CurrencySplit_AccountList		- CSV file containing a list of accounts to process.  If the filename is "filename_1.csv", "filename_2.csv"
							- you must set this variable to "filename"
			acct_id				- Account ID
			acct_name			- Account Name
		CurrencySplit_SourceCurrency		- Source Currency, will have a balance of zero after the script is process
		CurrencySplit_DestinationCurrency	- Destination Currency, will have a balance equal to the source currency
		CurrencySplit_NumOfFiles		- Integer representing the number of CSV to process.
							- This script can handle multiple CSVs in sequential order. ie. filename_1.csv, filename_2.csv, etc...
							- If only one file is used then it muse be named filename_1.csv
		CurrencySplit_MoveEnable		- Boolean value, if true, the script will move the balance
		CurrencySplit_DuplicateEnable		- Boolean value, if true, the script will duplicate the balance
							-- To reduce the chance of human error, the user is force to specify
							-- the type of operation individually: Move or Duplicate.  Only one can be true at a given time.
	Optional:
		CurrencySplit_MoveReason		- Reason to run the script.  Will default to generic message if not specify
		CurrencySplit_DuplicateReason		- Reason to run the script.  Will default to generic message if not specify
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
Test.Require(Var.Get(nil, "CurrencySplit_AccountList"), "Please set the global variable \"CurrencySplit_AccountList\" to the filename that contains the list of accounts.");
Test.Require(Var.Get(nil, "CurrencySplit_SourceCurrency"), "Please set the global variable \"CurrencySplit_SourceCurrency\" to the source currecny.");
Test.Require(Var.Get(nil, "CurrencySplit_DestinationCurrency"), "Please set the global variable \"CurrencySplit_DestinationCurrency\" to the destination currecny.");
Test.Require(Var.Get(nil, "CurrencySplit_NumOfFiles"), "Please set the global variable \"CurrencySplit_NumOfFiles\" to the number of files to process.");

local numOfFiles			= Var.Get(nil, "CurrencySplit_NumOfFiles");
local moveEnable			= Var.Get(nil, "CurrencySplit_MoveEnable");
local duplicateEnable			= Var.Get(nil, "CurrencySplit_DuplicateEnable");
local moveFileLocation			= "/MoveCurrency/";			-- CSVs containing the list of accounts should be located in C:\Core\data\server\TestServer\scripts\General\MoveCurrency
local duplicateFileLocation		= "/DuplicateCurrency/";		-- CSVs containing the list of accounts should be located in C:\Core\data\server\TestServer\scripts\General\DuplicateCurrency
local fileLocation;
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

-- Per Brent's request, he wants a wait time of 1/4 second between calls
-- Console.Wait() only works for time >= 1 second
-- Is there a function in the TestServer that lets you wait for < 1?
function Sleep(length)
	local start = os.clock();
	while os.clock() - start < length do end;

	return;
end;

-- Move Currency Functions
function MoveCurrency(tableIndex, account)
	if tableIndex > 0 then
		local currentAccount = {};
		local moveKeyValueResponse =  AccountServer.XMLRPC.MoveKeyValue(account.acct_name, Var.Get(nil, "CurrencySplit_SourceCurrency"), Var.Get(nil, "CurrencySplit_DestinationCurrency"), Var.Default(nil, "CurrencySplit_MoveReason", "Currency Split Conversion"));

		if moveKeyValueResponse == "key_set" then
			-- Success
			table.insert(accountListSuccess, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountSuccessFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tSuccess - \tID: " .. account.acct_id .. "\tName: " .. account.acct_name);
		else
			-- Fail
			table.insert(accountListFailure, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountFailureFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tFail - \t\tID: " .. account.acct_id .. "\tName: " .. account.acct_name);
		end

		Sleep(waitTime);
	end
end;

-- Duplicate Currency Functions
function DupicateCurrency(tableIndex, account)
	if tableIndex > 0 then
		local currentAccount = {};
		local duplicateKeyValueResponse =  AccountServer.XMLRPC.DuplicateKeyValue(account.acct_name, Var.Get(nil, "CurrencySplit_SourceCurrency"), Var.Get(nil, "CurrencySplit_DestinationCurrency"), Var.Default(nil, "CurrencySplit_DuplicateReason", "Currency Split Duplicate"));

		if duplicateKeyValueResponse == "key_set" then
			-- Success
			table.insert(accountListSuccess, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountSuccessFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tSuccess - \tID: " .. account.acct_id .. "\tName: " .. account.acct_name);
		else
			-- Fail
			table.insert(accountListFailure, account);
			table.insert(currentAccount, account);
			Console.WriteCSVFile(lastAccountFailureFileLocation, currentAccount);
			print(#accountListSuccess + #accountListFailure .. "\tFail - \t\tID: " .. account.acct_id .. "\tName: " .. account.acct_name);
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
	
	accountList = Console.ReadCSVFile(CSVPath);

	return;
end;

-- Grab accounts and update
function UpdateAccounts(fileNumber)
	-- Account List  File
	local filename = Var.Get(nil, "CurrencySplit_AccountList") .. "_" .. fileNumber;
	local CSVPath = Console.FilePathFromString(nil, fileLocation .. filename, "csv");

	-- Export Success Result file
	local exportSuccessFile		= Var.Get(nil, "CurrencySplit_AccountList").. "_" .. fileNumber .. "_".."SuccessResults" .."_"..timeStamp;
	local successFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportSuccessFile, "csv");

	-- Export Fail Result file
	local exportFailureFile		= Var.Get(nil, "CurrencySplit_AccountList").. "_" .. fileNumber .. "_".."FailResults" .."_"..timeStamp;
	local failureFileLocation	= Console.FilePathFromString(nil, fileLocation .. exportFailureFile, "csv");

	-- Get all accounts from CSV
	print("\n\n##### Processing " .. fileNumber .. " of " .. numOfFiles .. " files. #####");
	print("Getting accounts to update...");
	GetAccountList(CSVPath);

	if accountList ~= nil then
		-- Update Currency Balance
		if moveEnable and not duplicateEnable then
			Test.RepeatTable(MoveCurrency, accountList);
		elseif not moveEnable and duplicateEnable then
			Test.RepeatTable(DupicateCurrency, accountList);
		end

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
	print("\"CurrencySplit_NumOfFiles\" is not an integer.");
	Test.Fail("\"CurrencySplit_NumOfFiles\" is not an integer.");
elseif type(moveEnable)		~= "boolean" then
	print("\"CurrencySplit_MoveEnable\" is not a boolean value.");
	Test.Fail("\"CurrencySplit_MoveEnable\" is not a boolean value.");
elseif type(duplicateEnable)	~= "boolean" then
	print("\"CurrencySplit_DuplicateEnable\" is not a boolean value.");
	Test.Fail("\"CurrencySplit_DuplicateEnable\" is not a boolean value.");
end

-- Determining File Locations
-- To reduce the chance of human error, the user is force to specify
-- the type of operation individually: Move or Duplicate.  Only one can be true at a given time.
if moveEnable and not duplicateEnable then
	fileLocation		= moveFileLocation;
	print("Moving currency from " .. Var.Get(nil, "CurrencySplit_SourceCurrency") .. " to " .. Var.Get(nil, "CurrencySplit_DestinationCurrency"));
elseif not moveEnable and duplicateEnable then
	fileLocation		= duplicateFileLocation;
	print("Duplicating currency from " .. Var.Get(nil, "CurrencySplit_SourceCurrency") .. " to " .. Var.Get(nil, "CurrencySplit_DestinationCurrency"));
else
	print("\"CurrencySplit_MoveEnable\" and \"CurrencySplit_DuplicateEnable\" are not configured correctly.");
	Test.Fail("\"CurrencySplit_MoveEnable\" and \"CurrencySplit_DuplicateEnable\" are not configured correctly.");
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