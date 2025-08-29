autoImport("BaseTip")
MonsterScoreTip = class("MonsterScoreTip", BaseView)
autoImport("TipLabelCell")
autoImport("Table_MonsterOrigin")
autoImport("UIModelShowConfig")
autoImport("AdvTipRewardCell")
autoImport("AdventureAppendCell")
autoImport("AdventureBaseAttrCell")
autoImport("AdventureDropCell")
autoImport("AdventureCopySkillCell")
autoImport("AdventureDropItemCell")
MonsterScoreTip.QualityMap = {
  Monster = "com_tips_1",
  MINI = "com_tips_4",
  MVP = "com_tips_5"
}
local tempVector3 = LuaVector3.Zero()

function MonsterScoreTip:ctor(parent)
  self.resID = ResourcePathHelper.UITip("MonsterScoreTip")
  self.gameObject = Game.AssetManager_UI:CreateAsset(self.resID, parent)
  self.gameObject.transform.localPosition = LuaGeometry.GetTempVector3()
  self:Init()
end

function MonsterScoreTip:adjustPanelDepth(startDepth)
  local upPanel = Game.GameObjectUtil:FindCompInParents(self.gameObject, UIPanel)
  local panels = self:FindComponents(UIPanel)
  local minDepth
  for i = 1, #panels do
    if minDepth == nil then
      minDepth = panels[i].depth
    else
      minDepth = math.min(panels[i].depth, minDepth)
    end
  end
  startDepth = startDepth or 1
  for i = 1, #panels do
    panels[i].depth = panels[i].depth + startDepth + upPanel.depth - minDepth
  end
end

function MonsterScoreTip:Init()
  self.monstername = self:FindComponent("MonsterName", UILabel)
  self.qualitybg = self:FindComponent("QualityBg", UISprite)
  self.scrollView = self:FindComponent("ScrollView", UIScrollView)
  self.modeltexture = self:FindComponent("ModelTexture", UITexture)
  self.photosprite = self:FindComponent("PhotoSprite", UISprite)
  self.cardsprite = self:FindComponent("CardSprite", UISprite)
  self.adventureValue = self:FindComponent("adventureValue", UILabel)
  self.unlockBord = self:FindGO("UnLockBord")
  self.locksymbol = self:FindGO("Lock")
  self.table = self:FindComponent("AttriTable", UITable)
  self.attriCtl = UIGridListCtrl.new(self.table, AdventureTipLabelCell, "AdventureTipLabelCell")
  grid = self:FindComponent("BaseAttrGrid", UIGrid)
  local monsterBord = self:FindGO("MonsterSpecial")
  self.mclabel = TipLabelCell.new(self:FindGO("TipLabelCell", monsterBord))
  local modelBg = self:FindGO("ModelBg")
  self:AddDragEvent(modelBg, function(go, delta)
    if self.model then
      self.model:RotateDelta(-delta.x)
    end
  end)
  self.monsterSpecial = self:FindGO("MonsterSpecial")
  local monsterSpecialMask = self:FindGO("mask", self.monsterSpecial)
  self:AddClickEvent(monsterSpecialMask, function(go)
    self.monsterSpecial:SetActive(false)
  end)
  self.chatacterBtn = self:FindGO("ChatacterBtn")
  local btnText = self:FindComponent("Label", UILabel, self.chatacterBtn)
  btnText.text = ZhString.MonsterTip_CharacteristicDetail
  self:AddClickEvent(self.chatacterBtn, function(go)
    if self.data.attrUnlock then
      self.monsterSpecial:SetActive(not self.monsterSpecial.activeSelf)
    else
    end
  end)
  local appTb = self:FindComponent("AppendTable", UITable)
  self.appCtl = UIGridListCtrl.new(appTb, AdventureAppendCell, "AdventureAppendCell")
  self.appCtl:AddEventListener(MouseEvent.MouseClick, self.ShowAppendTip, self)
  local dropItemGO = self:FindGO("DropItem")
  self.dropItemCtrl = AdventureDropItemCell.new(dropItemGO)
  self.baseAttrCt = self:FindGO("BaseAttrCt")
  self.baseAttrCtTitle = self:FindComponent("title", UILabel, self.baseAttrCt)
  self.baseAttrCtTitle.text = ZhString.MonsterTip_PropertyTitle
  self.baseAttrCtGrid = self:FindComponent("Grid", UIGrid, self.baseAttrCt)
  self.baseAttrCtGrid = UIGridListCtrl.new(self.baseAttrCtGrid, AdventureBaseAttrCell, "AdventureBaseAttrCell")
  self.featureCt = self:FindGO("FeatureCt")
  local featureTitle = self:FindComponent("title", UILabel, self.featureCt)
  featureTitle.text = ZhString.MonsterTip_SpecialTitle
  self.fallCt = self:FindGO("FallCt")
  self.fallCt:SetActive(false)
  self.copySkillCt = self:FindGO("CopySkillCt")
  local copySkillTitle = self:FindComponent("title", UILabel, self.copySkillCt)
  copySkillTitle.text = ZhString.MonsterTip_CopySkillTitle
  local copySkillCtGrid = self:FindComponent("Grid", UIGrid, self.copySkillCt)
  self.copySkillCtGridCtrl = UIGridListCtrl.new(copySkillCtGrid, AdventureCopySkillCell, "AdventureCopySkillCell")
  self.EmptyDropLabel = self:FindComponent("EmptyDrop", UILabel)
  self.EmptyDropLabel.text = ZhString.MonsterTip_WDBossDropTitle
  local monoComp = self.gameObject:GetComponent(RelateGameObjectActive)
  if monoComp then
    function monoComp.enable_Call()
      self:OnEnable()
    end
    
    function monoComp.disable_Call()
      self:OnDisable()
    end
  end
  self:initLockBord()
  self.MonstPro = self:FindComponent("MonstPro", UISprite)
  self.UnlockReward = self:FindGO("UnlockReward")
  self:Hide(self.EmptyDropLabel.gameObject)
  self.tipAnchor = self:FindComponent("TipAnchor", UIWidget)
