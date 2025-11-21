Var = { };

function Var.AtomicBegin()
	ts.var_atomic_begin();
end

function Var.AtomicEnd()
	ts.var_atomic_end();
end

function Var.Eval(scope, var)
	return Var.Get(scope, var, 0);
end

function Var.Get(scope, var, pos)
	return ts.var_get(scope, var, pos or 0);
end

function Var.Type(scope, var, pos)
	return ts.var_get_type(scope, var, pos or 0);
end

function Var.Count(scope, var)
	return ts.var_get_count(scope, var);
end

function Var.Set(scope, var, val, var_type)
	ts.var_set(scope, var, -1, val, var_type);
	return val;
end

function Var.Default(scope, var, val, var_type)
	local cur = Var.Get(scope, var);

	if not cur then
		Var.Set(scope, var, val, var_type);
		return val;
	end

	return cur;
end

function Var.SetIndex(scope, var, pos, val, var_type)
	ts.var_set(scope, var, pos, val, var_type);
	return val;
end

function Var.DefaultIndex(scope, var, pos, val, var_type)
	local cur = Var.Get(scope, var, pos);

	if not cur then
		Var.SetIndex(scope, var, pos, val, var_type);
		return val;
	end

	return cur;
end

function Var.Push(scope, var, val, var_type)
	ts.var_insert(scope, var, -1, val, var_type);
	return val;
end

function Var.Insert(scope, var, pos, val, var_type)
	ts.var_insert(scope, var, pos, val, var_type);
	return val;
end

function Var.Label(scope, var, pos, label)
	ts.var_set_label(scope, var, pos, tostring(label));
end

function Var.Persist(scope, var, persist)
	ts.var_persist(scope, var, persist);
end

function Var.Clear(scope, var)
	local val = ts.var_get(scope, var, 0);
	ts.var_clear(scope, var, -1);
	return val;
end

function Var.ClearIndex(scope, var, pos)
	local val = ts.var_get(scope, var, pos);
	ts.var_clear(scope, var, pos);
	return val;
end

function Var.Ref(scope, name)
	return {__isvarref = true, scope = scope, name = name};
end

function Var.IsRef(ref)
	return ref.__isvarref;
end

function Var.ExpAdd(scope, var, ...)
	for _, v in ipairs({...}) do
		Var.Push(scope, var, v);
	end
end

function Var.MakeExp(func, scope, var, ...)
	func(scope, var);
	Var.ExpAdd(scope, var, ...);
end

function Var.Add(scope, var, ...)
	Var.MakeExp(ts.set_exp_add, scope, var, ...);
end

function Var.Subtract(scope, var, ...)
	Var.MakeExp(ts.set_exp_sub, scope, var, ...);
end

function Var.Multiply(scope, var, ...)
	Var.MakeExp(ts.set_exp_mul, scope, var, ...);
end

function Var.Divide(scope, var, ...)
	Var.MakeExp(ts.set_exp_div, scope, var, ...);
end

function Var.And(scope, var, ...)
	Var.MakeExp(ts.set_exp_and, scope, var, ...);
end

function Var.Or(scope, var, ...)
	Var.MakeExp(ts.set_exp_or, scope, var, ...);
end

function Var.Not(scope, var, val)
	Var.MakeExp(ts.set_exp_not, scope, var, val);
end