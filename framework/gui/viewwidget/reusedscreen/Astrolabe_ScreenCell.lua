autoImport("EventDispatcher")
Astrolabe_ScreenCell = class("Astrolabe_ScreenCell", EventDispatcher)

function Astrolabe_ScreenCell:ctor(center, size, row, col)
  self.center = LuaVector3(center[1], center[2], center[3])
  self.size = size
  self.row = row
  self.col = col
  self.pointDataMap = {}
  self.bgDataMap = {}
end

function Astrolabe_ScreenCell:Contains(v2)
  local c1, c2 = self.center[1], self.center[2]
  local s1, s2 = self.size[1] / 2, self.size[2] / 2
  local r1, r2, r3, r4 = c1 + s1, c2 + s2, c1 - s1, c2 - s2
  return r1 >= v2[1] and r2 >= v2[2] and r3 <= v2[1] and r4 <= v2[2]
end

function Astrolabe_ScreenCell:AddPointData(id, pointData)
  self.pointDataMap[id] = pointData
end

function Astrolabe_ScreenCell:RemovePointData(id)
  self.pointDataMap[id] = nil
end

function Astrolabe_ScreenCell:GetPointDataMap()
  return self.pointDataMap
end

function Astrolabe_ScreenCell:AddBgData(id, bgData)
  self.bgDataMap[id] = bgData
end

function Astrolabe_ScreenCell:RemoveBgData(id)
  self.bgDataMap[id] = nil
end

function Astrolabe_ScreenCell:GetBgDataMap()
  return self.bgDataMap
end

function Astrolabe_ScreenCell:ResetCenter(x, y, z)
  LuaVector3.Better_Set(self.center, x, y, z)
end

function Astrolabe_ScreenCell:ResetScreenPos(row, col)
  self.row = row
  self.col = col
end
