PveRaidType = {
  Rugelike = FuBenCmd_pb.ERAIDTYPE_ROGUELIKE or 46,
  PveCard = FuBenCmd_pb.ERAIDTYPE_PVECARD or 28,
  DeadBoss = FuBenCmd_pb.ERAIDTYPE_DEADBOSS or 51,
  Headwear = FuBenCmd_pb.ERAIDTYPE_HEADWEAR or 43,
  Comodo = FuBenCmd_pb.ERAIDTYPE_COMODO_TEAM_RAID or 59,
  MultiBoss = FuBenCmd_pb.ERAIDTYPE_SEVEN_ROYAL_TEAM_RAID or 62,
  InfiniteTower = FuBenCmd_pb.ERAIDTYPE_TOWER or 4,
  Thanatos = FuBenCmd_pb.ERAIDTYPE_THANATOS or 35,
  Crack = FuBenCmd_pb.ERAIDTYPE_CRACK or 65,
  GuildRaid = FuBenCmd_pb.ERAIDTYPE_GUILDRAID,
  Boss = FuBenCmd_pb.ERAIDTYPE_BOSS or 68,
  EquipUpgrade = FuBenCmd_pb.ERAIDTYPE_EQUIP_UP or 69,
  Element = FuBenCmd_pb.ERAIDTYPE_ELEMENT or 70,
  StarArk = FuBenCmd_pb.ERAIDTYPE_STAR_ARK or 71,
  NormalMaterials = FuBenCmd_pb.ERAIDTYPE_COMMON_MATERIALS or 73,
  MemoryPalace = FuBenCmd_pb.ERAIDTYPE_MEMORY_PALACE or 74,
  RoadOfHero = FuBenCmd_pb.ERAIDTYPE_HERO_JOURNEY or 76
}
RaidType2AERewardMode = {
  [PveRaidType.Crack] = ActivityEvent_pb.EAEREWARDMODE_SEAL,
  [PveRaidType.InfiniteTower] = ActivityEvent_pb.EAEREWARDMODE_TOWER,
  [PveRaidType.GuildRaid] = ActivityEvent_pb.EAEREWARDMODE_GUILDRAID,
  [PveRaidType.PveCard] = ActivityEvent_pb.EAEREWARDMODE_PVECARD,
  [PveRaidType.Thanatos] = ActivityEvent_pb.EAEREWARDMODE_TEAMGROUP,
  [PveRaidType.Comodo] = ActivityEvent_pb.EAEREWARDMODE_Comodo_Team,
  [PveRaidType.MultiBoss] = ActivityEvent_pb.EAEREWARDMODE_MULTIBOSS,
  [PveRaidType.EquipUpgrade] = ActivityEvent_pb.EAEREWARDMODE_EQUIP_UP_RAID,
  [PveRaidType.MemoryPalace] = ActivityEvent_pb.EAEREWARDMODE_MEMORY_PALACE
}
RaidType2GroupID = {
  [PveRaidType.Rugelike] = 8,
  [PveRaidType.PveCard] = 4,
  [PveRaidType.DeadBoss] = 6,
  [PveRaidType.Headwear] = 3,
  [PveRaidType.Comodo] = 1,
  [PveRaidType.MultiBoss] = 2,
  [PveRaidType.InfiniteTower] = 5,
  [PveRaidType.Thanatos] = 7,
  [PveRaidType.Crack] = 9,
  [PveRaidType.GuildRaid] = 19,
  [PveRaidType.Boss] = 20,
  [PveRaidType.NormalMaterials] = EPVEGROUPTYPE_COMMON_MATERIALS or 32,
  [PveRaidType.MemoryPalace] = 33
}
RaidType2AERewardMode = {
  [PveRaidType.Comodo] = AERewardType.ComodoRaid,
  [PveRaidType.MultiBoss] = AERewardType.SevenRoyalFamiliesRaid,
  [PveRaidType.PveCard] = AERewardType.PveCard,
  [PveRaidType.InfiniteTower] = AERewardType.Tower,
  [PveRaidType.Thanatos] = AERewardType.TeamGroup,
  [PveRaidType.MemoryPalace] = ActivityEvent_pb.EAEREWARDMODE_MEMORY_PALACE
}
ServerMergeStatus = {
  None = 0,
  InProcess = 1,
  Wait = 2,
  CountDown = 3,
  Open = 4
}
Pve_Difficulty_Type = {Normal = 0, Difficult = 1}
local _ArrayClear = TableUtility.ArrayClear
local _ArrayPushBack = TableUtility.ArrayPushBack
local _TableClear = TableUtility.TableClear
PveSortEnum = {Open = 1, Lock = 2}
local _SortFunc = function(l, r)
  local l_sortId = l:GetSortId()
  local r_sortId = r:GetSortId()
  local l_configSortId = l.staticEntranceData.configSortID
  local r_configSortId = r.staticEntranceData.configSortID
  if l_sortId == r_sortId then
    if l_configSortId == r_configSortId then
      return l.id < r.id
    else
      return l_configSortId < r_configSortId
    end
  else
    return l_sortId < r_sortId
  end
