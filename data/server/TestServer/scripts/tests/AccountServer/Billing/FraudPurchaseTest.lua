require("cryptic/AccountServer");
require("cryptic/AccountServer.Web.Legacy");
require("cryptic/AccountServer/XMLRPC");
require("cryptic/Test");
require("cryptic/Var");

Test.Begin();
local i = 1
while i <= 10000 do
	print("--Attempt "..i.."out of 10000")
	print(AccountServer.XMLRPC.Purchase("RetailLoadPurchase2", nil, "127"));
	i = i+1;
end
Test.Succeed();