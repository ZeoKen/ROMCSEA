autoImport("Logic_Transform_DirMove")
Logic_Transform = class("Logic_Transform")
local Thread_CheckThroughWall = 0.4
local IsCloseToWall = NavMeshUtils.IsCloseToWall
local tempVector3_1 = LuaVector3.New()

function Logic_Transform:ctor()
  self.speed = {
    1,
    1,
    1,
    1,
    1
  }
  self.extraLogics = {DirMove = nil}
  self._alive = false
end

function Logic_Transform:SetOwner(owner)
  self.owner = owner
end

function Logic_Transform:Construct()
  if self._alive then
    return
  end
  self._alive = true
  self.targetPosition = nil
  self.targetAngleY = nil
  self.targetScale = nil
  self.currentPosition = LuaVector3.New(10000, 10000, 10000)
  self.currentAngleY = 0
  self.currentScale = LuaVector3.One()
  self.useNavMesh = nil
  self.navMeshPathAgent = nil
  self.nextCorner = nil
  self.cornerIndex = nil
  self.lockRotationValue = nil
  self.targetAngleX = nil
end

function Logic_Transform:Deconstruct()
  if not self._alive then
    return
  end
  self.targetPosition = LuaVector3.Destroy(self.targetPosition)
  self.currentPosition = LuaVector3.Destroy(self.currentPosition)
  self.targetScale = LuaVector3.Destroy(self.targetScale)
  self.currentScale = LuaVector3.Destroy(self.currentScale)
  self.navMeshPathAgent = nil
  self.nextCorner = LuaVector3.Destroy(self.nextCorner)
  if self.extraLogics.DirMove then
    self.extraLogics.DirMove:Destroy()
    self.extraLogics.DirMove = nil
  end
  self._alive = false
end

local tempExtraDirMoveArgs = {}

function Logic_Transform:ExtraDirMove(dirAngleY, distance, speed, callback, callbackArg, dirPoint, ignoreTerrain)
  tempExtraDirMoveArgs[1] = dirAngleY
  tempExtraDirMoveArgs[2] = distance
  tempExtraDirMoveArgs[3] = speed
  tempExtraDirMoveArgs[4] = callback
  tempExtraDirMoveArgs[5] = callbackArg
  tempExtraDirMoveArgs[6] = dirPoint
  tempExtraDirMoveArgs[7] = ignoreTerrain
  if self.extraLogics.DirMove then
    self.extraLogics.DirMove:Destroy()
  end
  self.extraLogics.DirMove = Logic_Transform_DirMove.Create(tempExtraDirMoveArgs)
end

function Logic_Transform:SetMoveSpeed(v)
  self.speed[1] = v
end

function Logic_Transform:GetMoveSpeed()
  return self.speed[1]
end

function Logic_Transform:GetMoveSpeedWithFastForward()
  return self.speed[1] * self.speed[4]
end

function Logic_Transform:SetFastForwardSpeed(v)
  self.speed[4] = v
end

function Logic_Transform:GetFastForwardSpeed()
  return self.speed[4]
end

function Logic_Transform:SetTargetPosition(p)
  self.targetPosition = VectorUtility.Asign_3(self.targetPosition, p)
end

function Logic_Transform:NavMeshMoveTo(p, sampleRange)
  if self.useNavMesh and nil ~= self.targetPosition and VectorUtility.AlmostEqual_3(self.targetPosition, p) then
    return true
  end
  local ret, newP = NavMeshUtility.Better_Sample(p, tempVector3_1, sampleRange)
  if not ret then
    return false
  end
  self.useNavMesh = true
  if nil == self.currentPosition then
    self:PlaceTo(newP)
    return true
  end
  self.targetPosition = VectorUtility.Asign_3(self.targetPosition, newP)
  if nil == self.navMeshPathAgent then
    self.navMeshPathAgent = NavMeshPathAgent()
    if not BackwardCompatibilityUtil.CompatibilityMode_V37 then
      self.navMeshPathAgent.pathRadius = 0
    end
  else
    self.navMeshPathAgent:Clear()
  end
  if not self:_CalcNavMeshPath() then
    self:StopMove()
    return false
  end
  return true
end

function Logic_Transform:MoveTo(p, rotateToP)
  self.useNavMesh = false
  self.targetPosition = VectorUtility.Asign_3(self.targetPosition, p)
  self:RotateTo(rotateToP or p)
end

function Logic_Transform:NavMeshPlaceTo(p, sampleRange)
  self.targetPosition = LuaVector3.Destroy(self.targetPosition)
  LuaVector3.Better_Set(self.currentPosition, p[1], p[2], p[3])
  NavMeshUtility.SelfSample(self.currentPosition, sampleRange or 1)
