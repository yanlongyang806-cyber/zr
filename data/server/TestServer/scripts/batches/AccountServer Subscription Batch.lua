require("cryptic/AccountServer");
require("cryptic/Batch");
require("cryptic/Console/Patch");

Batch.Begin();
--In order to specify who to e-mail the report to, use a line like this one:
--Batch.ReportTo("vsarpeshkar", "lfalls");
--But replace the two names with whatever you want, e.g. "QAPlatform"

--Batch.ReportTo("lfalls"); --Not working atm

Batch.Test("AccountServer/Billing/AccountRegistration");
Batch.Test("AccountServer/Billing/SubscriptionChanges1");
Batch.Test("AccountServer/Billing/SubscriptionChanges2");
Batch.Test("AccountServer/Billing/SubscriptionLifetime");

--Batch.Test("AccountServer/SmokeTest/Recruitment");

Batch.End();