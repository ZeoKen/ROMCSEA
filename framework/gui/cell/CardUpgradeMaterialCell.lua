CardUpgradeMaterialCell = class("CardUpgradeMaterialCell", ItemCell)
local TextColorRed = "[c][FF3B35]"

function CardUpgradeMaterialCell:Init()
  local obj = self:LoadPreferb("cell/ItemCell", self.gameObject)
  obj.transform.localPosition = LuaGeometry.GetTempVector3()
  CardUpgradeMaterialCell.super.Init(self)
  self:FindObjs()
  self:AddEvts()
end

function CardUpgradeMaterialCell:FindObjs()
  self.choose = self:FindGO("Choose")
end

function CardUpgradeMaterialCell:AddEvts()
  self:AddCellClickEvent()
end

function CardUpgradeMaterialCell:SetData(data)
  if data then
    CardUpgradeMaterialCell.super.SetData(self, data.itemData)
    local num = data.itemData.num
    local bagNum = 0
    if data.id == GameConfig.MoneyId.Zeny then
      bagNum = MyselfProxy.Instance:GetROB()
    else
      local packageCheck = GameConfig.PackageMaterialCheck.cardupgrade
      bagNum = CardMakeProxy.Instance:GetItemNumAsMaterial(data.id, packageCheck)
    end
    if 1 < num then
      local colorStr = num <= bagNum and "" or TextColorRed
      local str = data.id == GameConfig.MoneyId.Zeny and colorStr .. num .. "[-][/c]" or colorStr .. bagNum .. "[-][/c]/" .. num
      self.numLab.text = str
    end
    self:SetIconGrey(num > bagNum)
  end
  self.cellData = data
end
