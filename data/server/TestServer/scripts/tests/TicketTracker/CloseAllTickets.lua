require("cryptic/Scope");
require("cryptic/Test");
require("cryptic/TicketTracker");

Test.Begin();

local batch_size = Scope.Var.Default("BatchSize", 500);
local cat = Scope.Var.Get("MainCategory");
Test.Require(cat, "Please fill the variable \"MainCategory\" with the name of the main category to hide.");
local subcat = Scope.Var.Get("Category");

local start_time = ts.get_time();
time_print("Getting number of affected tickets.");
count = TicketTracker.GetNumPrivateTickets(cat, subcat, 1, 0, 3);
Test.Require(count > 0, "No tickets to resolve!");
batches = math.ceil(count/batch_size);
time_print(("Marking %d tickets resolved. (%d batches of %d)"):format(count, batches, batch_size));

Test.RepeatSteps(1, batches, function(i)
	time_print(("Requesting batch %d (of %d)."):format(i, batches));
	local batch_start_time = ts.get_time();
	local sd = TicketTracker.GetTickets(cat, subcat, batch_size, (batches-i)*batch_size, 3);
	Test.Require(sd, ("Failed to get batch %d!"):format(i));

	time_print("    Requesting batch hide of affected tickets.");
	local list = TicketTracker.BatchListFromSearch(sd);
	sd = nil;
	Test.Require(TicketTracker.BatchResolve(list), "Failed to mark tickets resolved! This should be impossible!");

	list = nil;
	local batch_finish_time = ts.get_time();
	local batch_elapsed = batch_finish_time - batch_start_time;
	time_print(("    Batch %d resolve completed! (%0.2f s)"):format(i, batch_elapsed));

	collectgarbage("collect");
end);

local finish_time = ts.get_time();
local elapsed = finish_time - start_time;
time_print(("All tickets should now be marked resolved! (%0.2f s)"):format(elapsed));

Test.Succeed({["Tickets Resolved"] = count});
