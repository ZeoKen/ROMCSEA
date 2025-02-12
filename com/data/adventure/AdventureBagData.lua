AdventureBagData = class("AdventureBagData")
autoImport("AdventureTab")
autoImport("AdventureItemData")
autoImport("Table_AdventureValue")

function AdventureBagData:ctor(tabClass, type)
  self.tabs = {}
  self.itemMapTab = {}
  self.type = type
  self.tableData = Table_ItemTypeAdventureLog[self.type]
  self.totalScore = 0
  self.totalCount = 0
  self.curUnlockCount = 0
  self.allScore = 0
  self.allCount = 0
  self.wholeTab = AdventureTab.new()
  self.wholeTab:setBagTypeData(self.type)
  self:initTabDatas()
end

function AdventureBagData:initTabDatas()
  local categorys = AdventureDataProxy.Instance:getTabsByCategory(self.type)
  if categorys and categorys.childs then
    for k, v in pairs(categorys.childs) do
      local tabData = AdventureTab.new(v.staticData)
      self.tabs[k] = tabData
      for i = 1, #v.types do
        self.itemMapTab[v.types[i]] = tabData
      end
    end
  end
  if self.type == SceneManual_pb.EMANUALTYPE_MONSTER then
    self.allCount = Table_AdventureValue.monster.monster.count
    self.allCount = self.allCount + Table_AdventureValue.monster.mvp.count
    self.allCount = self.allCount + Table_AdventureValue.monster.mini.count
  elseif self.type == SceneManual_pb.EMANUALTYPE_PET then
  elseif self.type == SceneManual_pb.EMANUALTYPE_MAP then
    self.allCount = Table_AdventureValue.map
  elseif self.type == SceneManual_pb.EMANUALTYPE_NPC then
    self.allCount = AdventureDataProxy.Instance.NpcCount
  elseif self.type == SceneManual_pb.EMANUALTYPE_FASHION then
    self.allCount = Table_AdventureValue.item.fashionClothes.count
  elseif self.type == SceneManual_pb.EMANUALTYPE_MOUNT then
    self.allCount = Table_AdventureValue.item.ride.count
  elseif self.type == SceneManual_pb.EMANUALTYPE_CARD then
    self.allCount = Table_AdventureValue.item.card.count
  elseif self.type == SceneManual_pb.EMANUALTYPE_SCENERY then
    self.allCount = Table_AdventureValue.viewSpot.count
  elseif self.type == SceneManual_pb.EMANUALTYPE_COLLECTION then
    self.allCount = Table_AdventureValue.monthlyVIP.count
  end
end

