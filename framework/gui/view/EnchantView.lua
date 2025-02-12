autoImport("EquipChooseBord")
autoImport("EnchantAttrInfoCell")
autoImport("EnchantEffectCell")
EnchantView = class("EnchantView", BaseView)
EnchantView.ViewType = UIViewType.NormalLayer
EnchantEffectType = {
  Combine = "EnchantEffectType_combine",
  Enchant = "EnchantEffectType_Enchant"
}
EnchantView.ButtonLabText = {
  [EnchantType.Primary] = ZhString.EnchantView_PrimaryEnchant,
  [EnchantType.Medium] = ZhString.EnchantView_MediumEnchant,
  [EnchantType.Senior] = ZhString.EnchantView_SeniorEnchant
}
EnchantView.EnchantAction = "use_magic"
local DEFAULT_MATERIAL_SEARCH_BAGTYPES, ENCHANT_MATERIAL_SEARCH_BAGTYPES

function EnchantView:Init()
  local packageCheck = GameConfig.PackageMaterialCheck
  DEFAULT_MATERIAL_SEARCH_BAGTYPES = packageCheck.default
  ENCHANT_MATERIAL_SEARCH_BAGTYPES = packageCheck.enchant
  local viewdata = self.viewdata and self.viewdata.viewdata
  self.npcdata = viewdata and viewdata.npcdata
  self.enchantType = viewdata and viewdata.enchantType or EnchantType.Senior
  self:InitUI()
  self:MapEvent()
end

function EnchantView:InitUI()
  local ego = self:PlayUIEffect(EffectMap.UI.MiyinEquipStreng, self:FindGO("RightBg"), false)
  ego:ResetLocalPosition(LuaGeometry.GetTempVector3(290.6, 142))
  self.enchantTipBord = self:FindGO("EnchantTipBrod")
  self.enchantEffectBord = self:FindGO("EnchantEffectBord")
  self.enchantInfoBord = self:FindGO("EnchantInfoBord")
  self.addItemButton = self:FindGO("AddItemButton")
  self:AddClickEvent(self.addItemButton, function(go)
    self:clickTargetItem()
  end)
  self.targetGo = self:FindGO("TargetCell")
  local itemCellGO = self:LoadPreferb_ByFullPath(ResourcePathHelper.UICell("ItemCell"), self.targetGo)
  self.targetItemCell = BaseItemCell.new(self.targetGo)
  self.targetItemCell:AddEventListener(MouseEvent.MouseClick, self.clickTargetItem, self)
  self.effectBg = self:FindComponent("EffectBg", ChangeRqByTex)
  local enchantEffectGrid = self:FindComponent("EnchantEffectGrid", UIGrid, self.enchantEffectBord)
  self.enchantEffectCtl = UIGridListCtrl.new(enchantEffectGrid, EnchantEffectCell, "EnchantEffectCell")
  self.noEquipEnchantTip = self:FindGO("NoEnchantTip", self.enchantEffectBord)
  local coins = self:FindGO("TopCoins")
  self.usermrb = self:FindGO("MRB", coins)
  self.mrbLabel = self:FindComponent("Label", UILabel, self.usermrb)
  self.mrbSymbol = self:FindComponent("symbol", UISprite, self.usermrb)
  self.userRob = self:FindGO("Silver", coins)
  self.robLabel = self:FindComponent("Label", UILabel, self.userRob)
  IconManager:SetItemIcon(Table_Item[135].Icon, self.mrbSymbol)
  local robSymbol = self:FindComponent("symbol", UISprite, self.userRob)
  IconManager:SetItemIcon(Table_Item[GameConfig.MoneyId.Zeny].Icon, robSymbol)
  local chooseContaienr = self:FindGO("ChooseContainer")
  local chooseBordDataFunc = function()
    return self:GetEnchantEquips()
  end
  self.chooseBord = EquipChooseBord.new(chooseContaienr, chooseBordDataFunc)
  self.chooseBord:AddEventListener(EquipChooseBord.ChooseItem, self.ChooseItem, self)
  self.chooseBord:Hide()
  self.enchantButton = self:FindGO("EnchantButton")
  self.discount = self:FindComponent("Discount", UILabel)
  self.discount.gameObject:SetActive(false)
  local buttonLab = self:FindComponent("Label", UILabel, self.enchantButton)
  buttonLab.text = EnchantView.ButtonLabText[self.enchantType]
  self:AddClickEvent(self.enchantButton, function(go)
    self:TryEnchant()
  end)
  self.enchantTipLab = self:FindComponent("TipLabel", UILabel, self.enchantTipBord)
  self.costGrid = self:FindComponent("CostGrid", UIGrid)
  self.enchantMrbTable = self:FindComponent("MRB", UITable, self.costGrid.gameObject)
  self.enchantMrbIcon = self:FindComponent("PriceIcon", UISprite, self.enchantMrbTable.gameObject)
  self.enchantMrbLab = self:FindComponent("PriceNum", UILabel, self.enchantMrbTable.gameObject)
  self.enchantMrbOriginalLab = self:FindComponent("OriginalPriceNum", UILabel, self.enchantMrbTable.gameObject)
  self.enchantSilverTable = self:FindComponent("Silver", UITable, self.costGrid.gameObject)
  self.enchantSilverLab = self:FindComponent("PriceNum", UILabel, self.enchantSilverTable.gameObject)
  self.enchantSilverOriginalLab = self:FindComponent("OriginalPriceNum", UILabel, self.enchantSilverTable.gameObject)
  local enchantSilverIcon = self:FindComponent("PriceIcon", UISprite, self.enchantSilverTable.gameObject)
  IconManager:SetItemIcon(Table_Item[GameConfig.MoneyId.Zeny].Icon, enchantSilverIcon)
  self.enchantTipChoose = self:FindGO("ChooseState", self.enchantTipBord)
  self.enchantTipUnChoose = self:FindGO("UnChooseState", self.enchantTipBord)
  self:AddButtonEvent("EnchantInfoButton", function(go)
    self.enchantInfoBord:SetActive(true)
  end)
  self.enchantInfoTitle = self:FindComponent("Title", UILabel, self.enchantInfoBord)
  local enchantInfoTable = self:FindComponent("EnchantInfoTable", UITable)
  self.enchantInfoCtl = UIGridListCtrl.new(enchantInfoTable, EnchantAttrInfoCell, "EnchantAttrInfoCell")
  local infoCloseButton = self:FindGO("InfoCloseButton", self.enchantInfoBord)
  self:AddClickEvent(infoCloseButton, function(go)
    self.enchantInfoBord:SetActive(false)
  end)
  self.compareButton = self:FindGO("CompareButton")
  self.saveAttriButton = self:FindGO("SaveAttriButton")
  self:AddPressEvent(self.compareButton, function(go, isPress)
    if isPress then
      self:UpdateEquipEffect(false, true)
    else
      self:UpdateEquipEffect(true)
    end
  end)
  self:AddClickEvent(self.saveAttriButton, function(go)
    if self.nowItemData and self.hasUnSaveAttri then
      ServiceItemProxy.Instance:CallProcessEnchantItemCmd(true, self.nowItemData.id)
    end
  end)
  self:UpdateCoins()
  self:UpdateEnchantTip()
