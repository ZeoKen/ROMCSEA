autoImport("ItemCell")
ActivityExchangeItemCell = class("ActivityExchangeItemCell", ItemCell)

function ActivityExchangeItemCell:Init()
  ActivityExchangeItemCell.super.Init(self)
  self:FindObjs()
end

function ActivityExchangeItemCell:FindObjs()
  self.numLabGO = self:FindGO("NumLabel", self.item)
  if self.numLabGO then
    self.numLabTrans = self.numLabGO.transform
    self.numLab = self.numLabGO:GetComponent(UILabel)
    self.numLabGO:SetActive(true)
  end
  self:AddCellClickEvent()
end

function ActivityExchangeItemCell:UpdateNumLabel(num)
  self.numLab.text = num
end

function ActivityExchangeItemCell:SetPic(itemType, staticData)
end
