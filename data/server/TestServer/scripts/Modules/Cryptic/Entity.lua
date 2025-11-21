Entity = { };

function Entity.Parse(id)
	local t = { };
	Entity.WalkStruct(id, "", t);
	return t;
end

function Entity.WalkStruct(id, path, t)
	for _, m in ipairs(ts.entity_xmembers(id, path)) do
		local new_path = path.."."..m;
		local type = ts.entity_xtype(id, new_path);

		if type == ts.XPATH_NUMBER or type == ts.XPATH_STRING then
			t[m] = ts.entity_xvalue(id, new_path);
		elseif type == ts.XPATH_ARRAY then
			t[m] = { };
			Entity.WalkArray(id, new_path, t[m]);
		elseif type == ts.XPATH_STRUCT then
			t[m] = { };
			Entity.WalkStruct(id, new_path, t[m]);
		end
	end
end

function Entity.WalkArray(id, path, t)
	for _, k in ipairs(ts.entity_xindices(id, path)) do
		local new_path = path.."["..k.."]";
		local type = ts.entity_xtype(id, new_path);

		if type == ts.XPATH_NUMBER or type == ts.XPATH_STRING then
			t[k] = ts.entity_xvalue(id, new_path);
		elseif array_type == ts.XPATH_ARRAY then
			t[k] = { };
			Entity.WalkArray(id, new_path, t[k]);
		elseif type == ts.XPATH_STRUCT then
			t[k] = { };
			Entity.WalkStruct(id, new_path, t[k]);
		end
	end
end