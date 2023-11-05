local function defineScriptLogName()
	return os.time()
end

local logFileName = 'eventLog/log-'..defineScriptLogName()

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

-- Function to get the content of a file
local function getFileData(fileName)
    local file, err = io.open(fileName, "r")

    if not file then
        error("Error reading file:" .. tostring(err))
        return nil
    end

    local content = file:read("*a") -- read the whole file
    file:close()
    return content
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
		print('IniciIando registro de logs')
		print('Isso pode demorar um pouco...')
		print('Há um total de ' .. #eventLogsRegistered .. ' logs para serem registradas!')
		createFolder('eventLog')
		registerLogsInCacheOnSystem(true)
        print('Arquivo: "' ..  logFileName .. '.log' .. '" criado com sucesso!')
	end
end)

RegisterCommand('logeventfull', function(source)
	if source == 0 then
		print('IniciIando registro de logs')
		print('Isso pode demorar um pouco...')
		print('Há um total de ' .. #eventLogsRegistered .. ' logs para serem registradas!')
		createFolder('eventLog')
		registerLogsInCacheOnSystem(false)
        print('Arquivo: "' ..  logFileName .. '.log' .. '" criado com sucesso!')
	end
end)

function registerLogsInCacheOnSystem(justLogsFromLast10Minutes)
	for index, logInfo in ipairs(eventLogsRegistered) do
        if justLogsFromLast10Minutes then
            if logInfo.timestamp + 60 * 10 >= os.time() then
                local message = generateEventLogMessage(logInfo.eventName, logInfo.sourceId, logInfo.eventArgs)
                appendTextToFile(logFileName..'.log', message)
            end
        else
            local message = generateEventLogMessage(logInfo.eventName, logInfo.sourceId, logInfo.eventArgs)
            appendTextToFile(logFileName..'.log', message)
        end
	end
	eventLogsRegistered = {}
    collectgarbage("collect")
	print('Processo finalizado com sucesso!')
end

function generateEventLogMessage(eventName, sourceId, eventArgs)
	local message = '[EVENT_NAME]: ' .. eventName .. '\n[SOURCE_TRIGGERED]: ' .. sourceId .. '\n[BYTES]: ' .. getSizeInBytes(eventArgs) .. '\n[DATA_ARGS]: ' .. removeLineBreaks(getTableDumped(eventArgs)) .. '\n'
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

function removeEventEntries(inputStr, eventToRemove)
    local lines = {}
    local skip = 0

    for line in inputStr:gmatch("([^\r\n]+)") do  -- Modificado para também capturar linhas vazias
        if line:find('%[EVENT_NAME%]: rtx_tv:UpdateRoutingBucketClient') then
            skip = 4 -- incluindo a linha atual e as próximas 3
        end

        if line:find('%[DATA%-ARGS%]:') then
            line = line .. '\n'
        end

        if skip == 0 then
            table.insert(lines, line)
        else
            skip = skip - 1
        end
    end

    return table.concat(lines, "\n")
end

-- /logfilter [filename] [event-to-remove]
RegisterCommand('logfilter', function(source, args)
    if not hasPermission(source) then
        return
    end

    local couldLoad, fileData = pcall(getFileData, 'eventLog/' .. tostring(args[1]))

    if couldLoad and args[2] then
        local filteredLog = removeEventEntries(fileData, '%[EVENT_NAME%]: ' .. args[2])
        createFolder('eventLog')

        local filteredFileName = logFileName .. '-filter-' .. os.time() .. '.log'
        appendTextToFile(filteredFileName, filteredLog)
        print('Filtro criado com sucesso removendo eventos com nome: ' .. tostring(args[2]))
        print('Filename: ' .. filteredFileName)
    else
        print('Comando dado de forma inválida!')
    end
end)

local function transformLogAsStringIntoATable(input)
    local result = {}
    local currentEntry = nil

    for line in input:gmatch("[^\r\n]+") do
        if line:match("^%[EVENT_NAME%]:") then
            if currentEntry then
                table.insert(result, currentEntry)
            end
            currentEntry = {}
        end

        if currentEntry then
            local key, value = line:match("^%[(.-)%]:%s*(.*)")
            if key and value then
                if key == "BYTES" or key == "SOURCE_TRIGGERED" then
                    value = tonumber(value)
                elseif key == "DATA_ARGS" then
                    value = value
                end
                currentEntry[key] = value
            end
        end
    end

    if currentEntry then
        table.insert(result, currentEntry)
    end

    return result
end

local function getLoopedEvents(logsTabled)
    local LOGS_TRIGGERS_LIMIT_IN_A_ROW = 50
    local logsSequence = {}
    local preWarningEventsPack = {}
    local warningEventsPack = {}

    for index, logInfo in pairs(logsTabled) do
        if #logsSequence == 0 then
            table.insert(logsSequence, logInfo)
        else
            if logsSequence[#logsSequence].EVENT_NAME == logInfo.EVENT_NAME then
                table.insert(logsSequence, logInfo)
                if #logsSequence >= LOGS_TRIGGERS_LIMIT_IN_A_ROW then
                    preWarningEventsPack = logsSequence
                end
            else
                if #preWarningEventsPack > 0 then
                    table.insert(warningEventsPack, preWarningEventsPack)
                    preWarningEventsPack = {}
                end
                logsSequence = {}
            end
        end
    end

    return warningEventsPack
end

local function getBigGlobalEvents(logsTabled)
    local warningEventsPack = {}
    local warningEvents = {}
    local ARGS_LENGHT_LIMIT = 100

    for index, logInfo in pairs(logsTabled) do
        if logInfo.SOURCE_TRIGGERED == -1 and #logInfo['DATA_ARGS'] > ARGS_LENGHT_LIMIT then
            table.insert(warningEvents, logInfo)
        end
    end

    for index, logInfo in pairs(warningEvents) do
        if not warningEventsPack[logInfo.EVENT_NAME] then
            warningEventsPack[logInfo.EVENT_NAME] = {}
        end

        table.insert(warningEventsPack[logInfo.EVENT_NAME], logInfo)
    end

    local instance = {}

    for index, value in pairs(warningEventsPack) do
        table.insert(instance, value)
    end

    return instance
end

local function getKillerEvents(loopedEvents, bigGlobalEvents)
    local loopedEventsNames = {}
    local bigGlobalEventsNames = {}

    for index, eventPack in pairs(loopedEvents) do
        loopedEventsNames[eventPack[1].EVENT_NAME] = eventPack
    end

    for index, eventPack in pairs(bigGlobalEvents) do
        bigGlobalEventsNames[eventPack[1].EVENT_NAME] = eventPack
    end

    local instance = {}

    for eventName, eventInfo in pairs(bigGlobalEventsNames) do
        if loopedEventsNames[eventName] then
            table.insert(instance, eventInfo)
        end
    end

    return instance
end

local function trunkString(s)
    if #s > 80 then
        return string.sub(s, 1, 80) .. "..."
    else
        return s
    end
end

local function defineWarningEventsAndNotify(logsTabled)
    local loopedEvents = getLoopedEvents(logsTabled)
    local bigGlobalEvents = getBigGlobalEvents(logsTabled)
    local killerEvents = getKillerEvents(loopedEvents, bigGlobalEvents)
    
    local function filterLoopedEvents(loopedEvents)
        local instance = {}

        for index, eventPack in pairs(loopedEvents) do
            if not instance[eventPack[1].EVENT_NAME] then
                instance[eventPack[1].EVENT_NAME] = {}
            end

            for _, eventInfo in pairs(eventPack) do
                table.insert(instance[eventPack[1].EVENT_NAME], eventInfo)
            end
        end

        local newInstance = {}

        for index, eventPack in pairs(instance) do
            table.insert(newInstance, eventPack)
        end

        return newInstance
    end
    
    print('[EVENT_LOGGER] [BAIXO RISCO DE PERIGO] ' .. #filterLoopedEvents(loopedEvents) .. ' tipos eventos encontrados que triggam de forma excessiva para os clients.')
    print('[EVENT_LOGGER] [ALTO RISCO DE PERIGO] ' .. #bigGlobalEvents .. ' tipos eventos encontrados que triggam dados MUITO PESADOS (alta quantia de bytes) para TODOS OS JOGADORES')
    print('[EVENT_LOGGER] [RISCO MÁXIMO DE PERIGO] ' .. #killerEvents .. ' tipos de eventos que triggam de forma excessiva e ALTAMENTE PESADA para TODOS OS JOGADORES')


    local function listLowRiskEvents()
        local filteredLoopedEvents = filterLoopedEvents(loopedEvents)
        print('[EVENT_LOGGER] Lista de eventos de baixo risco')
        for index, eventPack in pairs(filteredLoopedEvents) do
            print(eventPack[1].EVENT_NAME)

            local function seeEventsArguments(showFullArguments)
                print('[EVENT_LOGGER] getting arguments ' .. eventPack[1].EVENT_NAME)
                
                table.sort(eventPack, function(a,b)
                    if a.SOURCE_TRIGGERED == -1 and b.SOURCE_TRIGGERED == -1 then
                        return false
                    elseif a.SOURCE_TRIGGERED == -1 then
                        return true
                    else
                        return a.SOURCE_TRIGGERED < b.SOURCE_TRIGGERED
                    end
                end)
                
                for _, eventInfo in pairs(eventPack) do
                    local arguments = eventInfo['DATA_ARGS']
                    if not showFullArguments then
                        arguments = trunkString(arguments)
                    end

                    print('[ARGS] ' .. arguments .. '\n[SOURCE_TARGET] ' .. eventInfo.SOURCE_TRIGGERED)
                end
            end

            RegisterCommand('args', function(source, args)
                if not hasPermission(source) then
                    return
                end

                if args[1] then
                    seeEventsArguments(true)
                else
                    seeEventsArguments(false)
                end
                print('/next - Para ir para o próximo evento')
            end)
            print('[EVENT_LOGGER] Para ver os argumentos desses eventos de forma mais detalhada:')
            print('[EVENT_LOGGER] /args - para ver or argumentos limitados a 80 caracteres (para evitar spam)')
            print('[EVENT_LOGGER] /args 1 - para ver os argumentos de forma completa (sem limite)')
            print('[AVISO] Cuidado ao ativar a opção 1! Pode deixar a análise ilegível!')

            local p = promise.new()

            RegisterCommand('next', function(source, args)
                if not hasPermission(source) then
                    return 
                end

                p:resolve()
            end)
            print('/next - Para ir para o próximo evento')

            Citizen.Await(p)
        end
        RegisterCommand('next', function(source, args)
            print('Não tem mais eventos!')
        end)
    end

    local function listMidRiskEvents()
        print('[EVENT_LOGGER] Lista de eventos de alto risco elevado')
        for index, eventPack in pairs(bigGlobalEvents) do
            print(eventPack[1].EVENT_NAME)
            
            local function seeEventsArguments(showFullArguments)
                print('[EVENT_LOGGER] getting arguments ' .. eventPack[1].EVENT_NAME)

                for _, eventInfo in pairs(eventPack) do
                    local arguments = eventInfo['DATA_ARGS']

                    if not showFullArguments then
                        arguments = trunkString(arguments)
                    end

                    print('[ARGS] ' .. arguments .. '\n[SOURCE_TARGET] ' .. eventInfo.SOURCE_TRIGGERED)
                end

            end

            RegisterCommand('args', function(source, args)
                if not hasPermission(source) then
                    return
                end

                if args[1] then
                    seeEventsArguments(true)
                else
                    seeEventsArguments(false)
                end
                print('/next - Para ir para o próximo evento')
            end)
            print('[EVENT_LOGGER] Para ver os argumentos desses eventos de forma mais detalhada:')
            print('[EVENT_LOGGER] /args - para ver or argumentos limitados a 80 caracteres (para evitar spam)')
            print('[EVENT_LOGGER] /args 1 - para ver os argumentos de forma completa (sem limite)')
            print('[AVISO] Cuidado ao ativar a opção 1! Pode deixar a análise ilegível!')

        end
        RegisterCommand('next', function(source, args)
            print('Não tem mais eventos!')
        end)
    end

    local function listHighRiskEvents()
        print('[EVENT_LOGGER] Lista de eventos de RISCO ELEVADISSIMO')
        for index, eventPack in pairs(killerEvents) do
            print(eventPack[1].EVENT_NAME)
            
            local function seeEventsArguments(showFullArguments)
                print('[EVENT_LOGGER] getting arguments ' .. eventPack[1].EVENT_NAME)

                for _, eventInfo in pairs(eventPack) do
                    local arguments = eventInfo['DATA_ARGS']

                    if not showFullArguments then
                        arguments = trunkString(arguments)
                    end

                    print('[ARGS] ' .. arguments .. '\n[SOURCE_TARGET] ' .. eventInfo.SOURCE_TRIGGERED)
                end

            end

            RegisterCommand('args', function(source, args)
                if not hasPermission(source) then
                    return
                end

                if args[1] then
                    seeEventsArguments(true)
                else
                    seeEventsArguments(false)
                end
                print('/next - Para ir para o próximo evento')
            end)
            print('[EVENT_LOGGER] Para ver os argumentos desses eventos de forma mais detalhada:')
            print('[EVENT_LOGGER] /args - para ver or argumentos limitados a 80 caracteres (para evitar spam)')
            print('[EVENT_LOGGER] /args 1 - para ver os argumentos de forma completa (sem limite)')
            print('[AVISO] Cuidado ao ativar a opção 1! Pode deixar a análise ilegível!')

        end
        RegisterCommand('next', function(source, args)
            print('Não tem mais eventos!')
        end)
    end

    RegisterCommand('result', function(source, args)
        if not hasPermission(source) then
            return
        end

        if args[1] == 'low' then
            listLowRiskEvents()
        elseif args[1] == 'mid' then
            listMidRiskEvents()
        elseif args[1] == 'high' then
            listHighRiskEvents()
        else
            print('/result low/mid/high')
        end

    end)

    print('[EVENT_LOGGER] Para analisar quais são os eventos pesados:')
    print('[EVENT_LOGGER] /result low - Ver nomes dos eventos de baixo risco')
    print('[EVENT_LOGGER] /result mid - Ver nomes dos eventos de risco alto')
    print('[EVENT_LOGGER] /result high - Ver nomes dos eventos de risco ALTÍSSIMO')
end

RegisterCommand('loganalyze', function(source, args)
    if not hasPermission(source) then
        return
    end

    local couldLoad, fileData = pcall(getFileData, 'eventLog/' .. tostring(args[1]))

    if couldLoad then
        print('Iniciando análise dos eventos...')
        local logsTabled = transformLogAsStringIntoATable(fileData)

        defineWarningEventsAndNotify(logsTabled)
    else
        print('Comando dado de forma inválida!')
    end
end)

RegisterCommand('loghelp', function(source)
    print('/loginstall - Para instalar dependências do script na base (precisa dar RR)')
    print('/loguninstall - Desinstalar dependências da base (precisa dar RR)')
    print('/logevent - Para gerar a log dos eventos dos últimos 10 minutos do servidor')
    print('/logeventfull - Para gerar a log dos eventos desde o start do servidor (COMANDO ALTAMENTE PESADO)')
    print('/logfilter [filename] [event-to-remove] - Remover eventos de uma log específica gerando outra log filtrada')
    print('/loganalyze [filename] - O algoritmo analisa quais eventos certamente estão pesados e derrubam o servidor')
end)

CreateThread(function()
    ExecuteCommand('loghelp')
end)