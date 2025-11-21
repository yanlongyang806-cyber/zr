require("cryptic/Schedule");

Schedule.Begin();
Schedule.WeeklyRun("batches/AccountServer", "Thursday", "19:15");
Schedule.DailyRunImportant("batches/TicketTracker", "19:15:22");
Schedule.HourlyRun("batches/AccountServer", 16);
Schedule.End();