Metric = { };

function Metric.Push(scope, var, val)
	return ts.push_metric(scope, var, val);
end

function Metric.Clear(scope, var)
	ts.clear_metric(scope, var);
end

function Metric.Average(scope, var)
	return ts.get_metric_average(scope, var);
end

function Metric.Count(scope, var)
	return ts.get_metric_count(scope, var);
end

function Metric.Minimum(scope, var)
	return ts.get_metric_minimum(scope, var);
end

function Metric.Maximum(scope, var)
	return ts.get_metric_maximum(scope, var);
end

function Metric.Total(scope, var)
	return ts.get_metric_total(scope, var);
end