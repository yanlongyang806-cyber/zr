require("cryptic/Metric");
require("cryptic/Var");

Scope = {
	cur_scope = nil,
};

function Scope.Set(scope)
	Scope.cur_scope = scope;
end

Scope.Var = {};
m = {
	__index = function(t, k)
		if type(Var[k]) == "function" then
			return function(...) return Var[k](Scope.cur_scope, ...); end;
		end
	end,
};
setmetatable(Scope.Var, m);

Scope.Metric = {};
m = {
	__index = function(t, k)
		if type(Metric[k]) == "function" then
			return function(...) return Metric[k](Scope.cur_scope, ...); end;
		end
	end,
};
setmetatable(Scope.Metric, m);