end

function Logic_Transform:PlaceTo(p)
  self.targetPosition = LuaVector3.Destroy(self.targetPosition)
  LuaVector3.Better_Set(self.currentPosition, p[1], p[2], p[3])
end

function Logic_Transform:SamplePosition(sampleRange)
  NavMeshUtility.SelfSample(self.currentPosition, sampleRange)
end

function Logic_Transform:StopMove()
  self.cornerIndex = 0
  self.targetPosition = LuaVector3.Destroy(self.targetPosition)
end

function Logic_Transform:SetRotateSpeed(v)
  self.speed[2] = v
end

function Logic_Transform:GetRotateSpeed()
  return self.speed[2]
end

function Logic_Transform:GetRotateSpeedWithScale()
  return self.speed[2] * self.speed[5]
end

function Logic_Transform:SetRotateSpeedScale(v)
  self.speed[5] = v
end

function Logic_Transform:GetRotateSpeedScale()
  return self.speed[5]
end

function Logic_Transform:RotateTo(p)
  if not p then
    return
  end
  if self:IsLockRotation() then
    return
  end
  if nil == self.currentAngleY then
    self.currentAngleY = VectorHelper.GetAngleByAxisY(self.currentPosition, p)
    return
  end
  if not VectorUtility.AlmostEqual_3_XZ(self.currentPosition, p) then
    self.targetAngleY = VectorHelper.GetAngleByAxisY(self.currentPosition, p)
  end
end

function Logic_Transform:LookAt(p)
  if self:IsLockRotation() then
    return
  end
  self.targetAngleY = nil
  self.currentAngleY = VectorHelper.GetAngleByAxisY(self.currentPosition, p)
end

function Logic_Transform:SetTargetAngleY(v)
  if self:IsLockRotation() then
    return
  end
  if nil == self.currentAngleY then
    self.currentAngleY = v
    return
  end
  self.targetAngleY = v
end

function Logic_Transform:SetAngleY(v, force)
  if not force then
    if self:IsLockRotation() then
      return
    end
    if self.targetPosition then
      self:RotateTo(self.nextCorner)
      return
    end
  end
  self.targetAngleY = nil
  self.currentAngleY = v
end

function Logic_Transform:StopRotation()
  self.targetAngleY = nil
end

function Logic_Transform:SetScaleSpeed(v)
  self.speed[3] = v
end

function Logic_Transform:GetScaleSpeed()
  return self.speed[3]
end

function Logic_Transform:ScaleTo(v)
  if nil ~= self.targetScale then
    LuaVector3.Better_Set(self.targetScale, v, v, v)
  else
    self.targetScale = LuaVector3.New(v, v, v)
  end
end

function Logic_Transform:SetScale(v)
  self.targetScale = LuaVector3.Destroy(self.targetScale)
  LuaVector3.Better_Set(self.currentScale, v, v, v)
end

function Logic_Transform:ScaleToXYZ(x, y, z)
  if nil ~= self.targetScale then
    LuaVector3.Better_Set(self.targetScale, x, y, z)
  else
    self.targetScale = LuaVector3.New(x, y, z)
  end
end

function Logic_Transform:SetScaleXYZ(x, y, z)
  self.targetScale = LuaVector3.Destroy(self.targetScale)
  LuaVector3.Better_Set(self.currentScale, x, y, z)
end

function Logic_Transform:StopScaling()
  self.targetScale = LuaVector3.Destroy(self.targetScale)
end

function Logic_Transform:_MoveToNextCorner()
  self.cornerIndex = self.cornerIndex + 1
  local ret, x, y, z = self.navMeshPathAgent:GetCorner(self.cornerIndex)
  if ret then
    if nil == self.nextCorner then
      self.nextCorner = LuaVector3.New(x, y, z)
    else
      LuaVector3.Better_Set(self.nextCorner, x, y, z)
    end
    self:RotateTo(self.nextCorner)
    if nil ~= self.owner then
      self.owner:Logic_OnMoveToNextCorner(self.nextCorner)
    end
  end
  return ret
end

local Path_Equal = function(p1, p2)
  if p1 == nil or p2 == nil then
    return false
  end
  if #p1 ~= #p2 then
    return false
  end
  for i = 1, #p1 do
    if p1[i][1] ~= p2[i][1] or p1[i][2] ~= p2[i][2] or p1[i][3] ~= p2[i][3] then
      return false
    end
  end
  return true
end

