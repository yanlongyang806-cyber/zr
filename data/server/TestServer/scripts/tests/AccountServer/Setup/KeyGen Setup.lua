require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer");
require("cryptic/Test");

Test.Begin();
AccountServer.KillKeyGenerating()
Test.Require(AccountServer.LaunchKeyGeneratingAndWait(), "Could not launch key generating Account Server.");
Test.Succeed();
