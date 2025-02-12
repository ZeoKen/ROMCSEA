local BaseCell = autoImport("BaseCell")
BalanceModeSkillCell = class("BalanceModeSkillCell", BaseCell)
local vector3 = LuaVector3.Zero()

function BalanceModeSkillCell:Init()
  self.skillName = self:FindGO("SkillName"):GetComponent(UILabel)
  self.nameBg = self:FindGO("NameBg"):GetComponent(UIMultiSprite)
  self.skillIcon = self:FindGO("SkillIcon"):GetComponent(UISprite)
  self.clickCell = self:FindGO("SkillBg")
  self.dragDrop = DragDropCell.new(self.clickCell:GetComponent(UIDragItem), 0.1)
  self.dragDrop.dragDropComponent.data = self
  self.dragDrop.dragDropComponent.OnCursor = DragCursorPanel.Instance.ShowItemCell_NoQuality
  self:SetEvent(self.clickCell, function()
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
  self:SetDoubleClick(self.clickCell, function()
    self:PassEvent(MouseEvent.DoubleClick, self)
  end)
  
  function self.dragDrop.dragDropComponent.OnStart(data)
    GameFacade.Instance:sendNotification(DragDropEvent.StartDrag, self)
  end
  
  function self.dragDrop.onManualEndDrag()
    GameFacade.Instance:sendNotification(DragDropEvent.EndDrag, self)
  end
  
  self.circleBg = self:FindGO("CircleBg")
  self.chooseSymbol = self:FindGO("ChooseSymbol")
  self.circleBg:SetActive(true)
  self.skillIcon.width = 60
  self.skillIcon.height = 60
  self.nameBg.CurrentState = 1
  LuaVector3.Better_Set(vector3, 67, 0, 0)
  self.nameBg.transform.localPosition = vector3
  self.nameBg.width = 186
  self:UpdateDragable()
end

function BalanceModeSkillCell:SetData(data)
  self.data = data
  self.type = data and data.type
  self.isArtifact = data and data.isArtifact
  self.id = data and data.id
  self.staticData = self.id and Table_Item[self.id]
  if not self.staticData then
    redlog("缺少遗物或者萃取配置", self.id)
    return
  end
  if self.type == 1 or self.type == 2 then
    local equipExtraceionInfo = Table_EquipExtraction[self.id]
    if equipExtraceionInfo then
      IconManager:SetItemIcon(self.staticData.Icon, self.skillIcon)
      self.skillName.text = self.staticData.NameZh
    end
  elseif self.isArtifact ~= nil then
    local artifactData = Table_PersonalArtifactCompose[self.id]
    if artifactData then
      IconManager:SetItemIcon(self.staticData.Icon, self.skillIcon)
      self.skillName.text = self.staticData.NameZh
    end
  end
  local isChoose = data.isChoose or false
  self.chooseSymbol:SetActive(isChoose)
  self.dragDrop.dragDropComponent.data.itemdata = ItemData.new("DragItem", self.id)
end

function BalanceModeSkillCell:UpdateDragable()
  self.dragDrop:SetDragEnable(true)
end

function BalanceModeSkillCell:GetSimulateSkillItemData()
  return self.data
end
