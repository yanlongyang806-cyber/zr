require("cryptic/AccountServer");
require("cryptic/AccountServer.Test");
require("cryptic/Console");
require("cryptic/Scope");
require("cryptic/Test");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

local fixup_fn = Scope.Var.Get("FixupList");

local plog_fn = Scope.Var.Get("PurchaseLogList");

function FixupAccount(i, a)
	local a_id = a["a_id"];
	local count = a["count"];

	time_print("Fixing up account "..i..": "..a_id);
	local r, t = AccountServer.XMLRPCRequest("FixupTransactionLogMigration",
		{["Uaccountid"] = a_id, ["Upurchaselogcount"] = count});
	if not r then
		Test.Note("Error fixing up account "..a_id..": "..t);
	elseif t["Status"] ~= "success" then
		Test.Note("Error fixing up account "..a_id..": "..t["Result"]);
	end
end

function FixupPurchaseLog(i, p)
	local log = {
		["Uaccountid"] = p["a_id"],
		["Uproductid"] = p["p_id"],
		["Source"] = p["source"],
		["Price"] = p["price"],
		["Currency"] = p["currency"],
		["Utimestampss2000"] = p["timestamp"],
		["Orderid"] = p["o_id"],
		["Merchanttransactionid"] = p["mt_id"],
		["Provider"] = p["provider"],
	};

	time_print("Fixing up purchase log "..i);
	local r, t = AccountServer.XMLRPCRequest("FixupMigratedPurchaseLog", log);
	if not r then
		print(t);
		Test.Fail();
		Test.Note("Error fixing up purchase log "..i..": "..t);
	end
end

if fixup_fn then
	local fixup_t = Console.ReadCSVFile(fixup_fn, "a_id", "count");

	time_print("Beginning account fixup...");
	local start = ts.get_time();
	Test.RepeatArray(FixupAccount, fixup_t);
	local finish = ts.get_time();
	time_print(("Finished account fixup. (%0.2fs)"):format(finish-start));
end

if plog_fn then
	local plog_t = Console.ReadCSVFile(plog_fn, "a_id", "p_id", "source", "price", "currency", "timestamp", "o_id", "mt_id", "provider");

	time_print("Beginning purchase log fixup...");
	local start = ts.get_time();
	Test.RepeatArray(FixupPurchaseLog, plog_t);
	local finish = ts.get_time();
	time_print(("Finished purchase log fixup. (%0.2fs)"):format(finish-start));
end

Test.Succeed();
