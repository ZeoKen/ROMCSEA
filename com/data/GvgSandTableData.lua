GvgSandTableData = class("GvgSandTableData")

function GvgSandTableData:ctor(data)
  self:SetData(data)
end

function GvgSandTableData:SetData(data)
  self.data = data
  self.city = data.city
  self.staticData = GvgProxy.GetStrongHoldStaticData(self.city)
  self.isClassic = self.staticData and self.staticData.Mode == GuildCmd_pb.EGUILDDATEBATTLEMODE_CLASSIC
  self.metalhp = data.metalhp
  self.defensenum = data.defensenum
  self.attacknum = data.attacknum
  self.cityState = data.state
  self.defguild = SandTableGuildData.new(data.defguild)
  local guilds = data.guild
  self.topGuilds = {}
  for i = 1, #guilds do
    local guildData = SandTableGuildData.new(guilds[i])
    table.insert(self.topGuilds, guildData)
  end
  local points = data.point_info
  self.points = {}
  local totalScore = 0
  for i = 1, #points do
    local pointData = {}
    pointData.guildData = SandTableGuildData.new(points[i].guild)
    pointData.isClassic = self.isClassic
    pointData.has_occupied = points[i].has_occupied
    pointData.id = points[i].id
    pointData.ratio = self.staticData and self.staticData.Point[pointData.id] and self.staticData.Point[pointData.id].calc_ratio
    if nil ~= points[i].score then
      pointData.score = points[i].score
      if points[i].score then
        totalScore = totalScore + 1
      end
    end
    self.points[pointData.id] = pointData
  end
  self.totalScore = totalScore
  self.raidstate = data.raidstate
  local perfectSpareLeftTime = data.perfect_spare_time or 0
  self.perfectSpareTime = ServerTime.CurServerTime() / 1000 + perfectSpareLeftTime
end

SandTableGuildData = class("SandTableGuildData")

function SandTableGuildData:ctor(data)
  self:SetData(data)
end

function SandTableGuildData:SetData(data)
  self.id = data.guildid
  self.name = data.name
  self.image = data.image
end
