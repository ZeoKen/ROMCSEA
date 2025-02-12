RewardListViewCell = class("RewardListViewCell", BaseCell)

function RewardListViewCell:Init()
  self:GetGameObjects()
end

function RewardListViewCell:GetGameObjects()
  self.icon = self:FindGO("Icon", self.gameObject):GetComponent(UISprite)
  self.itemName = self:FindGO("ItemName", self.gameObject):GetComponent(UILabel)
  self.count = self:FindGO("Count", self.gameObject):GetComponent(UILabel)
end

function RewardListViewCell:SetData(data)
  local itemStaticData = Table_Item[data.itemid]
  if self.icon then
    local setSuc = false
    local scaleVec3 = LuaVector3.One()
    if dType == 1200 then
      setSuc = IconManager:SetFaceIcon(itemStaticData.Icon, self.icon)
      setSuc = setSuc or IconManager:SetFaceIcon("boli", self.icon)
      LuaVector3.Mul(scaleVec3, 0.53)
    else
      setSuc = IconManager:SetItemIcon(itemStaticData.Icon, self.icon)
      setSuc = setSuc or IconManager:SetItemIcon("item_45001", self.icon)
      LuaVector3.Mul(scaleVec3, 0.75)
    end
    if setSuc then
      self.icon.gameObject:SetActive(true)
      self.icon:MakePixelPerfect()
      self.icon.transform.localScale = scaleVec3
    else
      self.icon.gameObject:SetActive(false)
    end
  end
  self.itemName.text = itemStaticData.NameZh
  self.count.text = "x " .. data.count
end
