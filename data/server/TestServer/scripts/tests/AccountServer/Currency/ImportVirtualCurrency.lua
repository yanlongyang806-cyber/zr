require("cryptic/AccountServer.Web.Core");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

Test.Require((Var.Get(nil, "Currency_ImportFile")), "Please set the global variable \"Currency_ImportFile\" to the filename you want to import from!");

local file = Var.Get(nil, "Currency_ImportFile");
local CSVPath = Console.FilePathFromString("Currency", file, "csv");
local CSVPathAlt = Console.FilePathFromString(nil, file, "csv");
local currencies = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);

Test.Require(currencies, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);

for _, v in ipairs(currencies) do
	if v["Name"] then
		print("Importing: " ..v["Name"]);
	end
	if not AccountServer.Web.AddVirtualCurrency(v["Currency"], v["Game"], v["Environment"], v["Created Time"], v["Deprecated Time"], v["Reporting ID"], v["Revenue Type"], v["Is Chain"], v["Chain Parts"]) then
		print("Fail!");
		Test.Note("Failed to add currency!", v);
	else
		print("Success!");
	end
end

Test.Succeed({["Import File"] = CSVPath});
