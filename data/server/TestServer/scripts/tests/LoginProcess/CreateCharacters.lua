require("cryptic/Console");
require("cryptic/Metric");
require("cryptic/Test");
require("cryptic/Var");

local chars = Var.Get(nil, "LoginProcess_CreateCharacters");
local persec = Var.Get(nil, "LoginProcess_CreatesPerSec");
local prod = Var.Get("Config", "ProductName").." "..Var.Get("Config", "ShortProductName");
local ms = math.floor(1000 / persec);

Test.Begin();
local t_0 = ts.get_time();
Console.RunAppAndWait("C:/src/Utilities/bin/LoginHammer.exe",
	"-SetProductName "..prod.." -AccountHammer -LoginHammer "..
	"-SetTestServer localhost -CreationFrequency 1.0 -SetConnections "..
	chars.." -SetDelay "..ms.." -SetGameServer nomap");
local t_1 = ts.get_time();

local succ = Metric.Count(nil, "LoginHammer_LoginMaps");
Test.Require(succ == chars, "Did not successfully create all characters!");

local creation_freq = chars / (t_1 - t_0);
local account_wait = Metric.Average(nil, "LoginHammer_AccountWait");
local login_wait = Metric.Average(nil, "LoginHammer_LoginWait");
local total_wait = account_wait + login_wait;
Test.Succeed({
	["Created Per Second"] = creation_freq,
	["Average Total Time To Login"] = total_wait,
});