end

function EnchantView:GetEnchantEquips()
  local equipEquips = BagProxy.Instance.roleEquip:GetItems() or {}
  local bagEquips = BagProxy.Instance:GetBagEquipItems()
  local result = {}
  for i = 1, #equipEquips do
    local equipInfo = equipEquips[i] and equipEquips[i].equipInfo
    if equipInfo and equipInfo:CanEnchant() then
      table.insert(result, equipEquips[i])
    end
  end
  for i = 1, #bagEquips do
    local equipInfo = bagEquips[i] and bagEquips[i].equipInfo
    if equipInfo and equipInfo:CanEnchant() then
      table.insert(result, bagEquips[i])
    end
  end
  return result
end

function EnchantView:clickTargetItem(cellCtl)
  self.chooseBord:Show(true)
  self.enchantInfoBord:SetActive(false)
  self.chooseBord:SetChoose(self.nowItemData)
end

function EnchantView:ChooseItem(itemData)
  self.nowItemData = itemData
  if self.nowItemData then
    self.addItemButton:SetActive(false)
    self.targetGo:SetActive(true)
  else
    self.addItemButton:SetActive(true)
    self.targetGo:SetActive(false)
  end
  self.targetItemCell:SetData(self.nowItemData)
  self.targetItemCell:UpdateMyselfInfo(self.nowItemData)
  self:UpdateEquipEffect()
  self:UpdateEnchantTip()
  self.chooseBord:Hide()
end

function EnchantView:GetCost()
  local itemType
  if self.nowItemData then
    itemType = self.nowItemData.staticData.Type
  end
  return BlackSmithProxy.Instance:GetEnchantCost(self.enchantType, itemType)
