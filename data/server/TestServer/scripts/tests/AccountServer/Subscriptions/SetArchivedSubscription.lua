require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Console");
require("cryptic/Var");

Test.Begin();

--Test login to AS
AccountServer.Test.FailOnLoginFailure();

--Require a CSV name
Test.Require(Var.Get(nil, "Test_Account"),
	"Please set the global variable \"Test_Account\" to the Account you want a subscription for!");
Test.Require(Var.Get(nil, "Test_InternalProduct"),
	"Please set the global variable \"Test_InternalProduct\" to the Internal Product name you want a subscription for!");
Test.Require(Var.Get(nil, "Test_SubFrom"),
	"Please set the global variable \"Test_SubFrom\" to the date (dd/mm/yyyy) you want a subscription to start on");
Test.Require(Var.Get(nil, "Test_SubTo"),
	"Please set the global variable \"Test_SubTo\" to the date (dd/mm/yyyy) you want a subscription to end on!");

local Account = Var.Get(nil, "Test_Account");
local From = Var.Get(nil, "Test_SubFrom");
local To = Var.Get(nil, "Test_SubTo");
local Internal = Var.Get(nil, "Test_InternalProduct")

print(AccountServer.XMLRPC.ArchiveSubHistory(Account, From, To,	Internal));

Test.Succeed();
