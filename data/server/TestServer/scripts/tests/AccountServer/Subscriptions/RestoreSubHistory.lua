require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Metric");
require("cryptic/Test");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

sub_to_int = {
	["SP-CO-6MonthPOR1"] = "S-CO",
	["SP-CO-6MonthPO"] = "S-CO", 
	["SP-CO-R1Month"] = "S-CO", 
	["SP-CO-R6Month"] = "S-CO",
	["SP-CO-LifetimePO"] = "S-CO",
	["SP-CO-GameCard-v2"] = "S-CO",
	["SP-CO-GameCard"] = "S-CO",
	["SP-CO-6MonthPOR3"] = "S-CO",
	["SP-STO-Int"] = "S-STO",
	["SP-CO-6MonthPOR6"] = "S-CO",
	["SP-CO-PR-R3Month-March10"] = "S-CO",
	["SP-STO-GameCard"] = "S-STO",
	["SP-CO-R3Month"] = "S-CO",
	["SP-CO-Int"] = "S-CO",
	["SP-STO-R6Month"] = "S-STO",
	["SP-CO-R3month-6monthPO"] = "S-CO",
	["SP-STO-R3Month"] = "S-STO",
	["SP-STO-R12MonthPO"] = "S-STO",
	["SP-STO-R1Month"] = "S-STO",
	["SP-STO-Lifetime"] = "S-STO",
	["six month invis hack"] = "S-CO",
};

int_to_prod = {
	["S-CO"] = "FightClub",
	["S-STO"] = "StarTrek",
};

local s_fn = Var.Get(nil, "SubRestoreCSV");
Test.Require(s_fn, "Please set \"SubRestoreCSV\" to the filepath of the fixup file.");

local fixup_start_date = Var.Default(nil, "SubRestoreFixupStartDate", false);

fpath = Console.FilePathFromString(nil, s_fn, "csv");

print("Reading fixup file...");
t_0 = ts.get_time();
local csv = Console.ReadCSVFile(fpath);
t_1 = ts.get_time();
Test.Require(csv, "Error reading file at "..fpath.."!");
print(string.format("...done. (%0.2fs)", t_1-t_0));
print();

print("Beginning iteration: "..#csv.." entries.");
Metric.Clear("SubRestore", "ArchiveEntry");
Metric.Clear("SubRestore", "CachedSubPoke");
Metric.Clear("SubRestore", "BadGUID");
Metric.Clear("SubRestore", "BadEnd");

local now = ToSS2000FromNow();

function RestoreSubHistory(i, v)
	local a_name = v["Customer ID"];
	local s_name = v["Billing Plan"];
	local s_int = sub_to_int[s_name];
	local s_prod = int_to_prod[s_int];
	local s_start = tonumber(v["Created Date"]);
	local s_end = tonumber(v["End Date"]);
	local status = v["Status"];

	if not a_name then
		Metric.Push("SubRestore", "BadGUID", 0.0);
		return;
	elseif status == "PendingCustomerAction" or not s_end then
		Metric.Push("SubRestore", "BadEnd", 0.0);
		return;
	elseif status == "Stopped" or status == "Hard Error" or ((status == "New" or status == "Good Standing") and s_end < now) then
		-- Add archived sub history
		t_0 = ts.get_time();
		local t = AccountServer.XMLRPC.ArchiveSubHistory(a_name, s_start, s_end, s_prod, s_int, nil, 1);
		t_1 = ts.get_time();
		Metric.Push("SubRestore", "ArchiveEntry", t_1-t_0);
	else
		local found = false;

		t_0 = ts.get_time();

		if fixup_start_date then
			-- Restore start time for existing cached sub
			local subs = AccountServer.Web.GetAccountCachedSubs(a_name);
			Test.ErrorUnless(subs, "Could not find any subs for "..a_name);

			for _, w in ipairs(subs) do
				if w["Sub Name"] == s_name then
					-- Found it, do our thing and break
					local t = AccountServer.XMLRPC.ChangeSubCreatedTime(a_name, w["VID"], s_start);
					found = true;
					break;
				end
			end
		end

		-- Make a sub history entry anyway, we don't lose anything by doing this and it covers our ass
		local t = AccountServer.XMLRPC.ArchiveSubHistory(a_name, s_start, s_end, s_prod, s_int, nil, 1);
		t_1 = ts.get_time();
		Metric.Push("SubRestore", "CachedSubPoke", t_1-t_0);
	end
end

Test.RepeatArray(RestoreSubHistory, csv);

Test.Succeed();