end

function EnchantView:GetMrb()
  local itemCost = self:GetCost()
  itemCost = itemCost and itemCost[1]
  local itemid = itemCost and itemCost.itemid or 135
  local items = BagProxy.Instance:GetMaterialItems_ByItemId(itemid, ENCHANT_MATERIAL_SEARCH_BAGTYPES)
  local searchNum = 0
  for i = 1, #items do
    searchNum = searchNum + items[i].num
  end
  return searchNum
end

function EnchantView:GetEnchantItemNum(itemid)
  local items = BagProxy.Instance:GetMaterialItems_ByItemId(itemid, ENCHANT_MATERIAL_SEARCH_BAGTYPES)
  local searchNum = 0
  for i = 1, #items do
    searchNum = searchNum + items[i].num
  end
  return searchNum
end

function EnchantView:UpdateCoins()
  self.robLabel.text = StringUtil.NumThousandFormat(MyselfProxy.Instance:GetROB())
  self.mrbLabel.text = StringUtil.NumThousandFormat(self:GetMrb())
end

function EnchantView:UpdateEquipEffect(withGoodTip, showOriginal)
  local nowData = self.nowItemData
  if nowData then
    self.enchantEffectBord:SetActive(true)
    local resultEffect, enchantAttrs = {}
    self.hasUnSaveAttri = nowData:HasUnSaveAttri()
    if not showOriginal and self.hasUnSaveAttri then
      enchantAttrs = {}
    else
      enchantAttrs = nowData.enchantInfo:GetEnchantAttrs()
    end
    self.hasNewGoodAttri = nowData.enchantInfo:HasNewGoodAttri()
    for i = 1, #enchantAttrs do
      local temp = {}
      temp.type = EnchantEffectType.Enchant
      temp.showline = true
      temp.withGoodTip = true
      temp.enchantAttri = enchantAttrs[i]
      table.insert(resultEffect, temp)
    end
    local combineEffects
    if not showOriginal and self.hasUnSaveAttri then
    else
      combineEffects = nowData.enchantInfo:GetCombineEffects()
    end
    if combineEffects then
      for i = 1, #combineEffects do
        local combineEffect = combineEffects[i]
        if combineEffect then
          local temp = {}
          temp.type = EnchantEffectType.Combine
          temp.isWork = combineEffect.isWork
          if temp.isWork then
            temp.combineTip = string.format("%s:%s", combineEffect.buffData.BuffName, combineEffect.buffData.BuffDesc)
          else
            temp.combineTip = string.format("%s:%s(%s)", combineEffect.buffData.BuffName, combineEffect.buffData.BuffDesc, combineEffect.WorkTip)
          end
          table.insert(resultEffect, temp)
        end
      end
    end
    self.enchantEffectCtl:ResetDatas(resultEffect)
    self.noEquipEnchantTip:SetActive(#resultEffect == 0)
    self.saveAttriButton:SetActive(self.hasUnSaveAttri)
    self.compareButton:SetActive(self.hasUnSaveAttri)
    self:sendNotification(self.hasUnSaveAttri and HomeEvent.WorkbenchHideHelpBtn or HomeEvent.WorkbenchShowHelpBtn)
  else
    self.enchantEffectBord:SetActive(false)
    self.hasUnSaveAttri = false
    self.hasNewGoodAttri = false
  end
end

function EnchantView:UpdateEnchantTip()
  self.material_enough = false
  if self.nowItemData then
    self.enchantTipChoose:SetActive(true)
    self.enchantTipUnChoose:SetActive(false)
    self.material_enough = true
    local itemCost, zenyCost, actDiscount, homeDiscount = self:GetCost()
    itemCost = itemCost and itemCost[1]
    self.discount.gameObject:SetActive(actDiscount ~= nil)
    if actDiscount then
      self.discount.text = string.format("%d%%", 100 - actDiscount)
    end
    if itemCost and itemCost.num and itemCost.num > 0 then
      self.enchantMrbTable.gameObject:SetActive(true)
      local nowMrbNum = math.floor(itemCost.num * (actDiscount or 100) / 100 + 0.01)
      if nowMrbNum > self:GetEnchantItemNum(itemCost.itemid) then
        self.material_enough = false
        self.enchantMrbLab.text = string.format("[c][FF3B0D]x%s[-][/c]", nowMrbNum)
      else
        self.enchantMrbLab.text = "x" .. nowMrbNum
      end
      local iconName = Table_Item[itemCost.itemid].Icon
      IconManager:SetItemIcon(iconName, self.mrbSymbol)
      IconManager:SetItemIcon(iconName, self.enchantMrbIcon)
      local showOrig = actDiscount and nowMrbNum ~= itemCost.num or false
      self.enchantMrbOriginalLab.gameObject:SetActive(showOrig)
      if showOrig then
        self.enchantMrbOriginalLab.text = "x" .. itemCost.num
      end
      self.enchantMrbTable:Reposition()
    else
      IconManager:SetItemIcon(Table_Item[135].Icon, self.mrbSymbol)
      self.enchantMrbTable.gameObject:SetActive(false)
    end
    if zenyCost and 0 < zenyCost then
      self.enchantSilverTable.gameObject:SetActive(true)
      local nowZenyCost = math.floor(zenyCost * (actDiscount or homeDiscount or 100) / 100 + 0.01)
      if nowZenyCost > MyselfProxy.Instance:GetROB() then
        self.material_enough = false
        self.enchantSilverLab.text = string.format("[c][FF3B0D]x%s[-][/c]", nowZenyCost)
      else
        self.enchantSilverLab.text = "x" .. nowZenyCost
      end
      local showOrig = actDiscount and nowZenyCost ~= zenyCost or false
      self.enchantSilverOriginalLab.gameObject:SetActive(showOrig)
      if showOrig then
        self.enchantSilverOriginalLab.text = "x" .. zenyCost
      end
      self.enchantSilverTable:Reposition()
    else
      self.enchantSilverTable.gameObject:SetActive(false)
    end
    self.costGrid.gameObject:SetActive(true)
    TimeTickManager.Me():CreateOnceDelayTick(16, function(self)
      self.costGrid:Reposition()
    end, self)
    self.enchantTipLab.text = string.format(ZhString.EnchantView_EnchantTip, self.nowItemData.staticData.NameZh, EnchantView.ButtonLabText[self.enchantType])
    self:UpdateEnchantInfo()
    self:UpdateCoins()
  else
    self.costGrid.gameObject:SetActive(false)
    self.discount.gameObject:SetActive(false)
    self.enchantTipChoose:SetActive(false)
    self.enchantTipUnChoose:SetActive(true)
  end
end

function EnchantView:UpdateEnchantInfo()
  if self.nowItemData then
    local enchantDatas = self:CombineEnchantInfoDatas()
    self.enchantInfoTitle.text = EnchantView.ButtonLabText[self.enchantType] .. ZhString.EnchantView_Attri
    self.enchantInfoCtl:ResetDatas(enchantDatas)
  else
    errorLog("Not Select Item")
  end
end

function EnchantView:CombineEnchantInfoDatas()
  local enchantType = self.enchantType
  local enchantDatas = EnchantEquipUtil.Instance:GetEnchantDatasByEnchantType(enchantType)
  local result = {}
  local equipType = self.nowItemData.staticData.Type
  for attriType, data in pairs(enchantDatas) do
    local attriMenuType, pos = EnchantEquipUtil.Instance:GetMenuType(attriType)
    local infoData = result[attriMenuType]
    if not infoData then
      infoData = {}
      infoData.attriMenuType = attriMenuType
      infoData.attris = {}
      result[attriMenuType] = infoData
    end
    local cbdata = {}
    cbdata.attriMenuType = attriMenuType
    cbdata.equipType = equipType
    cbdata.enchantType = enchantType
    cbdata.enchantData, cbdata.canGet = data:Get(equipType)
    cbdata.pos = pos
    table.insert(infoData.attris, cbdata)
  end
  local combineEffects = EnchantEquipUtil.Instance:GetCombineEffects(enchantType)
  local hasValue = next(combineEffects)
  if hasValue then
    local infoData = {}
    infoData.attriMenuType = EnchantMenuType.CombineAttri
    infoData.attris = {}
    table.insert(result, infoData)
    local enchantEquipUtil = EnchantEquipUtil.Instance
    local nameKeysMap, attris = {}, infoData.attris
    for _, data in pairs(combineEffects) do
      if nameKeysMap[data.Name] == nil then
        local cbdata = {}
        cbdata.attriMenuType = EnchantMenuType.CombineAttri
        cbdata.equipType = equipType
        cbdata.enchantType = enchantType
        cbdata.enchantData = data
        cbdata.pos = data.id
        cbdata.canGet = enchantEquipUtil:CanGetCombineEffect(data, equipType)
        table.insert(attris, cbdata)
        nameKeysMap[data.Name] = #attris
      else
        local canGet = enchantEquipUtil:CanGetCombineEffect(data, equipType)
        if canGet then
          local cbdata = attris[nameKeysMap[data.Name]]
          cbdata.enchantData = data
          cbdata.pos = data.id
          cbdata.canGet = true
        end
      end
    end
  end
  return result
end

local lastTryEnchantTime = 0

function EnchantView:TryEnchant()
  if self.waitRecv then
    return
  end
  local nowTime = ServerTime.CurClientTime()
  if nowTime - lastTryEnchantTime < 500 then
    return
  end
  lastTryEnchantTime = nowTime
  if self.nowItemData then
    local hasNewGoodAttri = self.nowItemData.enchantInfo:HasNewGoodAttri()
    if hasNewGoodAttri then
      MsgManager.ConfirmMsgByID(3060, function()
        self:DoEnchant()
      end)
      return
    end
    self:DoEnchant()
  else
    printRed("No Choosem Item")
  end
end

function EnchantView:DoEnchant()
  FunctionSecurity.Me():EnchantingEquip(self.ExcuteEnchant, self)
end

function EnchantView:ExcuteEnchant()
  if self.nowItemData then
    if not BlackSmithProxy.HasErrorEnchantInfo(self.nowItemData) and not self.material_enough then
      MsgManager.ShowMsgByIDTable(8)
      return
    end
    if not self.material_enough then
      MsgManager.ShowMsgByIDTable(8)
      return
    end
    if self.npcdata then
      self.npcdata:Client_PlayAction(EnchantView.EnchantAction, nil, false)
    end
    self.waitRecv = true
    ServiceItemProxy.Instance:CallEnchantEquip(self.enchantType, self.nowItemData.id)
    self:sendNotification(HomeEvent.WorkbenchStartWork)
  end
end

function EnchantView:MapEvent()
  self:AddListenEvt(ServiceEvent.ItemEnchantEquip, self.HandleEnchantEnd)
  self:AddListenEvt(ItemEvent.ItemUpdate, self.HandleEnchantItemUpdate)
  self:AddListenEvt(ItemEvent.EquipUpdate, self.HandleEnchantItemUpdate)
  self:AddListenEvt(MyselfEvent.MyDataChange, self.HandleMyDataChange)
end

function EnchantView:HandleMyDataChange(note)
  self:UpdateCoins()
  self:UpdateEnchantTip()
end

function EnchantView:HandleEnchantEnd(note)
  self.waitRecv = false
  self:UpdateEquipEffect(true)
  self:UpdateEnchantTip()
  self:PlayUISound(AudioMap.Maps.Refinesuccess)
  self:PlayUIEffect(EffectMap.UI.upgrade_surprised, self.effectBg.gameObject, true, EnchantView.UpgradeEffectHandle, self)
end

function EnchantView.UpgradeEffectHandle(effectHandle, owner)
  if owner then
    owner.effectBg:AddChild(effectHandle.gameObject)
  end
end

function EnchantView:HandleEnchantItemUpdate()
  self:UpdateEquipEffect(true)
  self:UpdateEnchantTip()
end

function EnchantView:OnEnter()
  EnchantView.super.OnEnter(self)
  if self.npcdata then
    local npcTrans = self.npcdata.assetRole.completeTransform
    if npcTrans then
      local viewPort = CameraConfig.HappyShop_ViewPort
      local rotation = CameraConfig.HappyShop_Rotation
      self:CameraFaceTo(npcTrans, viewPort, rotation)
    end
  else
    self:CameraRotateToMe()
  end
  self.waitRecv = false
end

function EnchantView:OnExit()
  self:CameraReset()
  TimeTickManager.Me():ClearTick(self)
  EnchantView.super.OnExit(self)
  TimeLimitShopProxy.Instance:viewPopUp()
end

function EnchantView:CloseSelf()
  if self.nowItemData then
    if self.hasNewGoodAttri then
      MsgManager.ConfirmMsgByID(3060, function()
        ServiceItemProxy.Instance:CallProcessEnchantItemCmd(false, self.nowItemData.id)
        EnchantView.super.CloseSelf(self)
      end, nil, nil)
      return
    elseif self.hasUnSaveAttri then
      ServiceItemProxy.Instance:CallProcessEnchantItemCmd(false, self.nowItemData.id)
    end
  end
  EnchantView.super.CloseSelf(self)
end
