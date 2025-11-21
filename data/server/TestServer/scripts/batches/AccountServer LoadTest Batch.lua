require("cryptic/AccountServer");
require("cryptic/Batch");
require("cryptic/Var");

AccountServer.DefaultX64(true);

-- MUST GENERATE AT LEAST AS MANY KEYS AS ACCOUNTS
Var.Default(nil, "AccountServer_NumAccounts", 1000000);
Var.Default(nil, "AccountServer_NumKeys", 1000000);

Batch.Begin();
--In order to specify who to e-mail the report to, use a line like this one:
--Batch.ReportTo("vsarpeshkar");
--But replace the two names with whatever you want, e.g. "QAPlatform"

--Setup
Batch.TestAlwaysRunMustSucceed("AccountServer/Setup/AccountServer Setup");

--Basic Load Tests
Batch.TestMustSucceed("AccountServer/Load/Accounts");
Batch.TestMustSucceed("AccountServer/Load/ActivityLog Buffer Test");

--Key Creation/Activation
Batch.TestMustSucceed("AccountServer/Load/KeyCreation");
Batch.TestMustSucceed("AccountServer/Load/KeyActivation");

--Cleanup
--Batch.TestAlwaysRun("AccountServer/Setup/AccountServer Teardown");
Batch.End();