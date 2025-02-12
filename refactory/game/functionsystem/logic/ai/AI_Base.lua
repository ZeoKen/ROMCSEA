autoImport("IdleAIManager")
autoImport("NCreature")
AI_Base = class("AI_Base")
local tempVector3 = LuaVector3.Zero()
local AlmostEqual = NumberUtility.AlmostEqual
local AlmostEqual_3 = VectorUtility.AlmostEqual_3
local Asign_3 = VectorUtility.Asign_3
local creatureDataIsSolo = CreatureDataWithPropUserdata.IsSolo
local creatureDataIsEnsemble = CreatureDataWithPropUserdata.IsEnsemble
local creatureLogicPlayAction = NCreature.Logic_PlayAction_Simple
local creatureGetIdleAction = NCreature.GetIdleAction
local idleAIManagerIdleBreak = IdleAIManager.Break
local idleAIManagerUpdate = IdleAIManager.Update

function AI_Base:ctor()
  self.dieBlockers = {}
  self.idleAIManager = IdleAIManager.new()
  self:_InitIdleAI(self.idleAIManager)
  self._alive = false
  self.forceUpdate = false
end

function AI_Base:Construct(creature)
  if self._alive then
    return
  end
  self._alive = true
  self.parent = nil
  self.prevPosition = nil
  self.prevAngleY = nil
  self.prevScale = nil
  self.idle = false
  self.idleElapsed = 0
  self.idleAction = nil
  self.requestClear = false
end

function AI_Base:Deconstruct(creature)
  if not self._alive then
    return
  end
  self:_Clear(0, 0, creature)
  self._alive = false
end

function AI_Base:_PlayIdleAction(time, deltaTime, creature)
  local creatureData = creature.data
  if nil ~= creatureData and creatureData:NoPlayIdle() then
    return
  end
  if creature:IsRobotNpc() and creature:IsFakeDead() then
    return
  end
  if creatureDataIsSolo(creatureData) or creatureDataIsEnsemble(creatureData) then
    creatureLogicPlayAction(creature, creatureGetIdleAction(creature))
  elseif nil ~= self.idleAction then
    if "none" ~= self.idleAction then
      creatureLogicPlayAction(creature, self.idleAction)
    end
    self.idleAction = nil
  else
    creatureLogicPlayAction(creature, creatureGetIdleAction(creature))
  end
  creature:RemoveWalkEffect(path)
end

function AI_Base:_InitIdleAI(idleAIManager)
end

function AI_Base:_Idle(time, deltaTime, creature)
  if nil ~= self.parent and not self.forceUpdate then
    return false
  end
  local creatureData = creature.data
  if creatureData:Freeze() or creatureData:NoAct() then
    return false
  end
  if not self.idle then
    self.idle = true
    self.idleElapsed = 0
    self:_PlayIdleAction(time, deltaTime, creature)
  else
    self.idleElapsed = self.idleElapsed + deltaTime
  end
  idleAIManagerUpdate(self.idleAIManager, self.idleElapsed, time, deltaTime, creature)
  return true
end

function AI_Base:_IdleBreak(time, deltaTime, creature)
  if not self.idle then
    return
  end
  self.idle = false
  self.idleElapsed = 0
  idleAIManagerIdleBreak(self.idleAIManager, self.idleElapsed, time, deltaTime, creature)
end

function AI_Base:SetParent(parentTransform, creature, noResetLocal)
  if self.parent == parentTransform then
    return
  end
  self.parent = parentTransform
  creature.assetRole:SetParent(self.parent, true)
  if nil ~= self.prevPosition then
    self.prevPosition:Destroy()
    self.prevPosition = nil
  end
  self.prevAngleY = nil
  self.prevScale = nil
  if not noResetLocal then
    creature.assetRole:SetPosition(LuaGeometry.Const_V3_zero)
    creature.assetRole:SetEulerAngles(LuaGeometry.Const_V3_zero)
    creature.assetRole:SetScale(1.0)
  end
end

function AI_Base:PauseIdleAI(creature)
  self.idleAIManager:Pause(creature)
end

function AI_Base:ResumeIdleAI(creature)
  self.idleAIManager:Resume(creature)
end

function AI_Base:SetIdleAction(action)
  self.idleAction = action
end

function AI_Base:SetNoIdleAction()
  self.idleAction = "none"
end

function AI_Base:DieBlocked()
  return 0 < #self.dieBlockers
