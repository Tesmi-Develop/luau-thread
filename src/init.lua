--!strict

type Array<T> = {T}
type Map<K, V> = { [K]: V }

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local THREAD_FINISH_BINDABLE_NAME = "threadFinished"
local THREAD_ACTOR_NAME = "threadActor"
local THREAD_RUN_MESSAGE = "runThread"

local runContextIsClient = RunService:IsClient();

-- Although processorToUse is of type LocalScript | Script, type Script allows the typechecker to work
local processorToUse = (if runContextIsClient then script:FindFirstChild("clientProcessor") else script:FindFirstChild("serverProcessor")) :: Script
local processorParent = if runContextIsClient then Players.LocalPlayer:WaitForChild("PlayerScripts") else ServerScriptService

local thread = {}

local spawnedThreadId = 0
local threadWatchers: Map<number, Array<thread>> = {}

local actorCache: Array<Actor> = {}

-- Get thread finished signal (or create it if it already exists, which could be the case if it was placed there in the editor or if the server made it)
local threadFinishedSignal = ReplicatedStorage:FindFirstChild(THREAD_FINISH_BINDABLE_NAME) :: BindableEvent?

if not threadFinishedSignal then
	threadFinishedSignal = Instance.new("BindableEvent")
	assert(threadFinishedSignal)

	threadFinishedSignal.Name = THREAD_FINISH_BINDABLE_NAME
	threadFinishedSignal.Parent = ReplicatedStorage
end

-- Ensures the typechecker recognises the signal exists
assert(threadFinishedSignal)

local function buildActor(): Actor
	local actor = Instance.new("Actor")
	actor.Name = THREAD_ACTOR_NAME
	actor.Parent = processorParent

	local processor = processorToUse:Clone()
	processor.Parent = actor

	processor.Enabled = true
	
	return actor
end

function thread.spawn(executeModule: ModuleScript, ...): number
	local args = {...}
	local id = spawnedThreadId
	spawnedThreadId += 1

	-- Get the last available actor or a new one
	local actor = table.remove(actorCache) or buildActor()

	-- Mark the current id as active and start the thread
	threadWatchers[id] = {};
	task.defer(function()
		actor:SendMessage(THREAD_RUN_MESSAGE, id, executeModule, table.unpack(args))
	end)
	
	return id
end

function thread.join(threadSpecifier: number | Array<number>)
	if type(threadSpecifier) == "table" then
		for _, threadId in threadSpecifier do
			-- Continue if the given thread has already finished
			local watcherArray = threadWatchers[threadId]

			if not watcherArray then
				continue
			end

			-- Stop current thread and add to watcher list
			table.insert(watcherArray, coroutine.running())
			coroutine.yield()
		end
	else
		-- Return instantly if the given thread has already finished
		local watcherArray = threadWatchers[threadSpecifier]

		if not watcherArray then
			return
		end

		-- Stop current thread and add to watcher list
		table.insert(watcherArray, coroutine.running())
		coroutine.yield()
	end
end

function thread.getModuleByTree(root: Instance, parts: Array<string>)
	local current = root;

	for _, nextPart in parts do
		current = current:WaitForChild(nextPart);
	end

	return current :: ModuleScript;
end

-- Connect to the thread finished signal to respawn the watchers connected in thread.join
threadFinishedSignal.Event:Connect(function(threadId: number, actor: Actor)
	-- Resume all watchers and cleanup
	local watcherArray = threadWatchers[threadId]

	for _, watcher in watcherArray do
		coroutine.resume(watcher);
	end

	threadWatchers[threadId] = nil

	-- Add the actor back to the actor cache
	table.insert(actorCache, actor)
end)

return table.freeze(thread)
