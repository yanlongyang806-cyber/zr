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

Batch.TestAlwaysRunMustSucceed("AccountServer/AccountServerSetup");
Batch.TestMustSucceed("AccountServer/AccountLoad");
Batch.TestMustSucceed("AccountServer/AccountKeyCreate");
Batch.TestMustSucceed("AccountServer/AccountKeyActivate");
Batch.TestAlwaysRun("AccountServer/AccountServerTeardown");
Batch.End();