end
autoImport("PvePassInfo")
autoImport("PveDropItemData")
autoImport("WildMvpAffixData")
PveEntranceProxy = class("PveEntranceProxy", pm.Proxy)
PveEntranceProxy.Instance = nil
PveEntranceProxy.NAME = "PveEntranceProxy"
PveEntranceProxy.EmptyDiff = "EMPTY_DIFF"

function PveEntranceProxy:ctor(proxyName, data)
  self.proxyName = proxyName or PveEntranceProxy.NAME
  if PveEntranceProxy.Instance == nil then
    PveEntranceProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function PveEntranceProxy:Init()
  self.raidMap = {}
  self.catalogAll = {}
  self.catalogAll_raid = {}
  self.catalogAll_crack = {}
  self.catalogAll_boss = {}
  self.catalogAll_RoadOfHero = {}
  self.catalogMap = {}
  self.catalogMap_raid = {}
  self.catalogMap_crack = {}
  self.catalogMap_boss = {}
  self.catalogMap_RoadOfHero = {}
  self.passInfoMap = {}
  self.targetMap = {}
  self.dropMap = {}
  self.raidCombinedMap = {}
  self.teamLeaderOpenMap = {}
  self.pvecardRewardTime = {}
  self.goalMap = {}
  self.bossId2MatchIdMap = {}
  self.activeAffixs = {}
  self.quickBossMap = {}
  self:InitStatic()
  self:InitMultiRewardCondition()
end

