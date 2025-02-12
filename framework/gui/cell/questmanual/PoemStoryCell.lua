local baseCell = autoImport("BaseCell")
QuestManualVersionCell = class("QuestManualVersionCell", baseCell)

function QuestManualVersionCell:Init()
  self:initView()
end

function QuestManualVersionCell:initView()
  self.icon = self:FindGO("icon"):GetComponent(UISprite)
end

function QuestManualVersionCell:setIsSelected(isSelected)
  if self.isSelected ~= isSelected then
    self.isSelected = isSelected
    if isSelected then
      self.icon.color = LuaGeometry.GetTempColor(0.2549019607843137, 0.34901960784313724, 0.6666666666666666, 1)
    else
      self.icon.color = LuaGeometry.GetTempColor(1, 1, 1, 1)
    end
  end
end

local tempVector3 = LuaVector3(0.7, 0.7, 0.7)

function QuestManualVersionCell:SetData(data)
  self.data = data
  IconManager:SetUIIcon(data.staticData.icon, self.icon)
  self.icon:MakePixelPerfect()
  self.icon.transform.localScale = tempVector3
  if data.icon == "" then
    IconManager:SetItemIcon("21", self.icon)
  end
  self:registGuide()
end
