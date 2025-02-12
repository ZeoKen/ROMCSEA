MissionCommandSkill = class("MissionCommandSkill", MissionCommand)
local FindNPCRange = 50
local SquareFindNPCRange = 2500
local MovingSwitchTargetInterval = 2
local tempVector3 = LuaVector3.Zero()

function MissionCommandSkill:ctor()
  MissionCommandSkill.super.ctor(self)
  self.autoBattle = AutoBattle.new()
  
  function self.targetFilter(target)
    if nil ~= target and not target:IsDead() and not target.data:NoAccessable() then
      return SquareFindNPCRange > VectorUtility.DistanceXZ_Square(Game.Myself:GetPosition(), target:GetPosition())
    end
    return false
  end
  
  self.nextSwitchTargetTime = 0
end

function MissionCommandSkill:Log()
  local args = self.args
  LogUtility.InfoFormat("MissionCommandSkill: {0}, {1}", LogUtility.StringFormat("targetMapID={0}, targetBPID={1}, targetPos=({2})", LogUtility.ToString(args.targetMapID), LogUtility.ToString(args.targetBPID), targetPos), LogUtility.StringFormat("npcID={0}, npcUID={1}, groupID={2}", LogUtility.ToString(args.npcID), LogUtility.ToString(args.npcUID), LogUtility.ToString(args.groupID)))
end

function MissionCommandSkill:AutoBattleOn()
  if self.args.npcID ~= nil then
    Game.Myself:Client_SetAutoBattleLockID(self.args.npcID)
  end
end

function MissionCommandSkill:AutoBattleOff()
  if self.args.npcID ~= nil then
    Game.Myself:Client_UnSetAutoBattleLockID(self.args.npcID)
  end
  if not self.ignoreAutoBattle then
    self:Shutdown()
  end
end

function MissionCommandSkill:AutoBattleLost()
  self:AutoBattleOff()
end

function MissionCommandSkill:CurrentTargetValid()
  return self.targetFilter(self:GetWeakData(1))
end

function MissionCommandSkill:SwitchTarget(time, deltaTime)
  local args = self.args
  local oldTarget = self:GetWeakData(1)
  local newTarget
  if nil ~= args.groupID then
    newTarget = NSceneNpcProxy.Instance:FindNearestNpcByGroupID(Game.Myself:GetPosition(), args.groupID, self.targetFilter)
  elseif args.npcIDs then
    newTarget = NSceneNpcProxy.Instance:FindNearestNpcByNpcIDs(Game.Myself:GetPosition(), args.npcIDs, self.targetFilter)
  else
    newTarget = NSceneNpcProxy.Instance:FindNearestNpc(Game.Myself:GetPosition(), args.npcID, self.targetFilter)
    newTarget = newTarget or NSceneNpcProxy.Instance:FindNearestClientNpc(Game.Myself:GetPosition(), args.npcID)
  end
  LogUtility.InfoFormat("<color=green>MissionCommandSkill SwitchTarget: </color>{0} --> {1}", oldTarget and oldTarget.data:GetName() or "nil", newTarget and newTarget.data:GetName() or "nil")
  if oldTarget ~= newTarget then
    self:SetWeakData(1, newTarget)
    if nil ~= newTarget then
      Game.Myself:Client_LockTarget(newTarget)
    end
  end
end

function MissionCommandSkill:GetTargetPos()
  local args = self.args
  local currentMapID = SceneProxy.Instance:GetCurMapID()
  if currentMapID == args.targetMapID then
    if nil ~= self.npcPoint then
      local pos = self.npcPoint.position
      LuaVector3.Better_Set(tempVector3, pos[1], pos[2], pos[3])
      return tempVector3
    end
    if nil ~= args.npcUID then
      local npcPointMap = Game.MapManager:GetNPCPointMap()
      if nil ~= npcPointMap then
        self.npcPoint = npcPointMap[args.npcUID]
        if nil ~= self.npcPoint then
          local pos = self.npcPoint.position
          LuaVector3.Better_Set(tempVector3, pos[1], pos[2], pos[3])
          return tempVector3
        end
      end
      LogUtility.InfoFormat("<color=red>MissionCommandSkill: </color>can't find npc by unique id, uID={0}, mapID={1}", args.npcUID, currentMapID)
    end
  end
  return args.targetPos
