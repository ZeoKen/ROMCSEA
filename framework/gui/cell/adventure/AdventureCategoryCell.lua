local baseCell = autoImport("BaseCell")
AdventureCategoryCell = class("AdventureCategoryCell", baseCell)
local GuideTargetMap = {
  [6] = ClientGuide.TargetType.adventureview_monstertab
}

function AdventureCategoryCell:Init()
  self:initView()
  self:initData()
end

function AdventureCategoryCell:initView()
  self.icon = self:FindGO("icon"):GetComponent(UISprite)
end

function AdventureCategoryCell:unRegistRedTip()
  if self.data.staticData.id ~= SceneManual_pb.EMANUALTYPE_SCENERY then
    for i = 1, #self.redTipIds do
      local single = self.redTipIds[i]
      RedTipProxy.Instance:RemoveWholeTip(single)
    end
  end
end

function AdventureCategoryCell:initData()
  self.redTipIds = {}
end

local tempColor = LuaColor.White()

function AdventureCategoryCell:setIsSelected(isSelected)
  if self.isSelected ~= isSelected then
    self.isSelected = isSelected
    if isSelected then
      LuaColor.Better_Set(tempColor, 0.2549019607843137, 0.34901960784313724, 0.6666666666666666, 1)
      self.icon.color = tempColor
    else
      LuaColor.Better_Set(tempColor, 1, 1, 1, 1)
      self.icon.color = tempColor
    end
  end
end

function AdventureCategoryCell:addViewEventListener()
end

function AdventureCategoryCell:registGuide()
  if self.data and self.data.staticData.GuideID then
    self:AddOrRemoveGuideId(self.gameObject, self.data.staticData.GuideID)
    local sId = self.data.staticData.id
    if GuideTargetMap[sId] then
      self:RegisterGuideTarget(GuideTargetMap[sId], self.gameObject)
    end
  end
end

local tempVector3 = LuaVector3.Zero()

function AdventureCategoryCell:SetData(data)
  self.data = data
  IconManager:SetUIIcon(data.staticData.icon, self.icon)
  self.icon:MakePixelPerfect()
  LuaVector3.Better_Set(tempVector3, 0.7, 0.7, 0.7)
  self.icon.transform.localScale = tempVector3
  if data.icon == "" then
    IconManager:SetItemIcon("21", self.icon)
  end
  self:registGuide()
end
