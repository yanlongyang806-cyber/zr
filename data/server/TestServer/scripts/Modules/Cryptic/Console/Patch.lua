require("cryptic/Console");
require("cryptic/Http");
require("cryptic/Var");

Console.Patch = {
	loc = Var.Default(nil, "PatchServer_Loc", "patchmaster"),
};

-----Accessors/setters
function Console.Patch.SetLoc(loc)
	Console.Patch.loc = Var.Set(nil, "PatchServer_Loc", loc);
end

function Console.Patch.DefaultLoc(loc)
	Console.Patch.loc = Var.Default(nil, "PatchServer_Loc", loc);
end

-----Patch Version Functions
function Console.Patch.GetAllBuildsForProject(project)
	local buildtable = {};
	local project = project or "Infrastructure"; --Any Database listed at http://patchmaster/
	local page = Http.Request(("http://%s/%s/view/"):format(Console.Patch.loc, project), nil, 80);

	--Strip everything but the build table
	t = page:match("<table class=\"table\">(.-)</table>");
	
	--Get each build listed (and not show more)
	for v in t:gfind("<tr class=.-'>(.-)</a></td><td>") do
		table.insert(buildtable, v);
	end
	
	return buildtable;
end

function Console.Patch.GetAllBuildsForInfrastructureProject(project)
	local buildtable = {};
	local t = Console.Patch.GetAllBuildsForProject("Infrastructure");
	local project = project or "Infrastructure";
	
	--Get the build for the project(AS, TT, GC or Infrastructure)
	for i, v in ipairs(t) do
		if v:match(project..".-") then
			table.insert(buildtable, v);
		end
	end

	return buildtable;
end

function Console.Patch.GetLatestBuildForProject(project)
	return Console.Patch.GetAllBuildsForProject(project)[1];
end

function Console.Patch.GetLatestBuildForInfrastructureProject(project)
	return Console.Patch.GetAllBuildsForInfrastructureProject(project)[1];
end

------Actual Patching Functions
function Console.Patch.Patch(wd, proj, ver)
	if not Console.CopyPatchClientTo(wd) then
		return false;
	end

	return Console.RunAppAndWait(wd.."/PatchClient.exe",
		"-sync -project "..proj.." -name "..ver);
end

function Console.Patch.CopyPatchClientTo(loc)
	return Console.RunAppAndWait("robocopy",
		"C:/Cryptic/tools/bin/ "..loc.." PatchClient.exe");
end
