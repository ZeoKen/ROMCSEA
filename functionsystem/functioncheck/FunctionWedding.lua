FunctionWedding = class("FunctionWedding")

function FunctionWedding.Me()
  if nil == FunctionWedding.me then
    FunctionWedding.me = FunctionWedding.new()
  end
  return FunctionWedding.me
end

local _courtShip_Player_Map = {}

function FunctionWedding:AddCourtshipDistanceCheck(playerid, itemid)
  local itemData = itemid and Table_Item[itemid]
  local distance = itemData and itemData.ItemTarget.range
  _courtShip_Player_Map[playerid] = distance or 2
  if self.courtshipCheckTick ~= nil then
    return
  end
  self.courtshipCheckTick = TimeTickManager.Me():CreateTick(0, 33, self._CourtshipDistanceCheck, self, 1)
end

function FunctionWedding:_CourtshipDistanceCheck()
  for playerid, distance in pairs(_courtShip_Player_Map) do
    local target = NSceneUserProxy.Instance:Find(playerid)
    if target == nil then
      self:RemoveCourtshipDistanceCheck()
      return
    end
    local targetPos = target:GetPosition()
    local myPos = Game.Myself:GetPosition()
    if LuaVector3.Distance_Square(myPos, targetPos) > distance * distance then
      self:RemoveCourtshipDistanceCheck(playerid)
      GameFacade.Instance:sendNotification(InviteConfirmEvent.Courtship_OutDistance, playerid)
      return
    end
  end
end

function FunctionWedding:RemoveCourtshipDistanceCheck(playerid)
  local needRemove = false
  if playerid ~= nil then
    _courtShip_Player_Map[playerid] = nil
    local k, v = next(_courtShip_Player_Map)
    needRemove = k == nil
  else
    needRemove = true
  end
  if not needRemove then
    return
  end
  if self.courtshipCheckTick == nil then
    return
  end
  self.courtshipCheckTick = nil
  TimeTickManager.Me():ClearTick(self, 1)
end

local tempArgs, tempV3 = {}, LuaVector3()

function FunctionWedding:StartWeddingCememony()
  local handFollowerId = Game.Myself:Client_GetHandInHandFollower()
  local gameconfig_wedding = GameConfig.Wedding
  if gameconfig_wedding == nil then
    return
  end
  if self.doingcememony then
    return
  end
  self.doingcememony = true
  local posConfig = gameconfig_wedding.WeddingPos
  local pos, dir
  if handFollowerId ~= nil and handFollowerId ~= 0 then
    pos = posConfig.pos1
    dir = posConfig.dir1 or 180
  else
    pos = posConfig.pos2
    dir = posConfig.dir2 or 180
  end
  LuaVector3.Better_Set(tempV3, pos[1], pos[2], pos[3])
  Game.Myself:Client_MoveTo(tempV3, nil, function()
    Game.Myself:Client_SetDirCmd(AI_CMD_SetAngleY.Mode.SetAngleY, dir)
    if self.cememony_pauseUI ~= true then
      self.cememony_pauseUI = true
      Game.Myself:Client_PauseIdleAI()
    end
    ServiceWeddingCCmdProxy.Instance:CallGoToWeddingPosCCmd()
  end)
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.PlotStoryView
  })
end

function FunctionWedding:EndWeddingCememony()
  if not self.doingcememony then
    return
  end
  self.doingcememony = false
  if self.cememony_pauseUI then
    self.cememony_pauseUI = false
    Game.Myself:Client_ResumeIdleAI()
  end
  GameFacade.Instance:sendNotification(UIEvent.CloseUI, UIViewType.NormalLayer)
  GameFacade.Instance:sendNotification(UIEvent.CloseUI, UIViewType.InterstitialLayer)
end
