require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "Products_ExportFile"), "Please set the global variable \"Products_ExportFile\" to the filename you want to save to!");

local ProductList = {};
local ProductDetails = {};
local ExportedProducts = {};
local CSVFileLocation = Console.FilePathFromString(nil, Var.Get(nil, "Products_ExportFile"), "csv");

--Get all products
ProductList = AccountServer.Web.GetProducts();

--For each product add to exporting table
for k, v in pairs(ProductList) do
	print("Exporting: " ..k);
	ProductDetails = AccountServer.Web.GetProductDetails(k);
	if ProductDetails then
		table.insert(ExportedProducts, ProductDetails);
		print("Success!");
	else
		Test.Note(k.. " failed getting details!");
		print("FAIL!");
	end
end

--Write CSV
ExportedProducts[0] = AccountServer.Web.GetProductDetailsHeader();
Console.WriteCSVFile(CSVFileLocation, ExportedProducts);

Test.Succeed({
	["Export File"] = CSVFileLocation,
	["Products Exported"] = ExportedProducts,
	});
