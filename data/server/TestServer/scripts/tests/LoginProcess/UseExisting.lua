require("cryptic/Console");
require("cryptic/Metric");
require("cryptic/Test");
require("cryptic/Var");

local logins = Var.Get(nil, "LoginProcess_LoginExisting");
local persec = Var.Get(nil, "LoginProcess_LoginsPerSec");
local prod = Var.Get("Config", "ProductName").." "..Var.Get("Config", "ShortProductName");
local ms = math.floor(1000 / persec);

Test.Begin();
local t_0 = ts.get_time();
Console.RunAppAndWait("C:/src/Utilities/bin/LoginHammer.exe",
	"-SetProductName "..prod.." -AccountHammer -LoginHammer "..
	"-SetTestServer localhost -SetConnections "..logins..
	" -SetDelay "..ms.." -SetGameServer nomap");
local t_1 = ts.get_time();

local succ = Metric.Count(nil, "LoginHammer_LoginMaps");
Test.Require(succ == logins, "Did not successfully create all characters!");

local login_freq = logins / (t_1 - t_0);
local account_wait = Metric.Average(nil, "LoginHammer_AccountWait");
local login_wait = Metric.Average(nil, "LoginHammer_LoginWait");
local total_wait = account_wait + login_wait;
Test.Succeed({
	["Logins Per Second"] = login_freq,
	["Average Total Time To Login"] = total_wait,
});
