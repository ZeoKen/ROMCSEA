UITableListCtrl = class("UITableListCtrl")

function UITableListCtrl:ctor(tableObj, poolName, sort)
  self.table = tableObj:GetComponent(ROUITable)
  self.panel = Game.GameObjectUtil:FindCompInParents(tableObj, UIPanel)
  self.scrollView = self.panel.gameObject:GetComponent(UIScrollView)
  if sort == nil then
    sort = 1
  end
  self:SortList(sort)
  self.poolName = poolName
  self.type = {}
  self.cells = {}
  self.datas = {}
  self.events = {}
  self.lastDatasCount = 0
  self:GetTablePos()
  
  function self.table.onInitializeItem(realI)
    local index = realI + 1
    local cellCtrl = self:AddCell(self.datas[index])
    cellCtrl.gameObject.name = index
    return cellCtrl.gameObject
  end
  
  function self.table.onRemoveItem(obj)
    self:RemoveCellByObj(obj)
  end
end

function UITableListCtrl:SetType(config)
  local data = {
    cellType = config.cellType,
    cellName = config.cellName,
    control = config.control
  }
  self.type[data.cellType] = data
end

function UITableListCtrl:AddCell(data)
  local config = self.type[data:GetCellType()]
  local cellCtrl
  if config.control.CreateAsTable then
    config.parent = self.table.gameObject
    cellCtrl = config.control.CreateAsTable(config)
  else
    local cellGo = self:LoadCellPfb(config.cellName)
    cellCtrl = config.control.new(cellGo)
  end
  cellCtrl.name = config.cellName
  for i = 1, #self.events do
    cellCtrl:AddEventListener(self.events[i].eventType, self.events[i].handler, self.events[i].handlerOwner)
  end
  table.insert(self.cells, cellCtrl)
  if data then
    cellCtrl:SetData(data)
  end
  return cellCtrl
end

function UITableListCtrl:LoadCellPfb(cName)
  local cellpfb = self:CreateAsset(ResourcePathHelper.UICell(cName))
  if cellpfb == nil then
    error("can not find cellpfb" .. cName)
  end
  cellpfb.transform:SetParent(self.table.transform, false)
  cellpfb.transform.localScale = LuaGeometry.GetTempVector3(1, 1, 1)
  return cellpfb
end

local offset = LuaVector3.Zero()
local tempOffset = LuaVector3.Zero()

function UITableListCtrl:UpdateInfo(datas, isLock)
  if not self.table.gameObject.activeInHierarchy then
    return
  end
  local newNum = #datas
  local delta = newNum - self.lastDatasCount
  LuaVector3.Better_Set(offset, 0, 0, 0)
  self:RemoveAll()
  self.datas = datas
  self.lastDatasCount = newNum
  if not isLock then
    for i = 1, newNum do
      if self.table:IsTableInPanel() then
        local cellCtrl = self:AddCell(datas[i])
        cellCtrl.gameObject.name = i
      else
        break
      end
    end
    self.table:SetShowIndex(newNum - 1)
    self.table:Reposition()
  else
    if delta == 0 then
      delta = 1
    end
    for i = 1, delta do
      if self.table:IsTableInPanel() then
        local cellCtrl = self:AddCell(datas[i])
        cellCtrl.gameObject.name = i
        local bound = NGUIMath.CalculateRelativeWidgetBounds(cellCtrl.gameObject.transform)
        LuaVector3.Better_Add(offset, bound.size, offset)
      else
        break
      end
    end
    local offsetPos = 0
    if self.table.IsHorizontal then
      local x, y, z = LuaGameObject.GetLocalPosition(self.table.transform)
      local off = x - self.lastTablePos
      offsetPos = offset[1] + self.table.padding.x * delta * 2 - off
      self.lastTablePos = x + offsetPos
      LuaVector3.Better_Set(tempOffset, self.lastTablePos, y, z)
      self.table.transform.localPosition = tempOffset
    else
      local x, y, z = LuaGameObject.GetLocalPosition(self.table.transform)
      local off = y - self.lastTablePos
      offsetPos = offset[2] + self.table.padding.y * delta * 2 - off
      self.lastTablePos = y + offsetPos
      LuaVector3.Better_Set(tempOffset, x, self.lastTablePos, z)
      self.table.transform.localPosition = tempOffset
    end
    if offsetPos ~= 0 then
      self:RemoveAll()
      for i = 1, newNum do
        if self.table:IsTableInPanel() then
          local cellCtrl = self:AddCell(datas[i])
          cellCtrl.gameObject.name = i
        else
          break
        end
      end
      self.table:SetShowIndex(newNum - 1)
      self.table:Reposition()
    end
  end
end

function UITableListCtrl:RemoveAll()
  for i = 1, #self.cells do
    local cellCtrl = self.cells[i]
    cellCtrl:ClearEvent()
    cellCtrl.gameObject.name = cellCtrl.name
    if cellCtrl.CreateAsTable then
      ReusableObject.Destroy(cellCtrl)
    else
      self:AddToPool(ResourcePathHelper.UICell(cellCtrl.name), cellCtrl.gameObject)
    end
    cellCtrl = nil
  end
  TableUtility.ArrayClear(self.cells)
end

function UITableListCtrl:RemoveCell(index)
  if index <= #self.cells then
    local cellCtrl = table.remove(self.cells, index)
    cellCtrl:ClearEvent()
    if cellCtrl.CreateAsTable then
      ReusableObject.Destroy(cellCtrl)
    else
      self:AddToPool(ResourcePathHelper.UICell(cellCtrl.name), cellCtrl.gameObject)
    end
    cellCtrl = nil
  end
end

function UITableListCtrl:RemoveCellByObj(obj)
  local index = 0
  for i = 1, #self.cells do
    if self.cells[i].gameObject == obj then
      index = i
    end
  end
  if index ~= 0 then
    self:RemoveCell(index)
  end
end

function UITableListCtrl:SortList(sort)
  function self.table.onCustomSort(trans1, trans2)
    if tonumber(trans1.name) < tonumber(trans2.name) then
      return -1 * sort
    elseif tonumber(trans1.name) > tonumber(trans2.name) then
      return 1 * sort
    else
      return 0
    end
  end
end

function UITableListCtrl:AddEventListener(eventType, handler, handlerOwner)
  local data = {
    eventType = eventType,
    handler = handler,
    handlerOwner = handlerOwner
  }
  table.insert(self.events, data)
end

function UITableListCtrl:GetIsMoveToFirst()
  return self.table.mIsMoveToFirst
end

function UITableListCtrl:GetCells()
  return self.cells
end

function UITableListCtrl:CreateAsset(path, parent)
  return Game.AssetManager_UI:CreateAsset(path, parent)
end

function UITableListCtrl:AddToPool(path, go)
  Game.GOLuaPoolManager:AddToUIPool(path, go)
end

function UITableListCtrl:ResetPosition()
  self.scrollView:ResetPosition()
  self:GetTablePos()
end

function UITableListCtrl:GetTablePos()
  local x, y, z = LuaGameObject.GetLocalPosition(self.table.transform)
  if self.table.IsHorizontal then
    self.lastTablePos = x
  else
    self.lastTablePos = y
  end
end
