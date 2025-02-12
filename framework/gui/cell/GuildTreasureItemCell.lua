autoImport("ItemCell")
GuildTreasureItemCell = class("GuildTreasureItemCell", ItemCell)

function GuildTreasureItemCell:Init()
  self:FindObjs()
  local itemRoot = self:FindGO("itemPos")
  local obj = self:LoadPreferb("cell/ItemCell", itemRoot)
  obj.transform.localPosition = LuaGeometry.GetTempVector3()
  GuildTreasureItemCell.super.Init(self)
  self.itemPos = self:FindGO("itemPos")
  self:SetEvent(self.itemPos, function()
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
end

function GuildTreasureItemCell:FindObjs()
  self.name = self:FindGO("name"):GetComponent(UILabel)
  self.typeLab = self:FindComponent("type", UILabel)
end

function GuildTreasureItemCell:SetData(data)
  if data then
    GuildTreasureItemCell.super.SetData(self, data)
    self.data = data
    self.typeLab.text = data:GetTypeName()
    self:UpdateNumLabel(data.num)
    self.name.text = data:GetName()
  else
    self.gameObject:SetActive(false)
  end
end
