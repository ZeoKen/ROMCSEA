SkillFreeCast = class("SkillFreeCast", ReusableObject)
SkillFreeCast.PoolSize = 5
local CreatureHideOpt = Asset_Effect.DeActiveOpt.CreatureHide
local Idle = Asset_Role.ActionName.Idle
local FindCreature = SceneCreatureProxy.FindCreature
local tempArgs = {
  [1] = nil,
  [2] = nil,
  [3] = nil,
  [4] = nil
}
local tempEffectArray = {}

function SkillFreeCast.GetArgs(creature, skillInfo)
  tempArgs[1] = skillInfo:GetSkillID()
  tempArgs[2] = skillInfo:GetCastInfo(creature)
  tempArgs[3] = creature.skill.targetCreatureGUID
  tempArgs[4] = creature.skill.phaseData:Clone()
  return tempArgs
end

function SkillFreeCast.Create(args)
  return ReusableObject.Create(SkillFreeCast, true, args)
end

function SkillFreeCast:ctor()
  self.effects = {}
  self.ses = {}
end

function SkillFreeCast:Update(time, deltaTime, creature)
  if not self.running then
    return
  end
  if self.phaseData:GetSkillPhase() == SkillPhase.None then
    self:_SwitchToFreeCast(creature)
  end
  if not self:Update_FreeCast(time, deltaTime, creature) then
    return
  end
  self.castTimeElapsed = self.castTimeElapsed + deltaTime
  if self.castTime < self.castTimeElapsed then
    self:_SwitchToAttack(creature)
  end
end

function SkillFreeCast:Update_FreeCast(time, deltaTime, creature)
  if creature.assetRole:IsPlayingAction(Idle) then
    self.info.LogicClass.CastPlayAction(self, creature)
    if self.targetCreatureGUID ~= 0 then
      local targetCreature = FindCreature(self.targetCreatureGUID)
      if targetCreature ~= nil then
        creature.logicTransform:LookAt(targetCreature:GetPosition())
      end
    else
      creature.logicTransform:LookAt(self.phaseData:GetPosition())
    end
  end
  return true
end

function SkillFreeCast:_SwitchToFreeCast(creature)
  self.phaseData:SetSkillPhase(SkillPhase.FreeCast)
  if self.info.LogicClass.FreeCast(self, creature) then
    self:_OnPhaseChanged(creature)
  else
    self:_End(creature)
  end
end

function SkillFreeCast:_SwitchToNone(creature)
  self.phaseData:SetSkillPhase(SkillPhase.None)
  self:_End(creature)
end

function SkillFreeCast:_SwitchToAttack(creature)
  self.phaseData:SetSkillPhase(SkillPhase.Attack)
  self:_End(creature)
end

function SkillFreeCast:InterruptCast(creature)
  if self.running and self.phaseData:GetSkillPhase() == SkillPhase.FreeCast then
    self.phaseData:SetSkillPhase(SkillPhase.None)
    self:_End(creature)
  end
end

function SkillFreeCast:AddEffect(effect)
  if effect == nil then
    return
  end
  if self.visible == false then
    effect:SetActive(self.visible, CreatureHideOpt)
  end
  TableUtility.ArrayPushBack(self.effects, effect)
  effect:RegisterWeakObserver(self)
end

function SkillFreeCast:ObserverDestroyed(effect)
  TableUtility.ArrayRemove(self.effects, effect)
end

function SkillFreeCast:AddSE(se)
  TableUtility.ArrayPushBack(self.ses, se)
end

function SkillFreeCast:SetEffectVisible(visible)
  if self.visible ~= visible then
    self.visible = visible
    local effect
    for i = 1, #self.effects do
      effect = self.effects[i]
      if effect ~= nil then
        effect:SetActive(self.visible, CreatureHideOpt)
      end
    end
  end
end

function SkillFreeCast:GetSkillID()
  return self.info:GetSkillID()
end

