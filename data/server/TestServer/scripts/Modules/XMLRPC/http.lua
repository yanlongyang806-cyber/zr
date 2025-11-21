---------------------------------------------------------------------
-- XML-RPC over HTTP.
-- See Copyright Notice in license.html
-- $Id: http.lua,v 1.2 2004/09/27 16:39:37 tomas Exp $
---------------------------------------------------------------------

require("socket.http");
require("xmlrpc");
require("ltn12");

xmlrpc.http = {};

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param method String with the name of the method to be called.
-- @return Table with the response (could be a `fault' or a `params'
--	XML-RPC element).
---------------------------------------------------------------------
function xmlrpc.http.call(url, method, ...)
	source = xmlrpc.clEncode(method, unpack({...}));
	sink, result = ltn12.sink.table();

	local _, code, headers, err = socket.http.request({
		url = url,
		source = ltn12.source.string(source),
		sink = sink,
		method = "POST",
		headers = {
			["User-Agent"] = "LuaXMLRPC",
			["Content-Type"] = "text/xml",
			["Content-Length"] = string.len(source),
		},
	});
	if tonumber(code) == 200 then
		return xmlrpc.clDecode(result);
	else
		return false, err or code;
	end
end

function xmlrpc.http.authcall(url, user, pass, method, ...)
	source = xmlrpc.clEncode(method, unpack({...}));
	sink, result = ltn12.sink.table();

	local _, code, headers, err = socket.http.request({
		url = url,
		source = ltn12.source.string(source),
		sink = sink,
		method = "POST",
		headers = {
			["User-Agent"] = "LuaXMLRPC",
			["Content-Type"] = "text/xml",
			["Content-Length"] = string.len(source),
		},
		user = user,
		password = pass,
	});
	if tonumber(code) == 200 then
		return xmlrpc.clDecode(result);
	else
		return false, err or code;
	end
end