function Logic_Transform:_TryCalcNavMeshPath(currentPosition, targetPosition)
  local ret, x, y, z = self.navMeshPathAgent:Calc(self.currentPosition, self.targetPosition)
  if self._samePathCount == nil then
    self._samePathCount = 0
  end
  if ret then
    local samePath = self.cacheCornors ~= nil and self.navMeshPathAgent:CompareToCurrentPath(self.cacheCornors)
    if samePath then
      self._samePathCount = self._samePathCount + 1
    elseif self._samePathCount > 0 then
      self._samePathCount = 0
      self.cacheCornors = nil
    else
      self.cacheCornors = self.navMeshPathAgent.corners
    end
  else
    self._samePathCount = 0
    self.cacheCornors = nil
  end
  return ret, x, y, z, self._samePathCount > 1
end

function Logic_Transform:_CalcNavMeshPath()
  local ret, x, y, z, samePath = self:_TryCalcNavMeshPath(self.currentPosition, self.targetPosition)
  if ret then
    if self.navMeshPathAgent.complete or self.navMeshPathAgent.completePartial then
      LuaVector3.Better_Set(self.targetPosition, x, y, z)
      if not samePath or self.cornerIndex == nil then
        self.cornerIndex = 0
      end
      if not self:_MoveToNextCorner() then
        ret = false
      end
    elseif self.navMeshPathAgent.invalid then
      ret = false
    end
  end
  return ret
end

function Logic_Transform:LockRotation(isLock)
  self.lockRotationValue = (self.lockRotationValue or 0) + (isLock and 1 or -1)
end

function Logic_Transform:IsLockRotation()
  return self.lockRotationValue and self.lockRotationValue > 0
end

function Logic_Transform:Update(time, deltaTime)
  if nil ~= self.targetPosition then
    if self.useNavMesh then
      if self.navMeshPathAgent.idle then
        if not self:_CalcNavMeshPath() then
          self:StopMove()
        end
      elseif self.navMeshPathAgent.complete or self.navMeshPathAgent.completePartial then
        local deltaDistance = self:GetMoveSpeedWithFastForward() * deltaTime
        LuaVector3.SelfMoveTowards(self.currentPosition, self.nextCorner, deltaDistance)
        if VectorUtility.AlmostEqual_3(self.currentPosition, self.nextCorner) and not self:_MoveToNextCorner() then
          VectorUtility.Asign_3(self.currentPosition, self.nextCorner)
          self:StopMove()
        end
      elseif self.navMeshPathAgent.invalid then
        self:StopMove()
      end
    else
      local deltaDistance = self:GetMoveSpeedWithFastForward() * deltaTime
      if deltaDistance > Thread_CheckThroughWall and IsCloseToWall(self.currentPosition, Thread_CheckThroughWall) then
        deltaDistance = 0.2
      end
      LuaVector3.SelfMoveTowards(self.currentPosition, self.targetPosition, deltaDistance)
      if VectorUtility.AlmostEqual_3(self.currentPosition, self.targetPosition) then
        VectorUtility.Asign_3(self.currentPosition, self.targetPosition)
        self:StopMove()
      end
    end
  end
  if nil ~= self.targetAngleY then
    local deltaAngle = self:GetRotateSpeedWithScale() * deltaTime
    self.currentAngleY = NumberUtility.MoveTowardsAngle(self.currentAngleY, self.targetAngleY, deltaAngle)
    if NumberUtility.AlmostEqualAngle(self.currentAngleY, self.targetAngleY) then
      self.currentAngleY = self.targetAngleY
      self:StopRotation()
    end
  end
  if nil ~= self.targetScale then
    local deltaScale = self.speed[3] * deltaTime
    LuaVector3.SelfMoveTowards(self.currentScale, self.targetScale, deltaScale)
    if VectorUtility.AlmostEqual_3(self.currentScale, self.targetScale) then
      VectorUtility.Asign_3(self.currentScale, self.targetScale)
      self:StopScaling()
    end
  end
  if self.extraLogics.DirMove then
    self.extraLogics.DirMove:Update(self, time, deltaTime)
    if not self.extraLogics.DirMove.running then
      self.extraLogics.DirMove:Destroy()
      self.extraLogics.DirMove = nil
    end
  end
end

function Logic_Transform:SetAngleX(v)
  if self:IsLockRotation() then
    return
  end
  self.targetAngleX = v
end

function Logic_Transform:GetAngleX()
  return self.targetAngleX
end

function Logic_Transform:LookAtTargetPos()
  if not self.targetPosition then
    return
  end
  self:RotateTo(self.nextCorner or self.targetPosition)
end

function Logic_Transform:GetCurAngleY()
  return self.currentAngleY or 0
end

function Logic_Transform:IsRotating()
  return self.targetAngleY
end
