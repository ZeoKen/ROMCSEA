local _ArrayFindIndex = TableUtility.ArrayFindIndex
local _ArrayClear = TableUtility.ArrayClear
local _HashToArray = TableUtil.HashToArray
autoImport("GuildTaskTraceData")
autoImport("GuildBuildingData")
autoImport("GuildingRankData")
GuildBuildingProxy = class("GuildBuildingProxy", pm.Proxy)
GuildBuildingProxy.Instance = nil
GuildBuildingProxy.NAME = "GuildBuildingProxy"
GuildBuildingProxy.Type = {
  EGUILDBUILDING_VENDING_MACHINE = GuildCmd_pb.EGUILDBUILDING_VENDING_MACHINE,
  EGUILDBUILDING_BAR = GuildCmd_pb.EGUILDBUILDING_BAR,
  EGUILDBUILDING_CAT_LITTER_BOX = GuildCmd_pb.EGUILDBUILDING_CAT_LITTER_BOX,
  EGUILDBUILDING_MAGIC_SEWING = GuildCmd_pb.EGUILDBUILDING_MAGIC_SEWING,
  EGUILDBUILDING_HIGH_REFINE = GuildCmd_pb.EGUILDBUILDING_HIGH_REFINE,
  EGUILDBUILDING_ARTIFACT_HEAD = GuildCmd_pb.EGUILDBUILDING_ARTIFACT_HEAD,
  EGUILDBUILDING_EGUILDBUILDING_CAT_PILLOW = GuildCmd_pb.EGUILDBUILDING_CAT_PILLOW,
  EGUILDBUILDING_EGUILDBUILDING_MATERIAL_MACHINE = GuildCmd_pb.EGUILDBUILDING_MATERIAL_MACHINE
}
GuildBuildingProxy.BuildAuth = {
  EBuildAuth_OnBuild = 1,
  EBuildAuth_OnCD = 2,
  EBuildAuth_Success = 3
}

function GuildBuildingProxy:ctor(proxyName, data)
  self.proxyName = proxyName or GuildBuildingProxy.NAME
  if GuildBuildingProxy.Instance == nil then
    GuildBuildingProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:ResetData()
end

function GuildBuildingProxy.GetGuildBuildingID(building_type, level)
  return building_type * 1000 + level
end

function GuildBuildingProxy:InitBuilding(nnpc, params)
  self.npc = nnpc
  self.params = params
end

function GuildBuildingProxy:GetNPC()
  return self.npc
end

function GuildBuildingProxy:GetBuildingType()
  return self.params
end

function GuildBuildingProxy:ResetData()
  self.buildDataList = {}
  self.BuildingData = {}
  self.shopBuildType = {}
  self.rankArray = {}
  self.traceTaskList = {}
  self:SetMaxLv()
end

function GuildBuildingProxy:SetMaxLv()
  self.maxLvMap = {}
  for k, v in pairs(Table_GuildBuilding) do
    local lv = self.maxLvMap[v.Type]
    if not lv then
      self.maxLvMap[v.Type] = v.Level
    else
      self.maxLvMap[v.Type] = math.max(lv, v.Level)
    end
  end
end

function GuildBuildingProxy:GetMaxLv(type)
  return self.maxLvMap[type] or 10
end

function GuildBuildingProxy:SetBuildingData(serviceData)
  self.buildingDataDirty = true
  for i = 1, #serviceData do
    local data = GuildBuildingData.new()
    data:SetData(serviceData[i])
    local valid = true
    if nil ~= Table_FuncState[4] and _ArrayFindIndex(Table_FuncState[4].NpcID, data.staticData.NpcID) > 0 then
      valid = FunctionUnLockFunc.checkFuncStateValid(4)
    end
    if valid then
      self.BuildingData[data.type] = data
    end
    if data.type == GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING then
      local static = self:CfgData(data.type, data.level)
      if static then
        local strength_pos = static.UnlockParam and static.UnlockParam.equip and static.UnlockParam.equip.strength_pos or nil
        if strength_pos then
          StrengthProxy.Instance:SetValidGuildStrengthSite(static.UnlockParam.equip.strength_pos)
        else
          redlog("公会建筑魔法缝纫机 未配置加固部位。建筑等级 : ", data.level)
        end
      end
    end
  end
