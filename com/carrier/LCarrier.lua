LCarrier = reusableClass("LCarrier")
LCarrier.PoolSize = 10
LCarrier.Status = {
  Wait = 0,
  Moving = 1,
  Arrived = 2
}
LCarrier.MasterSeat = -1
local tmpPos = LuaVector3.Zero()

function LCarrier:ctor()
  LCarrier.super.ctor(self)
  self.member = {}
  self.objRenderers = {}
end

function LCarrier:DoConstruct(asArray, serverData)
  self.myselfID = Game.Myself.data.id
  self.status = LCarrier.Status.Wait
  self.iAmMaster = false
  self.isMine = false
  self.masterID = 0
  self.carrierID = -1
  self.line = -1
  self.progress = 0
  self.destroyed = false
end

function LCarrier:DoDeconstruct(asArray)
  TableUtility.TableClear(self.objRenderers)
end

function LCarrier:SetIsMine(value)
  if self.isMine ~= value then
    self.isMine = value
    if self.carrier then
      if value then
        if self:IsWaiting() then
          self:Visible(true)
        end
        
        function self.carrier.progressListener(info)
          ServiceCarrierCmdProxy.Instance:CallCarrierMoveUserCmd(info.position, info.progress * 100)
        end
        
        function self.carrier.arrivedListener(info)
          self:Arrive()
          ServiceCarrierCmdProxy.Instance:CallReachCarrierUserCmd(info.position)
        end
      else
        self.carrier.progressListener = nil
        self.carrier.arrivedListener = nil
      end
    end
  end
end

function LCarrier:Visible(value)
  if self.carrier then
    local tarLayer = value and Game.ELayer.Default or Game.ELayer.InVisible
    for i = 1, #self.objRenderers do
      if self.objRenderers[i] then
        self.objRenderers[i].layer = tarLayer
      end
    end
  end
  self.visiblity = value
  local passenger
  for k, v in pairs(self.member) do
    passenger = SceneCreatureProxy.FindCreature(k)
    self:_VisiblePlayer(passenger, value)
  end
end

function LCarrier:_VisiblePlayer(player, value)
  if player then
    player:SetVisible(value, LayerChangeReason.CarrierWaiting)
    self:_VisiblePlayerUI(player, value)
  end
end

function LCarrier:_VisiblePlayerUI(player, value)
  if value then
    FunctionPlayerUI.Me():UnMaskAllUI(player, PUIVisibleReason.CarrierWait)
  else
    FunctionPlayerUI.Me():MaskAllUI(player, PUIVisibleReason.CarrierWait)
  end
end

function LCarrier:SetIAmMaster(value)
  if self.iAmMaster ~= value then
    self.iAmMaster = value
  end
end

