require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require((Var.Get(nil, "Subscriptions_ImportFile")), "Please set the global variable \"Subscriptions_ImportFile\" to the filename you want to import from!");

local file = Var.Get(nil, "Subscriptions_ImportFile");
local SubscriptionList = {};
local SubscriptionDetails = {};
local Subscriptions = {};
local CSVPath = Console.FilePathFromString("Subscriptions", file, "csv");
local CSVPathAlt = Console.FilePathFromString(nil, file, "csv");

--Get all products from CSV
Subscriptions = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);

Test.Require(Subscriptions, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);

--for each product add to Account Server
for i, _ in ipairs(Subscriptions) do
	print("Importing: " ..Subscriptions[i].name);
	local val = AccountServer.Web.CreateOrEditSubscription(Subscriptions[i].name, Subscriptions[i].internal, Subscriptions[i]);
	if not val then
		Test.Note(Subscriptions[i].name.." failed.");
		print("Fail!");
	else
		print("Success!");
		table.insert(SubscriptionList, Subscriptions[i].name);
	end
end


Test.Succeed({
	["Import File"] = file,
	["Subscriptions Imported"] = SubscriptionList,
	});
