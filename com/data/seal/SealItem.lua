SealItem = class("SealItem")

function SealItem:ctor(serverData, mapid)
  self:SetData(serverData, mapid)
end

function SealItem:SetData(serverData, mapid)
  if serverData then
    self.id = serverData.sealid
    self.mapid = mapid
    self.config = serverData.config
    self.refreshtime = serverData.refreshtime
    local pos = serverData.pos
    if not self.pos then
      self.pos = LuaVector3()
    end
    LuaVector3.Better_Set(self.pos, pos.x / 1000, pos.y / 1000, pos.z / 1000)
    self.ownseal = serverData.ownseal
    self.issealing = serverData.issealing
    self.etype = serverData.etype
    local updateStr = string.format("SealItem: |id:%s |mapid:%s |pos:Vector3(%s,%s,%s) |ownseal:%s |issealing:%s ", tostring(serverData.sealid), tostring(mapid), tostring(self.pos.x), tostring(self.pos.y), tostring(self.pos.z), tostring(serverData.ownseal), tostring(serverData.issealing))
  end
end

function SealItem:OnDestroy()
  if self.pos then
    self.pos:Destroy()
  end
  self.pos = nil
end
