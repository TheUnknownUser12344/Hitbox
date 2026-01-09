--!strict

local RunService = game:GetService("RunService")

--Hitbox Utilizing Roblox's Spatial Query Methods

local GoodSignal = require(script.GoodSignal)
local Janitor = require(script.janitor)
local State = require(script.State)
local Types = require(script.Types)

local HitQuery = {}
HitQuery.__index = HitQuery

function HitQuery.new(Parts: { BasePart }): Types.HitQuery
    local self = setmetatable({
        Parts = Parts,
        OverlapParams = nil,
        State = State.Inactive,

        PartEntered = GoodSignal.new(),
        PlayerEntered = GoodSignal.new(),
        Completed = GoodSignal.new(),

        FrameRate = "Unlimited",

        _Options = nil,
        _CurrentThread = nil,
        _t = 0,
        _PartCache = {},
        _Heartbeat = nil,
        _Janitor = Janitor.new(),
        _Destroyed = false,
    }, HitQuery)

    -- Register signals for cleanup
    self._Janitor:Add(self.PartEntered, "DisconnectAll")
    self._Janitor:Add(self.PlayerEntered, "DisconnectAll")
    self._Janitor:Add(self.Completed, "DisconnectAll")

    return (self :: any) :: Types.HitQuery
end

function HitQuery:_Identify(Part: BasePart, Class)
    return Part.Parent ~= workspace and (Part.Parent :: Instance).ClassName == Class or Part.ClassName == Class
end

function HitQuery:_Delay(): boolean
    return self.FrameRate ~= "Unlimited" and os.clock() - (self._t :: number) < 1 / (self.FrameRate :: number)
end

function HitQuery:_Enabled()
    local NewCache = {}

    for _, Part: BasePart in self.Parts :: { BasePart } do
        local PartsInPart = workspace:GetPartsInPart(Part, self.OverlapParams)

        for _, FoundPart in PartsInPart do
            -- Get Parent Of Part
            local Parent = FoundPart.Parent ~= workspace and FoundPart.Parent or FoundPart

            NewCache[FoundPart] = true
            -- Dont Fire If Its In The Cache
            if self._PartCache[FoundPart] then continue end

            self.PartEntered:Fire(FoundPart)

        -- Check _Options

        if self._Options == "Wait" and self._CurrentThread and #PartsInPart > 0 then
            task.spawn(self._CurrentThread :: thread)
        end

        if (self._Options == "Once" or self._Options == "Wait") and (#PartsInPart > 0) then
            self._Options = nil
            self._Janitor:Remove("DelayThread")
            self:Disable()
            self.Completed:Fire()
            return
        end
    end

    self._PartCache = NewCache
end

function HitQuery:_Active(Time)
    assert(not self._Destroyed, "Hitbox is destroyed")

    self._CurrentThread = coroutine.running()
    self._t = os.clock()

    self._Janitor:Add(
        RunService.Heartbeat:Connect(function()
            if self:_Delay() then return end
            self._t = os.clock()
            self:_Enabled()
        end), nil, "Update"
    )

    if Time ~= -1 then
        self._Janitor:Add(
            task.delay(Time, function()
                if self._Options == "Wait" and self._CurrentThread then
                    self._Options = nil
                    task.spawn(self._CurrentThread :: thread)
                end

                self:Disable()
                self.Completed:Fire()
            end) :: thread, nil, "DelayThread"
        )
    end

    if self._Options == "Wait" then
        return coroutine.yield()
    end
end

function HitQuery:_SetState(NewState, ...)
    if self.State == NewState then return end

    self:_OnExit(self.State, ...)
    
    self.State = NewState

    self:_OnEnter(NewState, ...)
end

function HitQuery:_OnEnter(state, Time)
    if state == State.Active then
        self:_Active(Time)
    elseif state == State.OnCooldown then
        self._Janitor:Add(
            task.delay(Time, function()
                self:_SetState(State.Inactive)             
            end), nil, "CooldownThread"
        )
    end
end

function HitQuery:_OnExit(state)
    if state == State.Active then
        self._Janitor:Remove("Update")

        table.clear(self._PartCache :: { BasePart })
    elseif state == State.OnCooldown then
        self._Janitor:Remove("CooldownThread")
    end
end

function HitQuery:Cooldown(Time)
    assert(Time, "A number must be specified.")

    self:_SetState(State.OnCooldown, Time)
end

function HitQuery:Once()
    self._Options = "Once"
    self:Enable(-1)
end

function HitQuery:Wait()
    self._Options = "Wait"
    self:Enable(-1)
end

--[[Enable. Turns on the hitbox changing its current state to Active.

    ==============

    Hitbox:Enable(5)

    ==============

    Hitbox.Option = "Once" -- Disables the hitbox after ANY SINGLE ENCOUNTER
    Hitbox:Enable(5)

    ==============
    
    Htibox:Enable(-1) -- Runs FOREVER until disabled.

    ==============
]]
function HitQuery:Enable(Time)
    if self.State == State.OnCooldown or self.State == State.Active then return end

    self:_SetState(State.Active, Time)
end

--[[Disable. Turns off the hitbox changing its current state to Inactive.
        
    Hitbox:Disable()
]]
function HitQuery:Disable()
    self:_SetState(State.Inactive)
end

--[[Destroy. Terminates the hitbox objects and cleans up any threads, connections, or signals that are currently active.
    
    Hitbox:Destroy()
]]
function HitQuery:Destroy()
    if self._Destroyed then return end
    self._Destroyed = true

    self:Disable()
    self._Janitor:Destroy()

    setmetatable(self, nil)
end

return HitQuery
