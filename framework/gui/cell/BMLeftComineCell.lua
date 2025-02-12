local BaseCell = autoImport("BaseCell")
BMLeftComineCell = class("BMLeftComineCell", BaseCell)
autoImport("BMLeftFatherCell")
autoImport("BMLeftChildCell")

function BMLeftComineCell:Init()
  self.gameObject:SetActive(true)
  local fahterObj = self:FindGO("FatherGoal")
  self.tweenScale = self:FindComponent("ChildContainer", TweenScale)
  self.arrow = self:FindGO("Arrow")
  self.fatherTog = fahterObj:GetComponent(UIToggle)
  self.FatherGoal = self:FindGO("FatherGoal")
  self.FatherGoal_UIMultiSprite = self.FatherGoal:GetComponent(UIMultiSprite)
  self.FatherGoal_Label = self:FindGO("Label", self.FatherGoal)
  self.FatherGoal_Label_UILabel = self.FatherGoal_Label:GetComponent(UILabel)
  self.fatherSymbol = self:FindGO("Symbol", fahterObj)
  self.fatherCell = BMLeftFatherCell.new(fahterObj)
  self.fatherCell:AddEventListener(MouseEvent.MouseClick, self.ClickFather, self)
  self.ChildContainer = self:FindGO("ChildContainer")
  self.ChildGoals = self:FindGO("ChildGoals", self.ChildContainer)
  self.ChildGoals_UIGrid = self.ChildGoals:GetComponent(UIGrid)
  self.childSpace = self.ChildGoals_UIGrid.cellHeight
  self.childCtl = UIGridListCtrl.new(self.ChildGoals_UIGrid, BMLeftChildCell, "BMLeftChildCell")
  if self.childCtl == nil then
    helplog("if self.childCtl == nil then")
  end
  self.childCtl:AddEventListener(MouseEvent.MouseClick, self.ClickChild, self)
  self.tweenScale:SetOnFinished(function()
    self:OnTweenScaleOnFinished()
  end)
  self.childBg = self:FindComponent("ChildBg", UISprite)
  self:Hide(self.fatherSymbol)
end

function BMLeftComineCell:ChangeFatherLabelText(str)
  self.FatherGoal_Label_UILabel.text = str
end

function BMLeftComineCell:OnTweenScaleOnFinished()
  if self.folderState then
  else
  end
end

function BMLeftComineCell:ClickFather(cellCtl)
  cellCtl = cellCtl or self.fatherCell
  self:SetChoose(true)
  self:PassEvent(MouseEvent.MouseClick, {
    type = "Father",
    combine = self,
    father = cellCtl
  })
end

function BMLeftComineCell:ClickChild(cellCtl)
  if cellCtl ~= self.nowChild then
    if self.nowChild then
      self.nowChild:SetChoose(false)
    end
    cellCtl:SetChoose(true)
    self.nowChild = cellCtl
  else
    self.nowChild:SetChoose(false)
    self.nowChild = nil
  end
  self:PassEvent(MouseEvent.MouseClick, {
    type = "Child",
    combine = self,
    child = self.nowChild
  })
end

function BMLeftComineCell:ChildrenLayout()
  self.childCtl:Layout()
end

function BMLeftComineCell:GetChildCtl()
  return self.childCtl
end

function BMLeftComineCell:SetData(data)
  self.data = data
  if data.fatherGoal then
    self.fatherCell:SetData(data.fatherGoal)
    self.childCtl:ResetDatas(data.childGoals)
    if #data.childGoals > 0 then
      self.childBg.height = 80 + self.childSpace * #data.childGoals
    else
      self:Hide(self.fatherSymbol)
    end
  else
    helplog("if(data.fatherGoal)then == nil")
  end
end

function BMLeftComineCell:SetChoose(choose)
  self.FatherGoal_UIMultiSprite.CurrentState = choose and 1 or 0
  self.FatherGoal_Label_UILabel.effectColor = choose and Color(0.6235294117647059, 0.30980392156862746, 0.03529411764705882) or Color(0.11372549019607843, 0.17647058823529413, 0.4627450980392157)
  if self.nowChild then
    self.nowChild:SetChoose(false)
    self.nowChild = nil
  end
  self.choose = true
end

function BMLeftComineCell:GetChoose()
  return self.choose
end

function BMLeftComineCell:GetFolderState()
  return self.folderState == true
end

function BMLeftComineCell:PlayReverseAnimation()
  self:SetFolderState(not self.folderState)
end

local tempV3 = LuaVector3()
local tempRot = LuaQuaternion()

function BMLeftComineCell:SetFolderState(isOpen)
  if self.folderState ~= isOpen then
    self.folderState = isOpen
    if isOpen then
      tempV3[1] = 0
      self.tweenScale:PlayForward()
    else
      tempV3[1] = 180
      self.tweenScale:PlayReverse()
    end
    LuaQuaternion.Better_SetEulerAngles(tempRot, tempV3)
    self.arrow.transform.rotation = tempRot
  end
end

function BMLeftComineCell:SetFolderStateForTopId4(isOpen)
  if self.folderState ~= isOpen then
    self.folderState = isOpen
  end
end

function BMLeftComineCell:PlayReverseAnimationForTopId4()
  self:SetFolderStateForTopId4(not self.folderState)
end