end

function MonsterScoreTip:adjustLockRewardPos()
  self:Hide(self.UnlockReward)
  local bound = NGUIMath.CalculateRelativeWidgetBounds(self.UnlockReward.transform)
  local pos = self.UnlockReward.transform.localPosition
  local y = pos.y - bound.size.y
  self.table.transform.localPosition = LuaGeometry.GetTempVector3(pos.x, y, pos.z)
end

function MonsterScoreTip:initLockBord()
  local obj = self:FindGO("LockBord")
  self.lockBord = self:FindGO("LockBordHolder")
  if not obj then
    obj = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UIView("LockBord"), self.lockBord)
    obj.name = "LockBord"
  end
  obj.transform.localPosition = LuaGeometry.GetTempVector3()
  obj.transform.localScale = LuaGeometry.GetTempVector3(1, 1, 1)
  self.sprLock = self:FindComponent("Sprite (1)", UISprite, obj)
  self.lockTipLabel = self:FindComponent("LockTipLabel", UILabel)
  
  function self.lockTipLabel.onChange()
    if self.sprLock then
      self.sprLock:ResetAndUpdateAnchors()
    end
  end
  
  local LockTitle = self:FindComponent("LockTitle", UILabel)
  LockTitle.text = ZhString.MonsterTip_LockTitle
  local LockReward = self:FindComponent("LockReward", UILabel)
  LockReward.text = ZhString.MonsterTip_LockReward
  self.fixedAttrLabel = self:FindComponent("fixedAttrLabel", UILabel)
  local fixLabelCt = self:FindComponent("fixLabelCt", UILabel)
  fixLabelCt.text = ZhString.MonsterTip_FixAttrCt
  self.FixAttrCt = self:FindGO("FixAttrCt")
  self:Hide(self.FixAttrCt)
  local grid = self:FindComponent("LockInfoGrid", UIGrid)
  self.advRewardCtl = UIGridListCtrl.new(grid, AdvTipRewardCell, "AdvTipRewardCell")
  self.modelBottombg = self:FindGO("modelBottombg")
end

function MonsterScoreTip:SetData(monsterData)
  self.data = monsterData
  self:initData()
  self:SetLockState()
  self:UpdateTopInfo()
  self:UpdateAttriText()
  self:adjustLockRewardPos()
  self:UpdateAppendData()
  self:UpdateDropItems()
  self:UpdateFeatureData()
  self:adjustPanelDepth(4)
  self:SetCopySkillData()
