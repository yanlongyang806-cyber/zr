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
count = TicketTracker.GetNumPrivateTickets(cat, subcat,1,0);
Test.Require(count > 0, "No tickets to hide!");
batches = math.ceil(count/batch_size);
time_print(("Hiding %d tickets. (%d batches of %d)"):format(count, batches, batch_size));

Test.RepeatSteps(1, batches, function(i)
	time_print(("Requesting batch %d (of %d)."):format(i, batches));
	local batch_start_time = ts.get_time();
	local sd = TicketTracker.GetTickets(cat, subcat, batch_size, (batches-i)*batch_size);
	Test.Require(sd, ("Failed to get batch %d!"):format(i));

	time_print("    Requesting batch hide of affected tickets.");
	local list = TicketTracker.BatchListFromSearch(sd);
	sd = nil;
	Test.Require(TicketTracker.BatchHide(list), "Failed to hide tickets! This should be impossible!");

	list = nil;
	local batch_finish_time = ts.get_time();
	local batch_elapsed = batch_finish_time - batch_start_time;
	time_print(("    Batch %d hide complete! (%0.2f s)"):format(i, batch_elapsed));

	collectgarbage("collect");
end);

local finish_time = ts.get_time();
local elapsed = finish_time - start_time;
time_print(("All hides complete! (%0.2f s)"):format(elapsed));

Test.Succeed({["Tickets Hidden"] = count});
