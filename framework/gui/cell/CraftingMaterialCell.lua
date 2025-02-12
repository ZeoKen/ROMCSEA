CraftingMaterialCell = class("CraftingMaterialCell", ItemCell)
local greenString = "[c][555B6E]%s[-][/c]"
local blackString = "[c][555B6E]%s[-][/c]"

function CraftingMaterialCell:Init()
  local obj = self:LoadPreferb("cell/ItemCell", self.gameObject)
  obj.transform.localPosition = LuaGeometry.GetTempVector3(0, -30, 0)
  CraftingMaterialCell.super.Init(self)
  self:FindObjs()
  self:AddCellClickEvent()
end

function CraftingMaterialCell:FindObjs()
  self.count = self:FindGO("Count"):GetComponent(UILabel)
  local itemCellNum = self:FindGO("NumLabel")
  if itemCellNum then
    itemCellNum.transform.localScale = LuaGeometry.Const_V3_zero
  end
end

function CraftingMaterialCell:SetData(data)
  if data then
    local count = 0
    self.itemData = ItemData.new(nil, data.itemid)
    count = CraftingPotProxy.Instance:GetItemNumByStaticID(data.itemid)
    local str, sum_num = tostring(count), tostring(data.itemNum)
    self.isEnough = false
    if count >= data.itemNum then
      self.isEnough = true
      str = string.format(blackString, str)
    else
      str = string.format("[c]%s%s[-][/c]", CustomStrColor.BanRed, str)
    end
    self.count.text = string.format("%s[c][555B6E]/%s[-][/c]", str, sum_num)
    CraftingMaterialCell.super.SetData(self, self.itemData)
  end
  self.data = data
end

function CraftingMaterialCell:IsEnough()
  return self.isEnough
end

function CraftingMaterialCell:NeedCount()
  if self.isEnough then
    return 0
  else
    redlog("needCount", self.data.itemNum - CraftingPotProxy.Instance:GetItemNumByStaticID(self.data.itemid))
    return self.data.itemNum - CraftingPotProxy.Instance:GetItemNumByStaticID(self.data.itemid)
  end
end
