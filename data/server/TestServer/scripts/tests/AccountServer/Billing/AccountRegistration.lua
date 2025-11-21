require("cryptic/AccountServer");
require("cryptic/AccountServer.XMLRPC");
require("cryptic/Test");
require("cryptic/Var");

Var.Set(nil, "Test_IP", "RANDOM");

local TimeStamp		= string.gsub(os.date(), "[%s%p]", "_");
local Name		= nil;
local EmailSuffix	= "@AccountRegistration.com";
local Password		= "password1";
local First		= "First";
local Last		= "Last";
local Fail4U		= "IFail4U";

--Return Messages
local Returned		= nil;
local Success		= "user_update_ok";
local NameExists	= "user_exists";
local DisplayExists	= "displayname_exists";
local NameDisplayExists	= "both_userdisplay_exists";
local EmailExists	= "email_exists";

local NameLength	= "disallowed_user_length";
local DisplayLength	= "disallowed_display_length";
local NameRestricted	= "restricted_user";
local DisplayRestricted	= "disallowed_display";
local NameNotAllowed	= "disallowed_user";
local DisplayNotAllowed	= "disallowed_display";
--letters, periods ('.'), hyphens ('-'), and underscores ('_') with at least one alphanumeric character.

local Unknown		= "user_error_unknown";
local RateLimit		= "rate_limit";

Test.Begin();
--Sucessful Registration
Name = "Success_"..TimeStamp;
local Email = Name..EmailSuffix;
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, Name, Email), Success);

--Account name already used
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, Fail4U, Fail4U), NameExists);

--Display name already used
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Fail4U, Password, Name, Fail4U), DisplayExists);

--Display AND Account name already used
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, Name, Fail4U), NameDisplayExists);

--Email already used
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Fail4U, Password, Fail4U, Email), EmailExists);

--Account name(s) with invalid lengths
Name = "Length_"..TimeStamp;
Email = Name..EmailSuffix;
Test.Verify(AccountServer.XMLRPC.CreateNewAccount("", Password, Name, Email), Unknown);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount("1", Password, Name, Email), NameLength);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount("12", Password, Name, Email), NameLength);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(string.format("%051d", 51), Password, Name, Email), NameLength);

--Display name(s) with invalid lengths
Name = "Length_"..TimeStamp;
Email = Name..EmailSuffix;
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, "", Email), Success);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, "1", Email), DisplayLength);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, "12", Email), DisplayLength);
Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, string.format("%051d", 51), Email), DisplayLength);

--Account name(s) with disallowed characters
local DisallowedListPath = Console.FilePathFromString(nil, "DisallowedList", "csv");
local DisallowedList = Console.ReadCSVFile(DisallowedListPath);
Test.Require(DisallowedList, "The DisallowedList was not found at: " ..DisallowedListPath);

for i, _ in ipairs(DisallowedList) do
	Name = DisallowedList[i].prefix.."_"..TimeStamp;
	Email = Name..EmailSuffix;
	Test.Verify(AccountServer.XMLRPC.CreateNewAccount(Name, Password, "IAmAnOKName_"..TimeStamp, Email), NameRestricted);
end

--Display name(s) with disallowed characters
for i, _ in ipairs(DisallowedList) do
	Name = DisallowedList[i].prefix.."_"..TimeStamp;
	Email = Name..EmailSuffix;
	Test.Verify(AccountServer.XMLRPC.CreateNewAccount("IAmAnOKName_"..TimeStamp, Password, Name, Email), DisplayNotAllowed);
end

Test.Succeed();
