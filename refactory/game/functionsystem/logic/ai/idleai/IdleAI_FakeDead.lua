IdleAI_FakeDead = class("IdleAI_FakeDead")
local UpdateInterval = 0.5
local TryUseSkillInterval = 1
local check
local FindCreature = SceneCreatureProxy.FindCreature
local Sp_Min = 10.0
local Hp_Max = 90.0
local Sp_Max = 90.0
local FakeState = {
  None = 0,
  RequestFakeDead = 1,
  InFakeDead = 2,
  RequestFakeDead_Off = 3
}

function IdleAI_FakeDead:ctor()
  self.nextUpdateTime = 0
  self.nextTryTime = 0
  self.state = FakeState.None
end

function IdleAI_FakeDead:Clear(idleElapsed, time, deltaTime, creature)
  self.nextUpdateTime = 0
  self.nextTryTime = 0
  self.state = FakeState.None
end

function IdleAI_FakeDead:Prepare(idleElapsed, time, deltaTime, creature)
  if nil ~= creature.ai.parent then
    return false
  end
  self.myself = Game.Myself
  if self.myselfProps == nil then
    self.myselfProps = Game.Myself.data and Game.Myself.data.props
  end
  if self.myself.data:IsTransformed() then
    return false
  end
  if Game.AutoBattleManager.on and self.on then
    if self.state ~= FakeState.None then
      return true
    end
    if not self.myself:IsFakeDead() then
      local props = self.myselfProps
      if nil ~= props then
        local maxHP = props:GetPropByName("MaxHp"):GetValue()
        local HP = props:GetPropByName("Hp"):GetValue()
        local maxSP = props:GetPropByName("MaxSp"):GetValue()
        local SP = props:GetPropByName("Sp"):GetValue()
        local hpOption = Game.SkillOptionManager:GetSkillOption(SkillOptionManager.OptionEnum.FakeDead)
        local Hp_Min = hpOption ~= 0 and hpOption or 10
        if (HP <= Hp_Min / 100.0 * maxHP or SP <= Sp_Min / 100.0 * maxSP) and self.skillID ~= nil and 0 < self.skillID and SkillProxy.Instance:SkillCanBeUsedByID(self.skillID) then
          return true
        end
      end
    else
      self.state = FakeState.InFakeDead
      return true
    end
  end
  return false
end

function IdleAI_FakeDead:_TryUseSkill(time, interval)
  if time < self.nextTryTime then
    return
  end
  self.nextTryTime = time + interval
  FunctionSkill.Me():TryUseSkill(self.skillID)
end

function IdleAI_FakeDead:Start(idleElapsed, time, deltaTime, creature)
  self.nextTryTime = 0
  if self.state == FakeState.None then
    self.state = FakeState.RequestFakeDead
  end
end

function IdleAI_FakeDead:End(idleElapsed, time, deltaTime, creature)
  self.nextTryTime = 0
  self.state = FakeState.None
end

function IdleAI_FakeDead:Update(idleElapsed, time, deltaTime, creature)
  if time < self.nextUpdateTime then
    return true
  end
  self.nextUpdateTime = time + UpdateInterval
  if self.state == FakeState.RequestFakeDead then
    if self.myself:IsFakeDead() then
      self.state = FakeState.InFakeDead
    else
      self:_TryUseSkill(time, TryUseSkillInterval)
    end
  elseif self.state == FakeState.InFakeDead then
    if not self.myself:IsFakeDead() then
      return false
    end
    local props = self.myselfProps
    if nil ~= props then
      local maxHP = props:GetPropByName("MaxHp"):GetValue()
      local HP = props:GetPropByName("Hp"):GetValue()
      local maxSP = props:GetPropByName("MaxSp"):GetValue()
      local SP = props:GetPropByName("Sp"):GetValue()
      if HP >= Hp_Max / 100.0 * maxHP and SP >= Sp_Max / 100.0 * maxSP and self.skillID ~= nil and self.skillID > 0 and SkillProxy.Instance:SkillCanBeUsedByID(self.skillID) then
        self:_TryUseSkill(time, TryUseSkillInterval)
        return true
      end
    end
  end
  return true
end

function IdleAI_FakeDead:_Set(on)
  self.on = on
  if self.on then
  else
  end
end

function IdleAI_FakeDead:Set_AutoFakeDead(skillID)
  self.skillID = skillID
  if self.skillID ~= nil and self.skillID > 0 then
    self:_Set(true)
  else
    self:_Set(false)
  end
end