function PveEntranceProxy:InitStatic()
  PveEntranceProxy.minUnlockLv = 999
  PveEntranceProxy.endlessTowerUnlockLv = 999
  for k, v in pairs(Table_PveRaidEntrance) do
    if v.Goal then
      self.goalMap[v.Goal] = v.id
    end
    local difficultyMap = self.raidMap[v.GroupId]
    if nil == difficultyMap then
      difficultyMap = {}
    end
    local data = PvePassInfo.new(k)
    difficultyMap[v.DifficultyName[2]] = data
    self.raidMap[v.GroupId] = difficultyMap
    PveEntranceProxy.minUnlockLv = math.min(PveEntranceProxy.minUnlockLv, v.UnlockLv)
    if data.staticEntranceData:IsInfiniteTower() then
      PveEntranceProxy.endlessTowerUnlockLv = math.min(PveEntranceProxy.endlessTowerUnlockLv, data.staticEntranceData.UnlockLv)
    end
  end
  for _, difficultyMap in pairs(self.raidMap) do
    local firstPveData = difficultyMap[1]
    if not firstPveData then
      redlog("error groupid: ", _)
    end
    if firstPveData.staticEntranceData:IsCrack() then
      _ArrayPushBack(self.catalogAll_crack, firstPveData)
    elseif firstPveData.staticEntranceData:IsBoss() then
      _ArrayPushBack(self.catalogAll_boss, firstPveData)
    elseif firstPveData.staticEntranceData:IsRoadOfHero() then
      _ArrayPushBack(self.catalogAll_RoadOfHero, firstPveData)
    else
      local catalogs = firstPveData.staticEntranceData.staticData.Catalog
      for i = 1, #catalogs do
        local catalogData = self.catalogMap_raid[catalogs[i]]
        catalogData = catalogData or {}
        catalogData[#catalogData + 1] = firstPveData
        self.catalogMap_raid[catalogs[i]] = catalogData
      end
      _ArrayPushBack(self.catalogAll_raid, firstPveData)
    end
  end
  self:StaticSortEntrance()
end

function PveEntranceProxy:PreprocessCrackEntrance()
  _TableClear(self.catalogMap_crack)
  local maxLvEntranceData
  for i = #self.catalogAll_crack, 1, -1 do
    if self:IsOpen(self.catalogAll_crack[i].id) then
      maxLvEntranceData = self.catalogAll_crack[i]
      break
    end
  end
  self.crackRaidFirstPveData = maxLvEntranceData or self.catalogAll_crack[1]
  local catalogs = self.crackRaidFirstPveData.staticEntranceData.staticData.Catalog
  for i = 1, #catalogs do
    local catalogData = self.catalogMap_crack[catalogs[i]]
    catalogData = catalogData or {}
    catalogData[#catalogData + 1] = self.crackRaidFirstPveData
    self.catalogMap_crack[catalogs[i]] = catalogData
  end
end

function PveEntranceProxy:PreprocessHeroRoadEntrance()
  _TableClear(self.catalogMap_RoadOfHero)
  local maxLvEntranceData = self.catalogAll_RoadOfHero[1]
  self.heroRoadFirstPveData = maxLvEntranceData or self.catalogAll_RoadOfHero[1]
  if self.heroRoadFirstPveData then
    local catalogs = self.heroRoadFirstPveData.staticEntranceData.staticData.Catalog
    for i = 1, #catalogs do
      local catalogData = self.catalogMap_RoadOfHero[catalogs[i]]
      catalogData = catalogData or {}
      catalogData[#catalogData + 1] = self.heroRoadFirstPveData
      self.catalogMap_RoadOfHero[catalogs[i]] = catalogData
    end
  end
end

function PveEntranceProxy:_setCatalogMap(targetMap)
  for catalog, list in pairs(targetMap) do
    local catalogData = self.catalogMap[catalog]
    catalogData = catalogData or {}
    for i = 1, #list do
      catalogData[#catalogData + 1] = list[i]
    end
    self.catalogMap[catalog] = catalogData
  end
end

function PveEntranceProxy:SetCatalogMap()
  _TableClear(self.catalogMap)
  self:_setCatalogMap(self.catalogMap_raid)
  self:_setCatalogMap(self.catalogMap_crack)
  self:_setCatalogMap(self.catalogMap_boss)
  self:_setCatalogMap(self.catalogMap_RoadOfHero)
end

function PveEntranceProxy:SetCatalogAll()
  _ArrayClear(self.catalogAll)
  for i = 1, #self.catalogAll_raid do
    _ArrayPushBack(self.catalogAll, self.catalogAll_raid[i])
  end
  _ArrayPushBack(self.catalogAll, self.crackRaidFirstPveData)
  _ArrayPushBack(self.catalogAll, self.bossFirstPveData)
  _ArrayPushBack(self.catalogAll, self.heroRoadFirstPveData)
end

function PveEntranceProxy:GetCatalogAll()
  return self.catalogAll
end

function PveEntranceProxy:HasServerLastBossEntranceInfo()
  return nil ~= self.lastBossEntranceId and self.lastBossEntranceId > 0
end

function PveEntranceProxy:PreprocessBossEntrance()
  self.bossFirstPveData = nil
  _TableClear(self.catalogMap_boss)
  if self:HasServerLastBossEntranceInfo() then
    for i = #self.catalogAll_boss, 1, -1 do
      if self.catalogAll_boss[i].id == self.lastBossEntranceId then
        self.bossFirstPveData = self.catalogAll_boss[i]
        break
      end
    end
    self.bossFirstPveData = self.bossFirstPveData or self.catalogAll_boss[1]
  else
    local maxLvEntranceData
    for i = #self.catalogAll_boss, 1, -1 do
      if self:IsOpen(self.catalogAll_boss[i].id) then
        maxLvEntranceData = self.catalogAll_boss[i]
        break
      end
    end
    self.bossFirstPveData = maxLvEntranceData or self.catalogAll_boss[1]
  end
  local catalogs = self.bossFirstPveData.staticEntranceData.staticData.Catalog
  for i = 1, #catalogs do
    local catalogData = self.catalogMap_boss[catalogs[i]]
    catalogData = catalogData or {}
    catalogData[#catalogData + 1] = self.bossFirstPveData
    self.catalogMap_boss[catalogs[i]] = catalogData
  end
end

function PveEntranceProxy:GetAllCrackPveData()
  return self.catalogAll_crack
end

function PveEntranceProxy:GetAllBossPveData()
  return self.catalogAll_boss
end

function PveEntranceProxy:GetAllRoadOfHeroData()
  return self.catalogAll_RoadOfHero
end

function PveEntranceProxy:StaticSortEntrance()
  table.sort(self.catalogAll_raid, function(l, r)
    return _SortFunc(l, r)
  end)
  table.sort(self.catalogAll_crack, function(l, r)
    return _SortFunc(l, r)
  end)
  table.sort(self.catalogAll_boss, function(l, r)
    return _SortFunc(l, r)
  end)
  table.sort(self.catalogAll_RoadOfHero, function(l, r)
    return _SortFunc(l, r)
  end)
end

function PveEntranceProxy:SortEntrance()
  table.sort(self.catalogAll, function(l, r)
    return _SortFunc(l, r)
  end)
  for _, v in pairs(self.catalogMap) do
    table.sort(v, function(l, r)
      return _SortFunc(l, r)
    end)
  end
end

function PveEntranceProxy:IsNewEntrancePveByRaidType(type)
  return nil ~= self.raidMap[type]
end

function PveEntranceProxy.IsNewEntrancePveById(id)
  return nil ~= id and nil ~= Table_PveRaidEntrance[id]
end

function PveEntranceProxy:GetCatalogData(c)
  return self.catalogMap[c]
end

function PveEntranceProxy:GetRaidData(groupid)
  return self.raidMap[groupid]
end

function PveEntranceProxy:GetDifficultyData(groupid, difficulty_type)
  local diffDatas = {}
  local diffMap = self:GetRaidData(groupid)
  if diffMap then
    for k, data in pairs(diffMap) do
      if difficulty_type then
        if data.staticEntranceData.difficultyType == difficulty_type then
          diffDatas[#diffDatas + 1] = data
        end
      else
        diffDatas[#diffDatas + 1] = data
      end
    end
  end
  table.sort(diffDatas, function(a, b)
    return a.staticEntranceData.staticDifficulty < b.staticEntranceData.staticDifficulty
  end)
  if #diffDatas < 7 then
    for i = 1, 7 - #diffDatas do
      diffDatas[#diffDatas + 1] = PveEntranceProxy.EmptyDiff
    end
  end
  return diffDatas
end

function PveEntranceProxy:GetCurMaxPickupLayer(gId, diffMode, cur_layer)
  local max = 0
  local diff = self:GetDifficultyData(gId, diffMode)
  for i = 1, #diff do
    if diff[i] ~= PveEntranceProxy.EmptyDiff and diff[i].IsPickup and diff[i]:IsPickup() and cur_layer > diff[i].staticEntranceData.difficultyIgoreType then
      max = math.max(max, diff[i].staticEntranceData.difficultyIgoreType)
    end
  end
  return max + 1
end

function PveEntranceProxy:GetRaidDifficultyData(type, difficulty)
  local map = self:GetRaidData(type)
  return map and map[difficulty]
end

function PveEntranceProxy:SetQuickBossMap(array)
  _TableClear(self.quickBossMap)
  if array then
    for i = 1, #array do
      self.quickBossMap[array[i]] = 1
    end
  end
end

function PveEntranceProxy:CheckBossCanQuick(bossid)
  return nil ~= self.quickBossMap[bossid]
end

function PveEntranceProxy:RecvSyncPvePassInfoFubenCmd(server_data, battletime, lastBossInfo, affixids, quickBoss, endlessrewardlayer, all_crack_non_first)
  self:SetQuickBossMap(quickBoss)
  if not server_data and not battletime then
    return
  end
  self:SetLastBossInfo(lastBossInfo)
  self.battletime = battletime
  for i = 1, #server_data do
    self:UpdatePassInfo(server_data[i])
  end
  if affixids then
    _ArrayClear(self.activeAffixs)
    for i = 1, #affixids do
      local config = Table_MonsterAffix[affixids[i]]
      if config then
        _ArrayPushBack(self.activeAffixs, WildMvpAffixData.new(config))
      end
    end
  end
  self:HandleCombinePveData()
  self.endlessrewardlayer = endlessrewardlayer
  self.all_crack_non_first = all_crack_non_first
  GameFacade.Instance:sendNotification(PVEEvent.SyncPvePassInfo)
end

function PveEntranceProxy:GetActiveAffix()
  return self.activeAffixs
end

function PveEntranceProxy:GetEndlessRewardLayer()
  return self.endlessrewardlayer
end

function PveEntranceProxy:HandleCombinePveData()
  self:PreprocessCrackEntrance()
  self:PreprocessBossEntrance()
  self:PreprocessHeroRoadEntrance()
  self:SetCatalogAll()
  self:SetCatalogMap()
  self:SortEntrance()
end

function PveEntranceProxy:SetLastBossInfo(serverLastBossInfo)
  if not (serverLastBossInfo and serverLastBossInfo.id) or serverLastBossInfo.id == 0 then
    return
  end
  self.lastBossEntranceId = serverLastBossInfo.id
  self.lastBossId = serverLastBossInfo.bossid
end

function PveEntranceProxy:HandleTeamLeaderPveCardOpenState(server_passinfos)
  if not server_passinfos then
    return
  end
  for i = 1, #server_passinfos do
    self.teamLeaderOpenMap[server_passinfos[i].id] = server_passinfos[i].open
  end
end

function PveEntranceProxy:CheckTeamLeaderOpenState(id)
  return self.teamLeaderOpenMap[id]
end

function PveEntranceProxy:UpdatePassInfo(data)
  local staticData = Table_PveRaidEntrance[data.id]
  if staticData then
    local diff = staticData.DifficultyName[2]
    local cacheData = self.raidMap[staticData.GroupId][diff]
    cacheData:SetServerData(data)
    self.passInfoMap[data.id] = cacheData
    FunctionPve.Debug("Pve副本入口 SyncPvePassInfo 服务器同步 id| firstpass | passtime | open :  ", data.id, data.firstpass, data.passtime, data.open)
  else
  end
end

function PveEntranceProxy:IsOpen(id)
  local _teamMgr = TeamProxy.Instance
  if _teamMgr:IHaveTeam() and _teamMgr:CheckIHaveLeaderAuthority() then
    local leaderOpenState = self:CheckTeamLeaderOpenState(id)
    if nil ~= leaderOpenState then
      return leaderOpenState
    end
  end
  local passInfo = self:GetPassInfo(id)
  if nil ~= passInfo then
    return passInfo.open
  end
  return false
end

function PveEntranceProxy:IsPickup(id)
  local passInfo = self:GetPassInfo(id)
  if nil ~= passInfo then
    return passInfo:IsPickup()
  end
  return false
end

function PveEntranceProxy:GetPassInfo(id)
  return self.passInfoMap[id]
end

function PveEntranceProxy:GetMatchRaidIdByBossId(id)
  local matchid = self.bossId2MatchIdMap[id]
  if not matchid then
    for _, passInfo in pairs(self.passInfoMap) do
      if passInfo.isBoss and passInfo:HasBossInfo(id) then
        matchid = passInfo:GetMatchRaidId()
        self.bossId2MatchIdMap[id] = matchid
        break
      end
    end
  end
  return matchid
end

function PveEntranceProxy:GetPassTime(id)
  local info = self:GetPassInfo(id)
  return info and info:GetPassTime() or 0
end

function PveEntranceProxy:GetCrackPassTime()
  return self.all_crack_non_first or 0
end

function PveEntranceProxy:OpenViewByBossId(entrance_id, boss_id)
  local info = self:GetPassInfo(entrance_id)
  if not info then
    self:OpenTargetPve(PveRaidType.Boss)
    return
  end
  local diff = info:GetDifficultyByBossId(boss_id)
  if not diff then
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.PveView,
      viewdata = {initialEntranceId = entrance_id}
    })
    return
  end
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.PveView,
    viewdata = {
      initialBossData = {
        entrance_id,
        diff,
        boss_id
      }
    }
  })
end

function PveEntranceProxy:OpenTargetPve(t, gid)
  if not t then
    return
  end
  gid = gid or RaidType2GroupID[t]
  local targetData = self.targetMap[gid]
  if not targetData then
    targetData = self.raidMap[gid]
    if not next(targetData) then
      redlog("检查配置表 Table_PveRaidEntrance . RaidType: ", t)
      return
    end
    self.targetMap[gid] = targetData
  end
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.PveView,
    viewdata = {
      targetData = {
        targetData[1]
      }
    }
  })
end

function PveEntranceProxy:OpenMultiTargetPve(t, gid)
  if not t then
    return
  end
  local resultList = {}
  for i = 1, #t do
    gid = gid or RaidType2GroupID[t[i]]
    local targetData = self.targetMap[gid]
    if not targetData then
      targetData = self.raidMap[gid]
      if not next(targetData) then
        redlog("检查配置表 Table_PveRaidEntrance . RaidType: ", t[i])
        return
      end
      self.targetMap[gid] = targetData
    end
    table.insert(resultList, targetData[1])
  end
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.PveView,
    viewdata = {targetData = resultList}
  })
