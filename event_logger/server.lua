local function defineScriptLogName()
	return os.time()
end

local logFileName = 'eventLog/log-'..defineScriptLogName()..'.log'

-- Function to create an empty file
local function createFile(fileName)
    local file, error = io.open(fileName, "w")
    if not file then
        print("Error creating file:", error)
        return nil
    end
    file:close()
    print("File created successfully:", fileName)
end

function createFolder(folderPath)
    local success, _, _, _ = os.execute("if not exist \"" .. folderPath .. "\" mkdir \"" .. folderPath .. "\"")
    if success then
        print("Pasta criada com sucesso ou já existia.")
    else
        print("Falha ao criar pasta.")
    end
end

-- Function to open a file with the specified mode
local function openFile(fileName, mode)
    local file, error = io.open(fileName, mode)
    if not file then
        print("Error opening file:", error)
        return nil
    end
    return file
end

-- Function to write text to a file with a newline at the end
local function writeToFile(file, text)
    if file then
        file:write(text .. "\n")
    else
        print("File not provided for writing.")
    end
end

-- Function to close a file
local function closeFile(file)
    if file then
        file:close()
    else
        print("File not provided for closing.")
    end
end

-- Main function to append text to a file
local function appendTextToFile(fileName, text)
    local file = openFile(fileName, "a")
    if not file then return end
    
    writeToFile(file, text)
    closeFile(file)
end

local eventLogsRegistered = {}

AddEventHandler('registerEventLog', function(eventName, sourceId, eventArgs)
	table.insert(eventLogsRegistered, {
		eventName = eventName, 
		sourceId = sourceId, 
		eventArgs = eventArgs,
        timestamp = os.time()
	})
end)

RegisterCommand('logevent', function(source)
	if source == 0 then
		print('Iniciando registro de logs')
		print('Isso pode demorar um pouco...')
		print('Há um total de ' .. #eventLogsRegistered .. ' logs para serem registradas!')
		createFolder('eventLog')
		registerLogsInCacheOnSystem()
	end
end)

function registerLogsInCacheOnSystem()
	for index, logInfo in ipairs(eventLogsRegistered) do
        if logInfo.timestamp + 60 * 10 >= os.time() then
            local message = generateEventLogMessage(logInfo.eventName, logInfo.sourceId, logInfo.eventArgs)
            appendTextToFile(logFileName, message)
        end
	end
	eventLogsRegistered = {}
    collectgarbage("collect")
	print('Processo finalizado com sucesso!')
end

function generateEventLogMessage(eventName, sourceId, eventArgs)
	local message = '[EVENT_NAME]: ' .. eventName .. '\n[SOURCE_TRIGGERED]: ' .. sourceId .. '\n[BYTES] ' .. getSizeInBytes(eventArgs) .. '\n[DATA-ARGS]: ' .. removeLineBreaks(getTableDumped(eventArgs)) .. '\n'
    return message
end

function removeLineBreaks(inputString)
    local stringWithoutLineBreaks = inputString:gsub("\n", " ")
    return stringWithoutLineBreaks
end

function getSizeInBytes(data)
    if type(data) == "number" then
        return #string.pack("f", data)
    elseif type(data) == "string" then
        return #data
    elseif type(data) == "table" then
        local totalSize = 0
        for _, v in pairs(data) do
            local size = getSizeInBytes(v)
            if size then
                totalSize = totalSize + size
            end
        end
        return totalSize
    else
        return nil -- Tipo não suportado
    end
end

function getTableDumped(node)
    return json.encode(node)
end

local function hasPermission(source)
    return source == 0
end

function listAllResourcePaths()
    local resourcePaths = {}
    local numResources = GetNumResources()

    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local resourcePath = GetResourcePath(resourceName)

		resourcePath = resourcePath:gsub("//", "/")

        resourcePaths[resourceName] = resourcePath
    end

    return resourcePaths
end

local function updateFxManifest(folder)
    local function updateFile(filePath, addLine)
        local file = io.open(filePath, "r")
        if not file then
            print(filePath .. " não encontrado em " .. folder)
            return false
        end

        local content = file:read("*a")
        file:close()

        -- Verifica se a linha já existe antes de adicionar
        if not content:find(addLine, 1, true) then
            content = addLine .. "\n" .. content

            file = io.open(filePath, "w")
            if file then
                file:write(content)
                file:close()
                print(filePath .. " atualizado em " .. folder)
                return true
            else
                print("Erro ao abrir " .. filePath .. " para escrita.")
                return false
            end
        else
            print(filePath .. " já está atualizado em " .. folder)
            return true
        end
    end

    local addLine = 'server_script "@event_logger/log_register.lua"'
    local updatedFxmanifest = updateFile(folder .. "/fxmanifest.lua", addLine)
    local updatedResource = updateFile(folder .. "/__resource.lua", addLine)

    return updatedFxmanifest or updatedResource
end

RegisterCommand("loginstall", function(source, args, rawCommand)
    if not hasPermission(source) then
        print("Você não tem permissão para usar esse comando.")
        return
    end

    local resourcePaths = listAllResourcePaths()
    
    for resourceName, resourcePath in pairs(resourcePaths) do
        updateFxManifest(resourcePath)
    end
end, false)

local function removeTextFromManifest(folder)
    local function removeTextFromFile(filePath)
        local file = io.open(filePath, "r")
        if not file then
            print(filePath .. " não encontrado em " .. folder)
            return false
        end

        local content = file:read("*a")
        file:close()

        local pattern = 'server_script "@event_logger/log_register.lua"\n'
        if content:find(pattern, 1, true) then
            content = content:gsub(pattern, "")

            file = io.open(filePath, "w")
            if file then
                file:write(content)
                file:close()
                print("Texto removido de " .. filePath .. " em " .. folder)
                return true
            else
                print("Erro ao abrir " .. filePath .. " para escrita.")
                return false
            end
        else
            print("Texto não encontrado em " .. filePath .. " em " .. folder)
            return false
        end
    end

    local removedFromFxmanifest = removeTextFromFile(folder .. "/fxmanifest.lua")
    local removedFromResource = removeTextFromFile(folder .. "/__resource.lua")

    return removedFromFxmanifest or removedFromResource
end


RegisterCommand("loguninstall", function(source, args, rawCommand)
    if not hasPermission(source) then
        print("Você não tem permissão para usar esse comando.")
        return
    end

    local resourcePaths = listAllResourcePaths()
    
    for resourceName, resourcePath in pairs(resourcePaths) do
        removeTextFromManifest(resourcePath)
    end
end, false)