end

function MissionCommandSkill:DoLaunch()
  self.ignoreAutoBattle = true
  Game.AutoBattleManager:SetController(self)
  Game.AutoBattleManager:AutoBattleOff()
  self.ignoreAutoBattle = false
  self.ignoreUpdate = true
end

function MissionCommandSkill:DoShutdown()
  self.teleport:Shutdown()
  self.ignoreUpdate = nil
end

function MissionCommandSkill:DoUpdate(time, deltaTime)
  if self:_MyselfNoMove() then
    if not self.teleport.pausing then
      self.teleport:Pause()
      Game.Myself:Logic_StopMove()
      Game.Myself:Logic_PlayAction_Idle()
    end
    return true
  elseif self.teleport.pausing then
    self.teleport:Resume()
  end
  if self.teleport.running then
    self.teleport:Update()
    if not self.teleport.running then
      Game.Myself:Logic_PlayAction_Idle()
    end
  end
  if not self:CurrentTargetValid() then
    if self.teleport.running and not self.teleport.pausing then
      if time > self.nextSwitchTargetTime then
        self.nextSwitchTargetTime = time + MovingSwitchTargetInterval
        self:SwitchTarget()
      end
    else
      self:SwitchTarget()
    end
  end
  local args = self.args
  if self:CurrentTargetValid() then
    if nil ~= args.skillID then
      LogUtility.InfoFormat("<color=yellow>MissionCommandSkill:UseSkill: </color>{0}", args.skillID)
      Game.Myself:Client_UseSkill(args.skillID, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, true)
    else
      self.autoBattle:Update(Game.Myself)
      Game.AutoBattleManager:AutoBattleOn()
    end
    self.teleport:Pause()
    return true
  elseif nil == args.skillID and self.autoBattle:Attack(Game.Myself, nil, nil, true) then
    Game.AutoBattleManager:AutoBattleOn()
    self.teleport:Pause()
    return true
  end
  if nil ~= self.autoBattle then
    self.ignoreAutoBattle = true
    Game.AutoBattleManager:AutoBattleOff()
    self.ignoreAutoBattle = false
  end
  if self.teleport.running then
    self.teleport:Resume()
  else
    local args = self.args
    local targetPos = self:GetTargetPos()
    local currentMapID = Game.MapManager:GetMapID()
    if (nil == args.targetMapID or args.targetMapID == currentMapID) and nil ~= targetPos then
      local myPosition = Game.Myself:GetPosition()
      if 1.0E-4 >= VectorUtility.DistanceXZ_Square(myPosition, targetPos) then
        return true
      end
    end
    if not self.teleport:Launch(args.targetMapID, args.targetBPID, targetPos) then
      LogUtility.InfoFormat("<color=red>MissionCommandSkill: </color>teleport failed, {0}, {1}", LogUtility.StringFormat("targetMapID={0}, targetBPID={1}, targetPos=({2})", LogUtility.ToString(args.targetMapID), LogUtility.ToString(args.targetBPID), targetPos), LogUtility.StringFormat("npcID={0}, npcUID={1}, groupID={2}", LogUtility.ToString(args.npcID), LogUtility.ToString(args.npcUID), LogUtility.ToString(args.groupID)))
      return false
    end
  end
  return true
end

function MissionCommandSkill:DoConstruct(asArray, args)
  MissionCommandSkill.super.DoConstruct(self, asArray, args)
  if nil == self.args.targetMapID then
    self.args.targetMapID = Game.MapManager:GetMapID()
  end
  if nil ~= self.args.targetPos then
    self.args.targetPos = self.args.targetPos:Clone()
  end
  self.teleport = Game.WorldTeleport
  self.npcPoint = nil
  self:CreateWeakData()
end

function MissionCommandSkill:DoDeconstruct(asArray)
  if nil ~= self.args.targetPos then
    self.args.targetPos:Destroy()
  end
  Game.AutoBattleManager:ClearController(self, true)
  MissionCommandSkill.super.DoDeconstruct(self, asArray)
  self.teleport = nil
  self.autoBattle:Reset()
  self.npcPoint = nil
end
