require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");


Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

local CSVPath = Console.FilePathFromString("Keys", "KeyUseReportList", "csv");
local Prefixes = Console.ReadCSVFile(CSVPath);
local Batches = nil;
local UsedKeys = nil;
local DistributedKeys = nil;
local PrefixDump = {};

Test.Require(Prefixes, "There were no Prefixes found in the list at: " ..CSVPath);

--For each Prefix
for i, _ in ipairs(Prefixes) do
	PrefixDump = {};
	print("Reading Prefix: "..Prefixes[i].prefix);

	--If the Prefix exists
	if AccountServer.Web.Legacy.GetKeyGroupPage(Prefixes[i].prefix) then
		print("", "Reading Prefix Batches...");
		Batches = AccountServer.Web.Legacy.GetBatchesForKeyGroup(Prefixes[i].prefix);

		--For each batch
		for k, v in pairs(Batches) do
			print("", "Reading Batch: "..k);

			--get used keys
			UsedKeys = AccountServer.Web.Legacy.GetUsedKeysForBatch(Prefixes[i].prefix, k);
			--add to table
			PrefixDump = Console.AppendTable(PrefixDump, UsedKeys)

						
			--get distributed keys
			DistributedKeys = AccountServer.Web.Legacy.GetDistributedKeysForBatch(Prefixes[i].prefix, k);
			--add to table
			PrefixDump = Console.AppendTable(PrefixDump, DistributedKeys)
			
		end
	end
	
	if PrefixDump then
		print("Writing Prefix: "..Prefixes[i].prefix);
		CSVPath = Console.FilePathFromString("Keys/Key Dumps", Prefixes[i].prefix.." Dump", "csv");
		Console.WriteCSVFile(CSVPath, PrefixDump);
	end
end

Test.Succeed({
	["Keys Reported On"] = Prefixes,
});