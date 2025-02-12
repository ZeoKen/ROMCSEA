RecipeData = class("RecipeData")
autoImport("ItemData")

function RecipeData:ctor(recipeid)
  if recipeid == nil then
    return
  end
  self.staticData = Table_Recipe[recipeid]
end

function RecipeData:SetUnLock(b)
  self.unlock = b
end

function RecipeData:GetProductItem()
  if self.product == nil then
    local product = self.staticData.Product
    if product then
      self.product = ItemData.new("RecipeProduct", product)
    end
  end
  return self.product
end

function RecipeData:GetDiffLevel()
  local product = self.staticData.Product
  local food_SData = product and Table_Food[product]
  if food_SData then
    return food_SData.CookHard
  end
  return 0
end

function RecipeData:GetSaveHpSp()
  local material = self.staticData.Material
  local hp, sp
  for i = 1, #material do
    local m = material[i]
    if m[1] == 1 then
      local fData = Table_Food[m[2]]
      local savehp = fData and fData.SaveHP or 0
      hp = savehp + hp
      local savesp = fData and fData.SaveSP or 0
      sp = savesp + sp
    end
  end
  return hp, sp
end

function RecipeData:Get_RcpMaterialsName()
  local material = self.staticData.Material
  if material == nil then
    return
  end
  local resultStr, m
  for i = 1, #material do
    m = material[i]
    if m[1] == 1 then
      local name = Table_Item[m[2]].NameZh
      resultStr = resultStr .. name
    elseif m[1] == 2 then
      local name = Table_ItemType[m[2]].Name
      resultStr = resultStr .. name
    end
    if i < #material then
      resultStr = resultStr .. ZhString.RecipeData_DunHao
    end
  end
  return resultStr
end
