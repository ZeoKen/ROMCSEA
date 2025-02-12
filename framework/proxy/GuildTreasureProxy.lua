GuildTreasureProxy = class("GuildTreasureProxy", pm.Proxy)
GuildTreasureProxy.Instance = nil
GuildTreasureProxy.NAME = "GuildTreasureProxy"
autoImport("GuildTreasureData")
autoImport("TreasureResultData")
local actionCsv = {
  showBox = "state1001",
  openBox = "state2001",
  disappear = "state3001"
}
GuildTreasureProxy.ActionType = {
  GVG_FRAME_ON = GuildCmd_pb.ETREASUREACTION_GVG_FRAME_ON,
  GUILD_FRAME_ON = GuildCmd_pb.ETREASUREACTION_GUILD_FRAME_ON,
  FRAME_OFF = GuildCmd_pb.ETREASUREACTION_FRAME_OFF,
  LEFT = GuildCmd_pb.ETREASUREACTION_LEFT,
  RIGHT = GuildCmd_pb.ETREASUREACTION_RIGHT,
  OPEN_GVG = GuildCmd_pb.ETREASUREACTION_OPEN_GVG,
  OPEN_GUILD = GuildCmd_pb.ETREASUREACTION_OPEN_GUILD,
  UPDATE = GuildCmd_pb.ETREASUREACTION_UPDATE
}
GuildTreasureProxy.ViewType = {
  HoldTreasure = 1,
  GuildTreasure = 2,
  TreasurePreview = 3
}

function GuildTreasureProxy:ctor(proxyName, data)
  self.proxyName = proxyName or GuildTreasureProxy.NAME
  if GuildTreasureProxy.Instance == nil then
    GuildTreasureProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function GuildTreasureProxy:SetViewType(t)
  self.viewType = t
  if t == GuildTreasureProxy.ViewType.TreasurePreview then
    self:InitPreviewData()
  end
end

function GuildTreasureProxy:Init()
  self.TreasureData = {}
  self.treasureResult = {}
end

function GuildTreasureProxy:GetViewType()
  return self.viewType
end

function GuildTreasureProxy:InitPreviewData()
  local myGuildData = GuildProxy.Instance.myGuildData
  if myGuildData and self.memberNum and self.memberNum == myGuildData.memberNum then
    return
  end
  self.memberNum = myGuildData.memberNum
  self.treasurePreviewData = {}
  for _, v in pairs(Table_Guild_Treasure) do
    local cell = GuildTreasureData.new(v.id)
    if v.Type == 4 then
      self.treasurePreviewData[#self.treasurePreviewData + 1] = cell
    end
  end
  table.sort(self.treasurePreviewData, function(l, r)
    return self:SortFunc(l, r)
  end)
end

function GuildTreasureProxy:ShowGuildTreasurePanel(data)
  if data.action == GuildTreasureProxy.ActionType.GVG_FRAME_ON or data.action == GuildTreasureProxy.ActionType.GUILD_FRAME_ON then
    helplog("ShowGuildTreasurePanel data.action ： ", data.action)
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.GuildTreasureView
    })
  end
end

function GuildTreasureProxy:SetTreasure(serviceData)
  local data = GuildTreasureData.new(serviceData.treasure.id, serviceData.treasure.count)
  data:SetTreasureCount(serviceData.guild_treasure_count, serviceData.bcoin_treasure_count)
  if serviceData.action == GuildTreasureProxy.ActionType.GVG_FRAME_ON then
    self:SetViewType(1)
  elseif serviceData.action == GuildTreasureProxy.ActionType.GUILD_FRAME_ON then
    self:SetViewType(2)
  end
  if serviceData.point then
    self.arrowPos = serviceData.point
  end
  self.TreasureData = data
end

function GuildTreasureProxy:HasGuildHoldTreasure()
  local myGuildData = GuildProxy.Instance.myGuildData
  if myGuildData == nil then
    return false
  end
  return myGuildData.gvg_treasure_count == 1
end

function GuildTreasureProxy:GetGuildTreasureCount()
  local myGuildData = GuildProxy.Instance.myGuildData
  if myGuildData == nil then
    return 0
  end
  return myGuildData.treasureCount
end

function GuildTreasureProxy:GetTreasureData()
  return self.TreasureData
end

function GuildTreasureProxy:GetPreviewIndex(data)
  local length = #self.treasurePreviewData
  local index = TableUtility.ArrayFindIndex(self.treasurePreviewData, data)
  if length == 1 then
    return 0
  elseif index == length then
    return 1
  elseif index == 1 then
    return 2
  else
    return 3
  end
