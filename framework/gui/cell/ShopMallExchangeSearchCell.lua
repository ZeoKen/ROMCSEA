local baseCell = autoImport("BaseCell")
ShopMallExchangeSearchCell = class("ShopMallExchangeSearchCell", baseCell)

function ShopMallExchangeSearchCell:Init()
  self.name = self:FindGO("Name"):GetComponent(UILabel)
  self:AddCellClickEvent()
end

function ShopMallExchangeSearchCell:SetData(data)
  self.data = data
  if data then
    self.itemData = Table_Exchange[data]
    if self.itemData and self.itemData.NameZh then
      self.name.text = self.itemData.NameZh
      UIUtil.WrapLabel(self.name)
    else
    end
  end
end
