require("cryptic/Var");

Report = { sub_counts = { } };

function Report.New(scope, name, ...)
	Report.Create(scope, name);
	Report.AddMultiple(scope, name, ...);
end

function Report.Create(scope, name)
	Var.Clear(scope, name);
end

function Report.Queue(scope, name)
	ts.queue_report(scope, name);
end

function Report.MakeSubReportName(scope, name)
	local sub_name = name;
	if scope then sub_name = scope.."::"..name end
	Report.sub_counts[sub_name] = (Report.sub_counts[sub_name] or 0) + 1;
	sub_name = sub_name.."_Sub_"..Report.sub_counts[sub_name];
	return sub_name;
end

function Report.Add(scope, name, data, pos)
	pos = pos or Var.Count(scope, name);

	if type(data) == "table" then
		if Var.IsRef(data) then
			Report.AddVar(scope, name, data, pos);
			return;
		end

		for k, v in pairs(data) do
			if type(v) == "table" then
				if Var.IsRef(v) then
					Report.AddVar(scope, name, v, pos);
				else
					local sub_name = Report.MakeSubReportName(scope, name);
					Report.AddVar(scope, name, Var.Ref(scope or name, sub_name), pos);
					Report.New(scope or name, sub_name, v);
				end

				if type(k) == "string" then
					Var.Label(scope, name, pos, k);
				end
			else
				Var.Insert(scope, name, pos, v);
				
				if type(k) == "string" then
					Var.Label(scope, name, pos, k);
				end
			end

			pos = pos + 1;
		end
	else
		Var.Insert(scope, name, pos, data);
	end
end

function Report.AddMultiple(scope, name, ...)
	for _, v in ipairs({...}) do
		Report.Add(scope, name, v);
	end
end

function Report.AddVar(scope, name, var, pos)
	Var.Insert(scope, name, pos or -1, var);
end

function Report.AddMultipleVars(scope, name, ...)
	for _, v in ipairs({...}) do
		Report.AddVar(scope, name, v);
	end
end

function Report.AddRecipient(recipient)
	Var.Push("Config", "ReportRecipients", recipient);
end

function Report.AddRecipients(...)
	for _, v in ipairs({...}) do
		Report.AddRecipient(v);
	end
end
