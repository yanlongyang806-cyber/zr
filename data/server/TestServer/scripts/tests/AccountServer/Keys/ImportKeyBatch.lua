require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");

Test.Begin();
--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "Keys_ImportFile"), "Please set the global variable \"Keys_ImportFile\" to the filename you want to import from!");

local file		= Var.Get(nil, "Keys_ImportFile");
local KeyBatchList	= {};
local KeyBatchDetails	= {};
local KeyBatches	= {};
local CSVPath		= Console.FilePathFromString("Keys", file, "csv");
local CSVPathAlt	= Console.FilePathFromString(nil, file, "csv");
local BadName		= false;
local filepathxp	= "C:/Core/data/server/TestServer/scripts/General/Keys/Key Dumps";
local ZippedBatches	= {}
local hash		= ts.sha_256(file..os.date())
local ZippedPassword	= hash:match("(%w%w%w%w%w%w%w%w)")
local ZippedQACSBatches	= {}
local ZippedQACSPassword = "QARocks"

--Get all items from CSV
KeyBatches = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);
Test.Require(KeyBatches, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);
print("Verifying key gen server is running (start it now if you haven't already)...");
Test.Require(AccountServer.WaitFor(120, AccountServer.PokeKeyGenerating),
	"The key generating server does not appear to be running!");

--for each prefix add to Account Server
for i, _ in ipairs(KeyBatches) do
	print("Importing prefix: " ..KeyBatches[i].prefix);

	--check if prefix already exists
	if not AccountServer.Web.Legacy.GetKeyGroupPage(KeyBatches[i].prefix) then

		--Check if product exists
		if not AccountServer.Web.Legacy.GetProductID(KeyBatches[i].product) then
			print("","Product "..KeyBatches[i].product.." does not exist, not setting the product for the batch!");
			KeyBatches[i].product = nil;
		end
		
		--Create prefix
		if not AccountServer.Web.CreateKeyGroup(KeyBatches[i].prefix, KeyBatches[i].product) then
			Test.Note(KeyBatches[i].prefix.." failed.");
			print("","Fail!");
		else
			print("","Success!");
			table.insert(KeyBatchList, KeyBatches[i].prefix);
		end
	else
		print("","Cancelling: No need, Prefix already exists.");
	end
end

--Update key gen server
print("Updating key gen server with prefixes...");
if AccountServer.Web.Legacy.UpdateProductKeyGroups() then
	print("","Success!");
else
	print("","Fail!");
end

--[[Cant get gimme on boston servers easily...
--Launch key gen server
print("Launching key generating server...");
AccountServer.KillKeyGenerating();
Test.Require(AccountServer.LaunchKeyGeneratingAndWait(300),
	"Could not launch key generating Account Server, was this script run on the account server itself?");
]]--

--for each batch add to Account Server
for i, _ in ipairs(KeyBatches) do
	print("Importing: " ..KeyBatches[i].batchname);
	
	--Check to see if batch name already exists
	local t = AccountServer.Web.Legacy.GetBatchesForKeyGroup(KeyBatches[i].prefix);
	if t then
		for k, _ in pairs(t) do
			if KeyBatches[i].batchname == k then
				BadName = true;
			end
		end
	end
	--Check for batch name length
	if string.len(KeyBatches[i].batchname) > 100 then
		BadName = true;
	end
	
	if BadName == true then
		print("", "Cancelling: Batch name already exists or is too long!");
	else
		--Create and Verify all keys were created
		AccountServer.Web.Legacy.UpdateProductKeyGroups()
		if  AccountServer.Web.KeyCreateBatch(KeyBatches[i].batchname,
			KeyBatches[i].product,KeyBatches[i].prefix,
			KeyBatches[i].numkeys,KeyBatches[i].description or KeyBatches[i].batchdescription) == false then
			print("","Fail!");
		else 

			print("","Success!");
			--print("", "http://"..AccountServer.loc.."/legacy/keygroupView?prefix="..KeyBatches[i].prefix);
			
			table.insert(KeyBatchList, KeyBatches[i].prefix);
			local keys = nil;

			--Write file to disk
			filexp = Console.FilePathFromString(filepathxp, KeyBatches[i].batchname..".txt");
			keys = AccountServer.Web.Legacy.GetUnusedKeysForBatch(KeyBatches[i].prefix, KeyBatches[i].batchname);
			Console.WriteTXTFile(filexp, keys, KeyBatches[i].batchname);
			table.insert(ZippedBatches, KeyBatches[i].batchname..".txt")
			
			if KeyBatches[i].qabatch == "1" then
				print("", "Creating QA batch...");
				local QABatch = KeyBatches[i].batchname.." (QA)";
				AccountServer.Web.KeyCreateBatch(QABatch,
					KeyBatches[i].product,
					KeyBatches[i].prefix,
					100,
					KeyBatches[i].description);
				
				filexp = Console.FilePathFromString(filepathxp, QABatch..".txt");
				keys = AccountServer.Web.Legacy.GetUnusedKeysForBatch(KeyBatches[i].prefix, QABatch);
				Console.WriteTXTFile(filexp, keys, QABatch);
				table.insert(ZippedQACSBatches, QABatch..".txt")
				print("Success!")
			end

			if KeyBatches[i].csbatch == "1" then
				print("", "Creating CS batch...");
				local CSBatch = KeyBatches[i].batchname.." (CS)";
				AccountServer.Web.KeyCreateBatch(CSBatch,
					KeyBatches[i].product,
					KeyBatches[i].prefix,
					100,
					KeyBatches[i].description);

				filexp = Console.FilePathFromString(filepathxp, CSBatch..".txt");
				keys = AccountServer.Web.Legacy.GetUnusedKeysForBatch(KeyBatches[i].prefix, CSBatch);
				Console.WriteTXTFile(filexp, keys, CSBatch);
				table.insert(ZippedQACSBatches, CSBatch..".txt")
				print("Success!")
			end
			
		end
	end
end

--Zip Files
print("Zipping up as "..file.."...")
if ZippedBatches[1] then
	Console.ZipFilesFromTable(filepathxp, file, ZippedPassword, ZippedBatches)
end
if ZippedQACSBatches[1] then
	Console.ZipFilesFromTable(filepathxp, "QACS-"..file, ZippedQACSPassword, ZippedQACSBatches)
end
--Cleanup key dumps
print("Cleaning up raw files...")
Console.RemoveFilesFromTable(filepathxp, ZippedBatches)
Console.RemoveFilesFromTable(filepathxp, ZippedQACSBatches)

--[[Cant get gimme on boston servers easily...
--Kill key gen server
print("Killing key generating server...");
AccountServer.KillKeyGenerating();
]]--

Test.Succeed({
	["Import File"] = file,
	["Keys Imported"] = KeyBatchList,
	["Zipped Password"] = ZippedPassword,
	["QA CS Zipped Password"] = ZippedQACSPassword,
});
