require("cryptic/AccountServer.Web.Core");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

Test.Require((Var.Get(nil, "Discounts_ImportFile")), "Please set the global variable \"Discounts_ImportFile\" to the filename you want to import from!");

local file = Var.Get(nil, "Discounts_ImportFile");
local CSVPath = Console.FilePathFromString("Discounts", file, "csv");
local CSVPathAlt = Console.FilePathFromString(nil, file, "csv");
local Discounts = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);

Test.Require(Discounts, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);

for _, v in ipairs(Discounts) do
	if v["Name"] then
		print("Importing: " ..v["Name"]);
	end
	if not AccountServer.Web.AddDiscount(v["Currency"], v["Internal Product"], v["Discount"], v["Prerequisites"], v["Name"], v["Start Time"], v["End Time"], v["Products"], v["Blacklist Products"], v["Categories"], v["Blacklist Categories"]) then
		print("Fail!");
		Test.Note("Failed to add discount!", v);
	else
		print("Success!");
	end
end

Test.Succeed({["Import File"] = CSVPath});
