require("cryptic/AccountServer.Web");
require("cryptic/Console");
require("socket.url");

AccountServer.Web.Legacy = {
	prod_fields = {
		"name",
		"internal",
		"description",
		"billingstatementidentifier",
		"shards",
		"permissions",
		"reqsubs",
		"subCategory",
		"alvl",
		"dependent",
		"categories",
		"dontAssociate",
		"keyValueChanges",
		"itemID",
		"prices",
		"taxClassification",
		"prerequisites",
		"daysGranted",
		"subGranted",
		"activationKeyPrefix",
		"expireDays",
		"xboxOfferID",
		"xboxContentID",
		"recruitUpgraded",
		"referredProduct",
		"recruitBilled",
	},

	cached_batch_ids = {},
};

function AccountServer.Web.Legacy.Request(page, body, port)
	local url = AccountServer.Web.HomeURL(true)..page;
	return Http.Request(url, body, port or AccountServer.port, AccountServer.user, AccountServer.password);
end

function AccountServer.Web.Legacy.GetForm(page, t, port)
	local req = page.."?"..Http.CreateFormRequest(t);
	return AccountServer.Web.Legacy.Request(req, nil, port);
end

function AccountServer.Web.Legacy.PostForm(page, t, port)
	local body = Http.CreateFormRequest(t);
	return AccountServer.Web.Legacy.Request(page, body, port);
end

function AccountServer.Web.Legacy.GetProductDetailsHeader()
	return AccountServer.Web.Legacy.prod_fields;
end

function AccountServer.Web.Legacy.RefreshPermissions(priv_n)
	AccountServer.Web.Legacy.GetForm("refreshPermissionCache", {name = priv_n});
end

function AccountServer.Web.Legacy.GetProductForm(prod)
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("productDetail", {product = prod});

	if c ~= 200 then
		return nil;
	end
	return r;
end

function AccountServer.Web.Legacy.GetAccountPermissionsForProduct(priv_n, prod)
	AccountServer.Web.RefreshPermissions(priv_n);
	
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("detail", {accountname = priv_n});
	
	if c ~= 200 then
		return nil, -1;
	end

	-- Oh god regular expression magic here goes
	local perm_src = r:match("Cached Permissions.-<tbody>(.-)</tbody>");
	if not perm_src then
		return nil, -1;
	end
  
	for perm in perm_src:gmatch("<tr>(.-)</tr>") do
		local perm_data = { };

		for data in perm:gmatch("<td.->(.-)</td>") do
			table.insert(perm_data, data);
		end

		local product, perm_str, alvl = unpack(perm_data);
		if product and perm_str and tonumber(alvl) and
			product:lower() == prod:lower() then
			-- This is the one; tableize the results
			return AccountServer.ParsePermissionString(perm_str), tonumber(alvl);
		end
	end

	return nil, -1;
end

function AccountServer.Web.Legacy.GetPermissionsForProduct(prod)
	local page = AccountServer.Web.Legacy.GetProductForm(prod);
	local prod_name = page:match("<input[^>]-name=\"internal\"[^>]-value=\"([^\"]-)\"");
	local perm_str = page:match("<input[^>]-name=\"permissions\"[^>]-value=\"([^\"]-)\"");
	local perm_table = { };

	if perm_str then
		perm_table = AccountServer.ParsePermissionString(perm_str);
	end

	local shard = page:match("<input[^>]-name=\"shards\"[^>]-value=\"([^\"]-)\"");
	perm_table["shard"] = shard;

	return prod_name, perm_table;
end

function AccountServer.Web.Legacy.GetProducts()
	local r, c, _, _ = AccountServer.Web.Legacy.Request("productView");

	if c ~= 200 then
		return nil;
	end

	return Http.ReadTable(r);
end

function AccountServer.Web.Legacy.GetProductDetails(name)
	local page = AccountServer.Web.Legacy.GetProductForm(name);
	
	if page then
		local form = AccountServer.Web.Legacy.GetHTMLForm(page, "productcreate");
		local tbl = {};

		tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetAllHTMLFormValues(form));
		tbl = Console.JoinTables(tbl, AccountServer.Web.GetLocalizations(page));
		tbl = Console.JoinTables(tbl, AccountServer.Web.GetKeyValues(page));
	
		return tbl;
	else
		return nil;
	end
end

