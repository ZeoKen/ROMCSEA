local BaseCell = autoImport("BaseCell")
SinglePropTypeCell = class("SinglePropTypeCell", BaseCell)
local selectedLabel = "514F7B"

function SinglePropTypeCell:Init()
  self:initView()
  self:AddCellClickEvent()
  self.isSelected = true
  self:SetIsSelect(false)
end

function SinglePropTypeCell:initView()
  self.name = self:FindComponent("name", UILabel)
  self.bg = self:FindGO("bg")
  self.selectBg = self:FindGO("selectBg")
end

function SinglePropTypeCell:SetIsSelect(ret)
  if self.isSelected ~= ret then
    if ret then
      local _, c = ColorUtil.TryParseHexString(selectedLabel)
      self.name.color = c
      self.bg:SetActive(false)
      self.selectBg:SetActive(true)
    else
      self.name.color = LuaGeometry.GetTempColor(1, 1, 1, 1)
      self.bg:SetActive(true)
      self.selectBg:SetActive(false)
    end
    self.isSelected = ret
  end
end

function SinglePropTypeCell:SetData(data)
  self.data = data
  self.id = data.id
  if self.data.name then
    self.name.text = self.data.name
  end
end
