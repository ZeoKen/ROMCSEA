EquipMemoryProxy = class("EquipMemoryProxy", pm.Proxy)
EquipMemoryProxy.Instance = nil
EquipMemoryProxy.NAME = "EquipMemoryProxy"
autoImport("EquipMemoryData")
EquipMemoryProxy.SortValue = {
  attack = 1,
  defence = 2,
  special = 3
}

function EquipMemoryProxy:ctor(proxyName, data)
  self.proxyName = proxyName or EquipMemoryProxy.NAME
  if EquipMemoryProxy.Instance == nil then
    EquipMemoryProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function EquipMemoryProxy:Init()
  self.equipPosData = {}
end

function EquipMemoryProxy:RecvUpdateMemoryPosItemCmd(data)
  xdlog("装备部位属性同步")
  local pos = data.pos
  TableUtility.TableClear(self.equipPosData)
  if pos and 0 < #pos then
    for i = 1, #pos do
      local single = pos[i]
      local _equipPos = single.pos
      local itemid = single.memory.itemid
      if itemid and itemid ~= 0 then
        local memoryData = EquipMemoryData.new(_equipPos)
        memoryData:SetMyServerData(single.memory)
        self.equipPosData[_equipPos] = memoryData
      end
      xdlog("装备在身上的记忆", _equipPos, single.memory.itemid, single.memory.lv)
    end
  end
end

function EquipMemoryProxy:GetTotalEquipMemoryLevels()
  local memoryLevels = {}
  for _pos, _memoryData in pairs(self.equipPosData) do
    local roleEquip = BagProxy.Instance:GetEquipBySite(_pos)
    local attrs = _memoryData.memoryAttrs or {}
    if roleEquip then
      for i = 1, #attrs do
        local attrid = attrs[i].id
        if not memoryLevels[attrid] then
          memoryLevels[attrid] = 1
        else
          memoryLevels[attrid] = memoryLevels[attrid] + 1
        end
      end
    end
  end
  return memoryLevels
end

function EquipMemoryProxy:GetPosData(pos)
  if self.equipPosData and self.equipPosData[pos] then
    return self.equipPosData[pos]
  end
end
