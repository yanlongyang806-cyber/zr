require("cryptic/AccountServer");
require("cryptic/Console");
require("cryptic/Http");
require("socket.url");

AccountServer.Web = {};

local mt = { __index = function(t, k)
	if rawget(t, k) then
		return rawget(t, k);
	end

	if rawget(t, "Core") and rawget(t, "Core")[k] then
		return rawget(t, "Core")[k];
	elseif rawget(t, "Legacy") and rawget(t, "Legacy")[k] then
		return rawget(t, "Legacy")[k];
	else
		return nil;
	end
end };

setmetatable(AccountServer.Web, mt);

function AccountServer.Web.HomeURL(legacy)
	if AccountServer.Web.new_interface == nil then
		AccountServer.Web.CheckInterface();
	end

	if legacy and AccountServer.Web.new_interface then
		return "http://"..AccountServer.loc.."/legacy/";
	else
		return "http://"..AccountServer.loc.."/";
	end
end

function AccountServer.Web.CheckInterface()
	local r, _, _, _ = Http.Request("http://"..AccountServer.loc.."/legacy/", nil, AccountServer.port, AccountServer.user, AccountServer.password);

	if r:match("Access denied") then
		AccountServer.Web.new_interface = false;
	else
		AccountServer.Web.new_interface = true;
	end
end

function AccountServer.Web.GetKeyList(prefix)	
	AccountServer.Web.DumpKeyList(AccountServer.dir.."/keylist.txt", prefix);
	return Console.ReadListFile(AccountServer.dir.."/keylist.txt");
end

function AccountServer.Web.DumpKeyList(loc, prefix)
	local req = "http://"..AccountServer.loc.."/directcommand?"..Http.CreateFormRequest({command = "dumpUnusedProductKeys \""..prefix.."\" \""..loc.."\""});
	Http.Request(req, nil, 8081, AccountServer.user, AccountServer.password);
end