end

function AI_Base:SetDieBlocker(blocker)
  TableUtility.ArrayPushBack(self.dieBlockers, blocker)
end

function AI_Base:ClearDieBlocker(blocker)
  TableUtility.ArrayRemove(self.dieBlockers, blocker)
end

function AI_Base:SetConcurrent(v)
end

function AI_Base:Clear(time, deltaTime, creature)
  self.requestClear = true
end

function AI_Base:_Clear(time, deltaTime, creature)
  self.requestClear = false
  self:SetParent(nil, creature)
  self.idleAIManager:Clear(self.idleElapsed, time, deltaTime, creature)
  self.idleAI_PlayShow = nil
  TableUtility.ArrayClear(self.dieBlockers)
  if nil ~= self.prevPosition then
    self.prevPosition:Destroy()
    self.prevPosition = nil
  end
  self.prevAngleY = nil
  if nil ~= self.prevScale then
    self.prevScale:Destroy()
    self.prevScale = nil
  end
end

function AI_Base:SyncLogicTransform(time, deltaTime, creature)
  local logicTransform = creature.logicTransform
  local assetRole = creature.assetRole
  if nil == self.prevPosition or not LuaVector3.Equal(self.prevPosition, logicTransform.currentPosition) then
    assetRole:SetPosition(logicTransform.currentPosition)
    self.prevPosition = VectorUtility.Asign_3(self.prevPosition, logicTransform.currentPosition)
  end
  if self.prevAngleY ~= logicTransform.currentAngleY then
    assetRole:SetEulerAngleY(logicTransform.currentAngleY)
    self.prevAngleY = logicTransform.currentAngleY
  end
  if nil == self.prevScale or not LuaVector3.Equal(self.prevScale, logicTransform.currentScale) then
    local s = logicTransform.currentScale
    assetRole:SetScaleXYZ(s[1], s[2], s[3])
    self.prevScale = VectorUtility.Asign_3(self.prevScale, logicTransform.currentScale)
  end
end

function AI_Base:Update(time, deltaTime, creature)
  local oldIdleAction = self.idleAction
  self:_DoRequest(time, deltaTime, creature)
  self:_DoUpdate(time, deltaTime, creature)
  self:_DoRequest(time, deltaTime, creature)
  if oldIdleAction == self.idleAction then
    self.idleAction = nil
  end
end

function AI_Base:_DoUpdate(time, deltaTime, creature)
  local parent = self.parent
  local logicTransform = creature.logicTransform
  if nil ~= parent then
    LuaVector3.Better_Set(tempVector3, LuaGameObject.GetPosition(parent))
    logicTransform:PlaceTo(tempVector3)
  end
  local assetRole = creature.assetRole
  if nil ~= parent then
  elseif nil == self.prevPosition or not AlmostEqual_3(self.prevPosition, logicTransform.currentPosition) then
    creature:SetPosition(logicTransform.currentPosition)
    self.prevPosition = Asign_3(self.prevPosition, logicTransform.currentPosition)
  end
  if nil == self.prevAngleY or not AlmostEqual(self.prevAngleY, logicTransform.currentAngleY) then
    LuaVector3.Better_Set(tempVector3, logicTransform.targetAngleX or 0, logicTransform.currentAngleY, 0)
    assetRole:SetEulerAngles(tempVector3)
    self.prevAngleY = logicTransform.currentAngleY
  end
  if nil == self.prevScale or not AlmostEqual_3(self.prevScale, logicTransform.currentScale) then
    local s = logicTransform.currentScale
    assetRole:SetScaleXYZ(s[1], s[2], s[3])
    self.prevScale = Asign_3(self.prevScale, logicTransform.currentScale)
  end
end

function AI_Base:_DoRequest(time, deltaTime, creature)
  if self.requestClear then
    self:_Clear(time, deltaTime, creature)
  end
end

function AI_Base:SetForceUpdate(b)
  self.forceUpdate = b
end

function AI_Base:AddPlayShow()
  if self.idleAI_PlayShow then
    return
  end
  self.idleAI_PlayShow = IdleAI_PlayShow.new()
  self.idleAIManager:PushAI(self.idleAI_PlayShow)
end

function AI_Base:RemovePlayShow()
  if not self.idleAI_PlayShow then
    return
  end
  self.idleAIManager:RemoveAI(self.idleAI_PlayShow)
  self.idleAI_PlayShow = nil
end