function LCarrier:CreateBus()
  TableUtility.TableClear(self.objRenderers)
  if self.carrier == nil and self.carrierID > 0 then
    self.carrier = BusManager.Instance:CloneBus(self.carrierID)
    if self.carrier and self.carrier.gameObject then
      local renderers = self.carrier.gameObject:GetComponentsInChildren(Renderer, true)
      if renderers then
        for i = 1, #renderers do
          self.objRenderers[#self.objRenderers + 1] = renderers[i].gameObject
        end
      end
    end
    self:Visible(false)
  end
end

function LCarrier:DestroyCarrier(pos)
  self.destroyed = true
  TableUtility.TableClear(self.objRenderers)
  if self.carrier then
    local passenger
    for k, v in pairs(self.member) do
      self:GetOff(k, pos)
    end
    if self.carrier and not Game.GameObjectUtil:ObjectIsNULL(self.carrier.gameObject) and not self.isMine then
      GameObject.Destroy(self.carrier.gameObject)
    end
    self.carrier = nil
  end
  if not self.isMine then
    self:Destroy()
  end
end

function LCarrier:IsWaiting()
  return self.status == LCarrier.Status.Wait
end

function LCarrier:IsMoving()
  return self.status == LCarrier.Status.Moving
end

function LCarrier:Reset(masterID, carrierID)
  self.masterID = masterID
  self.carrierID = carrierID or self.carrierID
  self:CreateBus()
  self:SetIAmMaster(self.masterID == self.myselfID)
end

function LCarrier:StartMove()
  if self.status ~= LCarrier.Status.Moving then
    self.status = LCarrier.Status.Moving
    self:Visible(true)
    self.carrier:GO(self.line, self.progress)
    if self.progress ~= 0 then
      self.carrier:ActionEventPlayAction("walk")
    end
    return true
  end
  return false
end

function LCarrier:Arrive()
  self.status = LCarrier.Status.Arrived
end

function LCarrier:GetOn(memberID, index, needAnim)
  local oldIndex = self.member[memberID]
  if memberID == self.myselfID then
    self:SetIsMine(true)
  end
  self.member[memberID] = index
  SceneCarrierProxy.Instance:SetInCarrier(memberID, self)
  helplog("LCarrier:GetOn", memberID, index, self.carrier)
  if self.carrier then
    if oldIndex ~= nil or memberID ~= self.myselfID then
      local passenger = SceneCreatureProxy.FindCreature(memberID)
      self:_GetOn(passenger, index)
    else
      Game.Myself:SetOnCarrier(true)
      FunctionBus.Me():Launch(self.carrier, self.carrierID, index, needAnim)
    end
  end
end

function LCarrier:MyForceLeave(pos)
  if pos then
    ProtolUtility.Better_S2C_Vector3(pos, tmpPos)
  else
    tmpPos[1], tmpPos[2], tmpPos[3] = 0, 0, 0
  end
  SceneCarrierProxy.Instance:SetInCarrier(self.myselfID, nil)
  self.member[self.myselfID] = nil
  if self.carrier then
    if self.myselfID ~= self.masterID and not self.destroyed then
      FunctionBus.Me():SetBusNil()
    else
    end
    FunctionBus.Me():Shutdown(tmpPos, function()
      Game.Myself:SetOnCarrier(false)
      self:SetIsMine(false)
      self:Visible(false)
      if self.destroyed then
        self:Destroy()
      end
    end, true)
  end
end

function LCarrier:GetOff(memberID, pos)
  if pos then
    ProtolUtility.Better_S2C_Vector3(pos, tmpPos)
  else
    tmpPos[1], tmpPos[2], tmpPos[3] = 0, 0, 0
  end
  self.member[memberID] = nil
  SceneCarrierProxy.Instance:SetInCarrier(memberID, nil)
  if self.carrier then
    if memberID == self.myselfID then
      if self.myselfID ~= self.masterID and not self.destroyed then
        FunctionBus.Me():SetBusNil()
      else
      end
      FunctionBus.Me():Shutdown(tmpPos, function()
        Game.Myself:SetOnCarrier(false)
        self:SetIsMine(false)
        self:Visible(false)
        if self.destroyed then
          self:Destroy()
        end
      end)
    else
      local passenger = SceneCreatureProxy.FindCreature(memberID)
      self:_GetOff(passenger, tmpPos)
    end
  end
end

function LCarrier:_GetOn(creature, seatID)
  if creature then
    local seat = self.carrier:GetSeat(seatID)
    if seat then
      creature:SetOnCarrier(true)
      local actionName = Table_Bus[self.carrierID] and Table_Bus[self.carrierID].RaiderAction
      if not StringUtil.IsEmpty(actionName) then
        creature.assetRole:PlayAction_Simple(actionName)
      else
        creature.assetRole:PlayAction_Sitdown()
      end
      creature:SetParent(seat.transform)
      creature.assetRole:SetShadowEnable(false)
      creature:Client_SetDirCmd(AI_CMD_SetAngleY.Mode.SetAngleY, 0, true)
    end
    self:_VisiblePlayer(creature, self.visiblity)
  end
end

function LCarrier:_GetOff(creature, pos)
  if creature then
    creature:SetOnCarrier(false)
    FunctionSystem.InterruptCreature(creature)
    creature.assetRole:SetShadowEnable(true)
    creature:SetParent(nil)
    pos = pos or creature:GetPosition()
    creature:Client_PlaceXYZTo(pos[1], pos[2], pos[3])
    self:_VisiblePlayer(creature, true)
  end
end

function LCarrier:SetProgress(progress)
  self.progress = progress
  if self.carrier and self:IsMoving() then
    self.carrier:GO(self.line, self.progress)
  end
end

function LCarrier:AllGetOffAtOnce()
  local passenger, pos
  for id, index in pairs(self.member) do
    passenger = SceneCreatureProxy.FindCreature(id)
    if passenger then
      self:_GetOff(passenger)
    end
  end
end

function LCarrier:AllReGetOn()
  local passenger, pos
  for id, index in pairs(self.member) do
    passenger = SceneCreatureProxy.FindCreature(id)
    self:_GetOn(passenger, index)
  end
end

function LCarrier:ChangeCarrier(carrierID)
  if carrierID ~= self.carrierID then
    self.carrierID = carrierID
    self:AllGetOffAtOnce()
    self.carrier:SResetAllCarriers(ResourcePathHelper.BusCarrier(carrierID))
    self:AllReGetOn()
  end
end

function LCarrier:HasMultiSeat()
  local seatCount = self.carrier:GetSeatCount()
  if seatCount < 2 then
    return false
  end
  local realSeatCount = 0
  local seat
  for i = 0, seatCount do
    seat = self.carrier:GetSeat(i)
    if not Slua.IsNull(seat) then
      realSeatCount = realSeatCount + 1
    end
    if 1 < realSeatCount then
      return true
    end
  end
  return false
end
