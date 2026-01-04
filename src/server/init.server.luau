local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.HitQuery)

local hitbox = Hitbox.new({workspace.Test1})

hitbox.PartEntered:Connect(function(part)
   print(part)
   print(hitbox.State)
end)

hitbox:Wait()

print("wojkaspd")