end

function GuildBuildingProxy:HandleRecvBuildingTaskUpdate(server_data)
  if GuildProxy.Instance:IHaveGuild() then
    GuildProxy.Instance.myGuildData.challenge_task_list_dirty = true
  end
  _ArrayClear(self.traceTaskList)
  for i = 1, #server_data do
    local reward = server_data[i].reward
    local refresh_time = server_data[i].refreshtime
    local id = GuildBuildingProxy.GetGuildBuildingID(server_data[i].type, server_data[i].level)
    local traceTaskData = GuildTaskTraceData.new()
    traceTaskData:SetBuildingData(id, refresh_time, reward)
    self.traceTaskList[#self.traceTaskList + 1] = traceTaskData
  end
end

function GuildBuildingProxy:GetTaskTraceData()
  return self.traceTaskList
end

function GuildBuildingProxy:SetSubmitTimes(t)
  self.curSubmitTime = t
end

function GuildBuildingProxy:PlayBuildingLvupEff(effects)
  local sendTypes = {}
  for i = 1, #effects do
    local gType = effects[i].type
    local glevel = effects[i].level
    local buildingData = self:GetBuildingDataByType(gType)
    if buildingData and buildingData.staticData then
      local data = GuildCmd_pb.BuildingLvupEffect()
      local name = buildingData.staticData.Name
      local icon = buildingData.staticData.Icon
      self:_playEffect(icon, name, glevel)
      data.type = gType
      data.level = glevel
      sendTypes[#sendTypes + 1] = data
    end
  end
  if 0 < #sendTypes then
    ServiceGuildCmdProxy.Instance:CallBuildingLvupEffGuildCmd(sendTypes)
  end
end

function GuildBuildingProxy:PlayUpdateEffect()
  local myGuildMemberData = GuildProxy.Instance:GetMyGuildMemberData()
  if myGuildMemberData then
    local guildings = myGuildMemberData:GetBuildingLevelup()
    local sendTypes = {}
    for i = 1, #guildings do
      local gType = guildings[i].type
      local needPlay = guildings[i].levelupeffect
      if needPlay then
        local buildingData = self.BuildingData[gType]
        if buildingData and buildingData.staticData then
          local data = GuildCmd_pb.BuildingLvupEffect()
          local name = buildingData.staticData.Name
          local glevel = buildingData.staticData.Level
          local icon = buildingData.staticData.Icon
          self:_playEffect(icon, name, glevel)
          data.type = gType
          data.level = glevel
          sendTypes[#sendTypes + 1] = data
        end
      end
    end
    if 0 < #sendTypes then
      ServiceGuildCmdProxy.Instance:CallBuildingLvupEffGuildCmd(sendTypes)
    end
  end
end

function GuildBuildingProxy:_playEffect(icon, name, level)
  local data = {}
  data.icontype = 0
  data.icon = icon or "item_150"
  data.content = string.format(ZhString.GuildBuilding_TypeLevelUp, name, level)
  GameFacade.Instance:sendNotification(UIEvent.ShowUI, {
    viewname = "SystemUnLockView"
  })
  GameFacade.Instance:sendNotification(SystemUnLockEvent.CommonUnlockInfo, data)
end

function GuildBuildingProxy:GetMatData(type)
  local data = self:GetBuildingDataByType(type)
  if data then
    return data.uiMatData
  end
  return nil
end

function GuildBuildingProxy:HasAuthorization()
  if GuildProxy.Instance:CanIDoAuthority(GuildAuthorityMap.Guild) then
    return true
  end
  return false
end

function GuildBuildingProxy:GetTotalSubmitCount(type)
  if self.BuildingData[type] then
    local matData = self.BuildingData[type].uiMatData
    local num = 0
    for k, v in pairs(matData) do
      num = num + v.materials.count
    end
    return num
  end
end

function GuildBuildingProxy:GetBuildingDataByType(type)
  if self.BuildingData[type] then
    return self.BuildingData[type]
  end
  return nil
end

function GuildBuildingProxy:GetBuildingData()
  if self.buildingDataDirty then
    self.buildingDataDirty = false
    _ArrayClear(self.buildDataList)
    _HashToArray(self.BuildingData, self.buildDataList)
    table.sort(self.buildDataList, function(a, b)
      return a.staticData.sortid < b.staticData.sortid
    end)
  end
  return self.buildDataList
end

function GuildBuildingProxy:GetBuildingLevelByType(type)
  local buildData = self:GetBuildingDataByType(type)
  if buildData then
    return buildData.level
  end
  return nil
end

function GuildBuildingProxy:SortRankArray(a, b)
  if a.submitCountTotal == b.submitCountTotal then
    return a.submitTime < b.submitTime
  else
    return a.submitCountTotal > b.submitCountTotal
  end
end

function GuildBuildingProxy:SetBuildingRank(data)
  self:ClearRankArray()
  local myGuildData = GuildProxy.Instance.myGuildData
  local items = data.items
  for i = 1, #items do
    local data = GuildingRankData.new()
    local item = items[i]
    if myGuildData then
      local memberData = myGuildData:GetMemberByGuid(item.charid)
      if memberData then
        data:Server_SetData(item)
        self.rankArray[#self.rankArray + 1] = data
      end
    end
  end
  if not self.rankArray or #self.rankArray < 0 then
    return
  end
  table.sort(self.rankArray, function(l, r)
    return self:SortRankArray(l, r)
  end)
end

function GuildBuildingProxy:ClearRankArray()
  _ArrayClear(self.rankArray)
end

function GuildBuildingProxy:GetRankArray()
  return self.rankArray
end

function GuildBuildingProxy:GetCurBuilding()
  for k, v in pairs(self.BuildingData) do
    if v.isbuilding then
      return v
    end
  end
  return nil
end

function GuildBuildingProxy:GetBuildAuth()
  for k, v in pairs(self.BuildingData) do
    if v.isbuilding then
      return GuildBuildingProxy.BuildAuth.EBuildAuth_OnBuild
    end
    if not v:CanBuildByTime() then
      return GuildBuildingProxy.BuildAuth.EBuildAuth_OnCD
    end
  end
  return GuildBuildingProxy.BuildAuth.EBuildAuth_Success
end

function GuildBuildingProxy:_getBuildingTypeByShopType(t)
  for k, v in pairs(Table_GuildBuilding) do
    if v.UnlockParam and v.UnlockParam.shoptype and v.UnlockParam.shoptype == t then
      self.shopBuildType[t] = v.Type
      return v.Type
    end
  end
  return nil
end

function GuildBuildingProxy:ShopGoodsLocked(shopType, shopId)
  local bType = self.shopBuildType[shopType]
  bType = bType or self:_getBuildingTypeByShopType(shopType)
  if bType then
    local buildData = self:GetBuildingDataByType(bType)
    if buildData and buildData.staticData and buildData.staticData.UnlockParam and buildData.staticData.UnlockParam.shopid then
      local unlockIDs = buildData.staticData.UnlockParam.shopid
      if unlockIDs and 0 < #unlockIDs then
        for i = 1, #unlockIDs do
          if shopId == unlockIDs[i] then
            return false
          end
        end
      end
    end
  end
  return true
end

function GuildBuildingProxy:CfgData(type, lv)
  for k, v in pairs(Table_GuildBuilding) do
    if v.Type == type and v.Level == lv then
      return v
    end
  end
  return nil
end

local sewing = GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING
local pillow = GuildBuildingProxy.Type.EGUILDBUILDING_EGUILDBUILDING_CAT_PILLOW

function GuildBuildingProxy:GetStrengthMaxLvl()
  local sewingLvl = self:GetBuildingLevelByType(sewing)
  local pillowLvl = self:GetBuildingDataByType(pillow)
  sewingLvl = sewingLvl and self:CfgData(sewing, sewingLvl)
  sewingLvl = sewingLvl and sewingLvl.UnlockParam and sewingLvl.UnlockParam.equip and sewingLvl.UnlockParam.equip.strengthmaxlv or 0
  pillowLvl = pillowLvl and pillowLvl.staticData and pillowLvl.staticData.UnlockParam and pillowLvl.staticData.UnlockParam.strengthmaxlv_add or 0
  return sewingLvl + pillowLvl
end

function GuildBuildingProxy:GetGuildMaterialLimitCount()
  local gb = self:GetBuildingDataByType(GuildBuildingProxy.Type.EGUILDBUILDING_EGUILDBUILDING_MATERIAL_MACHINE)
  if gb and gb.staticData and gb.staticData.UnlockParam.maxcount then
    return gb.staticData.UnlockParam.maxcount
  end
  return 0
end

function GuildBuildingProxy:GetGuildBuildingTaskInfo(type)
  local taskList = self:GetTaskTraceData()
  if taskList and 0 < #taskList then
    for i = 1, #taskList do
      if taskList[i].buildingType == type then
        return taskList[i]
      end
    end
  end
end

function GuildBuildingProxy:GetNextRefineMaxUpLv(curRefineMaxlv)
  if 15 <= curRefineMaxlv then
    return
  end
  local nextUnlockLv
  for k, v in pairs(Table_GuildBuilding) do
    if v.Type == GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING then
      local unlockParam = v.UnlockParam
      local unlockRefineLv = unlockParam and unlockParam.equip and unlockParam.equip.refinemaxlv
      if unlockRefineLv and curRefineMaxlv < unlockRefineLv and (not nextUnlockLv or nextUnlockLv > v.Level) then
        nextUnlockLv = v.Level
      end
    end
  end
  return nextUnlockLv
end

function GuildBuildingProxy:GetMiyinRefineValid(equipType)
  local taskData = self:GetGuildBuildingTaskInfo(GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING)
  if taskData then
    local taskID = taskData.id
    local sData = Table_GuildBuilding[taskID]
    if sData then
      local unlockParam = sData.UnlockParam
      local equipConfig = unlockParam and unlockParam.equip
      if equipConfig and equipConfig.refine_type and TableUtility.ArrayFindIndex(equipConfig.refine_type, equipType) > 0 then
        return true
      end
    end
  end
  return false
end

function GuildBuildingProxy:GetMiyinRefineUnlockLv(equipType)
  local nextUnlockLv
  for k, v in pairs(Table_GuildBuilding) do
    if v.Type == GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING then
      local unlockParam = v.UnlockParam
      local unlockRefineType = unlockParam and unlockParam.equip and unlockParam.equip.refine_type
      if TableUtility.ArrayFindIndex(unlockRefineType, equipType) > 0 and (not nextUnlockLv or nextUnlockLv > v.Level) then
        nextUnlockLv = v.Level
      end
    end
  end
  return nextUnlockLv
end

function GuildBuildingProxy:GetMiyinRefineUnlockedType()
  local result = {}
  local taskData = self:GetGuildBuildingTaskInfo(GuildBuildingProxy.Type.EGUILDBUILDING_MAGIC_SEWING)
  if taskData then
    local taskID = taskData.id
    local sData = Table_GuildBuilding[taskID]
    if sData then
      local unlockParam = sData.UnlockParam
      local equipConfig = unlockParam and unlockParam.equip
      if equipConfig and equipConfig.refine_type then
        TableUtility.ArrayShallowCopy(result, equipConfig.refine_type)
        return result
      end
    end
  end
end