end

function PveEntranceProxy:OpenMultiTargetPveByGroupID(gids)
  if not gids then
    return
  end
  local resultList = {}
  local crackList = {}
  local single_group = #gids == 1
  for i = 1, #gids do
    local targetData = self.targetMap[gids[i]]
    if targetData == nil then
      targetData = self.raidMap[gids[i]]
      if not targetData or not next(targetData) then
        redlog("检查配置表 Table_PveRaidEntrance . 缺少groupid: ", gids[i])
        return
      end
      self.targetMap[gids[i]] = targetData
    end
    if targetData[1].staticEntranceData:IsCrack() then
      crackList[#crackList + 1] = targetData[1]
    else
      resultList[#resultList + 1] = targetData[1]
    end
  end
  table.sort(crackList, function(l, r)
    return _SortFunc(l, r)
  end)
  self.targetMaxLvEntranceData = nil
  for i = #crackList, 1, -1 do
    if single_group or self:IsOpen(crackList[i].id) then
      self.targetMaxLvEntranceData = crackList[i]
      break
    end
  end
  if self.targetMaxLvEntranceData then
    table.insert(resultList, 1, self.targetMaxLvEntranceData)
  end
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.PveView,
    viewdata = {targetData = resultList}
  })
end

function PveEntranceProxy:GetCurCrackRaidFirstEnternceData()
  return self.targetMaxLvEntranceData or self.crackRaidFirstPveData
