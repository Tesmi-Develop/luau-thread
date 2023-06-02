--!strict

local thread = {}

--- << Make instances

local threadFinishedSignal = Instance.new("BindableEvent")
threadFinishedSignal.Name = "ThreadFinished"
threadFinishedSignal.Parent = script

--- << thread tracking

local highestThreadId = 0
local activeThreads: {{thread}} = {}

--- << Actor tracking

local actorCache: {Actor} = {}

--- << Private functions
local function BuildActor(): Actor
	
	local actor = Instance.new("Actor")
	actor.Name = "ThreadActor"
	actor.Parent = script
	
	--Enable actors processor
	local processor = script.Processor:Clone()
	processor.Enabled = true
	processor.Parent = actor

	--Build actor cache entry
	table.insert(actorCache, actor)
	return actor
end

--- << Public variables

function thread.spawn(execute_module: ModuleScript, shared_table: SharedTable, ...): number
	
	highestThreadId += 1
	
	--Get the last available actor or a new one
	local actor = actorCache[#actorCache] or BuildActor()
	table.remove(actorCache)
	
	--Mark the current ID as active and start the thread
	activeThreads[highestThreadId] = {};
	actor:SendMessage("RunThread", highestThreadId, execute_module, shared_table, ...)
	
	return highestThreadId
end

function thread.join(thread_id: number)
	
	--Return instantly if the given thread has allready finished
	local active_thread = activeThreads[thread_id]
	if not active_thread then
		
		return
	end
	
	--Stop current thread and add to active coroutine tracker
	table.insert(active_thread, coroutine.running())
	coroutine.yield()
end

--Connect to the thread finished signal to respawn join coroutines
threadFinishedSignal.Event:Connect(function(id: number, actor: Actor)

	local active_thread = activeThreads[id]
	for _, v in active_thread do

		task.spawn(v)
	end

	--Disconnect and clean up
	activeThreads[id] = nil
	
	--Add the actor back to the actor cache
	table.insert(actorCache, actor)
end)

return table.freeze(thread)
