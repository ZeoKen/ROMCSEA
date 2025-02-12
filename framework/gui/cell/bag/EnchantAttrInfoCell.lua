autoImport("EnchantInfoLabelCell")
local BaseCell = autoImport("BaseCell")
EnchantAttrInfoCell = class("EnchantAttrInfoCell", BaseCell)
EnchantAttrInfoCell.InfoLabelCellPrefabName = "EnchantInfoLabelCell"
EnchantAttrInfoCell.MenuTypeGridConfig = {
  [1] = {
    maxPerLine = 2,
    cellV2 = {270, 40}
  },
  [2] = {
    maxPerLine = 1,
    cellV2 = {270, 40}
  },
  [3] = {
    maxPerLine = 1,
    cellV2 = {270, 40}
  },
  [4] = {
    maxPerLine = 1,
    cellV2 = {270, 87}
  }
}

function EnchantAttrInfoCell:Init()
  EnchantAttrInfoCell.super.Init()
  self:InitCell()
end

function EnchantAttrInfoCell:InitCell()
  self.bg = self:FindComponent("Bg", UISprite)
  self.attriTip = self:FindGO("AttrTip")
  self.grid = self:FindComponent("Grid", UIGrid)
  self.ctl = UIGridListCtrl.new(self.grid, EnchantInfoLabelCell, self.InfoLabelCellPrefabName)
end

function EnchantAttrInfoCell:SetData(data)
  if not data then
    self:Hide()
    return
  end
  self.data = data
  self:Show()
  local gridConfig = EnchantAttrInfoCell.MenuTypeGridConfig[data.attriMenuType]
  self.grid.maxPerLine = gridConfig.maxPerLine
  self.grid.cellWidth = gridConfig.cellV2[1]
  self.grid.cellHeight = gridConfig.cellV2[2]
  self.attriTip:SetActive(data.attriMenuType == 4)
  local line = math.ceil(#data.attris / gridConfig.maxPerLine)
  if self.attriTip.activeSelf then
    self.grid.transform.localPosition = LuaGeometry.GetTempVector3(-230, -18, 0)
    self.bg.height = line * self.grid.cellHeight + 20
  else
    self.grid.transform.localPosition = LuaGeometry.GetTempVector3(-230, -18, 0)
    self.bg.height = line * self.grid.cellHeight + 20
  end
  table.sort(data.attris, function(a, b)
    return a.pos < b.pos
  end)
  self.ctl:ResetDatas(data.attris)
end

EnchantAttrInfoNewCell = class("EnchantAttrInfoNewCell", EnchantAttrInfoCell)
EnchantAttrInfoNewCell.InfoLabelCellPrefabName = "EnchantInfoLabelNewCell"
