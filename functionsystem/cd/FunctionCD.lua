autoImport("CDProxy")
FunctionCD = class("FunctionCD")

function FunctionCD:ctor(interval)
  interval = interval or 33
  self:Reset()
  self.timeTick = TimeTickManager.Me():CreateTick(0, interval, self.Update, self, 1, true)
end

function FunctionCD:Reset()
  self:SetEnable(false)
  self.objs = {}
end

function FunctionCD:SetInterval(time)
  self.interval = time
  self.passedTime = 0
end

function FunctionCD:IsRunning()
  if self.timeTick ~= nil then
    return self.timeTick.isTicking
  end
  return self.running
end

function FunctionCD:SetEnable(val)
  if self.timeTick ~= nil then
    if val then
      self.timeTick:StartTick()
    else
      self.timeTick:StopTick()
    end
  end
  self.running = val
  if not val then
    self.passedTime = 0
  end
end

function FunctionCD:Update(deltaTime)
  for k, v in pairs(self.objs) do
    if v:RefreshCD(deltaTime) then
      self.objs[k] = nil
    end
  end
end

function FunctionCD:Add(obj)
  self.objs[obj.id] = obj
  self:Update()
end

function FunctionCD:Remove(obj)
  if type(obj) == "table" then
    obj = obj.id
  end
  local removed = self.objs[obj]
  if removed and removed.ClearCD then
    removed:ClearCD()
  end
  self.objs[obj] = nil
end

function FunctionCD:RemoveAll()
  self:Reset()
end

function FunctionCD:IsEmpty()
  for k, v in pairs(self.objs) do
    return false
  end
  return true
end

function FunctionCD:Destroy()
  if self.timeTick ~= nil then
    TimeTickManager.Me():ClearTick(self)
    self.timeTick = nil
  end
end
