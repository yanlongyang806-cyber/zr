Schedule = {
	days = {
		["Sunday"] = 0,
		["sunday"] = 0,
		["Sun"] = 0,
		["sun"] = 0,

		["Monday"] = 1,
		["monday"] = 1,
		["Mon"] = 1,
		["mon"] = 1,

		["Tuesday"] = 2,
		["tuesday"] = 2,
		["Tues"] = 2,
		["tues"] = 2,
		["Tue"] = 2,
		["tue"] = 2,

		["Wednesday"] = 3,
		["wednesday"] = 3,
		["Wed"] = 3,
		["wed"] = 3,

		["Thursday"] = 4,
		["thursday"] = 4,
		["Thurs"] = 4,
		["thurs"] = 4,
		["Thu"] = 4,
		["thu"] = 4,

		["Friday"] = 5,
		["friday"] = 5,
		["Fri"] = 5,
		["fri"] = 5,

		["Saturday"] = 6,
		["saturday"] = 6,
		["Sat"] = 6,
		["sat"] = 6,
	},

	revdays = {
		[1] = "Sunday",
		[2] = "Monday",
		[3] = "Tuesday",
		[4] = "Wednesday",
		[5] = "Thursday",
		[6] = "Friday",
		[7] = "Saturday",
	},
};

function Schedule.Begin()
	ts.clear_schedules();
end

function Schedule.End()
	ts.done();
end

function Schedule.Add(script, day, time, int, rep, imp)
	local day_num = Schedule.days[day];

	if not day_num then
		print("No day \""..day.."\" exists for script "..script.."!");
		return;
	end

	local hr, min, sec = Schedule.GetTimeFromString(time);

	ts.schedule_script(script, day_num, hr, min, sec, int, rep, imp);
end

function Schedule.GetTimeFromString(time)
	if type(time) ~= "string" then
		return time, 0, 0;
	end

	local hr = tonumber(time:match("^(%d+):?.*$"));
	local min = tonumber(time:match("^%d+:(%d+):?.*$")) or 0;
	local sec = tonumber(time:match("^%d+:%d+:(%d+)$")) or 0;

	return hr, min, sec;
end

function Schedule.WeeklyRun(script, day, time)
	Schedule.Add(script, day, time, 0, 0, false);
end

function Schedule.WeeklyRunImportant(script, day, time)
	Schedule.Add(script, day, time, 0, 0, true);
end

function Schedule.WeeklyRunLimited(script, day, time, num)
	Schedule.Add(script, day, time, 0, num, false);
end

function Schedule.WeeklyRunImportantLimited(script, day, time, num)
	Schedule.Add(script, day, time, 0, num, true);
end

function Schedule.DailyRunHelper(script, time, num, imp)
	local today = Schedule.revdays[os.date("*t").wday];
	Schedule.Add(script, today, time, 86400, num, imp);
end

function Schedule.DailyRun(script, time)
	Schedule.DailyRunHelper(script, time, 0, false);
end

function Schedule.DailyRunImportant(script, time)
	Schedule.DailyRunHelper(script, time, 0, true);
end

function Schedule.DailyRunLimited(script, time, num)
	Schedule.DailyRunHelper(script, time, num, false);
end

function Schedule.DailyRunImportantLimited(script, time, num)
	Schedule.DailyRunHelper(script, time, num, true);
end

function Schedule.HourlyRunHelper(script, min, num, imp)
	local now = os.date("*t");
	local today = Schedule.revdays[now.wday];
	local hour = now.hour;

	if type(min) == "string" then
		min = tonumber(min);
	end

	if min <= now.min then
		hour = hour + 1;
	end

	Schedule.Add(script, today, hour..":"..min, 3600, num, imp);
end

function Schedule.HourlyRun(script, min)
	Schedule.HourlyRunHelper(script, min, 0, false);
end

function Schedule.HourlyRunImportant(script, min)
	Schedule.HourlyRunHelper(script, min, 0, true);
end

function Schedule.HourlyRunLimited(script, min, num)
	Schedule.HourlyRunHelper(script, min, num, false);
end

function Schedule.HourlyRunImportantLimited(script, min, num)
	Schedule.HourlyRunHelper(script, min, num, true);
end
