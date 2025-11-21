require("cryptic/Test");
require("cryptic/TicketTracker");

local tickets = Var.Get(nil, "TicketTracker_NumTickets");
Metric.Clear(nil, "TicketTrackerLoad_Created");
local categories = {
	"GameSupport.Character",
	"GameSupport.Items",
	"GameSupport.Powers",
	"GameSupport.Missions",
	"GameSupport.UI",
	"GameSupport.Graphics",
	"GameSupport.Audio",
	"GameSupport.Misc"
};

function TicketTrackerLoad_CreateTicket(i)
	local n = "TestAccount_"..string.format("%07d", math.random(0, tickets - 1));
	local t_0 = ts.get_time();
	local r, t = TicketTracker.CreateTicket({
		priv_n = n,
		disp_n = n,
		category = categories[math.random(#categories)],
		summary = "Test Ticket "..i,
		desc = "Description for test ticket "..i..".",
	});
	local t_1 = ts.get_time();

	Test.ErrorUnless(r, t);
	Metric.Push(nil, "TicketTrackerLoad_Created", t_1 - t_0);
end

Test.Begin();
Test.Repeat(TicketTrackerLoad_CreateTicket, 1, tickets);

-- Verify number of tickets
local num = TicketTracker.GetNumTickets();
Test.RequireEqual(TicketTracker.GetNumTickets(), tickets, "Not all tickets were created.");

-- Restart Ticket Tracker and re-verify
TicketTracker.Kill();
TicketTracker.LaunchAndWait();
Test.Require(TicketTracker.GetNumTickets(), tickets, "Not all tickets were loaded after restart.");

-- Success; output results
local creation_time = Metric.Average(nil, "TicketTrackerLoad_Created");
Test.Succeed({
	["Average Creation Time"] = creation_time,
	["Created Per Second"] = 1 / creation_time,
});
