require("cryptic/Batch");
require("cryptic/TicketTracker");
require("cryptic/Var");

TicketTracker.DefaultX64(true);

Var.Default(nil, "TicketTracker_NumTickets", 1000);

Batch.Begin();
Batch.TestMustSucceed("TicketTracker/TicketTrackerSetup");
Batch.TestMustSucceed("TicketTracker/TicketTrackerLoad");
Batch.TestAlwaysRun("TicketTracker/TicketTrackerTeardown");
Batch.End();