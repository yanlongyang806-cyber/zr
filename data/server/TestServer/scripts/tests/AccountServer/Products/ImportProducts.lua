require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();
print("Release the Kraken!")
--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "Products_ImportFile"), "Please set the global variable \"Products_ImportFile\" to the filename you want to import from!");

-- Optional Delay
-- Products_Delay is the number of seconds delay between each product being import
ProductsDelay		= Var.Get(nil, "Products_Delay", nil);

if ProductsDelay then
	if type(ProductsDelay) ~= "number" then
		Test.Fail("The optional Products_Delay variable is not set to an integer.");
	end
end

local file		= Var.Get(nil, "Products_ImportFile");
local ProductList	= {};
local ProductDetails	= {};
local Products		= {};
local CSVPath		= Console.FilePathFromString("Products", file, "csv");
local CSVPathAlt	= Console.FilePathFromString(nil, file, "csv");
local Result		= nil
local Message		= nil

--Backup Vars
local BackupProductDetails	= {};
local ExportedProducts		= {};
local TimeStamp			= string.gsub(os.date(), "[%s%p]", "_");
local BackupFile		= "ProductImportBackup_"..TimeStamp
local BackupFileLocation	= Console.FilePathFromString("Products/Backups",BackupFile, "csv");
local Backup			= {}

--Check for timestamp


--Get all products from CSV
print("Getting products to import...")
Products = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);
Test.Require(Products, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);

--for each product create a backup
print("Backing up products...")
for i, _ in ipairs(Products) do
	print("",Products[i].name)
	BackupProductDetails = AccountServer.Web.GetProductDetails(Products[i].name);
	
	--Blank out category if it didnt exist
	if BackupProductDetails == nil then
		print("","","Product doesn't exist, probably a new product.")
		BackupProductDetails = {["name"] = Products[i].name, ["categories"] = '""',}
	end

	table.insert(ExportedProducts, BackupProductDetails);
end

--Write and verify file
print("","Writing backup file "..BackupFile.." ...")
ExportedProducts[0] = AccountServer.Web.GetProductDetailsHeader();
Console.WriteCSVFile(BackupFileLocation, ExportedProducts);
Backup = Console.ReadCSVFile(BackupFileLocation) or Console.ReadCSVFile(BackupFileLocation);
Test.Require(Backup, "Backup was not created, aborting!");
print("","","Success!")

--for each product add to Account Server
print("Importing Products...");
for i, _ in ipairs(Products) do
	if ProductsDelay then
		Console.Wait(ProductsDelay);
	end
	print("","Importing: " ..Products[i].name);
	Result, Message = AccountServer.Web.CreateOrEditProduct(Products[i].name, Products[i].internal, Products[i])
	if not Result then
		Test.Note(Products[i].name.." failed.");
		print("","","Fail!");
		print("","",Message);
	else
		print("","","Success!");
		table.insert(ProductList, Products[i].name);
	end
end
print("Import completed!!!")

Test.Succeed({
	["Import File"] = file,
	["Products Imported"] = ProductList,
	});
