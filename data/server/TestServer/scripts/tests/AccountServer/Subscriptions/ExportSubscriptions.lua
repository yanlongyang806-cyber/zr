require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "Subscriptions_ExportFile"), "Please set the global variable \"Subscriptions_ExportFile\" to the filename you want to save to!");

local ProductList = {};
local ProductDetails = {};
local ExportedSubscriptions = {};
local CSVFileLocation = Console.FilePathFromString(nil, Var.Get(nil, "Subscriptions_ExportFile"), "csv");
print(CSVFileLocation);
--Get all Subscription
local SubscriptionList = AccountServer.Web.GetSubscriptions();

--For each product add to exporting table
for k, v in pairs(SubscriptionList) do
	print("Exporting: " ..k);
	local SubscriptionDetails = AccountServer.Web.GetSubscriptionDetails(k);

	if SubscriptionDetails then
		table.insert(ExportedSubscriptions, SubscriptionDetails);
		print("Success!");
	else
		Test.Note(k.. " failed getting details!");
		print("FAIL!");
	end
end

--Write CSV
ExportedSubscriptions[0] = AccountServer.Web.GetSubscriptionDetailsHeader();
Console.WriteCSVFile(CSVFileLocation, ExportedSubscriptions);

Test.Succeed({
	["Export File"] = CSVFileLocation,
	["Subscriptions Exported"] = ExportedSubscriptions,
	});
