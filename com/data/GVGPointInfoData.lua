local gvg_total_point_count = 8
GVGPointInfoData = class("GVGPointInfoData")

function GVGPointInfoData:ctor(data)
  self.pointid = data.pointid
  self.state = data.state
  self.per = data.per
  self.guildid = data.guildid
  self.guildName = data.guildname
  self.guildPortrait = data.guildportrait
  self.smallMetalGuid = data.metal_guid
  self.isSmallMetalOccupied = data.metal_occupied
  self.occupiedGuilds = {}
  if data.occupied_guilds then
    for _, v in ipairs(data.occupied_guilds) do
      self.occupiedGuilds[v] = 1
    end
  end
  if nil ~= data.score then
    self.score = data.score
  end
  self:UpdateFlag()
end

function GVGPointInfoData:Update(data)
  local cacheState = self.state
  self.state = data.state
  self.guildid = data.guildid
  self.guildName = data.guildname
  self.guildPortrait = data.guildportrait
  self.per = data.per
  self.smallMetalGuid = data.metal_guid
  if not self.occupiedGuilds then
    self.occupiedGuilds = {}
  else
    TableUtility.TableClear(self.occupiedGuilds)
  end
  if data.occupied_guilds then
    for _, v in ipairs(data.occupied_guilds) do
      self.occupiedGuilds[v] = 1
    end
  end
  if self.pointid == GvgProxy.Instance:GetCurOccupingPointID() then
    GameFacade.Instance:sendNotification(GVGEvent.GVG_UpdatePointPercentTip)
  end
  if cacheState ~= self.state then
    self:UpdateFlag()
  end
  if nil ~= data.score then
    self.score = data.score
  end
end

function GVGPointInfoData:CheckScore()
  return self.score == true
end

function GVGPointInfoData:UpdateFlag()
  local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
  if not flagManager then
    return
  end
  local static_data = GvgProxy.Instance.curStrongHoldStaticData
  local ratio = static_data and static_data.Point and static_data.Point[self.pointid] and static_data.Point[self.pointid].calc_ratio
  if ratio then
    self:UpdateClassicModeFlag(ratio)
  else
    self:UpdateBaseModeFlag()
  end
end

function GVGPointInfoData:UpdateClassicModeFlag(ratio)
  if not ratio or type(ratio) ~= "number" then
    return
  end
  for i = 1, ratio do
    self:_SetFlag(i)
  end
  self:HideUnuseClassicFlag(ratio)
end

function GVGPointInfoData:HideUnuseClassicFlag(ratio)
  local unuse_count = gvg_total_point_count - ratio
  if 0 < unuse_count then
    local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
    if not flagManager then
      return
    end
    for i = ratio + 1, gvg_total_point_count do
      flagManager:HideNewGvgFlag(i)
    end
  end
end

function GVGPointInfoData:UpdateBaseModeFlag()
  self:_SetFlag(self.pointid)
end

function GVGPointInfoData:_SetFlag(pointid)
  local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
  if not flagManager then
    return
  end
  if self:IsOccupied() then
    flagManager:ResetNewGvgFlag(pointid, self.guildPortrait, self.guildid)
  else
    flagManager:HideNewGvgFlag(pointid)
  end
end

function GVGPointInfoData:GetOccupyProcess()
  return self.per and self.per / 100 or 0
end

function GVGPointInfoData:HasMaxSmallmetal()
  local own = GvgProxy.Instance:GetSmallMetalCnt(self.guildid)
  local max = GameConfig.GVGConfig.occupy_smallmetal_maxcount or 5
  return own >= max
end

function GVGPointInfoData:IsOccupied()
  return self.state == GvgProxy.EpointState.Occupied
end

function GVGPointInfoData:IsSmallMetalOccupied()
  return self.isSmallMetalOccupied
end

function GVGPointInfoData:CheckSmallMetalExist()
  return nil ~= self.smallMetalGuid and 0 ~= self.smallMetalGuid
end

function GVGPointInfoData:GetOccupyGuildPortrait()
  if self:IsOccupied() then
    return tonumber(self.guildPortrait) or self.guildPortrait
  end
  return -1
end

function GVGPointInfoData:GetGuildID()
  return self.guildid
end

function GVGPointInfoData:IsMyGuildPoint()
  return GuildProxy.Instance:IsMyGuildUnion(self.guildid)
end

function GVGPointInfoData:CanGetRewardFromThisHold()
  local guildProxy = GuildProxy.Instance
  local gvgProxy = GvgProxy.Instance
  if gvgProxy:IsDefSide() then
    return false
  end
  if not gvgProxy:CanIGetMoreStrongHoldReward() then
    return false
  end
  local myGuildId = gvgProxy:GetGuildID()
  if not myGuildId then
    return false
  end
  if self.occupiedGuilds and self.occupiedGuilds[myGuildId] then
    return false
  end
  if not gvgProxy:CheckCurMapIsInGuildUnionGroup() then
    return false
  end
  return true
end