end

function MonsterScoreTip:UpdateFeatureData()
  local originActive = self.monsterSpecial.activeSelf
  if not originActive then
    self:Show(self.monsterSpecial)
  end
  local sdata = self.data.staticData
  local attrs = {}
  local propMap = UserProxy.Instance.creatureProps
  local templab
  for i = 1, #GameConfig.MonsterShowType do
    local key = GameConfig.MonsterShowType[i]
    if key == "Hp" then
      templab = {}
      templab.name = "HP"
      templab.value = sdata[key]
      table.insert(attrs, templab)
    elseif key == "Level" then
      templab = {}
      templab.name = ZhString.MonsterTip_Characteristic_Level
      templab.value = sdata[key]
      table.insert(attrs, templab)
    elseif key == "Race" then
      templab = {}
      templab.name = ZhString.MonsterTip_Characteristic_Race
      templab.value = GameConfig.MonsterAttr.Race[sdata[key]]
      table.insert(attrs, templab)
    elseif key == "Shape" then
      templab = {}
      templab.name = ZhString.MonsterTip_Characteristic_Shape
      templab.value = GameConfig.MonsterAttr.Body[sdata[key]]
      table.insert(attrs, templab)
    elseif sdata[key] then
      local prop = propMap[key]
      if prop then
        templab = {}
        templab.name = prop.displayName
        templab.value = sdata[key]
        table.insert(attrs, templab)
      end
    end
  end
  self.baseAttrCtGrid:ResetDatas(attrs)
  self.baseAttrCtGrid:Layout()
  if sdata.Behaviors then
    local showDatas = self:GetMCharacteristicDatas(sdata.Behaviors)
    local cTip = ZhString.MonsterTip_None
    if 0 < #showDatas then
      cTip = ""
      local bordInfo = {}
      bordInfo.hideline = true
      bordInfo.label = {}
      for i = 1, #showDatas do
        cTip = cTip .. showDatas[i].NameZh
        if i < #showDatas then
          cTip = cTip .. "\n"
        end
        local templabel = showDatas[i].NameZh .. ":" .. showDatas[i].Desc
        table.insert(bordInfo.label, templabel)
      end
      self.mclabel:SetData(bordInfo)
      self:Show(self.featureCt)
    else
      self:Hide(self.featureCt)
    end
  end
  if self.featureCt.activeSelf then
    local trans = self.baseAttrCt.transform
    local bound = NGUIMath.CalculateRelativeWidgetBounds(trans, false)
    local pos = trans.localPosition
    pos = Vector3(pos.x, pos.y - bound.size.y, pos.z)
    trans = self.featureCt.transform
    trans.localPosition = pos
  end
  if not originActive or not self.data.attrUnlock then
    self:Hide(self.monsterSpecial)
  end
end

function MonsterScoreTip:initData()
  self.dropItemData = {}
  local itemDatas = {}
  self.dropItemData.itemDatas = itemDatas
  local sdata = self.data.staticData
  if sdata then
    local dropItems = ItemUtil.GetDeath_Drops(sdata.id)
    if dropItems then
      for i = 1, #dropItems do
        local single = dropItems[i]
        local id = single.itemData.id
        if id ~= 100 and id ~= 105 then
          table.insert(itemDatas, single)
          local cardData = Table_Card[id]
          if cardData then
            self.dropCardId = id
          end
        end
      end
    end
    if sdata.Nature then
      local result = IconManager:SetUIIcon(sdata.Nature, self.MonstPro)
      if not result then
        self:Hide(self.MonstPro.gameObject)
      else
        self:Show(self.MonstPro.gameObject)
      end
    else
      self:Hide(self.MonstPro.gameObject)
    end
  end
end