function AccountServer.Web.Legacy.ProductModifyInternal(name, internal, tbl, page)
	tbl = Console.TrimTable(tbl) or {};

	tbl.name = name;
	tbl.internal = internal;

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm(page, tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.CreateProduct(name, internal, tbl)
	if tbl.description == nil or tbl.description == "" then
		return false, "No description was found for the product "..name
	end
	return AccountServer.Web.ProductModifyInternal(name, internal, tbl, "productCreate");
end

function AccountServer.Web.Legacy.EditProduct(name, internal, tbl)
	return AccountServer.Web.ProductModifyInternal(name, internal, tbl, "productEdit");
end

function AccountServer.Web.Legacy.CreateOrEditProduct(name, internal, tbl)
	local details = AccountServer.Web.GetProductDetails(name);
	local result = false;
	local exists = false;
	local tbl = Console.TrimTable(tbl);
	local message = nil;

	if details then
		exists = true;
	end

	details = details or {};

	local loc = {};
	local kv = {};

	if tbl then
		for k, v in pairs(tbl) do
			if type(k) == "number" then
				if v:match("loc:") then
					local tag, name, desc = v:match("^loc:\"(.-)\":\"(.-)\":\"(.-)\"$");
					table.insert(loc, {tag, name, desc});
				elseif v:match("kv:") then
					local key, value = v:match("^kv:\"(.-)\":\"(.-)\"$");
					table.insert(kv, {key, value});
				end
			else
				v = tostring(v);
				v = Console.Trim(v);
				
				if v ~= "" then
					details[k] = v:match("^\"(.-)\"$") or v;
				end
			end
		end
	end

	if exists then
		result = AccountServer.Web.EditProduct(name, internal, details);
	else
		result, message = AccountServer.Web.CreateProduct(name, internal, details);
	end

	if not result then
		return result, message;
	end

	if result == false then
		return result, message;
	end

	for _, v in ipairs(loc) do
		result = AccountServer.Web.AddProductLocalization(name, unpack(v)) or result;
	end

	for _, v in ipairs(kv) do
		result = AccountServer.Web.SetProductKeyValue(name, unpack(v)) or result;
	end

	return result;
end

function AccountServer.Web.Legacy.GetProductID(name)
	local page = AccountServer.Web.GetProductForm(name);

	if not page then
		return nil;
	else
		return page:match("<input[^>]-name=\"productID\"[^>]-value=\"(%d+)\"[^>]->");
	end
end

function AccountServer.Web.Legacy.AddProductLocalization(name, tag, loc_name, loc_desc)
	local prod_id = AccountServer.Web.GetProductID(name);
	local tbl = {};
	tbl.productID = prod_id;
	tbl.languageTag = Console.Trim(tag);
	tbl.name = Console.Trim(loc_name);
	tbl.description = Console.Trim(loc_desc);

	if not prod_id then
		return false;
	end

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm("localizeProduct", tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.RemoveProductLocalization(name, tag)
	local prod_id = AccountServer.Web.GetProductID(name);
	local tbl = {};
	tbl.productID = prod_id;
	tbl.languageTag = Console.Trim(tag);

	if not prod_id then
		return false;
	end

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm("unlocalizeProduct", tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.GetProductLocalizations(name)
	local page = AccountServer.Web.GetProductForm(name);

	return Http.ReadTable(page, "Localization");
end

function AccountServer.Web.Legacy.SetProductKeyValue(name, key, value)
	local prod_id = AccountServer.Web.GetProductID(name);
	local tbl = {};
	tbl.productID = prod_id;
	tbl.key = Console.Trim(key);
	tbl.value = Console.Trim(value);

	if not prod_id then
		return false;
	end

	_, c, _, _ = AccountServer.Web.Legacy.PostForm("setProductKeyValue", tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.AddProductKeyValue(name, key, value)
	AccountServer.Web.SetProductKeyValue(name, key, value);
end

function AccountServer.Web.Legacy.RemoveProductKeyValue(name, key)
	AccountServer.Web.SetProductKeyValue(name, key, "");
end

function AccountServer.Web.Legacy.GetProductKeyValues(name)
	local page = AccountServer.Web.GetProductForm(name);

	return Http.ReadTable(page, "Read%-Only Key%-Values");
end

function AccountServer.Web.Legacy.UpdateProductKeyGroups()
	local r, c, _, _ = AccountServer.Web.Legacy.Request("keygroupUpdate", nil, 81);
	local message = r:match('<div id="content">(.-)</div>');
	
	if c == 301 or c == 302 then
		return true, message;
	else
		return false, message;
	end
end

function AccountServer.Web.Legacy.CreateKeyGroup(prefix, product)
	local r, c, _, _ = AccountServer.Web.Legacy.PostForm("keygroupCreate", {prefix = prefix, name = product});
	local message = r:match('<div id="content">(.-)</div>');

	if c == 301 or c == 302 then --or m:match("Failed") removed, this was getting false positives
		return true, message;
	else
		return false, message;
	end
end

function AccountServer.Web.Legacy.GetProductsForKeyGroup(prefix)
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("keygroupView", {prefix = prefix});
	local prods = nil;

	if c ~= 200 or r:match("Could not find") then
		return nil;
	end

	prods = {};
	local prod_string = r:match("<input[^>]-name=\"productList\"[^>]-value=\"([^\"]-)\"[^>]->");

	for product in prod_string:gmatch("([^,]+)") do
		table.insert(prods, product);
	end

	return prods;
end

function AccountServer.Web.Legacy.GetKeyGroupPage(prefix)
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("keygroupView", {prefix = prefix});

	if c ~= 200 or r:match("Could not find") then
		return nil;
	end

	return r;
end

function AccountServer.Web.Legacy.GetBatchesForKeyGroup(prefix)
	local page = AccountServer.Web.Legacy.GetKeyGroupPage(prefix);
	return Http.ReadTable(page, "Product Key Batches");
end

function AccountServer.Web.Legacy.GetIDForKeyBatch(prefix, batch)
	if AccountServer.Web.Legacy.cached_batch_ids[prefix] and AccountServer.Web.Legacy.cached_batch_ids[prefix][batch] then
		return AccountServer.Web.Legacy.cached_batch_ids[prefix][batch];
	end

	local page = AccountServer.Web.Legacy.GetKeyGroupPage(prefix);
	
	if not page then
		return nil;
	end

	batch = Utils.EscapeRegex(batch);
	local id = page:match("<a href=\"batchView%?id=(%d+)\">"..batch.."</a>");
	AccountServer.Web.Legacy.cached_batch_ids[prefix] = AccountServer.Web.Legacy.cached_batch_ids[prefix] or {};
	AccountServer.Web.Legacy.cached_batch_ids[prefix][batch] = id;
	
	return id;
end

function GetFormForBatch(prefix, batch)
	local id = AccountServer.Web.Legacy.GetIDForKeyBatch(prefix, batch);

	if not id then
		return nil;
	end

	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("batchView", {id = id});

	if c ~= 200 then
		return nil;
	end

	return r;
end

function AccountServer.Web.Legacy.GetUnusedKeysForBatch(prefix, batch)
	local r = GetFormForBatch(prefix, batch);
	
	return Http.ReadTable(r, "Unused Product Keys", false);
end

function AccountServer.Web.Legacy.GetUsedKeysForBatch(prefix, batch)
	local r = GetFormForBatch(prefix, batch);
	local t = {};
	local usedkeys = {};

	t = Http.ReadTable(r, "Used Product Keys", false);
	
	for i, v in ipairs(t) do
		table.insert(usedkeys, {account = v[2], key = v[1]});
	end

	return usedkeys;
end

function AccountServer.Web.Legacy.GetDistributedKeysForBatch(prefix, batch)
	local r = GetFormForBatch(prefix, batch);
	local t = {};
	local distkeys = {};

	t = Http.ReadTable(r, "Unused Product Keys", false);
	--hackery since there isnt rows
	for i, v in ipairs(t) do
		--If its a key, and there isnt an account name afterwards 
		if t[(i+1)] then
			if string.len(t[i]) == 25 and string.len(t[(i+1)]) < 25 then
				table.insert(distkeys, {key = t[i]});
	
			--else if is an account name
			elseif string.len(t[i]) < 25 then
				distkeys[#distkeys].distaccount = t[i]
			end
		end
	end

	return distkeys;
end

function AccountServer.Web.Legacy.GetKeyGroups()
	local r, c, _, _ = AccountServer.Web.Legacy.Request("keygroupList");

	if c ~= 200 then
		return nil;
	end

	return Http.ReadTable(r);
end

function AccountServer.Web.Legacy.KeyCreateBatch(name, prod, prefix, count, desc)
	local t = {
		prefix		= prefix,
		name		= name,
		keycount	= count,
		description	= desc,
	};
	t = Console.TrimTable(t);
	
	local oldtimeout = socket.http.TIMEOUT;
	socket.http.TIMEOUT = math.floor(0.04 * count) + 300;
	local r, c, _, _ = AccountServer.Web.Legacy.PostForm("batchCreateAction", t, 81);
	socket.http.TIMEOUT = oldtimeout;

	if c == 200 then
		return tonumber(r:match("Created Key Batch of (%d+) keys"));
	else
		return false;
	end
end


AccountServer.Web.Legacy.sub_fields = {
		"name",
		"internal",
		"description",
		"billingstatementidentifier",
		"productname",
		"periodtype",
		"periodamount",
		"initialfreedays",
		"prices",
		"gamecard",
		"mockProduct",
		"categories",
		"billedProduct",
};

function AccountServer.Web.Legacy.GetSubscriptionDetailsHeader()
	return AccountServer.Web.Legacy.sub_fields;
end

function AccountServer.Web.Legacy.GetSubscriptionForm(sub)
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("subscriptionDetail", {subscription = sub});
	
	if c ~= 200 then
		return nil;
	end

	return r;
end

function AccountServer.Web.Legacy.GetSubscriptions()
	local r, c, _, _ = AccountServer.Web.Legacy.Request("subscriptionView");

	if c ~= 200 then
		return nil;
	end

	return Http.ReadTable(r);
end

function AccountServer.Web.Legacy.SubscriptionModifyInternal(name, internal, tbl, page)
	tbl = Console.TrimTable(tbl) or {};

	tbl.name = name;
	tbl.internal = internal;

	for k, v in pairs(tbl) do
		if type(v) == "string" then
			tbl[k] = Console.Trim(v);
		end
	end

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm(page, tbl);
	
	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.CreateSubscription(name, internal, tbl)
	return AccountServer.Web.SubscriptionModifyInternal(name, internal, tbl, "subscriptionCreate");
end

function AccountServer.Web.Legacy.EditSubscription(name, internal, tbl)
	return AccountServer.Web.SubscriptionModifyInternal(name, internal, tbl, "subscriptionEdit");
end

function AccountServer.Web.Legacy.CreateOrEditSubscription(name, internal, tbl)
	local details = AccountServer.Web.GetSubscriptionDetails(name);
	local result = false;
	local exists = false;

	if details then
		exists = true;
	end

	details = details or {};

	local loc = {};
	local kv = {};

	if tbl then
		for k, v in pairs(tbl) do
			if type(k) == "number" then
				if v:match("loc:") then
					local tag, name, desc = v:match("^loc:\"(.-)\":\"(.-)\":\"(.-)\"$");
					table.insert(loc, {tag, name, desc});
				end
			else
				details[k] = v;
			end
		end
	end

	if exists then
		result = AccountServer.Web.EditSubscription(name, internal, details);
	else
		result = AccountServer.Web.CreateSubscription(name, internal, details);
	end

	if not result then
		return result;
	end

	for _, v in ipairs(loc) do
		result = AccountServer.Web.AddSubscriptionLocalization(name, unpack(v)) or result;
	end

	return result;
end

function AccountServer.Web.Legacy.GetSubscriptionID(name)
	local page = AccountServer.Web.GetSubscriptionForm(name);

	return page:match("<input[^>]-name=\"subscriptionID\"[^>]-value=\"(%d+)\"[^>]->");
end

function AccountServer.Web.Legacy.AddSubscriptionLocalization(name, tag, loc_name, loc_desc)
	local sub_id = AccountServer.Web.GetSubscriptionID(name);
	local tbl = {};
	tbl.subscriptionID = sub_id;
	tbl.languageTag = Console.Trim(tag);
	tbl.name = Console.Trim(loc_name);
	tbl.description = Console.Trim(loc_desc);

	if not sub_id then
		return false;
	end

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm("localizeSubscription", tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.RemoveSubscriptionLocalization(name, tag)
	local sub_id = AccountServer.Web.GetSubscriptionID(name);
	local tbl = {};
	tbl.subscriptionID = sub_id;
	tbl.languageTag = Console.Trim(tag);

	if not sub_id then
		return false;
	end

	local _, c, _, _ = AccountServer.Web.Legacy.PostForm("unlocalizeSubscription", tbl);

	if c == 301 or c == 302 then
		return true;
	else
		return false;
	end
end

function AccountServer.Web.Legacy.GetSubPeriod(form)
	local pd_type_str = form:match("<div[^>]->Period Type</div>[^<]-<div[^>]->[^<]-</div>%s*([^<]+)");
	local pd_amt = form:match("<div[^>]->Period Amount</div>[^<]-<div[^>]->[^<]-</div>%s*([^<]+)");

	local lookup = {["Year"] = "0", ["Month"] = "1", ["Day"] = "2"};
	local pd_type = lookup[pd_type_str];

	return {["periodtype"] = pd_type, ["periodamount"] = pd_amt};
end

function AccountServer.Web.Legacy.GetSubscriptionDetails(name)
	local page = AccountServer.Web.GetSubscriptionForm(name);

	if page then
		local form = AccountServer.Web.Legacy.GetHTMLForm(page, "subscriptioncreate");
		local tbl = {};

		tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetAllHTMLFormValues(form));
		tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetSubPeriod(form));
		tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetLocalizations(page));
		
		return tbl;
	else
		return nil;
	end
end

function AccountServer.Web.Legacy.GetHTMLForm(page, name)
	return page:match("<form[^>]-name=\"" ..name.. "\"[^>]->(.-)</form>");
end

function AccountServer.Web.Legacy.GetHTMLHidden(form)
	local tbl = {};

	for name, value in form:gmatch("<input[^>]-type=\"hidden\"[^>]-name=\"([^\"]-)\"[^>]-value=\"([^\"]-)\"[^>]->") do
		tbl[name] = Http.UnescapeString(value);
	end
	
	return tbl;
end

function AccountServer.Web.Legacy.GetHTMLText(form)
	local tbl = {};
	
	for name, value in form:gmatch("<input[^>]-type=\"text\"[^>]-name=\"([^\"]-)\"[^>]-value=\"([^\"]-)\"[^>]->") do
		tbl[name] = Http.UnescapeString(value);
	end

	return tbl;
end

function AccountServer.Web.Legacy.GetHTMLChecked(form)
	local tbl = {};
	
	for name, value in form:gmatch("<input[^>]-type=\"checkbox\"[^>]-name=\"([^\"]-)\"[^>]-CHECKED[^>]-value=\"([^\"]-)\"[^>]->") do
		tbl[name] = Http.UnescapeString(value);
	end
	
	return tbl;
end

function AccountServer.Web.Legacy.GetHTMLSelected(form, tbl)
	local tbl = {};
	
	for name, opts in form:gmatch("<select[^>]-name=\"([^\"]-)\"[^>]->(.-)</select>") do
		local selection = opts:match("<option[^>]-SELECTED[^>]-value=\"([^\"]-)\"[^>]->");
		tbl[name] = Http.UnescapeString(selection);
	end

	return tbl;
end

function AccountServer.Web.Legacy.GetLocalizations(page)
	local tbl = {};
	local loc = Http.ReadTable(page, "Localization");

	for k, v in pairs(loc) do
		if not k:match("<.->") then
			table.insert(tbl, "loc:\""..k.."\":\""..v.Name.."\":\""..v.Description.."\"");
		end
	end
	
	return tbl;
end

function AccountServer.Web.Legacy.GetKeyValues(page)
	local kv = Http.ReadTable(page, "Read%-Only Key%-Values");
	local tbl = {};
	
	for k, v in pairs(kv) do
		if not k:match("<.->") then
			table.insert(tbl, "kv:\""..k.."\":\""..v.Value.."\"");
		end
	end
	return tbl;
end

function AccountServer.Web.Legacy.GetAllHTMLFormValues(form)
	local tbl = {};
	
	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetHTMLHidden(form));
	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetHTMLText(form));
	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetHTMLChecked(form));
	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetHTMLSelected(form));
	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetLocalizations(form));
	
	return tbl;