function SkillFreeCast:_OnPhaseChanged(creature)
  local newPhase = self.phaseData:GetSkillPhase()
  if self.oldPhase == newPhase then
    return
  end
  if SkillPhase.FreeCast == newPhase then
    self:_OnLaunch(creature)
    creature:Logic_FreeCastBegin()
    self:LaunchCastWarningEffect(creature)
  elseif SkillPhase.FreeCast == self.oldPhase then
    creature:Logic_FreeCastEnd()
    self:ShutdownCastWarningEffect(creature)
  end
  self.oldPhase = newPhase
end

function SkillFreeCast:_OnLaunch(creature)
  local skillName = self.info:GetSpeakName(creature)
  if nil == skillName then
    return
  end
  if self.info:NoSpeak(creature) then
    return
  end
  local sceneUI = creature:GetSceneUI()
  if nil ~= sceneUI then
    sceneUI.roleTopUI:SpeakSkill(skillName)
  end
end

function SkillFreeCast:_End(creature)
  self:_Clear(creature)
  self.running = false
  self:_OnPhaseChanged(creature)
end

function SkillFreeCast:_DestroyEffects(creature)
  TableUtility.ArrayShallowCopy(tempEffectArray, self.effects)
  TableUtility.ArrayClear(self.effects)
  for i = #tempEffectArray, 1, -1 do
    tempEffectArray[i]:Destroy()
    tempEffectArray[i] = nil
  end
end

function SkillFreeCast:_DestroySEs(creature)
  for i = #self.ses, 1, -1 do
    self.ses[i]:Stop()
    self.ses[i] = nil
  end
end

function SkillFreeCast:_Clear(creature)
  self:_DestroyEffects(creature)
  self:_DestroySEs(creature)
end

function SkillFreeCast:LaunchCastWarningEffect(creature)
  if self.info:ShowWarningEffect() then
    self:ShowWarningEffect(creature)
  end
end

function SkillFreeCast:ShowWarningEffect(creature)
  if creature then
    local path = self:GetCastWarningEffectPath(creature)
    if not path then
      return
    end
    local key = self.info:GetSkillID()
    local castTime = self:GetCastTime(creature)
    local endSize, endSize2 = self.info:GetShowLength(creature)
    local scale = creature:GetScale() or 1
    self.sourceCreatureGuid = creature.data.id
    if scale ~= 0 and endSize then
      creature:PlayCastWarningEffect(key, path, endSize / scale, (endSize2 or endSize) / scale, castTime)
    end
  end
end

function SkillFreeCast:GetCastWarningEffectPath(creature)
  if self.info.logicParam.angle then
    return EffectMap.SkillEffectMap.Eff_sector_buff
  elseif self.info.logicParam.range then
    return EffectMap.SkillEffectMap.Eff_circular_buff
  elseif self.info.logicParam.distance then
    return EffectMap.SkillEffectMap.Eff_square_buff
  end
  return nil
end

function SkillFreeCast:GetCastTime(creature)
  local castTime, _ = self.info:GetCastInfo(creature)
  return castTime
end

function SkillFreeCast:ShutdownCastWarningEffect(creature)
  local sourceCreature = creature
  if not sourceCreature and self.sourceCreatureGuid then
    local guid = self.phaseData:GetSkillPhase()
    sourceCreature = FindCreature(self.sourceCreatureGuid)
  end
  local key = self.info:GetSkillID()
  if sourceCreature then
    sourceCreature:ClearCastWarningEffect(key)
  end
end

function SkillFreeCast:DoConstruct(asArray, args)
  self.running = true
  self.visible = true
  self.castTimeElapsed = 0
  self.oldPhase = SkillPhase.None
  self.info = Game.LogicManager_Skill:GetSkillInfo(args[1])
  self.castTime = args[2]
  self.targetCreatureGUID = args[3]
  self.phaseData = args[4]
  self.phaseData:SetSkillPhase(self.oldPhase)
end

function SkillFreeCast:DoDeconstruct(asArray)
  self:ShutdownCastWarningEffect(creature)
  self.sourceCreatureGuid = nil
  self.running = nil
  self.visible = nil
  self.castTimeElapsed = nil
  self.oldPhase = nil
  self.info = nil
  self.castTime = nil
  self.targetCreatureGUID = nil
  if self.phaseData ~= nil then
    self.phaseData:Destroy()
    self.phaseData = nil
  end
  self:_Clear()
end
