CardMakeMaterialData = class("CardMakeMaterialData")

function CardMakeMaterialData:ctor(data, slotId)
  self:SetData(data)
  self.slotId = slotId
end

function CardMakeMaterialData:SetData(data)
  if data then
    self.id = data.id
    self.itemData = ItemData.new("CardMake", self.id)
    if data.num then
      self.itemData.num = data.num
      self.costNum = data.num
    end
    self.isExtra = data.isExtra
  end
end
