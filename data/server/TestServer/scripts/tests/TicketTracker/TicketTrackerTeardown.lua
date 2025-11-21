require("cryptic/Test");
require("cryptic/TicketTracker");

Test.Begin();
TicketTracker.Kill();
Test.Succeed();