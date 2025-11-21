require("cryptic/Report");
require("cryptic/Var");

Batch = {
	cur_batch_name = ts.get_script_name():match("([%w%s]+)%.?[^/]*$"),

	flag = "Success",
	start_time = "Start Time",
	duration = "Duration (s)",

	test_queue = { },
};

function Batch.Begin()
	Batch.parent = Var.Clear(Batch.cur_batch_name, "_parent");
	Batch.subbatch = Var.Clear(Batch.cur_batch_name, "_child");
	Batch.pre_var = Var.Clear(Batch.cur_batch_name, "_pre_var");

	Batch.report = Batch.cur_batch_name.." Batch Report";
	Batch.scope = Batch.parent or Batch.report;
	Batch.flag_var = Batch.cur_batch_name.." "..Batch.flag;
	Batch.duration_var = Batch.cur_batch_name.." "..Batch.duration;

	Report.Create(Batch.parent, Batch.report);
	Var.And(Batch.scope, Batch.flag_var);
	Report.Add(Batch.parent, Batch.report, {[Batch.flag] = Var.Ref(Batch.scope, Batch.flag_var)}, 0);
	Report.Add(Batch.parent, Batch.report, {[Batch.start_time] = os.date("%a %m/%d/%Y %I:%M:%S %p")}, 1);
	Var.Add(Batch.scope, Batch.duration_var);
	Report.Add(Batch.parent, Batch.report, {[Batch.duration] = Var.Ref(Batch.scope, Batch.duration_var)}, 2);

	if Batch.pre_var and not Var.Eval(Batch.parent, Batch.pre_var) then
		Var.Set(Batch.scope, Batch.flag_var, false);
		Var.Set(Batch.scope, Batch.duration_var, 0.0);
		Report.Add(Batch.parent, Batch.report, "Failed prerequisite check.");
		ts.done();
	end
	
	Var.Push(Batch.scope, Batch.flag_var, true);
end

function Batch.Queue(name, always, batch, succeed)
	local subname = name:match("^.-/?([%w%s]+)$");
	local script = name;
	local flag = subname.." Success";
	local duration = subname.." Duration (s)";
	local result = subname;

	if batch then
		script = "batches/"..script;
		result = result.." Batch Report";
	else
		script = "tests/"..script;
		result = result.." Test Report";
	end

	Var.Set(subname, "_child", true);
	Var.Set(subname, "_parent", Batch.scope);

	if not always then
		Var.Set(subname, "_pre_var", Batch.flag_var);
	end

	table.insert(Batch.test_queue, script);
	
	if succeed then
		Var.Push(Batch.scope, Batch.flag_var, Var.Ref(Batch.scope, flag));
	end

	Var.Push(Batch.scope, Batch.duration_var, Var.Ref(Batch.scope, duration));
	Var.Clear(Batch.scope, result);
	Report.AddVar(Batch.parent, Batch.report, Var.Ref(Batch.scope, result));
	Var.Label(Batch.parent, Batch.report, -1, result);
end

function Batch.Report(...)
	Report.AddMultiple(Batch.parent, Batch.report, ...);
end

function Batch.ReportVars(...)
	Report.AddMultipleVars(Batch.parent, Batch.report, ...);
end

function Batch.ReportTo(...)
	Report.AddRecipients(...);
end

function Batch.QueueTests()
	for i = #Batch.test_queue, 1, -1 do
		ts.queue_script_now(Batch.test_queue[i]);
	end
	
	if not Batch.subbatch then
		Report.Queue(Batch.parent, Batch.report);
	end
end

function Batch.Test(name)
	Batch.Queue(name, false, false, false);
end

function Batch.TestMustSucceed(name)
	Batch.Queue(name, false, false, true);
end

function Batch.TestAlwaysRun(name)
	Batch.Queue(name, true, false, false);
end

function Batch.TestAlwaysRunMustSucceed(name)
	Batch.Queue(name, true, false, true);
end

function Batch.SubBatch(name)
	Batch.Queue(name, false, true, false);
end

function Batch.SubBatchMustSucceed(name)
	Batch.Queue(name, false, true, true);
end

function Batch.SubBatchAlwaysRun(name)
	Batch.Queue(name, true, true, false);
end

function Batch.SubBatchAlwaysRunMustSucceed(name)
	Batch.Queue(name, true, true, true);
end

function Batch.End()
	Batch.QueueTests();
	Batch.cur_batch_name = nil;
	ts.done();
end
