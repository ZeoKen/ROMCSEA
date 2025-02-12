local baseCell = autoImport("BaseCell")
AttributePointModifyCell = class("AttributePointModifyCell", baseCell)
local hideType = {hideClickSound = true}

function AttributePointModifyCell:Init()
  self:initView()
  self:addViewEventListener()
  self.needNum = 0
  self.originRealPoint = 0
  self.autoRealPoint = 0
  self.originTimeOfAdd = 0
  self.timeOfAdd = 0
  self.leftPoint = nil
end

function AttributePointModifyCell:initView()
  self.cellName = self:FindGO("cellName"):GetComponent(UILabel)
  self.point = self:FindGO("point"):GetComponent(UILabel)
  self.extra = self:FindGO("extra"):GetComponent(UILabel)
  self.currentAdd = self:FindGO("currentAdd"):GetComponent(UILabel)
  self.needNumLabel = self:FindGO("needNum"):GetComponent(UILabel)
  self.addBtnCollider = self:FindGO("plusBg"):GetComponent(BoxCollider)
  self.reduceBtnCollider = self:FindGO("reduceBg"):GetComponent(BoxCollider)
  self.neddNumIndicator = self:FindGO("neddNumIndicator")
  self.reduceBg = self:FindGO("reduceBg"):GetComponent(UISprite)
  self.plusBg = self:FindGO("plusBg"):GetComponent(UISprite)
  self.interference = self:FindGO("Interference")
  self.iValueLabel = self:FindGO("IValue"):GetComponent(UILabel)
end

function AttributePointModifyCell:addViewEventListener()
  local btn = self:FindGO("reduceBg")
  self:SetEvent(btn, function()
    self:reducePointAction()
  end, hideType)
  self.reduceLongPress = btn:GetComponent(UILongPress)
  local longPressFun = function(obj, state)
    if state then
      TimeTickManager.Me():CreateTick(0, 50, self.reducePointAction, self)
    else
      TimeTickManager.Me():ClearTick(self)
    end
  end
  self.reduceLongPress.pressEvent = longPressFun
  btn = self:FindChild("plusBg")
  self:SetEvent(btn, function()
    self:addPointAction()
  end, hideType)
  self.addLongPress = btn:GetComponent(UILongPress)
  
  function longPressFun(obj, state)
    if state then
      TimeTickManager.Me():CreateTick(0, 50, self.addPointAction, self)
    else
      TimeTickManager.Me():ClearTick(self)
    end
  end
  
  self.addLongPress.pressEvent = longPressFun
end

function AttributePointModifyCell:reducePointAction()
  if not self.timeOfAdd or not self.leftPoint then
    return
  end
  local attrTabel = Table_AttributePoint[self.originTimeOfAdd + self.timeOfAdd]
  self.timeOfAdd = self.timeOfAdd - 1
  self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint + attrTabel.NeedPoint
  self:PassEvent(MouseEvent.MouseClick)
  FunctionGuide.Me():attrPointReduceCheck(self.timeOfAdd)
end

function AttributePointModifyCell:addPointAction()
  if not self.timeOfAdd or not self.leftPoint then
    return
  end
  self.timeOfAdd = self.timeOfAdd + 1
  self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint - self.needNum
  self:PassEvent(MouseEvent.MouseClick)
  FunctionGuide.Me():attrPointCheck(self.leftPoint.currentLeftPoint)
end

function AttributePointModifyCell:updateLeftPoint()
  local canAddPoint
  local attrTabel = Table_AttributePoint[self.originTimeOfAdd + self.timeOfAdd + 1]
  if attrTabel ~= nil then
    canAddPoint = true
    self.needNum = attrTabel.NeedPoint
    self.needNumLabel.text = tostring(self.needNum)
  else
    canAddPoint = false
    self.needNumLabel.text = "-"
  end
  canAddPoint = canAddPoint and self.leftPoint.currentLeftPoint >= self.needNum
  if canAddPoint then
    self.plusBg.color = Color(1, 1, 1, 1)
    self.addBtnCollider.enabled = true
    self.addLongPress.enabled = true
    self:Show(self.neddNumIndicator)
  else
    self.plusBg.color = Color(1, 1, 1, 0.5)
    self.addBtnCollider.enabled = false
    self.addLongPress.enabled = false
    self:Hide(self.neddNumIndicator)
  end
  if self.timeOfAdd > 0 then
    self.reduceBg.color = Color(1, 1, 1, 1)
    self.reduceBtnCollider.enabled = true
    self.reduceLongPress.enabled = true
  else
    self.reduceBg.color = Color(1, 1, 1, 0.5)
    self.reduceBtnCollider.enabled = false
    self.reduceLongPress.enabled = false
  end
  self.currentAdd.text = self.timeOfAdd == 0 and "" or "+" .. self.timeOfAdd
