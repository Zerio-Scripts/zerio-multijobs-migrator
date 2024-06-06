local function ExecuteSQL(query, params)
    local resp = promise.new()

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:execute(query, params, function(retVal)
            resp:resolve(retVal)
        end)
    elseif GetResourceState("mysql-async") == "started" and GetResourceState("oxmysql") == "missing" then
        exports["mysql-async"]:mysql_execute(query, params, function(retVal)
            resp:resolve(retVal)
        end)
    elseif GetResourceState("ghmattimysql") == "started" and GetResourceState("oxmysql") ~= "started" then
        exports.ghmattimysql:execute(query, params, function(retVal)
            resp:resolve(retVal)
        end)
    else
        resp:resolve(nil)
    end

    Citizen.Await(resp)
    return resp.value
end

local function SelectSQL(query, params)
    local resp = promise.new()

    if GetResourceState("oxmysql") == "started" then
        local retVal = exports.oxmysql:executeSync(query, params)
        resp:resolve(retVal)
    elseif GetResourceState("mysql-async") == "started" and GetResourceState("oxmysql") == "missing" then
        exports["mysql-async"]:mysql_fetch_all(query, params, function(retVal)
            resp:resolve(retVal)
        end)
    elseif GetResourceState("ghmattimysql") == "started" and GetResourceState("oxmysql") ~= "started" then
        exports.ghmattimysql:scalar(query, params, function(retVal)
            resp:resolve(retVal)
        end)
    else
        resp:resolve(nil)
    end

    Citizen.Await(resp)

    return resp.value
end

if GetResourceState("qb-core") ~= "missing" or GetResourceState("qbx_core") ~= "missing" then
    local data = SelectSQL("select zeriomultijobs, citizenid from players")

    local length = #data
    for i,v in pairs(data) do
        local decodedData = json.decode(v.zeriomultijobs)

        for _i2,v2 in pairs(decodedData) do
            ExecuteSQL("insert into zerio_multijobs (identifier, jobName, jobGrade) values(@identifier, @job, @grade)", {
                ["@identifier"] = v.citizenid,
                ["@job"] = v2.name,
                ["@grade"] = v2.rank
            })
        end

        print("Migrating player " .. v.citizenid .. ", " .. tostring(i) .. "/" .. tostring(length))
    end
elseif GetResourceState("es_extended") ~= "missing" then
    local data = SelectSQL("select data, identifier from `zerio-multijobs`")

    local length = #data
    for i,v in pairs(data) do
        local decodedData = json.decode(v.data)

        for _i2,v2 in pairs(decodedData) do
            ExecuteSQL("insert into zerio_multijobs (identifier, jobName, jobGrade) values(@identifier, @job, @grade)", {
                ["@identifier"] = v.identifier,
                ["@job"] = v2.name,
                ["@grade"] = v2.rank
            })
        end

        print("Migrating player " .. v.citizenid .. ", " .. tostring(i) .. "/" .. tostring(length))
    end
end