end

AccountServer.Web.Legacy.account_fields = {
		"accountname",
		"guid",
		"accountID",
};

function AccountServer.Web.Legacy.GetAccountForm(name)
	local r, c, _, _ = AccountServer.Web.Legacy.GetForm("detail", {accountname = name});

	if c ~= 200 then
		return nil;
	end
	return r;
end

function AccountServer.Web.Legacy.GetAccountCachedSubs(name)
	local page = AccountServer.Web.Legacy.GetAccountForm(name);

	if not page then
		return nil;
	end

	local tbl = Http.ReadTable(page, "Cached Vindicia Subscriptions", false);
	
	return tbl;
end

function AccountServer.Web.Legacy.GetAccountDetails(name)
	local page = AccountServer.Web.Legacy.GetAccountForm(name);
	--local form = AccountServer.Web.Legacy.GetHTMLForm(page, "productcreate");
	local tbl = {};

	tbl = Console.JoinTables(tbl, AccountServer.Web.Legacy.GetAllHTMLFormValues(page));
	
	--[[MISSING:
		Simpler permissions?
		Activated keys
		Distributed keys
		Personal Info
		Payment Methods
		Products?
		Sub Stats
		Vindicia Subs
		Refunded Subs
		Sub History
		Cached Permissions
		Playtimes
		Key Values
	--]]
	return tbl;
end
