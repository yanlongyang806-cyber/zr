require("cryptic/Console");
require("cryptic/Scope");
require("cryptic/Test");
require("xmlrpc.http");

function Wait(timeout)
	local t = ts.get_time();

	while ts.get_time() - t < timeout do
	end
end

Test.Begin();

local shard = Scope.Var.Get("Shard");
Test.Require(shard, "Please specify the target shard in the variable \"RestoreNumeric:Shard\".");

local user = Scope.Var.Get("User");
Test.Require(user, "Please specify your Cryptic account name in the variable \"RestoreNumeric:User\".");

local pass = Scope.Var.Get("Password");
Test.Require(pass, "Please specify your Cryptic account password in the variable \"RestoreNumeric:Password\".");

local path = Scope.Var.Get("ImportFile");
Test.Require(path, "Please specify the full path to the fixup CSV in \"RestoreNumeric:ImportFile\".");

local numeric = Scope.Var.Get("Numeric");
Test.Require(numeric, "Please specify the numeric to fixup in \"RestoreNumeric:Numeric\".");

local go = Scope.Var.Get("Failsafe");

function WebRequestXMLRPC(call, ...)
	return xmlrpc.http.authcall(("http://%s/xmlrpc/WebRequestServer[0]"):format(shard), user, pass, call, ...);
end

function FixupChar(i, char)
	time_print("Fixing up character: "..char.character);

	local r, t = WebRequestXMLRPC("GiveNumeric", char.character, numeric, (go and char.amount or 0));
	if not r then
		Test.Error("CHARACTER ERROR "..i..": "..char.character.." - "..t);
	end
	Wait(0.4);
end

local start_time = ts.get_time();

-- Read in a CSV containing rows specifying the characters to fix up
local chars = Console.ReadCSVFile(path, "character", "amount");

time_print("Beginning fixup.");
Test.RepeatArray(FixupChar, chars);

local finish_time = ts.get_time();
local elapsed = finish_time - start_time;

time_print(("Done performing fixup! (%0.2f s)"):format(elapsed));
time_print("Check the report for any errors.");

Test.Succeed();