end

function PveEntranceProxy:GetCurBossFirstPveData()
  return self.bossFirstPveData
end

function PveEntranceProxy:HandleSyncPveRaidAchieveFubenCmd(server_data)
  if not server_data then
    return
  end
  for i = 1, #server_data do
    self:UpdateAchieveInfo(server_data[i])
  end
  GameFacade.Instance:sendNotification(PVEEvent.SyncPvePassInfo)
end

function PveEntranceProxy:UpdateAchieveInfo(data)
  if not self.achieveMap then
    self.achieveMap = {}
  end
  local p = self.achieveMap[data.groupid]
  p = p or {}
  local achID
  for i = 1, #data.achieveids do
    local single = data.achieveids[i]
    achID = single.achieveid
    if achID then
      p[achID] = data.achieveids[i].pick
    end
  end
  self.achieveMap[data.groupid] = p
end

function PveEntranceProxy:CheckDone(groupid, index)
  if not self.achieveMap or not self.achieveMap[groupid] then
    return nil
  end
  return self.achieveMap[groupid][index]
end

function PveEntranceProxy:GetGroupAchieve(groupid)
  if not (self.achieveMap and self.achieveMap[groupid]) or not self.achieveMap[groupid] then
    return 0
  end
  local count = 0
  for key, value in pairs(self.achieveMap[groupid]) do
    if value then
      count = count + 1
    end
  end
  return count
