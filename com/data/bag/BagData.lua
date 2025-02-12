autoImport("ItemData")
autoImport("BagTabData")
autoImport("BagMainTab")
BagData = class("BagData")

function BagData:ctor(tabs, tabClass, type)
  self.uplimit = 0
  self.tabs = {}
  self.itemMapTab = {}
  self.type = type
  self.wholeTab = BagMainTab.new()
  tabClass = tabClass or BagTabData
  if tabs ~= nil then
    for i = 1, #tabs do
      local class = tabs[i].class or tabClass
      local tabData = class.new(tabs[i].data)
      self.tabs[tabs[i].data] = tabData
      local types = tabs[i].data.types
      for j = 1, #types do
        self.itemMapTab[types[j]] = tabData
      end
    end
  end
end

function BagData:AddItems(items, tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      tab:AddItems(items)
    end
  end
  self.wholeTab:AddItems(items)
  BagProxy.Instance:RefreshUpgradeCheckInfo(self)
end

function BagData:AddItem(item)
  local tab = self.itemMapTab[item.staticData.Type]
  if tab ~= nil then
    tab:AddItem(item)
  end
  self.wholeTab:AddItem(item)
end

function BagData:RemoveItems(items, recordMap)
  for i = 1, #items do
    recordMap[items[i].base.guid] = 1
    self:RemoveItemByGuid(items[i].base.guid)
  end
end

function BagData:RemoveItemsByGuid(itemIds)
  for i = 1, #itemIds do
    self:RemoveItemByGuid(itemIds[i])
  end
  BagProxy.Instance:RefreshUpgradeCheckInfo(self)
end

function BagData:RemoveItemByGuid(itemId)
  local item = self:GetItemByGuid(itemId)
  if item ~= nil then
    self.wholeTab:RemoveItemByGuid(itemId)
    local tab = self.itemMapTab[item.staticData.Type]
    if tab ~= nil then
      tab:RemoveItemByGuid(itemId)
    end
  end
end

function BagData:UpdateItems(serverItems, recordMap)
  for i = 1, #serverItems do
    local sItem = serverItems[i]
    local sItemData = sItem.base
    local item = self:GetItemByGuid(sItemData.guid)
    if sItemData.index == self.wholeTab.holdPlaceData.index and sItemData.id ~= 0 then
      self.wholeTab:ClearPlaceHolder()
    end
    if item ~= nil then
      self:UpdateTab(item, sItem.base.count)
      self:UpdateItem(item, sItem)
    else
      item = ItemData.new(sItemData.guid, sItemData.id)
      self:UpdateItem(item, sItem)
      if item.staticData ~= nil then
        self:AddItem(item)
      elseif sItemData.id ~= 0 then
        redlog("未找到物品配置" .. sItemData.id)
      else
        self.wholeTab:ResetPlaceHolder(sItemData)
      end
    end
    recordMap[item.id] = 1
  end
  BagProxy.Instance:RefreshUpgradeCheckInfo(self)
end

function BagData:UpdateTab(item, count)
  local tab = self.itemMapTab[item.staticData.Type]
  if nil ~= tab then
    tab:Update_StaticIdNum(item, count)
  end
  self.wholeTab:Update_StaticIdNum(item, count)
end

function BagData:UpdateItem(item, serverItem)
  local sItemData = serverItem.base
  item = item or self:GetItemByGuid(sItemData.guid)
  if item ~= nil then
    if sItemData.index ~= item.index then
      self.wholeTab:SetDirty(true)
    end
    item:ParseFromServerData(serverItem)
    item.isactive = sItemData.isactive
    if item.isactive then
      self.activeItemId = item.id
    elseif self.activeItemId == item.id then
      self.activeItemId = nil
    end
  end
end

function BagData:GetActiveItem()
  if self.activeItemId then
    local item = self:GetItemByGuid(self.activeItemId)
    if not item then
      self.activeItemId = nil
    end
    return item
  end
end

function BagData:Reset()
  self.wholeTab:Reset()
  for k, v in pairs(self.tabs) do
    v:Reset()
  end
end

function BagData:GetTab(tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab
    end
  end
  return self.wholeTab
end

function BagData:GetItems(tabType)
  if tabType ~= nil then
    for k, v in pairs(self.tabs) do
      if k.name == tabType.name then
        return v:GetItems()
      end
    end
  end
  return self.wholeTab:GetItems()
end

function BagData:GetItemsWithoutNoPile(tabType)
  if tabType ~= nil then
    local tab = self.tabs[tabType]
    if tab ~= nil then
      return tab:GetItemsWithoutNoPile()
    end
  end
  return self.wholeTab:GetItemsWithoutNoPile()
end

function BagData:GetItemByGuid(guid)
  return self.wholeTab:GetItemByGuid(guid)
end

function BagData:SetUplimit(limit)
  if type(limit) == "number" then
    self.uplimit = limit
  end
end

function BagData:GetUplimit()
  return self.uplimit
end

function BagData:GetVirtualUplimit()
  local noPileSlotNum = self:GetNoPileSlotItemNum()
  return self:GetUplimit() + noPileSlotNum
end

function BagData:GetSpaceItemNum()
  local items = self:GetItems()
  local result = 0
  if items then
    local virtualUplimit = self:GetVirtualUplimit()
    result = math.max(0, virtualUplimit - #items)
  end
  return result
end

function BagData:IsFull()
  if self.uplimit == 0 then
    return false
  end
  return 0 >= self:GetSpaceItemNum()
end

function BagData:GetItemFreeSpaceByStaticId(itemid)
  local items = self.wholeTab:GetItemsByStaticID(itemid)
  local freeSpace = 0
  local maxnum = 1
  local itemData = Table_Item[itemid]
  local typeData = Table_ItemType[itemData.Type]
  maxnum = typeData and typeData.UseNumber
  if maxnum == nil then
    maxnum = Table_Item[itemid].MaxNum or 1
  end
  if items then
    for _, item in pairs(items) do
      local itemnum = math.max(item.num, 1)
      if maxnum > itemnum then
        freeSpace = freeSpace + (maxnum - itemnum)
      end
    end
  end
  local spaceItemNum = self:GetSpaceItemNum()
  return freeSpace + maxnum * spaceItemNum
end

function BagData:GetNoPileSlotItemNum()
  local num = 0
  local items = self:GetItems()
  for i = 1, #items do
    local item = items[i]
    if item:IsNoPileSlot() then
      num = num + 1
    end
  end
  return num
end
