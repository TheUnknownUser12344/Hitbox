local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.Hitbox)

local hitbox = Hitbox.new({workspace.Test1})

hitbox.PartEntered:Connect(function(part)
   print(part)
   print(hitbox.State)
end)

hitbox:Enable(3)