end

local BattleTimeStringColor = {
  [1] = "[000000]%d[-])",
  [2] = "[E4593D]%d[-]"
}

function PveEntranceProxy:GetBattleTimelen(cost, strFormat)
  local color = 1
  if (self.battletime or 0) < cost * 60 then
    color = 2
  end
  return string.format(strFormat, string.format(BattleTimeStringColor[color], cost)), color
end

function PveEntranceProxy:HandlePveCardTimes(data)
  self.pveCard_addTimes = data.addtimes
  self.pveCard_battleTime = data.battletime
  self.pveCard_totalBattleTime = data.totalbattletime
  self.pvecardTimeInited = true
end

function PveEntranceProxy:GetPveCardAddTimes()
  return self.pveCard_addTimes or 0
end

function PveEntranceProxy:HandlePveCardRewardTime(items)
  if not items then
    return
  end
  for i = 1, #items do
    self.pvecardRewardTime[items[i].diff] = {
      times = items[i].times,
      firstpass = items[i].firstpass
    }
  end
end

function PveEntranceProxy:GetPveCardRewardTime(diff)
  local rewardTimeData = self.pvecardRewardTime[diff]
  if not rewardTimeData then
    return 0, false
  else
    return rewardTimeData.times, rewardTimeData.firstpass
  end
