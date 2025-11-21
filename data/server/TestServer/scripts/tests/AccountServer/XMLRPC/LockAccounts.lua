require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Scope");

local pw_chars = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
	'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A',
	'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4', '5',
	'6', '7', '8', '9', '0'};

Test.Begin();

local fn = Scope.Var.Get("List");
Test.Require(fn, "Must provide a CSV file of accounts/emails to lock!");

AccountServer.Test.FailOnLoginFailure();

local t = Console.ReadCSVFile(fn, "a_name", "email");

function LockAccount(i, a)
	local a_name = a["a_name"];
	local pw = "";
	local email = a["email"];
	
	if email ~= "" then
		email = email.."_COMPROMISED";
	else
		email = nil;
	end

	for i = 1, 16 do
		pw = pw..pw_chars[math.random(#pw_chars)];
	end

	print(a_name, pw, email);
	local r, t = AccountServer.XMLRPC.UpdateUser(a_name, pw, email);

	if not r then
		Test.Error(("XMLRPC FAIL %s: (%s, %s)"):format(a_name, pw, email or "N/A"));
	elseif t["UserStatus"] ~= "user_update_ok" then
		Test.Error(("AS FAIL %s: (%s, %s)"):format(a_name, pw, email or "N/A"));
	else
		Test.Note(("%s: (%s, %s)"):format(a_name, pw, email or "N/A"));
	end
end

math.randomseed(os.time());
Test.RepeatArray(LockAccount, t);
Test.Succeed();
