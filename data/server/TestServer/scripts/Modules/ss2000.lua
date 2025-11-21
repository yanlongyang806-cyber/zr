require("os");

_G["__SS2000date"] = _G["__SS2000date"] or {
	month = 1,
	day = 1,
	year = 2000,
	hour = 0,
	min = 0,
	sec = 0,
};

function ToSS2000(date_t)
	return os.difftime(os.time(date_t), os.time(_G["__SS2000date"]));
end

function FromSS2000(timess2000)
	local t = _G["__SS2000date"];
	t.sec = timess2000;
	return os.date("*t", os.time(t));
end

function TimestampFromSS2000(timess2000)
	local t = _G["__SS2000date"];
	t.sec = timess2000;
	return os.date("%c", os.time(t));
end

function SQLTimestampFromSS2000(timess2000, override)
	if timess2000 == 0 and not override then
		return "";
	end

	local t = _G["__SS2000date"];
	t.sec = timess2000;
	return os.date("%Y-%m-%d %H:%M:%S", os.time(t));
end

function DatestampFromSS2000(timess2000)
	local t = _G["__SS2000date"];
	t.sec = timess2000;
	return os.date("%m/%d/%Y", os.time(t));
end

function ToSS2000FromDatestamp(date)
	local date_t = {};

	if type(date) == "number" then
		return nil;
	end
	
	date_t.month, date_t.day, date_t.year = date:match("(%d+)/(%d+)/(%d+)");

	if not date_t.month then
		return nil;
	end

	return ToSS2000(date_t);
end

function ToSS2000FromTimestamp(time)
	local date_t = {};

	if type(time) == "number" then
		return nil;
	end

	date_t.month, date_t.day, date_t.year, date_t.hour, date_t.min, date_t.sec = time:match("(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)");

	if not date_t.month then
		return nil;
	end

	return ToSS2000(date_t);
end

function ToSS2000FromSQLTimestamp(time)
	local date_t = {};

	date_t.year, date_t.month, date_t.day, date_t.hour, date_t.min, date_t.sec = time:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)");
	
	if not date_t.year then
		return nil;
	end

	return ToSS2000(date_t);
end

function ToSS2000FromNow()
	return os.difftime(os.time(), os.time(_G["__SS2000date"]));
end
