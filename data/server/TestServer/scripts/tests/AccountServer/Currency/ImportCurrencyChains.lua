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
local CurrencyChains = Console.ReadCSVFile(CSVPath) or Console.ReadCSVFile(CSVPathAlt);

Test.Require(CurrencyChains, "The file " ..file .."was not found at: " ..CSVPath .." OR " ..CSVPathAlt);

for _, v in ipairs(CurrencyChains) do
	if v["alias"] then
		print("Importing: " ..v["alias"], v["chain"]);
	end
	if not AccountServer.Web.AddCurrencyChain(v["alias"], v["chain"]) then
		print("Fail!");
		Test.Note("Failed to add Currency Chain!", v);
	else
		print("Success!");
	end
end

Test.Succeed({["Import File"] = CSVPath});