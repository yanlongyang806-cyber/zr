require("cryptic/AccountServer/Test");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/Scope");
require("cryptic/Test");
require("ss2000");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

local earliest_time = Scope.Var.Get("EarliestTime");
Test.Require(earliest_time, "Specify the earliest SS2000 timestamp to check in \"EarliestTime\"!");

local latest_time = Scope.Var.Get("LatestTime");
if not latest_time then latest_time = ToSS2000FromNow(); end

local interval = Scope.Var.Get("Interval");
if not interval then interval = 86400; end

local cur_start = earliest_time + 1;

Scope.Var.Clear("Itemtotal");
Scope.Var.Clear("Amttotal");
Test.ReportVars(Scope.Var.Ref("Itemtotal"), Scope.Var.Ref("Amttotal"));

while true do
	if cur_start > latest_time then break end
	local cur_end = cur_start + interval - 1;
	if cur_end > latest_time then cur_end = latest_time; end
	local cur_start_stamp = TimestampFromSS2000(cur_start);
	local cur_end_stamp = TimestampFromSS2000(cur_end);

	time_print(("Getting transactions from %s to %s."):format(cur_start_stamp, cur_end_stamp));
	local r, t = AccountServer.XMLRPC.TransactionFetchDelta(cur_start, cur_end, 7);
	Test.Require(r, ("Failed to request delta: (%d, %d)"):format(cur_start, cur_end), t);
	local transid = t.Transid;
	Test.Require(transid, ("Failed to get trans ID: (%d, %d)"):format(cur_start, cur_end), t.Result);

	while true do
		local t = AccountServer.XMLRPC.TransView(transid);

		if t and t.Status ~= "PROCESS" then
			if t.Transactioninfo then
				local items = #t.Transactioninfo;
				local amt = 0;
				for _, trans in ipairs(t.Transactioninfo) do
					amt = amt + tonumber(trans.Amount);
				end
				Scope.Var.Add("Itemtotal", items);
				Scope.Var.Add("Amttotal", amt);
				Test.Report(("(%d, %d, %d, %0.2f)"):format(cur_start, cur_end, items, amt));
			end
			break
		end
	end

	cur_start = cur_end + 1;
end

Test.Succeed();