function MonsterScoreTip:SetLockState()
  self.isUnlock = false
  if self.data then
    self.isUnlock = self.data.status ~= SceneManual_pb.EMANUALSTATUS_DISPLAY
    if not self.data.AdventureValue or self.data.AdventureValue > 0 then
    else
    end
    self.lockTipLabel.text = self.data.staticData.NameZh
    if self.sprLock then
      self.sprLock:ResetAndUpdateAnchors()
    end
    self:UpdateAdvReward()
    local UnlockReward = self:FindGO("UnlockReward")
    if self.isUnlock then
      self:Hide(UnlockReward)
    end
  end
  if self.data.attrUnlock then
    self:SetTextureWhite(self.chatacterBtn)
    self.photosprite.color = Color(1, 1, 1, 1)
  else
    self:SetTextureColor(self.chatacterBtn, Color(0.00392156862745098, 0.00784313725490196, 0.011764705882352941, 0.6274509803921569))
    self.photosprite.color = Color(1, 1, 1, 0.4)
  end
  local hasCard = AdventureDataProxy.Instance:checkHasMonsterDropCard(self.dropCardId)
  if hasCard then
    self.cardsprite.color = Color(1, 1, 1, 1)
  else
    self.cardsprite.color = Color(1, 1, 1, 0.4)
  end
  self.lockBord.gameObject:SetActive(not self.isUnlock)
  if not self.isUnlock then
    self.monstername.text = "????"
    self:Hide(self.modelBottombg)
  else
    self:Show(self.modelBottombg)
  end
  return self.isUnlock
end

function MonsterScoreTip:UpdateAdvReward()
  self.advRewardCtl:ResetDatas({})
  local value = 0
  if self.data and self.data.staticData and self.data.staticData.AdventureValue then
    value = self.data.staticData.AdventureValue
  end
  self.adventureValue.text = value
end

function MonsterScoreTip:UpdateTopInfo()
  local data = self.data
  local sdata = data and data.staticData
  if sdata then
    self.monstername.text = sdata.NameZh
  end
end

function MonsterScoreTip:Show3DModel()
  local data = self.data
  local monsterData = data and data.staticData
  if monsterData and self.monsterId ~= monsterData.id then
    UIModelUtil.Instance:ResetTexture(self.modeltexture)
    UIModelUtil.Instance:SetMonsterModelTexture(self.modeltexture, monsterData.id, nil, nil, function(obj)
      self.model = obj
      local showPos = monsterData.LoadShowPose
      if showPos and #showPos == 3 then
        LuaVector3.Better_Set(tempVector3, showPos[1], showPos[2], showPos[3])
        self.model:SetPosition(tempVector3)
      end
      self.model:SetEulerAngleY(monsterData.LoadShowRotate or 0)
      local size = monsterData.LoadShowSize or 1
      self.model:SetScale(size)
      local bossData = Table_Boss[self.data.staticId]
      if bossData and bossData.Type == 3 then
        UIModelUtil.Instance:ChangeBGMeshRenderer("Bg_beijing_1", self.modeltexture)
      else
        UIModelUtil.Instance:ChangeBGMeshRenderer("Bg_beijing", self.modeltexture)
      end
    end)
    self.monsterId = monsterData.id
  end
  return false
end

function MonsterScoreTip:ShowScore()
end

function MonsterScoreTip:GetMonsterDetail()
  local rewards = AdventureDataProxy.Instance:getAppendRewardByTargetId(self.data.staticId, "selfie")
  if not self.data.attrUnlock and rewards and 0 < #rewards then
    local items = ItemUtil.GetRewardItemIdsByTeamId(rewards[1])
    if not items then
      redlog("there is no reward! rewardId", tostring(rewards[1]))
    end
    local unlocktip = {}
    unlocktip.label = {}
    unlocktip.hideline = true
    unlocktip.labelType = AdventureDataProxy.LabelType.Status
    unlocktip.tiplabel = ZhString.MonsterTip_MonstDetail
    local singleLabel = {
      text = string.format(ZhString.MonsterTip_UnLockMonstDetail, self.data.staticData.NameZh) .. "{uiicon=Adventure_icon_05}x" .. items[1].num,
      unlock = self.isUnlock or false
    }
    table.insert(unlocktip.label, singleLabel)
    return unlocktip
  end
end

function MonsterScoreTip:GetMonsterDes()
  if self.isUnlock then
    local desc = {}
    desc.label = self.data.staticData.Desc
    desc.hideline = true
    return desc
  end
end

