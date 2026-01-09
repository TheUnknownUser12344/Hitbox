local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.HitQuery)

local hitbox = Hitbox.new({workspace.Test1})

-- hitbox.PlayerEntered:Connect(function(Player)
-- 	-- print(Player)
--    print(hitbox.State)
-- end)

hitbox.FrameRate = 10

hitbox:Enable(-1)

print("wojkaspd")