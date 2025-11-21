require("cryptic/AccountServer");
require("cryptic/Console");
require("cryptic/Console/Patch");
require("cryptic/Test");
require("cryptic/Var");

AccountServer.DefaultVersion(Console.Patch.GetLatestBuildForInfrastructureProject("AS"));

Test.Begin();
AccountServer.Kill();
AccountServer.KillKeyGenerating();
AccountServer.Patch();
AccountServer.LaunchAndWait();
Test.Succeed();