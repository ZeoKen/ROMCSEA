autoImport("SkillTip")
BalanceModeSkillTip = class("BalanceModeSkillTip", SkillTip)

function BalanceModeSkillTip:FindObjs()
  BalanceModeSkillTip.super.FindObjs(self)
  self:HideUnnecessary()
end

function BalanceModeSkillTip:FindCurrentUI()
  BalanceModeSkillTip.super.FindCurrentUI(self)
  self.skillIcon_Bg = self:FindGO("SkillIconBg"):GetComponent(UISprite)
  self.equipBtn = self:FindGO("EquipBtn")
  self.equipBtn:SetActive(true)
  self:AddClickEvent(self.equipBtn, function()
    local type = self.data and self.data.type
    local isArtifact = self.data and self.data.isArtifact or false
    if isArtifact then
      SkillProxy.Instance:CallBalanceModeChooseMess(nil, nil, self.data.id)
    elseif type == 1 then
      SkillProxy.Instance:CallBalanceModeChooseMess(self.data.id, nil, nil)
    elseif type == 2 then
      SkillProxy.Instance:CallBalanceModeChooseMess(nil, self.data.id, nil)
    end
    self:CloseSelf()
  end)
end

function BalanceModeSkillTip:HideUnnecessary()
  self:Hide(self.nextInfo)
  self:Hide(self.nextCD)
  self:Hide(self.sperator)
  self:Hide(self.useCount)
  self:Hide(self.currentCD)
  self:Hide(self.skillLevel)
  self:Hide(self.useCount)
  self:Hide(self.skillType)
end

function BalanceModeSkillTip:SetData(data)
  self.data = data.data
  self:UpdateCurrentInfo(self.data)
  local layoutHeight = self:Layout()
  local height = math.max(math.min(layoutHeight + 190, SkillTip.MaxHeight), SkillTip.MinHeight)
  self.bg.height = height
  self:UpdateAnchors()
  self.scroll:ResetPosition()
  self:SetConditionLabel()
end

function BalanceModeSkillTip:SetConditionLabel()
  self.condition.text = ZhString.PetSkillTip_NoUpgrade
end

function BalanceModeSkillTip:UpdateCurrentInfo(data)
  local isArtifact = data.isArtifact or false
  local itemID = data.id
  local itemData = Table_Item[itemID]
  if itemData then
    self.skillName.text = itemData.NameZh
    IconManager:SetItemIcon(itemData.Icon, self.icon)
    self.icon.gameObject.transform.localScale = LuaGeometry.GetTempVector3(0.8, 0.8, 0.8)
    self.skillIcon_Bg.enabled = true
  end
  if isArtifact then
    local artifactData = Table_PersonalArtifactCompose[itemID]
    if artifactData then
      local effectIds, effectDesc = artifactData.UniqueEffect
      local str = ""
      for i = 1, #effectIds do
        effectDesc = ItemUtil.getBufferDescById(effectIds[i])
        if not StringUtil.IsEmpty(effectDesc) then
          str = str .. effectDesc
          if i < #effectIds then
            str = str .. "\n"
          end
        end
      end
      self.currentInfo.text = str
    end
  else
    local equipExtraceionInfo = Table_EquipExtraction[itemID]
    if equipExtraceionInfo then
      self.currentInfo.text = equipExtraceionInfo.Dsc
    end
  end
end
