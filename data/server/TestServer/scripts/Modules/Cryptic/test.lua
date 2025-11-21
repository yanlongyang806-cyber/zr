require("cryptic/AccountServer");
require("cryptic/Report");
require("cryptic/Scope");
require("cryptic/Var");

Test = {
	cur_test_name = ts.get_script_name():match("([%w%s]+)%.?[^/]*$"),
	
	flag = "Success",
	start_time_var = "Start Time",
	duration = "Duration (s)",
	errors_var = "Errors",
	notes_var = "Notes",

	errors = { },
	notes = { },
	level = 0,
};

function Test.Begin()
	Scope.Set(Test.cur_test_name);

	Test.parent = Var.Clear(Test.cur_test_name, "_parent");
	Test.subtest = Var.Clear(Test.cur_test_name, "_child");
	Test.pre_var = Var.Clear(Test.cur_test_name, "_pre_var");

	Test.report = Test.cur_test_name.." Test Report";
	Test.scope = Test.parent or Test.report;
	Test.flag_var = Test.cur_test_name.." "..Test.flag;
	Test.duration_var = Test.cur_test_name.." "..Test.duration;

	Test.start_time = ts.get_time();
	time_print("Started test "..Test.cur_test_name..".");

	Report.Create(Test.parent, Test.report);
	Report.Add(Test.parent, Test.report, {[Test.flag] = Var.Ref(Test.scope, Test.flag_var)}, 0);
	Report.Add(Test.parent, Test.report, {[Test.start_time_var] = os.date("%a %m/%d/%Y %I:%M:%S %p")}, 1);

	if Test.pre_var and not Var.Eval(Test.parent, Test.pre_var) then
		Test.Fail("Failed prerequisite check.");
	end
	
	Var.Set(Test.scope, Test.flag_var, false);
end

function Test.Report(...)
	Report.AddMultiple(Test.parent, Test.report, ...);
end

function Test.ReportVars(...)
	Report.AddMultipleVars(Test.parent, Test.report, ...);
end

function Test.ReportTo(...)
	Report.AddRecipients(...);
end

function Test.End(success, ...)
	Test.end_time = ts.get_time();
	time_print("Ended test "..Test.cur_test_name..".");

	Var.Set(Test.scope, Test.flag_var, success);
	Var.Set(Test.scope, Test.duration_var, Test.end_time - Test.start_time);
	Report.Add(Test.parent, Test.report, {[Test.duration] = Var.Ref(Test.scope, Test.duration_var)}, 2);

	if #Test.errors > 0 then
		Report.Add(Test.parent, Test.report, {[Test.errors_var] = Test.errors});
	end

	if #Test.notes > 0 then
		Report.Add(Test.parent, Test.report, {[Test.notes_var] = Test.notes});
	end

	Report.AddMultiple(Test.parent, Test.report, ...);

	if not Test.subtest then
		Report.Queue(Test.parent, Test.report);
	end

	ts.done();
end

function Test.DoIf(exp, func, ...)
	if exp then
		func(...);
	end
end

function Test.DoUnless(exp, func, ...)
	if not exp then
		print(...);
		func(...);
	end
end

function Test.Succeed(...)
	Test.End(true, ...);
end

function Test.Fail(...)
	Test.End(false, ...);
end

function Test.FailIf(exp, ...)
	Test.DoIf(exp, Test.Fail, ...);
end

function Test.FailUnless(exp, ...)
	Test.DoUnless(exp, Test.Fail, ...);
end

function Test.Require(exp, ...)
	Test.FailUnless(exp, ...);
end

function Test.Verify(var1, var2, ...)
	print("Verifying:", var1, var2);
	Test.FailUnless((var1 == var2), "Got:", var1, "Expected:", var2, ...);
end

function Test.VerifyNote(var1, var2, ...)
	print("Verifying (Note if fail):", var1, var2);
	Test.NoteIf((var1 ~= var2), "Got:", var1, "Expected:", var2, ...);
end

function Test.Error(...)
	if Test.level > 0 then
		if #{...} > 1 then
			table.insert(Test.errors, {...});
		elseif #{...} == 1 then
			table.insert(Test.errors, ...);
		end

		error("Test.Error:"..Test.level);
	else
		Test.Fail(...);
	end
end

function Test.ErrorIf(exp, ...)
	Test.DoIf(exp, Test.Error, ...);
end

function Test.ErrorUnless(exp, ...)
	Test.DoUnless(exp, Test.Error, ...);
end

function Test.Note(...)
	if #{...} > 1 then
		table.insert(Test.notes, {...});
	elseif #{...} == 1 then
		table.insert(Test.notes, ...);
	end
