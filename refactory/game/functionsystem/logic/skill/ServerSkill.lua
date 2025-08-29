ServerSkill = class("ServerSkill", SkillBase)
local FindCreature = SceneCreatureProxy.FindCreature
local attackFrame, attackCount, attackMaxCount = 0, 0, 4

function ServerSkill:ctor()
  ServerSkill.super.ctor(self)
end

function ServerSkill:IsServerSkill()
  return true
end

function ServerSkill:GetCastTime(creature)
  return self.phaseData:GetCastTime()
end

function ServerSkill:GetAttackAction(creature)
  return self.phaseData:GetActionName()
end

function ServerSkill:SetPhase(phaseData, creature)
  if 0 == phaseData:GetSkillID() then
    LogUtility.InfoFormat("<color=red>[{0}] ServerSkill:SetPhase: </color>skillID=0", creature.data and creature.data:GetName() or "No Name")
    return false
  end
  if self.info and self.info:CanClientInterrupt() then
    local oldSkillPhase = self.phaseData:GetSkillPhase()
    if SkillPhase.Cast == oldSkillPhase then
      return false, false
    end
  end
  if self.info and self.info:GetRotateOnly() then
    local targetAngleY = creature.logicTransform.targetAngleY
    if targetAngleY then
      creature.logicTransform:SetAngleY(targetAngleY, true)
    end
  end
  local skillPhase = phaseData:GetSkillPhase()
  if SkillPhase.FreeCast ~= skillPhase then
    creature:Logic_RemoveSkillFreeCast()
  end
  local actionName = phaseData:GetActionName()
  if actionName and actionName ~= "" then
    self.attackAction = actionName
  end
  if SkillPhase.Cast == skillPhase then
    self:_TryBeAutoLocked(phaseData, creature)
    self:_TryRefreshHatred(phaseData, creature)
    self:_SetPhaseData(phaseData, creature)
    self:_SwitchToCast(creature)
    if self.running then
      return true, true
    end
  elseif SkillPhase.FreeCast == skillPhase then
    self:_TryBeAutoLocked(phaseData, creature)
    self:_TryRefreshHatred(phaseData, creature)
    self:_SetPhaseData(phaseData, creature)
    self:_SwitchToFreeCast(creature)
  elseif SkillPhase.Attack == skillPhase then
    self:_TryBeAutoLocked(phaseData, creature)
    self:_TryRefreshHatred(phaseData, creature)
    self:_SetPhaseData(phaseData, creature)
    if nil ~= self.phaseData and nil ~= self.info and SkillTargetType.Point == self.info:GetTargetType(creature) then
      self.phaseData:SamplePosition()
    end
    self:_SwitchToAttack(creature)
    if self.running then
      return true, false
    end
  elseif SkillPhase.Invalid == skillPhase then
    self:_TryBeAutoLocked(phaseData, creature)
    self:_TryRefreshHatred(phaseData, creature)
    self:_SetPhaseData(phaseData, creature)
    self:_SwitchToInvalid(creature)
    if self.running then
      return true, false
    end
  elseif SkillPhase.None == skillPhase and self.phaseData:GetSkillID() == phaseData:GetSkillID() then
    self:_SetPhaseData(phaseData, creature)
    self:_End(creature)
  end
  return false
end

function ServerSkill:OnDelayHit(creature, phaseData)
  self:_TryBeAutoLocked(phaseData, creature)
  self:_TryRefreshHatred(phaseData, creature)
end

function ServerSkill:NeedDelayAttack()
  return attackCount > attackMaxCount
end

function ServerSkill:_TryBeAutoLocked(phaseData, creature)
  local targetCount = phaseData:GetTargetCount()
  if targetCount <= 0 then
    return
  end
  if nil ~= creature.data then
    if RoleDefines_Camp.ENEMY == creature.data:GetCamp() then
      if creature.data.GetNoAutoLock and creature.data:GetNoAutoLock() then
      elseif nil == Game.Myself:GetLockTarget() then
        local myselfID = Game.Myself.data.id
        for i = 1, targetCount do
          local targetID = phaseData:GetTarget(i)
          if targetID == myselfID then
            Game.Myself:Client_LockTarget(creature)
            break
          end
        end
      end
    elseif Game.Myself:Client_GetFollowLeaderID() == creature.data.id then
      for i = 1, targetCount do
        local targetID = phaseData:GetTarget(i)
        local targetCreature = FindCreature(targetID)
        if nil ~= targetCreature and RoleDefines_Camp.ENEMY == targetCreature.data:GetCamp() then
          Game.Myself:Client_SetFollowLeaderTarget(targetID, UnityTime)
          break
        end
      end
    end
  end
end

function ServerSkill:_TryRefreshHatred(phaseData, creature)
  local targetCount = phaseData:GetTargetCount()
  if targetCount <= 0 then
    return
  end
  if nil ~= creature.data and RoleDefines_Camp.ENEMY == creature.data:GetCamp() and TeamProxy.Instance:IHaveTeam() then
    local myTeam = TeamProxy.Instance.myTeam
    for i = 1, targetCount do
      local targetID = phaseData:GetTarget(i)
      if nil ~= myTeam:GetMemberByGuid(targetID) then
        creature:BeHatred(true, UnityTime)
        break
      end
    end
  end
end

function ServerSkill:_SetPhaseData(phaseData, creature)
  self:_Clear(creature)
  if nil ~= phaseData then
    self:SetSkillID(phaseData:GetSkillID())
    phaseData:CopyTo(self.phaseData)
  else
    self:SetSkillID(0)
    self.phaseData:Reset(0)
  end
end

function ServerSkill:_RecordAttackCount()
  if attackFrame ~= UnityFrameCount then
    attackFrame = UnityFrameCount
    attackCount = 1
  else
    attackCount = attackCount + 1
  end
end

function ServerSkill:_SwitchToAttack(creature, ignoreCast)
  self:_RecordAttackCount()
  ServerSkill.super._SwitchToAttack(self, creature, ignoreCast)
end

function ServerSkill:_End(creature)
  self.phaseData:SetSkillPhase(SkillPhase.None)
  ServerSkill.super._End(self, creature)
end

function ServerSkill:_CheckAttackResult(ret, actionPlayed)
  if ret and actionPlayed then
    return ServerSkill.super._CheckAttackResult(self, ret, actionPlayed)
  end
  return self.info and self.info:NoActionNeedFire() or false
end

function ServerSkill:Update_Cast(time, deltaTime, creature)
  return ServerSkill.super.Update_Cast(self, time, deltaTime, creature)
end