end

function GuildTreasureProxy:SortFunc(left, right)
  return left.staticData.Order < right.staticData.Order
end

local tempV3 = LuaVector3()
local tempRot = LuaQuaternion()

function GuildTreasureProxy:LoadNpc(boxDisappear)
  if self.viewType ~= GuildTreasureProxy.ViewType.TreasurePreview then
    if not self.TreasureData or not self.TreasureData.staticData then
      return
    end
    self:SetNpcId(self.TreasureData.staticData.NPC)
  end
  if not self.npcId then
    return
  end
  local parts = Asset_RoleUtility.CreateNpcRoleParts(self.npcId)
  if self.npcModel then
    if boxDisappear then
      self:_playAction(actionCsv.disappear)
    end
    local delayTime = boxDisappear and 1 or 0
    self:ClearLt()
    self.lt = TimeTickManager.Me():CreateOnceDelayTick(delayTime * 1000, function(owner, deltaTime)
      self.npcModel:Redress(parts)
      self:_playAction(actionCsv.showBox)
    end, self)
  else
    self.npcModel = Asset_Role.Create(parts)
    self.npcModel:SetPosition(GameConfig.GuildTreasure.Treasure_pos)
    self.npcModel:SetScale(2)
    local rotationCsv = GameConfig.GuildTreasure.Treasure_dir
    tempV3[2] = rotationCsv
    LuaQuaternion.Better_SetEulerAngles(tempRot, tempV3)
    self.npcModel:SetRotation(tempRot)
    self:_playAction(actionCsv.showBox)
  end
  self.npcModel:RegisterWeakObserver(self)
end

function GuildTreasureProxy:SetNpcId(id)
  self.npcId = id
end

function GuildTreasureProxy:GetTreasureNpcId()
  return GameConfig.GuildTreasure.NpcId or 7861
end

function GuildTreasureProxy:GetNpcModel()
  return self.npcModel
end

function GuildTreasureProxy:ExitUI()
  self:DestroyModel()
  self:ClearLt()
  self.viewType = nil
end

function GuildTreasureProxy:_playAction(actionName)
  local actionParam = Asset_Role.GetPlayActionParams(actionName, nil, 1)
  actionParam[6] = true
  if self.npcModel then
    self.npcModel:PlayActionRaw(actionParam)
  end
end

function GuildTreasureProxy:ObserverDestroyed(obj)
  if obj == self.npcModel then
    self.npcModel = nil
  end
end

function GuildTreasureProxy:PlayOpenBox(serviceData, isMyself)
  if serviceData.action == GuildTreasureProxy.ActionType.UPDATE then
    return
  end
  if serviceData.treasure and serviceData.treasure.id == 0 then
    if isMyself then
      self:_playAction(actionCsv.openBox)
    else
      self:ExitUI()
    end
    return
  end
  if serviceData.action == GuildTreasureProxy.ActionType.OPEN_GVG or serviceData.action == GuildTreasureProxy.ActionType.OPEN_GUILD then
    self:_playAction(actionCsv.openBox)
    self:ClearLt()
    self.lt = TimeTickManager.Me():CreateOnceDelayTick(1000, function(owner, deltaTime)
      self:LoadNpc(true)
    end, self)
  else
    self:LoadNpc()
  end
end

function GuildTreasureProxy:SetTreasureResult(result)
  TableUtility.ArrayClear(self.treasureResult)
  self.treasureResult = TreasureResultData.new()
  self.treasureResult:Server_SetData(result)
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.GuildTreasureRewardPopUp
  })
end

function GuildTreasureProxy:GetTreasureResult()
  return self.treasureResult
end

function GuildTreasureProxy:GetTreasureMaxCharID()
  if self.treasureResult then
    local items = self.treasureResult.treasureItems
    local maxCount = 0
    local maxCharID
    for k, v in pairs(items) do
      local ItemData = v.ItemData
      if ItemData and 0 < #ItemData and maxCount < ItemData[1].num then
        maxCount = ItemData[1].num
        maxCharID = v.charid
      end
    end
    return maxCharID
  end
end

function GuildTreasureProxy:DestroyModel()
  if self.npcModel then
    self.npcModel:Destroy()
    self.npcModel = nil
  end
end

function GuildTreasureProxy:ClearLt()
  if self.lt then
    self.lt:Destroy()
    self.lt = nil
  end
end