end

function Test.NoteIf(exp, ...)
	Test.DoIf(exp, Test.Note, ...);
end

function Test.NoteUnless(exp, ...)
	Test.DoUnless(exp, Test.Note, ...);
end

function Test.DoSteps(funcs, index, v)
	for _, func in ipairs(funcs) do
		func(index, v);
	end
end

function Test.CallSubErrorHandler(err)
	if err:match("TS%.%w+$") then
		return err;
	elseif not err:match("Test%.Error:%d+") then
		print("RUNTIME ERROR: "..err);
		print(debug.traceback());
		print("    CURRENT MEM USAGE: "..collectgarbage("count"));
		Test.Note({"Lua error: "..err, debug.traceback()});
	end
end

function Test.CallSub(func, ...)
	local t = {...};

	Test.level = Test.level + 1;
	local res, err = xpcall(function() return func(unpack(t)) end, Test.CallSubErrorHandler);
	Test.level = Test.level - 1;

	if not res and err and err:match("^TS%.%w+$") then
		error(err);
	end
end

function Test.Repeat(func, start, finish, step)
	if not step then
		if start <= finish then
			step = 1;
		else
			step = -1;
		end
	end

	for i = start, finish, step do
		Test.CallSub(func, i);
	end
end

function Test.RepeatSteps(start, finish, step, ...)
	local funcs = {...};

	if type(step) == "function" then
		table.insert(funcs, 1, step);
		step = nil;
	end
	
	if not step then
		if start <= finish then
			step = 1;
		else
			step = -1;
		end
	end

	for i = start, finish, step do
		Test.CallSub(Test.DoSteps, funcs, i);
	end
end

function Test.RepeatArray(func, tbl)
	for i, v in ipairs(tbl) do
		Test.CallSub(func, i, v);
	end
end

function Test.RepeatStepsArray(tbl, ...)
	local funcs = {...};

	for i, v in ipairs(tbl) do
		Test.CallSub(Test.DoSteps, funcs, i, v);
	end
end

function Test.RepeatTable(func, tbl)
	for k, v in pairs(tbl) do
		Test.CallSub(func, k, v);
	end
end

function Test.RepeatStepsTable(tbl, ...)
	local funcs = {...};

	for k, v in pairs(tbl) do
		Test.CallSub(Test.DoSteps, funcs, k, v);
	end
end

function Test.Compare(var1, var2)
	if type(var1) ~= type(var2) then
		return nil;
	end

	if type(var1) ~= "table" then
		if var1 < var2 then
			return -1;
		elseif var1 > var2 then
			return 1;
		else
			return 0;
		end
	end

	local diff = { };

	for k, v in pairs(var1) do
		if Test.Compare(v, var2[k]) ~= 0 then
			table.insert(diff, k);
		end
	end

	for k, v in pairs(var2) do
		if Test.Compare(var1[k], v) ~= 0 then
			table.insert(diff, k);
		end
	end

	if #diff > 0 then
		return diff;
	else
		return 0;
	end
end

function Test.Equal(var1, var2)
	return Test.Compare(var1, var2) == 0;
end

function Test.NotEqual(var1, var2)
	return Test.Compare(var1, var2) ~= 0;
end

function Test.LessThan(var1, var2)
	return Test.Compare(var1, var2) == -1;
end

function Test.GreaterThan(var1, var2)
	return Test.Compare(var1, var2) == 1;
end

function Test.FailIfEqual(var1, var2, ...)
	Test.FailIf(Test.Equal(var1, var2), var1, var2, ...);
end

function Test.FailIfNotEqual(var1, var2, ...)
	Test.FailIf(Test.NotEqual(var1, var2), var1, var2, ...);
end

function Test.RequireEqual(var1, var2, ...)
	Test.FailIfNotEqual(var1, var2, ...);
end

function Test.RequireUnequal(var1, var2, ...)
	Test.FailIfEqual(var1, var2, ...);
end

function Test.ErrorIfEqual(var1, var2, ...)
	Test.ErrorIf(Test.Equal(var1, var2), var1, var2, ...);
end

function Test.ErrorIfNotEqual(var1, var2, ...)
	Test.ErrorIf(Test.NotEqual(var1, var2), var1, var2, ...);
end

function Test.NoteIfEqual(var1, var2, ...)
	Test.NoteIf(Test.Equal(var1, var2), var1, var2, ...);
end

function Test.NoteIfNotEqual(var1, var2, ...)
	Test.NoteIf(Test.NotEqual(var1, var2), var1, var2, ...);
end
