require("cryptic/AccountServer.Test");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Console");
require("cryptic/Scope");
require("cryptic/Test");

Test.Begin();
AccountServer.Test.FailOnLoginFailure();

local l_fn = Scope.Var.Get("List");
Test.Require(l_fn, "Please set \"TakeProduct::List\" to the filepath of the fixup file.");

local prod = Scope.Var.Get("Product");
Test.Require(prod, "Please set \"TakeProduct::Product\" to the product name to remove.");

local accts = Console.ReadListFile(l_fn);
Test.Require(accts, "Couldn't read fixup file!");

function TakeProduct(i, acct)
	local r, t = AccountServer.XMLRPC.TakeProduct(acct, prod);

	if not r then
		Test.Note(("Failed to take product %s from account %s"):format(prod, acct));
	elseif t["Result"] ~= "product_taken" then
		Test.Note(("Failed to take product %s from account %s because: %s"):format(prod, acct, t["Result"]));
	end
end

Test.RepeatArray(TakeProduct, accts);
Test.Succeed();
