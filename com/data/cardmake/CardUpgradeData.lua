autoImport("CardUpgradeMaterialData")
CardUpgradeData = class("CardUpgradeData")

function CardUpgradeData:ctor(bagItemData)
  self:SetData(bagItemData)
end

function CardUpgradeData:SetData(bagItemData)
  self.guid = bagItemData.id
  self.itemData = bagItemData
  self.levelConfigs = Game.CardUpgradeMap and Game.CardUpgradeMap[self.itemData.staticData.id]
  self.materials = {}
end

function CardUpgradeData:IsLocked()
  return self.itemData.num <= 0
end

function CardUpgradeData:GetNextLvMaterials()
  if not self.levelConfigs then
    return
  end
  TableUtility.ArrayClear(self.materials)
  local curLv = self.itemData.cardLv or 0
  local nextLv = curLv + 1
  local zeny = 0
  local myZeny = MyselfProxy.Instance:GetROB()
  local isLack = false
  local cfg = self.levelConfigs[nextLv]
  if cfg then
    local packageCheck = GameConfig.PackageMaterialCheck.cardupgrade
    for i = 1, #cfg.Cost do
      local cost = cfg.Cost[i]
      if cost[1] ~= GameConfig.MoneyId.Zeny then
        local data = CardUpgradeMaterialData.new(cost)
        TableUtility.ArrayPushBack(self.materials, data)
        local bagNum = CardMakeProxy.Instance:GetItemNumAsMaterial(cost[1], packageCheck)
        if bagNum < cost[2] then
          isLack = true
        end
      else
        zeny = zeny + cost[2]
      end
    end
    isLack = isLack or myZeny < zeny
  end
  return self.materials, zeny, isLack
end

local ItemTipDefaultUiIconPrefix = "{uiicon=new-com_icon_tips}"

function CardUpgradeData:GetAttrs(level)
  if not self.levelConfigs then
    return
  end
  local cfg = self.levelConfigs[level]
  if not cfg then
    return
  end
  local attrs = {}
  local desc = cfg.Desc
  if desc then
    local bufferStrs = string.split(desc, "\n")
    for i = 1, #bufferStrs do
      table.insert(attrs, ItemTipDefaultUiIconPrefix .. bufferStrs[i])
    end
  end
  return attrs
end
