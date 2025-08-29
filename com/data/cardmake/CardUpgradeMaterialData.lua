CardUpgradeMaterialData = class("CardUpgradeMaterialData")

function CardUpgradeMaterialData:ctor(data)
  self:SetData(data)
end

function CardUpgradeMaterialData:SetData(data)
  self.data = data
  if data then
    self.id = data[1]
    self.itemData = ItemData.new("CardUpgrade", self.id)
    if data[2] then
      self.itemData.num = data[2]
    end
  end
end
