require("cryptic/AccountServer.Web.Core");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

local file = Var.Get(nil, "Discounts_DisableFile");
Test.Require(file, "Please set the global variable \"Discounts_DisableFile\" to the filename you want to import from!");

local CSVPath = Console.FilePathFromString("Discounts", file, "csv");
local CSVPathAlt = Console.FilePathFromString(nil, file, "csv");
local Discounts = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);

for _, v in ipairs(Discounts) do
	if v["Name"] then
		print("Disabling: " ..v["Name"]);
	end
	if not AccountServer.Web.DisableDiscount(v["Currency"], v["Internal Product"], v["Prerequisites"], v["Name"]) then
		print("Fail!");
		Test.Note("Failed to add discount!", v);
	else
		print("Success!");
	end
end

Test.Succeed({["Import File"] = file});
