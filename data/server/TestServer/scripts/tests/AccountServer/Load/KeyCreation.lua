require("cryptic/AccountServer.Web.Legacy");
require("cryptic/Console");
require("cryptic/Test");
require("cryptic/Var");

local keys = Var.Get(nil, "AccountServer_NumKeys");

Test.Begin();
Test.Require(AccountServer.Web.CreateOrEditProduct("TestProduct", "FightClub", {shards = "all", alvl = 9}), "Could not create test product.");
Test.Require(AccountServer.Web.CreateKeyGroup("TESTP", "TestProduct"), "Could not create key group.");
Test.Require(AccountServer.LaunchKeyGeneratingAndWait(), "Could not launch key generating Account Server.");

-- Generate keys
local t_0 = ts.get_time();
local generated = AccountServer.Web.KeyCreateBatch("TestBatch", "TestProduct", "TESTP", keys);
local t_1 = ts.get_time();
Test.Require(generated, "Could not generate test key batch.");
Test.RequireEqual(generated, keys, "Generated fewer keys than expected.");
AccountServer.KillKeyGenerating();

-- Verify key count
local num = AccountServer.GetNumKeysByBatch("TestBatch");
Test.RequireEqual(num, keys, "Found fewer keys than expected.");

-- Restart Account Server and verify key count
AccountServer.Kill();
AccountServer.LaunchAndWait();
local num = AccountServer.GetNumKeysByBatch("TestBatch");
Test.RequireEqual(num, keys, "Found fewer keys than expected after restart.");

Test.Succeed({
	["Created Per Second"] = keys / (t_1 - t_0)
});
