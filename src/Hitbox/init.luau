local RunService = game:GetService("RunService")

--Hitbox Utilizing Roblox's Spatial Query Methods

local GoodSignal = require(script.GoodSignal)
local Janitor = require(script.janitor)

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Parts)
    local self = setmetatable({
        Parts = Parts,
        OverlapParams = nil,

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
    for _, Part in self.Parts do
        local PartsInPart = workspace:GetPartsInPart(Part, self.OverlapParams)

        for _, FoundPart in PartsInPart do
            -- Get Parent Of Part
            local Parent = FoundPart.Parent ~= workspace and FoundPart.Parent or FoundPart

            -- Dont Fire If Its In The Cache
            if self._PartCache[Parent] then continue end

            self.PartEntered:Fire(FoundPart)

            if Hitbox:_Identify(FoundPart, "Model") then
                local Humanoid = Parent:FindFirstChildOfClass("Humanoid")

                if not Humanoid then continue end

                -- Its A Character

                self.PlayerEntered:Fire(Parent, FoundPart)
            end

            -- This Allows For Indexing Instead Of A Find Search
            self._PartCache[Parent] = true
        end

        -- Check Options

        if self.Options == "Wait" and self._CurrentThread and #PartsInPart > 0 then
            task.spawn(self._CurrentThread)
        end

        if (self.Options == "Once" or self.Options == "Wait") and #PartsInPart > 0 then
            
            task.cancel(self._DelayThread)
            self:Disable()
            self.Completed:Fire()
            return
        end
    end
end

function Hitbox:Enable(Time)
    assert(not self._Destroyed, "Hitbox is destroyed")

    self._CurrentThread = coroutine.running()
    self._t = os.clock()

    self._Heartbeat = self._Janitor:Add(
        RunService.Heartbeat:Connect(function()
            if self:_Delay() then return end
            self._t = os.clock()
            self:_Enabled()
        end)
    )

    if Time == -1 then return end

    self._DelayThread = self._Janitor:Add(
        task.delay(Time, function()
            if self.Options == "Wait" and self._CurrentThread then
                task.spawn(self._CurrentThread)
            end

            self:Disable()
            self.Completed:Fire()
        end)
    )

    if self.Options == "Wait" then
        return coroutine.yield()
    end
end

function Hitbox:Disable()
    if self._Heartbeat then
        self._Heartbeat:Disconnect()
        self._Heartbeat = nil
    end

    table.clear(self._PartCache)
end

function Hitbox:Destroy()
    if self._Destroyed then return end
    self._Destroyed = true

    self:Disable()
    self._Janitor:Destroy()

    setmetatable(self, nil)
end

return Hitbox