end

function PveEntranceProxy:CanAddPveCardTime(show_msg)
  if not self.pvecardTimeInited then
    return
  end
  local config = GameConfig.AddPveCardTimes
  if not config then
    FunctionPve.Debug("未配置GameConfig.AddPveCardTimes")
    return false
  end
  local unit_price = config.BattleTime
  if not unit_price then
    FunctionPve.Debug("未配置GameConfig.AddPveCardTimes.BattleTime")
    return false
  end
  if unit_price > self.pveCard_battleTime then
    if show_msg then
      MsgManager.ShowMsgByID(43144)
    end
    return false
  end
  local limitTimes = config.LimitTimes
  if "number" == type(limitTimes) and 0 < limitTimes then
    if limitTimes <= self.pveCard_addTimes then
      if show_msg then
        MsgManager.ShowMsgByID(43143)
      end
      return false
    end
  else
    self.pvecard_noLimited = true
  end
  return true
end

function PveEntranceProxy:HandleQueryRaidServerCombinedCmd(data)
  local combinedData = data.data
  if not combinedData then
    return
  end
  for i = 1, #combinedData do
    local tempData = {}
    TableUtility.TableShallowCopy(tempData, combinedData[i])
    xdlog("进度", tempData.raidid)
    self.raidCombinedMap[tempData.raidid] = tempData
  end
