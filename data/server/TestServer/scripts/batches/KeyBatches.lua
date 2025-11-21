require("cryptic/AccountServer");
require("cryptic/Batch");
require("cryptic/Console/Patch");

AccountServer.DefaultVersion(Console.Patch.GetLatestBuildForInfrastructureProject("AS"));
AccountServer.SetX64(true);

Batch.Begin();
--In order to specify who to e-mail the report to, use a line like this one:
--Batch.ReportTo("vsarpeshkar", "lfalls");
--But replace the two names with whatever you want, e.g. "QAPlatform"

--Batch.ReportTo("lfalls"); --Not working atm

Batch.TestMustSucceed("AccountServer/KeyBatchTest");
Batch.End();