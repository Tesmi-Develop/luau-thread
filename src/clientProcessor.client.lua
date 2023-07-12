---!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THREAD_FINISH_BINDABLE_NAME = "threadFinished"
local THREAD_RUN_MESSAGE = "runThread"

local threadFinishedSignal = ReplicatedStorage:WaitForChild(THREAD_FINISH_BINDABLE_NAME) :: BindableEvent
local selfActor = script:GetActor()

selfActor:BindToMessage(THREAD_RUN_MESSAGE, function(threadId: number, executeModule: ModuleScript, ...)	
	local execute = require(executeModule)

	-- Execute the specified module
	task.desynchronize()
	execute(...)
	task.synchronize()

	-- Resume all watchers waiting on this
	threadFinishedSignal:Fire(threadId, selfActor)
end)