end

function PveEntranceProxy:GetRaidServerCombinedData(raidid)
  if not self.raidCombinedMap[raidid] then
    return nil
  end
  return self.raidCombinedMap[raidid]
end

function PveEntranceProxy:IsRaidCombined(raidid)
  local combinedInfo = self:GetRaidServerCombinedData(raidid)
  if not combinedInfo then
    return false
  end
  if combinedInfo.passnum >= combinedInfo.neednum and combinedInfo.opentick <= ServerTime.CurServerTime() / 1000 then
    return false
  end
end

function PveEntranceProxy:GetRaidCombinedStatus(raidid)
  local combinedInfo = self:GetRaidServerCombinedData(raidid)
  if not combinedInfo then
    return ServerMergeStatus.None
  end
  if combinedInfo.passnum >= combinedInfo.neednum then
    if not combinedInfo.opentick or combinedInfo.opentick == 0 then
      return ServerMergeStatus.Wait, combinedInfo
    elseif combinedInfo.opentick > ServerTime.CurServerTime() / 1000 then
      return ServerMergeStatus.CountDown, combinedInfo
    elseif combinedInfo.opentick <= ServerTime.CurServerTime() / 1000 then
      return ServerMergeStatus.Open, combinedInfo
    end
  else
    return ServerMergeStatus.InProcess, combinedInfo
  end
end

function PveEntranceProxy:IsOpenByTeamGoal(teamgoal)
  local id = self.goalMap and self.goalMap[teamgoal]
  return self:IsOpen(id)
end

function PveEntranceProxy:HandleTowerLaunchCmd()
  GameFacade.Instance:sendNotification(PVEEvent.EndlessLaunchSuccess)
end

local _RewardMultiples
local RewardMultiples = function(t)
  if not _RewardMultiples then
    _RewardMultiples = {}
    _RewardMultiples[PveRaidType.PveCard] = GameConfig.NewPveRaid and GameConfig.NewPveRaid.MultiTimes
  end
  return _RewardMultiples[t]
end

function PveEntranceProxy:InitMultiRewardCondition()
  self.multi_reward_condition = {}
  self.multi_reward_condition[PveRaidType.PveCard] = self.MultiRewardCheckCondition_PveCard
end

function PveEntranceProxy:MultiRewardCheckCondition_PveCard(id, multiples)
  return multiples > self:GetPassTime(id)
end

function PveEntranceProxy:TryGetRewardMultiply(id, onlyCalcActivity)
  local result = 1
  local type = Table_PveRaidEntrance[id].RaidType
  if not onlyCalcActivity then
    local condition = self.multi_reward_condition[type]
    local multiples = RewardMultiples(type)
    if condition and multiples and condition(self, id, multiples) then
      result = multiples
    end
  end
  local rewardMode = RaidType2AERewardMode[type]
  if rewardMode then
    local rewardInfo = ActivityEventProxy.Instance:GetRewardByType(rewardMode)
    if rewardInfo then
      local multiply = rewardInfo:GetMultiple() or 1
      if 1 < multiply then
        result = result * multiply
      end
    end
  end
  if 1 < result then
    return result
  else
    return nil
  end
end

function PveEntranceProxy:CanResetRaidFuben(entranceid)
  local passinfo = self:GetPassInfo(entranceid)
  local staticData = Table_PveRaidEntrance[entranceid]
  return (passinfo.reset_time or 0) < (staticData.MaxResetTime or 0)
end

function PveEntranceProxy.IsSingleRaid(raidType)
  if raidType == PveRaidType.RoadOfHero then
    return true
  end
end
