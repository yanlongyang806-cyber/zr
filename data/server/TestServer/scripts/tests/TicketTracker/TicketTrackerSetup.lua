require("cryptic/Console");
require("cryptic/Test");
require("cryptic/TicketTracker");

Test.Begin();
TicketTracker.Kill();
TicketTracker.CleanDB();
TicketTracker.Patch();
TicketTracker.LaunchAndWait();
Test.Succeed();