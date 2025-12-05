-- Created by Navillion
-- Usage: Put this into a script and parent it under the model that you want to weld

local parts = script.Parent
local objects = {}

-- Find parts to weld
for i,v in pairs(parts:GetDescendants()) do
  if v:IsA("BasePart") then
    v.Anchored = true
    v:BreakJoints()
    table.insert(objects, v)
  end
end

-- Sort objects by position
local key = function(a, b)
  return a.Position.Z < b.Position.Z
end

table.sort(objects, key)

-- Weld parts with WeldConstraints
for i, part in pairs(objects) do
  if i == #objects then
    continue
  end

  -- Create weld and weld to the next highest part
  local WeldConstraint = Instance.new("WeldConstraint", part)
  WeldConstraint.Part0 = part
  WeldConstraint.Part1 = objects[i+1]	
end
