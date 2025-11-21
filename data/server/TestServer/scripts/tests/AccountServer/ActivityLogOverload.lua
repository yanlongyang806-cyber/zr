require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Test");

Test.Begin();
Var.Set(nil, "Test_IP", "RANDOM");
local a_names = {};
local use_existing_accounts = false;

local n_accounts_file = Scope.Var.Get("AccountsFile");
local n_accounts = Scope.Var.Get("Numaccounts") or 10000;
Test.Require(n_accounts_file or n_accounts, "Please set the variable \"Numaccounts\" to the number of test accounts to create.");

local n_max_log_size = Scope.Var.Get("Logsize") or 1000;
Test.Require(n_accounts_file or n_max_log_size, "Please set the variable \"Logsize\" to the number of activity logs to create in total.");

if n_accounts_file then
	n_accounts_file = Console.FilePathFromString(nil, n_accounts_file, "txt");
	a_names = Console.ReadListFile(n_accounts_file);
	n_accounts = #a_names;
	use_existing_accounts = true;
end

local n_account_prefix = Scope.Var.Default("AccountPrefix", "AccountLog");
local n_buffer_size = Scope.Var.Default("ActivityLogBufferSize", 40);
local n_buffer_duration = Scope.Var.Default("ActivityLogBufferDuration", 60);
local n_buffer_process = Scope.Var.Default("AccountLogBufferProcessedInTick", 5);
local n_major_factor = Scope.Var.Default("ActivityDistributionFactor", 0.7);

if AccountServer.loc == "localhost" then
	AccountServer.Kill();
	AccountServer.DefaultVersion("AS.213.20100621_1054.0" or Scope.Var.Get("Accountserver_Version"));
	AccountServer.CleanDB();
	AccountServer.Patch();
	AccountServer.LaunchAndWait(nil, "AccountLogBufferSize "..n_buffer_size, "AccountLogBufferDuration "..n_buffer_duration, "giAccountLogBufferProcessedInTick "..n_buffer_process);
end

local dist_table = {};

function EightyTwenty(t, a, b, p, f)
	p = p or 1.0;

	if a == b then
		t[a] = p;
		return;
	end

	local c = math.floor((b-a+1)*f) + a - 1;

	EightyTwenty(t, a, c, p*(1-f), f);
	EightyTwenty(t, c+1, b, p*f, f);
end

if not use_existing_accounts then
	EightyTwenty(dist_table, 1, n_accounts, 1.0, n_major_factor);
end

function ActivityLogOverload_CreateAccount(i)
	table.insert(a_names, n_account_prefix.."_"..string.format("%07d", i));
	local n = a_names[i];
	local r, t = AccountServer.XMLRPC.CreateNewAccount(n, n, n, n.."@crypticstudios.com", n, n);
	
	if r ~= "user_update_ok" then
		Test.Error({Account = n, Error = r});
		print("Failed to create account:", n, r);
	end

	local r = AccountServer.XMLRPC.ValidateEmail(n, t);

	if r ~= "user_validate_email_ok" then
		Test.Error({Account = n, Error = r});
		print("Failed to activate account:", n, r);
	end

	table.insert(n_accounts_file, a_names[i]);
end

function ActivityLogOverload_Burst(i)
	local n = a_names[i];

	if i % 100 == 0 then
		time_print("Bursting account "..i.." of "..n_accounts);
	end
	
	if use_existing_accounts or math.random() < dist_table[i] then
		AccountServer.XMLRPC.GiveProduct(n, p_n);
	end
end

-----Actual test starts here

--Create Test Product
local p_n = "PRD-TestMicrotrans";
local p_t = {
	name = p_n,
	keyValueChanges = "CrypticPoints += 0, PRD-TestMicrotrans += 1",
	dontAssociate = 1,
};
AccountServer.Web.CreateOrEditProduct(p_n, "StarTrek", p_t);

--Main loop
if use_existing_accounts then
	Test.Repeat(ActivityLogOverload_Burst, 1, n_accounts);
else
	Test.Repeat(ActivityLogOverload_CreateAccount, 1, n_accounts);

	local n_bursts = math.ceil(n_max_log_size / (6 * dist_table[n_accounts]));
	for i = 1, n_bursts do
		time_print("Burst "..i.." of "..n_bursts);
		Test.Repeat(ActivityLogOverload_Burst, 1, n_accounts);
	end
end


Test.Succeed();
