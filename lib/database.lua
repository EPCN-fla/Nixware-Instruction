local DB_PATH = 'C:\\nixware\\database\\'

local json = require 'json'
local database = {namespaces = {}}
local storage = {}

function storage.set(self, key, value)
    self.data[key] = value
end

function storage.get(self, key)
    return self.data[key] or error('Key not found in database')
end

function storage.save(self)
    local file = io.open(DB_PATH .. self.namespace .. '.json', 'w')
    file:write(json.encode(self.data))

    file:close()
end

function database.new(namespace, data)
    database.namespaces[namespace .. '.json'] = setmetatable({ namespace = namespace, data = data or {} }, { __index = storage })

    print('added new database')

    return database.namespaces[namespace .. '.json']
end

function database.get(namespace)
    if database.namespaces[namespace .. '.json'] ~= nil then
        return database.namespaces[namespace .. '.json']
    else
        return database.new(namespace)
    end
end

function database.list()
    local list = {}

    for key, value in pairs(database.namespaces) do
        table.insert(list, string.gsub(key, '.json', ''))
    end

    return list
end


for file in io.popen([[dir "C:\nixware\database" /b]]):lines() do
    if string.find(file, ".json") then
        local data = io.open(DB_PATH .. file, 'r')

        if data ~= nil then
            local parsed_data = json.decode(data:read('*a'))

            database.new(string.gsub(file, '.json', ''), parsed_data)

            data:close()
        end
    end
end

return database