end

function AttributePointModifyCell:addPoint(num)
  local complete = true
  for i = 1, num do
    local attrTabel = Table_AttributePoint[self.originTimeOfAdd + self.timeOfAdd + 1]
    if attrTabel ~= nil then
      local needNum = attrTabel.NeedPoint
      if needNum <= self.leftPoint.currentLeftPoint then
        self.timeOfAdd = self.timeOfAdd + 1
        self.autoRealPoint = self.autoRealPoint + 1
        self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint - needNum
      else
        return 1
      end
    else
      return 1
    end
  end
  return 0
end

function AttributePointModifyCell:resetSolution()
  for i = 1, self.autoRealPoint do
    local attrTabel = Table_AttributePoint[self.originTimeOfAdd + self.timeOfAdd]
    if attrTabel ~= nil then
      local needNum = attrTabel.NeedPoint
      self.timeOfAdd = self.timeOfAdd - 1
      self.autoRealPoint = self.autoRealPoint - 1
      self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint + needNum
    else
      return
    end
  end
  self.autoRealPoint = 0
  self:PassEvent(MouseEvent.MouseClick)
end

function AttributePointModifyCell:resetTimeOfAdd()
  for i = 1, self.timeOfAdd do
    local attrTabel = Table_AttributePoint[self.originTimeOfAdd + self.timeOfAdd]
    if attrTabel ~= nil then
      local needNum = attrTabel.NeedPoint
      self.timeOfAdd = self.timeOfAdd - 1
      self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint + needNum
    else
      return
    end
  end
  self.autoRealPoint = 0
  self:updateLeftPoint()
end

function AttributePointModifyCell:clearTimeOfAdd()
  self.timeOfAdd = 0
  self.autoRealPoint = 0
end

function AttributePointModifyCell:GetAttrName()
  if self.data and self.data.prop and self.data.prop.propVO then
    return self.data.prop.propVO.name
  end
end

function AttributePointModifyCell:SetData(data)
  self.data = data
  self.leftPoint = data.leftPoint
  if BranchMgr.IsChina() or BranchMgr.IsTW() then
    self.cellName.text = data.prop.propVO.displayName .. data.prop.propVO.name
  else
    self.cellName.text = data.prop.propVO.name
  end
  self.originTimeOfAdd = data.timeOfAdd
  self.point.text = self.originTimeOfAdd
  self.originRealPoint = self.data.prop:GetValue() - self.data.extraP:GetValue()
  local extra = self.data.prop:GetValue() - self.originTimeOfAdd
  if extra == 0 then
    self.extra.text = ""
  elseif 0 < extra then
    self.extra.text = "+" .. extra
  else
    self.extra.text = ""
    if self.originTimeOfAdd + extra > 0 then
      self.point.text = self.originTimeOfAdd + extra
    else
      self.point.text = 0
    end
  end
  self:updateLeftPoint()
  if self.data.prop.propVO.id == 100 then
    self:AddOrRemoveGuideId(self.plusBg.gameObject, 6)
    self:AddOrRemoveGuideId(self.reduceBg.gameObject, 461)
  elseif self.data.prop.propVO.id == 101 then
    self:AddOrRemoveGuideId(self.plusBg.gameObject, 12)
  else
    self:AddOrRemoveGuideId(self.plusBg.gameObject)
  end
  local iValue = MyselfProxy.Instance:GetMyInterferenceValueByType(self.data.prop.propVO.id)
  if iValue and iValue ~= 0 then
    if 0 < iValue then
      self.iValueLabel.text = "+" .. iValue
    else
      self.iValueLabel.text = iValue
    end
    self.interference:SetActive(true)
  else
    self.interference:SetActive(false)
  end
end

function AttributePointModifyCell:ClearEvent()
  self.reduceLongPress = nil
  self.addLongPress = nil
end
