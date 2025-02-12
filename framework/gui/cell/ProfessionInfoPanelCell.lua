local baseCell = autoImport("BaseCell")
ProfessionInfoPanelCell = class("ProfessionInfoPanelCell", baseCell)

function ProfessionInfoPanelCell:Init()
  self:initView()
end

function ProfessionInfoPanelCell:initView()
  self.name = self:FindGO("name"):GetComponent(UILabel)
  self.value = self:FindGO("value"):GetComponent(UILabel)
  self.value.gameObject.transform.localPosition = LuaGeometry.GetTempVector3(180, 0, 0)
end

function ProfessionInfoPanelCell:SetData(data)
  self.name.text = data.name .. ":"
  self.value.text = "[ff8a00]+" .. data.value .. "[-]"
end