function AdventureBagData:AddItems(items, tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      tab:AddItems(items)
    end
  end
  self.wholeTab:AddItems(items)
end

function AdventureBagData:getTabByItemAndType(item, type)
  if item == nil or not item.staticData then
    return
  end
  local tab
  if type == SceneManual_pb.EMANUALTYPE_NPC or type == SceneManual_pb.EMANUALTYPE_MONSTER or type == SceneManual_pb.EMANUALTYPE_PRESTIGE then
    local mapData = item.staticData.ManualMap and Table_Map[item.staticData.ManualMap]
    local configData = mapData and mapData.Range and GameConfig.AdventureCategoryMapType[mapData.Range] or GameConfig.AdventureCategoryMapType.default
    tab = self.itemMapTab[configData[self.type]]
  elseif type == SceneManual_pb.EMANUALTYPE_PET then
    tab = self.itemMapTab[GameConfig.AdventureCategoryMonsterType[item.staticData.Type]]
  elseif type == SceneManual_pb.EMANUALTYPE_ACHIEVE then
  elseif type == SceneManual_pb.EMANUALTYPE_MAP then
  elseif type == SceneManual_pb.EMANUALTYPE_MATE then
    tab = self.itemMapTab[GameConfig.AdventureCategoryMonsterType.MercenaryCat]
  elseif type == SceneManual_pb.EMANUALTYPE_SCENERY then
    local mapData = Table_Map[item.staticData.MapName]
    if mapData then
      tab = self.itemMapTab[mapData.Range]
    end
  else
    tab = self.itemMapTab[item.staticData.Type]
  end
  if not tab then
  end
  return tab
end

function AdventureBagData:AddItem(item, type)
  local tab = self:getTabByItemAndType(item, type)
  if tab ~= nil then
    tab:AddItem(item)
    item.tabData = tab.tab
    tab.totalCount = tab.totalCount + 1
  end
  self.wholeTab:AddItem(item)
  if type == SceneManual_pb.EMANUALTYPE_MAP then
    AdventureDataProxy.Instance:NewMapAdd(item.staticId)
  end
  if item.status ~= SceneManual_pb.EMANUALSTATUS_DISPLAY and item.status ~= SceneManual_pb.EMANUALSTATUS_UNLOCK_CLIENT then
    self.totalScore = self.totalScore + item.AdventureValue
    self.curUnlockCount = self.curUnlockCount + 1
    if tab ~= nil then
      tab.curUnlockCount = tab.curUnlockCount + 1
      tab.totalScore = tab.totalScore + item.AdventureValue
    end
  end
  self.totalCount = self.totalCount + 1
end

function AdventureBagData:UpdateItems(manualData, type)
  local serverItems = manualData.items
  local updateSceneIds = {}
  for i = 1, #serverItems do
    local sItem = serverItems[i]
    local item = self:GetItemByStaticID(sItem.id)
    if item ~= nil then
      local oldStatus = item.status
      self:UpdateItem(item, sItem)
      local tab = self:getTabByItemAndType(item, type)
      if tab then
        tab:SetDirty()
        tab:RemoveCacheNum(sItem.id)
      end
      if oldStatus == SceneManual_pb.EMANUALSTATUS_UNLOCK_CLIENT and item.status ~= SceneManual_pb.EMANUALSTATUS_UNLOCK_CLIENT then
        self.totalScore = self.totalScore + item.AdventureValue
        self.curUnlockCount = self.curUnlockCount + 1
        if tab then
          tab.curUnlockCount = tab.curUnlockCount + 1
          tab.totalScore = tab.totalScore + item.AdventureValue
        end
      end
      if type == SceneManual_pb.EMANUALTYPE_SCENERY and oldStatus == SceneManual_pb.EMANUALSTATUS_DISPLAY and item.staticData.Type == 1 and item.status ~= SceneManual_pb.EMANUALSTATUS_DISPLAY then
        table.insert(updateSceneIds, item.staticId)
      end
    else
      item = AdventureItemData.new(sItem, type)
      self:UpdateItem(item, sItem)
      if item.staticData ~= nil then
        self:AddItem(item, type)
      end
    end
  end
  if 0 < #updateSceneIds then
    GameFacade.Instance:sendNotification(AdventureDataEvent.SceneItemsUpdate, updateSceneIds)
  end
end

function AdventureBagData:UpdateItem(item, serverItem)
  if item ~= nil then
    item:updateManualData(serverItem)
    self.wholeTab:SetDirty(true)
  end
end

function AdventureBagData:Reset()
  self.wholeTab:Reset()
  for k, v in pairs(self.tabs) do
    v:Reset()
  end
end

function AdventureBagData:GetTab(tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab
    end
  end
  return self.wholeTab
end

function AdventureBagData:GetItems(tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab:GetItems()
    end
  end
  return self.wholeTab:GetItems()
end

function AdventureBagData:GetItemsBySubID(tabType, subID)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab:GetItemsBySubID(subID)
    end
  end
  return self.wholeTab:GetItemsBySubID(subID)
end

function AdventureBagData:GetItemByStaticID(id)
  return self.wholeTab:GetItemByStaticID(id)
end

function AdventureBagData:IsEmpty(tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab:IsEmpty()
    end
  end
  return self.wholeTab:IsEmpty()
end

function AdventureBagData:GetUnlockNum()
  local items = self:GetItems()
  local count = 0
  if items and 0 < #items then
    for i = 1, #items do
      local item = items[i]
      if item.status ~= SceneManual_pb.EMANUALSTATUS_DISPLAY and item.status ~= SceneManual_pb.EMANUALSTATUS_UNLOCK_CLIENT then
        count = count + 1
      end
    end
  end
  return count
end

function AdventureBagData:GetValidItemNum(tabType)
  local num = 0
  local items = self:GetItems(tabType)
  if items then
    for i = 1, #items do
      if items[i]:IsValid() then
        num = num + 1
      end
    end
  end
  return num
end