function MonsterScoreTip:GetMonsterUnlock()
  local advReward, advRDatas = self.data.staticData.AdventureReward, {}
  if self.data.staticData.AdventureValue and self.data.staticData.AdventureValue > 0 then
    local temp = {}
    temp.hideline = true
    temp.tiplabel = ZhString.MonsterTip_LockProperyReward
    temp.labelType = AdventureDataProxy.LabelType.Status
    temp.label = {}
    local singleLabel = {
      text = AdventureDataProxy.getUnlockCondition(self.data, true) .. ZhString.FunctionDialogEvent_And .. "{uiicon=Adventure_icon_05}x" .. self.data.staticData.AdventureValue,
      unlock = self.isUnlock or false
    }
    table.insert(temp.label, singleLabel)
    return temp
  end
end

function MonsterScoreTip:GetPosition()
  local position = {}
  local posTip = ZhString.MonsterTip_None
  if Table_MonsterOrigin then
    local posConfigs = Table_MonsterOrigin[self.data.staticData.id]
    if posConfigs and 0 < #posConfigs then
      posTip = ""
      local filterMap = {}
      for i = 1, #posConfigs do
        local mapID = posConfigs[i].mapID
        if not filterMap[mapID] then
          filterMap[mapID] = true
          local mapdata = Table_Map[mapID]
          if mapdata and mapdata.Mode == 1 then
            posTip = posTip .. mapdata.NameZh
            posTip = posTip .. ZhString.Common_Comma
          end
        end
      end
      local len = StringUtil.getTextLen(posTip)
      posTip = StringUtil.getTextByIndex(posTip, 1, len - 1)
    end
  end
  position.label = posTip
  position.hideline = true
  position.tiplabel = ZhString.MonsterTip_Position
  return position
end

function MonsterScoreTip:GetKillNum()
  local killNum = self.data:getKillNum()
  if killNum and 0 < killNum then
    if 999999 < killNum then
      killNum = 999999
    end
    local temp = {}
    temp.hideline = true
    temp.tiplabel = ZhString.MonsterTip_KillNum
    temp.label = {}
    local singleLabel = {
      text = string.format(ZhString.MonsterTip_TotalKillNum, self.data.staticData.NameZh, killNum)
    }
    table.insert(temp.label, singleLabel)
    return temp
  end
end

function MonsterScoreTip:UpdateAttriText()
  local contextData = {}
  local data = self.data
  local sdata = self.data.staticData
  if data and sdata then
    local sdata = self.data.staticData
    if sdata then
      self:Show3DModel()
      self:ShowScore()
    end
    if self.isUnlock then
      local monsterDes = self:GetMonsterDes()
      if monsterDes then
        table.insert(contextData, monsterDes)
      end
      local monsterDetail = self:GetMonsterDetail()
      if monsterDetail then
        table.insert(contextData, monsterDetail)
      end
      local unlockReward = self:GetMonsterUnlock()
      if unlockReward then
        table.insert(contextData, unlockReward)
      end
      local position = self:GetPosition()
      table.insert(contextData, position)
      local killNum = self:GetKillNum()
      table.insert(contextData, killNum)
    else
      local monsterDes = self:GetMonsterDes()
      if monsterDes then
        table.insert(contextData, monsterDes)
      end
      local monsterDetail = self:GetMonsterDetail()
      if monsterDetail then
        table.insert(contextData, monsterDetail)
      end
      local unlockReward = self:GetMonsterUnlock()
      if unlockReward then
        table.insert(contextData, unlockReward)
      end
      local position = self:GetPosition()
      table.insert(contextData, position)
    end
  end
  self.attriCtl:ResetDatas(contextData)
end

function MonsterScoreTip:GetMCharacteristicDatas(behaviorId)
  local showResult, allReuslt = {}, {}
  local pos = 0
  while 0 < behaviorId do
    if behaviorId % 2 == 1 then
      local data = Table_MCharacteristic[math.pow(2, pos)]
      if data then
        if data.show == 1 then
          table.insert(showResult, data)
        end
        table.insert(allReuslt, data)
      end
    end
    behaviorId = math.floor(behaviorId / 2)
    pos = pos + 1
  end
  return showResult, allReuslt
end

