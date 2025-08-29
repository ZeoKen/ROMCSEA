autoImport("PurifyMaterialData")
PurifyProductData = class("PurifyProductData")

function PurifyProductData:ctor(data)
  self:Init()
  self:SetData(data)
  self.PurifyProductsConfig = GameConfig.PurifyProducts
end

function PurifyProductData:Init()
  self.isChoose = false
  self.materials = {}
end

function PurifyProductData:SetData(data)
  self.productItemID = data.productid
  self.showNewmark = data.newmark
  self.close = data.close
  self.showConfirmMsg = data.confirm
  if data.times then
    self.frequencyType = data.times.type
    self.totalTimes = data.times.totaltimes
    self.leftTimes = data.times.lefttimes
  end
  if data.materials then
    local materials = data.materials
    self.materials = {}
    for i = 1, #materials do
      local single = PurifyMaterialData.new(data.materials[i])
      self.materials[#self.materials + 1] = single
    end
  end
end

function PurifyProductData:GetMaterials()
  return self.materials
end

function PurifyProductData:SetChoose(isChoose)
  self.isChoose = isChoose
end

function PurifyProductData:IsChoose()
  return self.isChoose
end

function PurifyProductData:IsSeasonItem()
  if self.close and self.PurifyProductsConfig.SeasonItem then
    return self.close, self.PurifyProductsConfig.SeasonItem[self.productItemID]
  end
  return self.close
end

function PurifyProductData:GetConfirmMsg()
  if self.confirm and self.PurifyProductsConfig.ConfirmMsg then
    return self.confirm, self.PurifyProductsConfig.ConfirmMsg[self.productItemID]
  end
  return self.confirm
end

function PurifyProductData:GetProductLimit()
  if self.totalTimes and self.totalTimes > 0 then
    return self.leftTimes, self.totalTimes
  end
  return self.leftTimes
end
