_TriggerClientEvent = TriggerClientEvent

local function registerEventLog(eventName, sourceId, eventArgs)
	TriggerEvent('registerEventLog', eventName, sourceId, eventArgs)
end

function TriggerClientEvent(eventName, sourceId, ...)
	local eventArgs = {...}
	registerEventLog(eventName, sourceId, eventArgs)
	return _TriggerClientEvent(eventName, sourceId, ...)
end