function MonsterScoreTip:UpdateAppendData()
  if self.isUnlock then
    local trans = self.attriCtl.layoutCtrl.transform
    local bound = NGUIMath.CalculateRelativeWidgetBounds(trans, true)
    local pos = trans.localPosition
    pos = Vector3(pos.x, pos.y - bound.size.y, pos.z - 20)
    trans = self.appCtl.layoutCtrl.transform
    trans.localPosition = pos
    local appends = self.data:getNoRewardAppend()
    if 0 < #appends then
      self.appCtl:ResetDatas(appends)
    else
      self.appCtl:ResetDatas()
    end
  else
    self.appCtl:ResetDatas()
  end
end

function MonsterScoreTip:UpdateDropItems()
  if self.isUnlock then
    if self.dropItemData and #self.dropItemData.itemDatas > 0 then
      self.dropItemCtrl.gameObject:SetActive(true)
      local trans = self.appCtl.layoutCtrl.transform
      local bound = NGUIMath.CalculateRelativeWidgetBounds(trans, true)
      local pos = trans.localPosition
      pos = Vector3(pos.x, pos.y - bound.size.y - 20, pos.z)
      self.dropItemCtrl.gameObject.transform.localPosition = pos
      self.dropItemCtrl:SetData(self.dropItemData)
    else
      self.dropItemCtrl.gameObject:SetActive(false)
    end
  else
    self.dropItemCtrl.gameObject:SetActive(false)
  end
end

function MonsterScoreTip:SetCopySkillData()
  local config = Table_Monster[self.data.staticData.id]
  if not config then
    return
  end
  if not config.CopySkill then
    self.copySkillCt:SetActive(false)
  else
    self.copySkillCt:SetActive(true)
    local trans = self.featureCt.activeSelf and self.featureCt.transform or self.baseAttrCt.transform
    local bound = NGUIMath.CalculateRelativeWidgetBounds(trans, true)
    local pos = LuaGeometry.TempGetLocalPosition(trans)
    pos.y = pos.y - bound.size.y - 20
    self.copySkillCt.transform.localPosition = pos
    local skills = ReusableTable.CreateArray()
    if type(config.CopySkill) == "table" then
      for i = 1, #config.CopySkill do
        local skillId = config.CopySkill[i]
        local data = Table_Skill[skillId]
        skills[#skills + 1] = data
      end
    elseif type(config.CopySkill) == "number" then
      local data = Table_Skill[config.CopySkill]
      skills[#skills + 1] = data
    end
    self.copySkillCtGridCtrl:ResetDatas(skills)
    ReusableTable.DestroyAndClearArray(skills)
  end
end

function MonsterScoreTip:OnEnable()
end

function MonsterScoreTip:OnExit()
  self.attriCtl:ResetDatas()
  self.mclabel:SetData(nil)
  self.baseAttrCtGrid:ResetDatas()
  self.appCtl:ResetDatas()
  if self.dropItemCtrl then
    self.dropItemCtrl:SetData(nil)
    self.dropItemCtrl = nil
  end
  self.advRewardCtl:ResetDatas()
  self.copySkillCtGridCtrl:ResetDatas()
  UIModelUtil.Instance:ResetTexture(self.modeltexture)
  Game.GOLuaPoolManager:AddToUIPool(self.resID, self.gameObject)
  MonsterScoreTip.super.OnExit(self)
end

local tipOffset = {200, 0}
local tipData = {}

function MonsterScoreTip:ShowAppendTip(cell)
  local cellData = cell.data
  if not cellData then
    return
  end
  local datas = AdventureDataProxy.Instance:GetAppendDatas(cellData.staticData.targetID, cellData.staticData.Content, cellData)
  table.sort(datas, function(a, b)
    local numA = a.staticData and a.staticData.Params and a.staticData.Params[1]
    local numB = b.staticData and b.staticData.Params and b.staticData.Params[1]
    if numA and numB then
      return numA < numB
    elseif numB then
      return true
    end
    return false
  end)
  for i, v in ipairs(datas) do
    v.index = i
    v:UpdateDataByCurAppend(cellData)
  end
  tipData.datas = datas
  TipManager.Instance:ShowAddventureAppendTip(tipData, self.tipAnchor, NGUIUtil.AnchorSide.Right, tipOffset)
end
