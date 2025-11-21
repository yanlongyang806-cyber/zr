require("cryptic/AccountServer.Web");
require("cryptic/Http");

AccountServer.Web.Core = {};

function AccountServer.Web.Core.Request(page, body, port)
	local url = AccountServer.Web.HomeURL()..page;
	return Http.Request(url, body, port or AccountServer.port, AccountServer.user, AccountServer.password);
end

function AccountServer.Web.Core.GetForm(page, t, port)
	local req = page.."?"..Http.CreateFormRequest(t);
	return AccountServer.Web.Core.Request(req, nil, port);
end

function AccountServer.Web.Core.PostForm(page, t, port)
	local body = Http.CreateFormRequest(t);
	return AccountServer.Web.Core.Request(page, body, port);
end

function AccountServer.Web.Core.ResultMessage(r, c)
	if c ~= 200 then
		return false;
	elseif r:match("<div class=\".-ui-state-error.-\"") then
		return r:match("<strong>Error:</strong>\s*([\w ]*)");
	else
		return true;
	end
end

-------Discounts

function AccountServer.Web.Core.AddDiscount(currency, internal, discount, kv, name, start_ts, end_ts, prods, b_prods, cats, b_cats)
	local r, c, _, _ = AccountServer.Web.Core.PostForm("admin/discounts.html", {
		name = name or "",
		currency = currency,
		productInternalName = internal,
		percentageDiscount = discount,
		keyValuePrereqs = kv,
		products = prods,
		blacklistProducts = b_prods,
		categories = cats,
		blacklistCategories = b_cats,
		startTime = start_ts,
		endTime = end_ts,
		saveDiscount = "Add or Replace",
	});
	
	return AccountServer.Web.Core.ResultMessage(r, c);
end

function AccountServer.Web.Core.GetDiscountID(currency, internal, kv, name)
	local r, c, _, _ = AccountServer.Web.Core.Request("admin/discounts.html");

	if c ~= 200 then
		return nil;
	end

	local t = Http.ReadTable(r, "Discounts", false);
	local ids = {};
		
	for _, v in ipairs(t) do

		--[[
		if v["Currency"] == currency and v["Product Internal Name"] == internal and v["Prerequisites"]:match("Infix: ([^<]+)") == kv then
			return tonumber(v["Actions"]:match("<input[^>]-value=\"(%d+)\"[^>]-name=\"id\""));
		end
		]]--
		--[[
		--Does not iterate since we can have multiple copies of the same discount
		if v["Currency"] == currency and v["Product Internal Name"] == internal and v["Prerequisites"]:match("Infix: ([^<]+)") == kv and v["Name"] == name then
			return tonumber(v["Actions"]:match("<input[^>]-value=\"(%d+)\"[^>]-name=\"id\""));
		end
		]]--
		--Make an array of ALL IDS that match
		if v["Currency"] == currency and v["Product Internal Name"] == internal and v["Prerequisites"]:match("Infix: ([^<]+)") == kv and v["Name"] == name then
			for k, v in string.gmatch(v["Actions"], ("<input[^>]-value=\"(%d+)\"[^>]-name=\"id\"")) do
				table.insert(ids, k);
			end
		end
	end

	return ids;
end

function AccountServer.Web.Core.EnableDiscount(currency, internal, kv, name)
	local disc_id = AccountServer.Web.GetDiscountID(currency, internal, kv, name);

	if not disc_id then
		return false;
	end

	for k, v in pairs(disc_id) do
		local r, c, _, _ = AccountServer.Web.Core.PostForm("admin/discounts.html", {
			id = v,
			disable = 0,
			setEnabled = "Enable"
		});
	end
	return AccountServer.Web.Core.ResultMessage(r, c);
end

function AccountServer.Web.Core.DisableDiscount(currency, internal, kv, name)
	local disc_id = AccountServer.Web.GetDiscountID(currency, internal, kv, name);
	local success = true;
	if not disc_id then
		return false;
	end

	for k, v in pairs(disc_id) do
		local r, c, _, _ = AccountServer.Web.Core.PostForm("admin/discounts.html", {
			id = v,
			disable = 1,
			setEnabled = "Disable"
		});
		if AccountServer.Web.Core.ResultMessage(r, c) == false then
			success = false;
		end
	end
	return success;
end

-------Currency Chains

function AccountServer.Web.Core.AddCurrencyChain(alias, chain)
	local r, c, _, _ = AccountServer.Web.Core.PostForm("admin/chains.html", {
		alias = alias,
		chain = chain,
		saveChain = "Add or Replace",
	});
	
	return AccountServer.Web.Core.ResultMessage(r, c);
end

--------Virtual Currencies

function AccountServer.Web.Core.AddVirtualCurrency(name, game, environment, created, deprecated, reporting_id, revenue_type, is_chain, chain_parts)
	local r, c, _, _ = AccountServer.Web.Core.PostForm("admin/currency.html", {
		name = name,
		game = game,
		environment = environment,
		created = created,
		deprecated = deprecated,
		reportingid = reporting_id,
		revenuetype = revenue_type,
		ischain = is_chain,
		parts = chain_parts,
		saveCurrency = 1,
	});

	return AccountServer.Web.Core.ResultMessage(r, c);
end
