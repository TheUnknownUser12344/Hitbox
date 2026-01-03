local RunService = game:GetService("RunService")

--Hitbox Utilizing Roblox's Spatial Query Methods

local GoodSignal = require(script.GoodSignal)
local Janitor = require(script.janitor)
local State = require(script.State)

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Parts)
    local self = setmetatable({
        Parts = Parts,
        OverlapParams = nil,
        State = State.Inactive,

        PartEntered = GoodSignal.new(),
        PlayerEntered = GoodSignal.new(),
        Completed = GoodSignal.new(),

        FrameRate = "Unlimited",
        Options = nil,

        _PartCache = {},
        _Heartbeat = nil,
        _Janitor = Janitor.new(),
        _Destroyed = false,
    }, Hitbox)

    -- Register signals for cleanup
    self._Janitor:Add(self.PartEntered, "DisconnectAll")
    self._Janitor:Add(self.PlayerEntered, "DisconnectAll")
    self._Janitor:Add(self.Completed, "DisconnectAll")

    return self
end

function Hitbox:_Identify(Part, Class)
    return Part.Parent ~= workspace and Part.Parent.ClassName == Class or Part.ClassName == Class
end

function Hitbox:_Delay()
    return self.FrameRate ~= "Unlimited" and os.clock() - self._t < 1 / self.FrameRate
end

function Hitbox:_Enabled()
    local NewCache = {}

    for _, Part in self.Parts do
        local PartsInPart = workspace:GetPartsInPart(Part, self.OverlapParams)

        for _, FoundPart in PartsInPart do
            -- Get Parent Of Part
            local Parent = FoundPart.Parent ~= workspace and FoundPart.Parent or FoundPart

            NewCache[FoundPart] = true
            -- Dont Fire If Its In The Cache
            if self._PartCache[FoundPart] then continue end

            self.PartEntered:Fire(FoundPart)

            if Hitbox:_Identify(FoundPart, "Model") then
                local Humanoid = Parent:FindFirstChildOfClass("Humanoid")

                if not Humanoid then continue end

                -- Its A Character

                self.PlayerEntered:Fire(Parent, FoundPart)
            end
        end

        -- Check Options

        if self.Options == "Wait" and self._CurrentThread and #PartsInPart > 0 then
            task.spawn(self._CurrentThread)
        end

        if (self.Options == "Once" or self.Options == "Wait") and #PartsInPart > 0 then
            self._Janitor:Remove("DelayThread")
            self:Disable()
            self.Completed:Fire()
            return
        end
    end

    self._PartCache = NewCache
end

function Hitbox:_SetState(NewState, ...)
    if self.State == NewState then return end

    self:_OnExit(self.State, ...)
    
    self.State = NewState

    self:_OnEnter(NewState, ...)
end

function Hitbox:_OnEnter(state, Time)
    if state == State.Active then
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

        if Time == -1 then return end

        self._Janitor:Add(
            task.delay(Time, function()
                if self.Options == "Wait" and self._CurrentThread then
                    task.spawn(self._CurrentThread)
                end

                self:Disable()
                self.Completed:Fire()
            end), nil, "DelayThread"
        )

        if self.Options == "Wait" then
            return coroutine.yield()
        end
    elseif state == State.OnCooldown then
        self._Janitor:Add(
            task.delay(Time, function()
                self:_SetState(State.Inactive)                
            end), nil, "CooldownThread"
        )
    end
end

function Hitbox:_OnExit(state)
    if state == State.Active then
        self._Janitor:Remove("Update")

        table.clear(self._PartCache)
    elseif state == State.OnCooldown then
        self._Janitor:Remove("CooldownThread")
    end
end

function Hitbox:Cooldown(Time)
    assert(Time, "A number must be specified.")

    self:_SetState(State.OnCooldown, Time)
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
function Hitbox:Enable(Time)
    if self.State == State.OnCooldown then return end

    self:_SetState(State.Active, Time)
end

--[[Disable. Turns off the hitbox changing its current state to Inactive.
        
    Hitbox:Disable()
]]
function Hitbox:Disable()
    self:_SetState(State.Inactive)
end

--[[Destroy. Terminates the hitbox objects and cleans up any threads, connections, or signals that are currently active.
    
    Hitbox:Destroy()
]]
function Hitbox:Destroy()
    if self._Destroyed then return end
    self._Destroyed = true

    self:Disable()
    self._Janitor:Destroy()

    setmetatable(self, nil)
end

return Hitbox
