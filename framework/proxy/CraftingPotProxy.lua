autoImport("PurifyProductData")
CraftingPotProxy = class("CraftingPotProxy", pm.Proxy)
CraftingPotProxy.Instance = nil
CraftingPotProxy.NAME = "CraftingPotProxy"
local packageCheck = GameConfig.PackageMaterialCheck and GameConfig.PackageMaterialCheck.purify_products

function CraftingPotProxy:ctor(proxyName, data)
  self.proxyName = proxyName or CraftingPotProxy.NAME
  if CraftingPotProxy.Instance == nil then
    CraftingPotProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function CraftingPotProxy:Init()
  self.products = {}
end

function CraftingPotProxy:InitCall(val)
  self.initCall = val
  if val then
    self.products = {}
  end
end

function CraftingPotProxy:RecvPurifyProductsMaterialsMessCCmd(data)
  if data.materials then
    local products = data.materials
    for i = 1, #products do
      if not self.products[products[i].productid] then
        self.products[products[i].productid] = PurifyProductData.new(products[i])
      else
        self.products[products[i].productid]:SetData(products[i])
        GameFacade.Instance:sendNotification(CraftingPotViewEvent.UpdateProduct)
      end
    end
  end
end

function CraftingPotProxy:SetChoosePurifyProducts(productID)
  for _productid, productData in pairs(self.products) do
    productData:SetChoose(productID == _productid)
  end
end

function CraftingPotProxy:GetPurifyProducts()
  local result = {}
  for _, productData in pairs(self.products) do
    if not productData:IsChoose() then
      result[#result + 1] = productData
    end
  end
  return result
end

function CraftingPotProxy:GetProduct(productid)
  return self.products[productid]
end

function CraftingPotProxy:GetComposingItems(productid)
  return self.products[productid] and self.products[productid]:GetMaterials()
end

function CraftingPotProxy:RecvPurifyProductsRefineMessCCmd(data)
  if data.materials then
    local products = data.materials
    for i = 1, #products do
      self.products[products[i].productid]:SetData(products[i])
    end
  end
end

function CraftingPotProxy:GetItemNumByStaticID(itemid)
  local _BagProxy = BagProxy.Instance
  local count = 0
  for i = 1, #packageCheck do
    count = count + _BagProxy:GetItemNumByStaticID(itemid, packageCheck[i])
  end
  return count
end

function CraftingPotProxy:IsSkipGetEffect()
  return LocalSaveProxy.Instance:GetSkipAnimation(SKIPTYPE.Crafting)
end
