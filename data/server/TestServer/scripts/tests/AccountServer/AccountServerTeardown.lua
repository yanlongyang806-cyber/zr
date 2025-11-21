require("cryptic/AccountServer");
require("cryptic/Test");

Test.Begin();
AccountServer.Kill();
AccountServer.KillKeyGenerating();
Test.Succeed();