require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

Test.Require(Var.Get(nil, "SetKeyValue_accountname"), "Please set the global variable "
	.. "\"SetKeyValue_accountname\" to an account name.");

local account_name = Var.Get(nil, "SetKeyValue_accountname");
local key = Var.Default(nil, "SetKeyValue_key", "PaidCrypticPoints");
local value = Var.Default(nil, "SetKeyValue_value", "100");
local increment = Var.Default(nil, "SetKeyValue_increment", 1);
local reason = Var.Default(nil, "SetKeyValue_reason", "Testing");
local transaction_type = Var.Default(nil, "SetKeyValue_transactiontype", "Stipend");

-- #############################
-- Valid Transaction Type
--   CashPurchase
--   MicroPurchase
--   Stipend
--   Exchange
--   CustomerService
--   Other
-- #############################

-- #############################
-- MAIN SCRIPT
-- #############################

-- Test login to AS
AccountServer.Test.FailOnLoginFailure();

print("This test will run with the following parameters.");
print("Account Name:\t", account_name);
print("Key:\t\t", key);
print("Value:\t\t", value);
print("Increment:\t", increment);
print("Reason:\t\t", reason);
print("Transaction Type:", transaction_type);

local kevValueResult = AccountServer.XMLRPC.SetKeyValueEX(account_name, key, value, increment, reason, transaction_type);

print("\n\n#############################\n\n");

if (kevValueResult == "key_set") then
	print("SetKeyValueEx() was successful");
else
	print("SetKeyValueEx() failed");
end;

print("\n\n#############################\n\n");

Test.Succeed();


