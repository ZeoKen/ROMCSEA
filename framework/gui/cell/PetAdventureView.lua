PetAdventureView = class("PetAdventureView", SubView)
autoImport("PetAdventureQuestCell")
autoImport("PetAdventureChooseCell")
autoImport("PetDropItemCell")
autoImport("PetDropItemData")
autoImport("PopupGridList")
PetAdventureView.ViewType = UIViewType.NormalLayer
local startAdventureEff = EffectMap.Maps.StartPetAdventure
local effectResID = EffectMap.UI.PVP_Win
local rewardEffResID = EffectMap.UI.Pet_RewardUp
local totalQuest = GameConfig.PetAdventureMinLimit.max_adventure
local fightTimeHelpId = 100003
local rewardEfficHelpId = 100002
local Zeny = 100
local jobBase = 400
local base = 300
local tempVector3 = LuaVector3.Zero()
local tempPos = LuaVector3.Zero()
local tempRot1 = LuaQuaternion(0, 0, 0, 0)
local tempRot2 = LuaQuaternion(0, 0, 0, 0)
local PACKAGE_MATERIAL = GameConfig.PackageMaterialCheck.pet_workspace or {
  1,
  7,
  9
}
local chooseBtnPosition = {
  [1] = LuaVector3(-122, 58, 0),
  [2] = LuaVector3(-260, 58, 0),
  [3] = LuaVector3(0, 58, 0),
  [4] = LuaVector3(-360, 58, 0),
  [5] = LuaVector3(118, 58, 0)
}
local SUB_VIEW_PATH = ResourcePathHelper.UIView("PetAdventureView")

function PetAdventureView:Init()
  self:FindObjs()
  self:AddViewEvts()
  self:AddEvts()
  self:Hide(self.PetQuest)
end

function PetAdventureView:LoadSubView()
  local obj = self:LoadPreferb_ByFullPath(SUB_VIEW_PATH, self.container.adventureObj, true)
  obj.name = "PetAdventureView"
end

local QuestPhase = {
  NONE = 0,
  MATCH = 1,
  FINISHED = 2,
  UNDERWAY = 3
}
local _ticketIconName = "item_5833"

function PetAdventureView:FindObjs()
  self:LoadSubView()
  self.PetQuest = self:FindGO("Pos")
  self.loadingPos = self:FindGO("Loading")
  self.petScroll = self:FindComponent("petQuestScroll", UIScrollView)
  self.petTexture = self:FindComponent("petTexture", UITexture)
  local PetInfo = self:FindGO("PetInfo")
  self.adventureNameLab = self:FindComponent("adventureName", UILabel, PetInfo)
  self.recommendPetLab = self:FindComponent("recommendLab", UILabel, PetInfo)
  self.petDesc = self:FindComponent("petDesc", UILabel, PetInfo)
  self.effectPos = self:FindGO("effectRoot")
  self.rewardEffectPos = self:FindGO("rewardEffectPos")
  self.goBtn = self:FindGO("goBtn")
  self.getRewardBtn = self:FindGO("GetRewardBtn")
  self.againGoBtn = self:FindGO("AgainGoBtn")
  self.againGoLabel = self:FindComponent("Label", UILabel, self.againGoBtn)
  self.againGoLabel.text = ZhString.PetAdventure_AgainGo
  self.consumeFightTimeLab = self:FindComponent("ConsumeFightTimeLab", UILabel)
  self.questProcessLab = self:FindComponent("questProcess", UILabel)
  self.costPos = self:FindGO("costPos")
  self.costMoney = self:FindComponent("costMoney", UILabel, self.costPos)
  self.areaFilter = self:FindComponent("areaFilter", UIPopupList)
  self.petChoosePanel = self:FindGO("petChoosePos")
  self.costLab = self:FindComponent("costLab", UILabel)
  self.goBtnLabelEffectColor = self.costLab.effectColor
  self.curFightEfficiency = self:FindComponent("fightEffec", UILabel)
  self.dailyAdventureCountLab = self:FindComponent("DailyAdventureCount", UILabel)
  self.consumeHelpBtn = self:FindGO("consumeHelpBtn")
  self.petChooseNum = self:FindComponent("petChooseNum", UILabel)
  self.rewardTitle = self:FindComponent("rewardTitle", UILabel)
  self.PetStatusTitle = self:FindComponent("PetStatusTitle", UILabel)
  self.curAreaName = self:FindComponent("areaFilterName", UILabel)
  self.finishedImg = self:FindComponent("finishedImg", UISprite)
  IconManager:SetArtFontIcon("com_bg_reached", self.finishedImg)
  self.emptyCost = self:FindComponent("emptyCost", UILabel)
  self.iconImg = self:FindComponent("costIcon", UISprite)
  self.againGoPos = self:FindGO("AgainGoInfo")
  self.againTipLabel = self:FindComponent("AgainTipLabel", UILabel, self.againGoPos)
  local againUseTicketInfo = self:FindGO("AgainUseTicketInfo", self.againGoPos)
  local ticketIcon = self:FindComponent("icon", UISprite, againUseTicketInfo)
  IconManager:SetItemIcon(_ticketIconName, ticketIcon)
  local useLabel = self:FindComponent("useLabel", UILabel, againUseTicketInfo)
  useLabel.text = ZhString.PetAdventure_UseTicket
  self.againGoTicketNum = self:FindComponent("hasTicketCount", UILabel, againUseTicketInfo)
  self.againUseTicketToggle = self:FindComponent("AgainUseTicketToggle", UIToggle, againUseTicketInfo)
  if GameConfig.PetAdventureView and GameConfig.PetAdventureView.PetAdventureVolume and GameConfig.PetAdventureView.PetAdventureVolume == 1 then
    againUseTicketInfo:SetActive(false)
  end
  local againcostPos = self:FindGO("againCostPos")
  self.againCostMoney = self:FindComponent("costMoney", UILabel, againcostPos)
  self.useTicketBar = self:FindGO("useTicket")
  self.ticketNum = self:FindComponent("hasTicketCount", UILabel)
  self.useTicketToggle = self:FindComponent("useTicketToggle", UIToggle)
  EventDelegate.Add(self.useTicketToggle.onChange, function()
    self:UpdatePetQuestInfoOnUseTicketChange()
  end)
  self.useTicketTextLabel = self:FindComponent("useLabel", UILabel)
  self.useTicketTextLabel.text = ZhString.PetAdventure_UseTicket
  local l_sprUseTicketIcon = self:FindComponent("icon", UISprite)
  IconManager:SetItemIcon(_ticketIconName, l_sprUseTicketIcon)
  self.closecomp = self.petChoosePanel:GetComponent(CloseWhenClickOtherPlace)
  
  function self.closecomp.callBack(go)
    PetAdventureProxy.Instance:ResetPetClickIndex()
  end
  
  self:UpdateAdvTicketNum()
  local container = self:FindGO("PetQuestWrap")
  local questConfig = {
    wrapObj = container,
    pfbNum = 6,
    cellName = "PetAdventureQuestCell",
    control = PetAdventureQuestCell,
    dir = 1
  }
  self.petQuestlist = WrapCellHelper.new(questConfig)
  self.petQuestlist:AddEventListener(MouseEvent.MouseClick, self.ClickPetQuestCell, self)
  self.petQuestlist:AddEventListener(PetQuestEvent.OnClickMonster, self.onClickSpec, self)
  local PetWrapObj = self:FindGO("PetWrap")
  local petConfig = {
    wrapObj = PetWrapObj,
    pfbNum = 6,
    cellName = "PetAdventureChooseCell",
    control = PetAdventureChooseCell,
    dir = 1
  }
  self.petlist = WrapCellHelper.new(petConfig)
  self.petlist:AddEventListener(MouseEvent.MouseClick, self.ClickChoosenPetCell, self)
  self.petlist:AddEventListener(PetEvent.ClickPetAdventureIcon, self.ShowPetHeadTips, self)
  self:Hide(self.petChoosePanel)
  PetAdventureProxy.Instance:ResetPetClickIndex()
end

function PetAdventureView:tabClick(selectTabData)
  self.selectTabData = selectTabData
  local allData = self:SetAreaData()
  local areaId = selectTabData.areaID
  local result
  if areaId == 0 then
    result = self.petQuestData
  else
    result = allData[areaId]
  end
  if 0 < #result then
    self:UpdateQuestByArea(result)
    self.curAreaValue = selectTabData.Name
  else
    self.itemTabs.labCurrent.text = self.curAreaValue
    MsgManager.ShowMsgByID(8022)
  end
end

function PetAdventureView:UpdateAdvTicketNum()
  self.ticketNum.text = "X " .. self:GetAdvTicketNum()
  self.againGoTicketNum.text = "X " .. self:GetAdvTicketNum()
end

local advTicketItemId = 5833

function PetAdventureView:GetAdvTicketNum()
  return BagProxy.Instance:GetItemNumByStaticID(advTicketItemId)
end

function PetAdventureView:UseTicketValid(UIToggle)
  UIToggle = UIToggle or self.useTicketToggle
  return UIToggle.value == true and self:GetAdvTicketNum() > 0
end

function PetAdventureView:ShowPetHeadTips(cellctl)
  if cellctl then
    local stickPos = cellctl.headTipStick
    local tipData = cellctl.data
    local petheadTip = TipManager.Instance:ShowPetAdventureHeadTip(tipData, stickPos, NGUIUtil.AnchorSide.Right, {205, -120})
    petheadTip:AddIgnoreBounds(self.petChoosePanel)
    self:AddIgnoreBounds(petheadTip.gameObject)
  end
end

function PetAdventureView:AddIgnoreBounds(obj)
  if self.gameObject and self.closecomp then
    self.closecomp:AddTarget(obj.transform)
  end
end

function PetAdventureView:AddEvts()
  self:AddClickEvent(self.goBtn, function(g)
    self:StartPetAdventure()
  end)
  self:AddClickEvent(self.getRewardBtn, function(g)
    self:ClickGetRewardBtn()
  end)
  self:AddClickEvent(self.curFightEfficiency.gameObject, function(g)
    local data = PetAdventureProxy.Instance.tipData
    if data then
      self:ShowAdventureEffDetail(data)
    end
  end)
  self:AddClickEvent(self.recommendPetLab.gameObject, function(g)
    self:ShowRecommendPetTip()
  end)
  self:RegistShowGeneralHelpByHelpID(fightTimeHelpId, self.consumeHelpBtn)
  local rewardTipBtn = self:FindGO("rewardTitleTipBtn")
  self:RegistShowGeneralHelpByHelpID(rewardEfficHelpId, rewardTipBtn)
  local closePetChoose = self:FindGO("closePetChoose")
  self:AddClickEvent(closePetChoose, function()
    self:Hide(self.petChoosePanel)
    PetAdventureProxy.Instance:ResetPetClickIndex()
    TipManager.Instance:CloseTip()
  end)
  self:AddClickEvent(self.againGoBtn, function()
    local leftTime = PetAdventureProxy.Instance:GetLeftAdventureTime(self.ChooseQuestData.staticData.id)
    if leftTime and leftTime <= 0 then
      MsgManager.ShowMsgByID(41004)
      return
    end
    self.againGoPos:SetActive(true)
    self.againUseTicketToggle.value = 0 < self:GetAdvTicketNum()
    local petCount = #self.ChooseQuestData:GetServerPet()
    if self.ChooseQuestData.staticData.Cost.num then
      self.againCostMoney.text = self.ChooseQuestData.staticData.Cost.num[petCount]
    end
  end)
  local cancelAgainBtn = self:FindGO("CancelAgainBtn")
  self:AddClickEvent(cancelAgainBtn, function()
    self.againGoPos:SetActive(false)
  end)
  local confirmAgainBtn = self:FindGO("ConfirmAgainBtn")
  local confirmAgainCostPos = self:FindGO("againCostPos", confirmAgainBtn)
  local tickIcon = self:FindComponent("costIcon", UISprite, confirmAgainCostPos)
  IconManager:SetItemIcon("item_5503", tickIcon)
  self:AddClickEvent(confirmAgainBtn, function()
    local costItem = self.ChooseQuestData.staticData.Cost.id
    local ownCount = BagProxy.Instance:GetItemNumByStaticID(costItem, PACKAGE_MATERIAL)
    local petCount = #self.ChooseQuestData:GetServerPet()
    if nil ~= self.ChooseQuestData.staticData.Cost.num then
      local needCount = self.ChooseQuestData.staticData.Cost.num[petCount]
      if ownCount < needCount then
        MsgManager.ShowMsgByID(8011)
        return
      end
    end
    local againUseTicket = self:UseTicketValid(self.againUseTicketToggle)
    local monsterId = self.ChooseQuestData.specid
    local servicePets = {}
    for i = 1, #self.ChooseQuestData.petEggs do
      if "table" == type(self.ChooseQuestData.petEggs[i]) then
        servicePets[#servicePets + 1] = self.ChooseQuestData.petEggs[i].guid
      end
    end
    self:ClickGetRewardBtn()
    ServiceScenePetProxy.Instance:CallStartAdventurePetCmd(self.chooseQuestID, servicePets, monsterId, againUseTicket)
    self.againGoPos:SetActive(false)
  end)
end

function PetAdventureView:_resetClickIndex()
  self.clickPetIndex = nil
end

function PetAdventureView:UpdateQuestByArea(data)
  self.petQuestlist:ResetDatas(data)
  self:_ShowFirstQuestData()
  self.petQuestlist:ResetPosition()
end

function PetAdventureView:InitQuestData()
  self.petQuestData = PetAdventureProxy.Instance:GetQuestData()
  self.petQuestlist:UpdateInfo(self.petQuestData)
  self.petQuestlist:ResetPosition()
  self:_ShowFirstQuestData()
  self:SetProcessLab()
  if not self.itemTabs then
    self.itemTabs = PopupGridList.new(self:FindGO("ItemTabs"), function(self, data)
      if self.selectTabData ~= data then
        self.selectTabData = data
        self:tabClick(self.selectTabData)
      end
    end, self, self:FindComponent("filterPanel", UIPanel).depth + 2)
    self:InitAreaFilter()
  end
end

local listPopUpItems = {}

function PetAdventureView:InitAreaFilter()
  TableUtility.ArrayClear(listPopUpItems)
  for k, v in pairs(GameConfig.PetAdventureArea) do
    local data = {}
    data.Name = v
    data.areaID = k
    table.insert(listPopUpItems, data)
  end
  self.itemTabs:SetData(listPopUpItems)
end

function PetAdventureView:_ShowFirstQuestData()
  local questData = self.petQuestlist:GetCellCtls()
  local firstData = questData[1]
  if firstData then
    self:ClickPetQuestCell(firstData)
  end
end

function PetAdventureView:ShowRecommendPetTip()
  local chooseData = self.ChooseQuestData
  local condition = chooseData and chooseData.staticData.Condition
  if condition then
    TipManager.Instance:ShowRecommendTip(condition, self.recommendPetLab, NGUIUtil.AnchorSide.Top, {0, 200})
  end
end

function PetAdventureView:ClickChoosenPetCell(cellctl)
  local clickPetId = cellctl.data.id
  local data = cellctl and cellctl.data
  if data then
    local choosePet = data.guid
    if PetAdventureProxy.Instance:bOverFlowPet(choosePet) then
      local petNum = self.ChooseQuestData.staticData.PetNum
      MsgManager.ShowMsgByIDTable(8012, petNum)
      return
    end
    local locked = PetAdventureProxy.Instance:bPetlocked(data)
    if locked then
      MsgManager.ShowMsgByID(8015)
      return
    end
    local index = PetAdventureProxy.Instance:SetMatchPetData(data)
    self:ShowPetModel(index)
    local petChoosenData = self.petlist:GetCellCtls()
    for _, cell in pairs(petChoosenData) do
      cell:UpdateChoose()
    end
    self:_updateInfoByState()
  end
end

function PetAdventureView:_refreshEfficiency()
  local configEff = PetAdventureProxy.Instance:GetFightEfficiency()
  if 0 == configEff then
    self:Hide(self.curFightEfficiency)
    return configEff
  end
  self.curFightEfficiency.text = string.format(ZhString.PetAdventure_FightEfficiency, math.ceil(configEff * 100))
  self:Show(self.curFightEfficiency)
  return configEff
end

function PetAdventureView:OnClickPetChoose(index)
  if self.ChooseQuestData.status ~= PetAdventureProxy.QuestPhase.MATCH then
    return
  end
  self.petDataCells = PetAdventureProxy.Instance:GetOwnPetsData()
  if not self.petDataCells or #self.petDataCells <= 0 then
    MsgManager.ShowMsgByID(8019)
    return
  end
  PetAdventureProxy.Instance.clickPetIndex = index
  self:Show(self.petChoosePanel)
  TipManager.Instance:HidePetSpecTip()
  self.petlist:UpdateInfo(self.petDataCells)
  self.petlist:ResetPosition()
end

function PetAdventureView:SetProcessLab()
  local count = PetAdventureProxy.Instance:GetQuestProcess()
  self.questProcessLab.text = string.format(ZhString.PetAdventure_Process, count, totalQuest)
end

function PetAdventureView:SetAreaData()
  local static = Table_Pet_Adventure
  local result = {}
  for k, v in pairs(GameConfig.PetAdventureArea) do
    local data = {}
    for _, v in pairs(self.petQuestData) do
      local area = static[v.id].BigArea
      if k == area then
        table.insert(data, v)
      end
    end
    result[k] = data
  end
  return result
end

function PetAdventureView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.ScenePetQueryPetAdventureListPetCmd, self.HandlePetAdventureList)
  self:AddListenEvt(ServiceEvent.ScenePetPetAdventureResultNtfPetCmd, self.HandlePetAdventureResult)
  self:AddListenEvt(ServiceEvent.ScenePetQueryBattlePetCmd, self.HandleBattlePet)
  self:AddListenEvt(ServiceEvent.PlayerMapChange, self.HandleMapChange)
  self:AddListenEvt(MyselfEvent.MyDataChange, self.UpdateAdvTicketNum)
  self:AddListenEvt(ItemEvent.ItemUpdate, self.UpdateAdvTicketNum)
end

function PetAdventureView:HandleMapChange()
  self.container:CloseSelf()
end

function PetAdventureView:HandlePetAdventureList(note)
  if not PetAdventureProxy.Instance.recvQuestComplete then
    return
  end
  if self.loadingPos.activeSelf then
    self:Hide(self.loadingPos)
  end
  if not self.PetQuest.activeSelf then
    self:Show(self.PetQuest)
  end
  self:InitQuestData()
end

function PetAdventureView:ShowSpecialIDTip(data, stick, side, offset)
  local callback = function(param)
    if not self.destroyed and self.ChooseQuestData then
      self.chooseSpecid = nil
      self:_setAdventureName(param)
      self.ChooseQuestData.specid = param
      local cellData = self.petQuestlist:GetCellCtls()
      for _, cell in pairs(cellData) do
        if cell.data and cell.data.id == self.ChooseQuestData.id then
          cell:SetChooseSpecial(param)
        end
      end
      self:_updateInfoByState()
    end
  end
  local sdata = {
    itemdata = data,
    ignoreBounds = ignoreBounds,
    callback = callback,
    callbackParam = callbackParam
  }
  local tip = TipManager.Instance:ShowPetSpeicMonsterTip(sdata, stick, side, offset)
end

function PetAdventureView:_getMonsterID()
  local cellData = self.petQuestlist:GetCellCtls()
  for _, cell in pairs(cellData) do
    if cell.data and cell.data.id == self.ChooseQuestData.id then
      return cell.monsterId
    end
  end
end

function PetAdventureView:ShowAdventureEffDetail(data, stick, side, offset)
  local sdata = {
    itemdata = data,
    ignoreBounds = ignoreBounds
  }
  local tip = TipManager.Instance:ShowPetAdventureEffDetail(sdata, stick, side, offset)
end

function PetAdventureView:HandlePetAdventureResult(note)
  local serData = note.body.item
  self.petQuestData = PetAdventureProxy.Instance:GetQuestData()
  self.petQuestlist:UpdateInfo(self.petQuestData)
  self.petQuestlist:ResetPosition()
  self:SetProcessLab()
  if serData.status == PetAdventureProxy.QuestPhase.SUBMIT then
    self:_ShowFirstQuestData()
    return
  end
  for k, v in pairs(self.petQuestData) do
    if v.id == serData.id and serData.status == PetAdventureProxy.QuestPhase.UNDERWAY then
      self:UpdatePetQuestInfo(v)
    end
  end
end

function PetAdventureView:HandleBattlePet(note)
  local data = note.body
  if data and data.pets then
    PetAdventureProxy.Instance:GetBattlePet(data.pets)
  end
end

function PetAdventureView:StartPetAdventure()
  local processCount = PetAdventureProxy.Instance:GetQuestProcess()
  if processCount >= GameConfig.PetAdventureMinLimit.max_adventure then
    MsgManager.ShowMsgByID(8013)
    return
  end
  local chooseData = self.ChooseQuestData
  local leftTime = PetAdventureProxy.Instance:GetLeftAdventureTime(chooseData.staticData.id)
  local petNum = self.ChooseQuestData.staticData.PetNum
  if leftTime and leftTime <= 0 then
    MsgManager.ShowMsgByID(41004)
    return
  end
  if chooseData.staticData.Cost and chooseData.staticData.Cost.id then
    local petCount = PetAdventureProxy.Instance:GetMatchNum()
    if petCount == 0 then
      return
    end
    local staticNum = chooseData.staticData.Cost.num
    if petNum ~= #staticNum then
      helplog("Table_Pet_Adventure cost 配置错误,错误ID: ", chooseData.staticData.id)
      return
    end
    local costItem = chooseData.staticData.Cost.id
    if costItem == GameConfig.MoneyId.Zeny then
      local rob = MyselfProxy.Instance:GetROB()
      if rob < staticNum[petCount] then
        MsgManager.ShowMsgByID(1)
        return
      end
    else
      local ownCount = BagProxy.Instance:GetItemNumByStaticID(costItem, PACKAGE_MATERIAL)
      local needCount = staticNum[petCount]
      if ownCount < needCount then
        MsgManager.ShowMsgByID(8011)
        return
      end
    end
  end
  if 1 == chooseData.staticData.QuestType then
    local full = petNum == PetAdventureProxy.Instance:GetMatchNum()
    if not full then
      MsgManager.ShowMsgByID(8015)
      return
    end
  elseif 0 == PetAdventureProxy.Instance:GetMatchNum() then
    MsgManager.ShowMsgByID(8019)
    return
  end
  local matchPet = PetAdventureProxy.Instance:GetMatchPetData()
  local servicePets = {}
  for i = 1, #matchPet do
    if matchPet[i] and 0 ~= matchPet[i] and matchPet[i].guid then
      servicePets[i] = matchPet[i].guid
    else
      servicePets[i] = "0"
    end
  end
  local cellMonsterID = self:_getMonsterID()
  local useTicket = 1 ~= chooseData.staticData.QuestType and self.useTicketToggle.value
  if useTicket == true and 1 > self:GetAdvTicketNum() then
    useTicket = false
    local id = 39016
    local dont = LocalSaveProxy.Instance:GetDontShowAgain(id)
    if dont == nil then
      MsgManager.DontAgainConfirmMsgByID(id, function()
        ServiceScenePetProxy.Instance:CallStartAdventurePetCmd(self.chooseQuestID, servicePets, cellMonsterID, useTicket)
        UIMultiModelUtil.Instance:PlayEffect(startAdventureEff, RoleDefines_EP.Chest)
      end)
      return
    end
  end
  ServiceScenePetProxy.Instance:CallStartAdventurePetCmd(self.chooseQuestID, servicePets, cellMonsterID, useTicket)
  UIMultiModelUtil.Instance:PlayEffect(startAdventureEff, RoleDefines_EP.Chest)
end

function PetAdventureView:ClickGetRewardBtn()
  if self.chooseQuestID and 0 ~= self.chooseQuestID then
    ServiceScenePetProxy.Instance:CallGetAdventureRewardPetCmd(self.chooseQuestID)
  end
end

function PetAdventureView:_showVictoryEffect()
  self:PlayUIEffect(effectResID, self.effectPos, false, nil, self)
end

function PetAdventureView:_updateInfoByState()
  local petCount = PetAdventureProxy.Instance:GetMatchNum()
  local staticPetNum = self.ChooseQuestData.staticData.PetNum
  local bEmptyPets = 0 == petCount
  self.petChooseNum.text = string.format(ZhString.PetAdventure_MatchPetCount, petCount, staticPetNum)
  local chooseData = self.ChooseQuestData
  local staticdata = chooseData.staticData
  if chooseData.status ~= PetAdventureProxy.QuestPhase.MATCH then
    self.costPos:SetActive(false)
    self:Hide(self.emptyCost)
  elseif staticdata.Cost and staticdata.Cost.id then
    self.costPos:SetActive(true)
    local staticNum = staticdata.Cost.num
    if staticPetNum ~= #staticNum then
      helplog("Table_Pet_Adventure cost 配置错误,错误ID: ", staticdata.id)
      return
    end
    local costIconName = Table_Item[staticdata.Cost.id].Icon
    IconManager:SetItemIcon(costIconName, self.iconImg)
    self.iconImg:MakePixelPerfect()
    if bEmptyPets then
      self.costPos:SetActive(false)
      self:Show(self.emptyCost)
    else
      local ownCount = BagProxy.Instance:GetItemNumByStaticID(staticdata.Cost.id, PACKAGE_MATERIAL)
      local needCount = staticNum[petCount]
      if needCount then
        if ownCount >= needCount then
          self.costMoney.color = ColorUtil.NGUIWhite
        else
          self.costMoney.color = ColorUtil.Red
        end
        self.costMoney.text = needCount
      end
      self.costPos:SetActive(true)
      self:Hide(self.emptyCost)
    end
  else
    self.costPos:SetActive(false)
    self:Show(self.emptyCost)
  end
  local full = staticPetNum == petCount
  local bSpecialQuest = 1 == chooseData.staticData.QuestType
  local status = self.ChooseQuestData.status
  if status == PetAdventureProxy.QuestPhase.FINISHED then
    self:Hide(self.PetStatusTitle)
    self:Hide(self.recommendPetLab)
    self:Show(self.finishedImg)
  elseif status == PetAdventureProxy.QuestPhase.MATCH then
    if bSpecialQuest then
      self:Hide(self.recommendPetLab)
      self:Show(self.PetStatusTitle)
      local petNum = staticdata.PetNum
      self.PetStatusTitle.text = string.format(ZhString.PetAdventure_ThreePets, petNum)
    else
      self:Hide(self.PetStatusTitle)
      self:Show(self.recommendPetLab)
    end
    self:Hide(self.finishedImg)
  elseif status == PetAdventureProxy.QuestPhase.UNDERWAY then
    self:Show(self.PetStatusTitle)
    self:Hide(self.recommendPetLab)
    self:Hide(self.finishedImg)
  end
  if bEmptyPets then
    self:SetTextureGrey(self.goBtn)
    self.costLab.effectColor = ColorUtil.NGUIGray
    self.emptyCost.effectColor = ColorUtil.NGUIGray
  elseif not bSpecialQuest then
    self:SetTextureWhite(self.goBtn)
    self.costLab.effectColor = self.goBtnLabelEffectColor
    self.emptyCost.effectColor = self.goBtnLabelEffectColor
  elseif full then
    self:SetTextureWhite(self.goBtn)
    self.costLab.effectColor = self.goBtnLabelEffectColor
    self.emptyCost.effectColor = self.goBtnLabelEffectColor
  else
    self:SetTextureGrey(self.goBtn)
    self.costLab.effectColor = ColorUtil.NGUIGray
    self.emptyCost.effectColor = ColorUtil.NGUIGray
  end
  local condition = chooseData.staticData.Condition
  local icons = {}
  local recommendCond1 = self:FindComponent("recommendCond1", UISprite)
  local recommendCond2 = self:FindComponent("recommendCond2", UISprite)
  local recommendCond3 = self:FindComponent("recommendCond3", UISprite)
  icons = {
    recommendCond1,
    recommendCond2,
    recommendCond3
  }
  for i = 1, #icons do
    self:Hide(icons[i])
  end
  local useVaildTicket = self:UseTicketValid()
  local rareCount = 0
  for i = 1, #condition do
    local conditionData = Table_Pet_AdventureCond[condition[i]]
    if nil == conditionData then
      helplog("Table_Pet_AdventureCond 配置错误，错误ID：", tostring(condition[i]))
      return
    end
    local conType = conditionData.TypeID
    local param = conditionData.Param
    local staticIcon = conditionData.Icon
    self:Show(icons[i])
    local bOwn, ticketUnlockUsed = self:_bConditionLocked(conditionData, icons[i], useVaildTicket)
    if ticketUnlockUsed == true then
      useVaildTicket = false
    end
    if icons[i].transform.childCount == 1 then
      local spEffect = icons[i].transform:GetChild(0)
      spEffect.gameObject:SetActive(bOwn)
    end
    if bOwn then
      rareCount = rareCount + 1
    end
  end
  local rewardData = {}
  if chooseData.rareReward then
    for i = 1, #chooseData.rareReward do
      local rareRewardCell = chooseData.rareReward[i]
      if status == PetAdventureProxy.QuestPhase.MATCH then
        local n = rareRewardCell.num / 1000
        if n < 1 then
          helplog("稀有奖励数量发送错误")
        end
        if rareCount == 0 then
          rareRewardCell:SetCount(nil, 0)
          rareRewardCell:SetlockState(true)
        else
          rareRewardCell:SetCount(nil, math.floor(n) * rareCount)
          rareRewardCell:SetlockState(false)
        end
      else
        rareRewardCell:SetCount(nil, rareRewardCell.num)
      end
      rareRewardCell:SetRare(true)
      rewardData[#rewardData + 1] = rareRewardCell
    end
  end
  local normalReward = chooseData.rewardMap
  local needCountDown = status == PetAdventureProxy.QuestPhase.UNDERWAY
  if chooseData.multiMonsterReward then
    local curMonsterId = self:_getMonsterID()
    if curMonsterId then
      local curRewardInfo = normalReward[curMonsterId]
      if curRewardInfo then
        for i = 1, #curRewardInfo do
          local cell = curRewardInfo[i]
          local n = status == PetAdventureProxy.QuestPhase.MATCH and cell.num / 1000 or cell.num
          local count = n < 1 and 0 or math.floor(n)
          cell:SetCount(nil, count)
          cell:SetRare(false)
          rewardData[#rewardData + 1] = cell
        end
      end
    end
  else
    for i = 1, #normalReward do
      local dropItemData = normalReward[i]
      local n = status == PetAdventureProxy.QuestPhase.MATCH and dropItemData.num / 1000 or dropItemData.num
      local count = n < 1 and 0 or math.floor(n)
      dropItemData:SetCount(nil, count)
      dropItemData:SetRare(false)
      rewardData[#rewardData + 1] = dropItemData
    end
  end
  if not needCountDown then
    self:_updateDropItem(rewardData)
  end
end

function PetAdventureView:_bConditionLocked(condStaticData, IconSprite, ticketUnlock)
  local petData = PetAdventureProxy.Instance:GetMatchPetData()
  local conType = condStaticData.TypeID
  local param = condStaticData.Param
  local staticIcon = condStaticData.Icon
  if "PetID" == conType then
    IconManager:SetFaceIcon(staticIcon, IconSprite)
    self:SetTextureGrey(IconSprite.gameObject)
  elseif "Skill" == conType then
    IconManager:SetSkillIcon(staticIcon, IconSprite)
    self:SetTextureGrey(IconSprite.gameObject)
  else
    IconManager:SetUIIcon(staticIcon, IconSprite)
    self:SetTextureGrey(IconSprite.gameObject)
  end
  local conLock = {
    PetID = false,
    Skill = false,
    Friendly = false,
    Nature = false,
    Race = false
  }
  for i = 1, #petData do
    if petData[i] and 0 ~= petData[i] then
      local id = petData[i].petid
      if "PetID" == conType and not conLock.PetID then
        if id and id == param[1] then
          self:SetTextureWhite(IconSprite.gameObject)
          conLock.PetID = true
        else
          self:SetTextureGrey(IconSprite.gameObject)
        end
      elseif "Skill" == conType and not conLock.Skill then
        local bOwnSkill = petData[i]:bOwnSkill(param)
        if bOwnSkill then
          self:SetTextureWhite(IconSprite.gameObject)
          conLock.Skill = true
        else
          self:SetTextureGrey(IconSprite.gameObject)
        end
      elseif "Friendly" == conType and not conLock.Friendly then
        local f = petData[i].friendlv >= param[1]
        if f then
          self:SetTextureWhite(IconSprite.gameObject)
          conLock.Friendly = true
        else
          self:SetTextureGrey(IconSprite.gameObject)
        end
      elseif "Nature" == conType and not conLock.Nature then
        if id and Table_Monster[id].Nature and Table_Monster[id].Nature == param[1] then
          self:SetTextureWhite(IconSprite.gameObject)
          conLock.Nature = true
        else
          self:SetTextureGrey(IconSprite.gameObject)
        end
      elseif "Race" == conType and not conLock.Race then
        if id and Table_Monster[id].Race and Table_Monster[id].Race == param[1] then
          self:SetTextureWhite(IconSprite.gameObject)
          conLock.Race = true
        else
          self:SetTextureGrey(IconSprite.gameObject)
        end
      end
    end
  end
  for k, v in pairs(conLock) do
    if v then
      return true
    end
  end
  if ticketUnlock == true then
    self:SetTextureWhite(IconSprite.gameObject)
    return true, true
  else
    return false
  end
end

function PetAdventureView:ClickPetQuestCell(cellctl)
  local data = cellctl and cellctl.data
  if data then
    self:UpdatePetQuestInfo(data)
    local clickQuestId = data.id
    if self.chooseQuestID ~= clickQuestId then
      self.chooseQuestID = clickQuestId
      local questData = self.petQuestlist:GetCellCtls()
      for _, cell in pairs(questData) do
        cell:SetChoose(clickQuestId)
        cell:SetChooseSpecial()
      end
    end
  end
end

function PetAdventureView:onClickSpec(cellctl)
  self:ClickPetQuestCell(cellctl)
  if cellctl and cellctl.data.id then
    if cellctl.data.status ~= PetAdventureProxy.QuestPhase.MATCH then
      return
    end
    local mId = {0}
    local staticMonsterId = cellctl.data.staticData.MonsterReward
    for i = 1, #staticMonsterId do
      mId[#mId + 1] = staticMonsterId[i]
    end
    if not mId then
      return
    end
    if self.chooseSpecid ~= cellctl.data.id then
      self.chooseSpecid = cellctl.data.id
      self:ShowSpecialIDTip(mId, cellctl.monsterIcon, NGUIUtil.AnchorSide.Right, {40, 0})
    else
      TipManager.Instance:CloseTip()
      self.chooseSpecid = nil
    end
  end
end

function PetAdventureView:_refreshPetModel(petData)
  local staticPetNum = self.ChooseQuestData.staticData.PetNum
  PetAdventureProxy.Instance:SetPetsData(staticPetNum, petData)
  for i = 1, staticPetNum do
    self:ShowPetModel(i)
  end
end

function PetAdventureView:UpdatePetQuestInfo(data)
  PetAdventureProxy.Instance:SetChooseQuestData(data)
  self.ChooseQuestData = data
  local bSpecialQuest = data.staticData and 1 == data.staticData.QuestType
  local staticdata = data.staticData
  local staticPetNum = staticdata.PetNum
  local petChooseBtn1 = self:FindGO("ChooseBtn1")
  local petChooseBtn2 = self:FindGO("ChooseBtn2")
  local petChooseBtn3 = self:FindGO("ChooseBtn3")
  local ChooseBtn1 = self:FindGO("choosebg1")
  local ChooseBtn2 = self:FindGO("choosebg2")
  local ChooseBtn3 = self:FindGO("choosebg3")
  self.petChooseBg = {
    ChooseBtn1,
    ChooseBtn2,
    ChooseBtn3
  }
  self.petChooseBtn = {
    petChooseBtn1,
    petChooseBtn2,
    petChooseBtn3
  }
  if 1 == staticPetNum then
    self.petChooseBtn[1].transform.localPosition = chooseBtnPosition[1]
  elseif 2 == staticPetNum then
    self.petChooseBtn[1].transform.localPosition = chooseBtnPosition[2]
    self.petChooseBtn[2].transform.localPosition = chooseBtnPosition[3]
  elseif 3 == staticPetNum then
    self.petChooseBtn[1].transform.localPosition = chooseBtnPosition[4]
    self.petChooseBtn[2].transform.localPosition = chooseBtnPosition[1]
    self.petChooseBtn[3].transform.localPosition = chooseBtnPosition[5]
  end
  for i = 1, #self.petChooseBtn do
    self:Hide(self.petChooseBtn[i])
  end
  for i = 1, staticPetNum do
    self:Show(self.petChooseBtn[i])
  end
  for i = 1, #self.petChooseBtn do
    self:AddClickEvent(self.petChooseBtn[i], function(g)
      self:OnClickPetChoose(i)
    end)
  end
  self.petDesc.text = staticdata.Desc
  UIUtil.WrapLabel(self.petDesc)
  if staticdata.DailyAdventureCount and staticdata.DailyAdventureCount > 0 then
    self.dailyAdventureCountLab.gameObject:SetActive(true)
    local leftTime = PetAdventureProxy.Instance:GetLeftAdventureTime(staticdata.id)
    self.dailyAdventureCountLab.text = string.format(ZhString.PetAdventure_DailyAdventureCount, leftTime)
  else
    self.dailyAdventureCountLab.gameObject:SetActive(false)
  end
  self:_setAdventureName(data.specid)
  local fT = staticdata.CostFightTime or 0
  self.fTShowCache = fT
  self:_updateConsumeFightTimeLab()
  self.startTime = data.startTime
  self.ConsumeTime = staticdata.ConsumeTime
  local questType = staticdata.QuestType
  local status = data.status
  self:_ClearTickEff()
  if PetAdventureProxy.QuestPhase.UNDERWAY == status then
    self.reachedGap = 0
    self.bDirty = true
    self.timeTick = TimeTickManager.Me():CreateTick(0, 1000, self._refreshAdventureTime, self)
    if bSpecialQuest then
      self:_refreshSpecQuestReward()
    end
  else
    self:Hide(self.PetStatusTitle)
  end
  self.againGoBtn:SetActive(false)
  if status == PetAdventureProxy.QuestPhase.MATCH then
    self.rewardTitle.text = ZhString.PetAdventure_RewardPreview
    self:Hide(self.getRewardBtn)
    self:Show(self.goBtn)
    self.useTicketBar:SetActive(not bSpecialQuest)
    self.consumeHelpBtn:SetActive(0 ~= fT)
  elseif status == PetAdventureProxy.QuestPhase.FINISHED then
    self.rewardTitle.text = ZhString.PetAdventure_Reward
    self:Show(self.getRewardBtn)
    tempVector3[2] = -108
    if bSpecialQuest then
      tempVector3[1] = 70
    else
      tempVector3[1] = -95
      self.againGoBtn:SetActive(true)
    end
    self.getRewardBtn.transform.localPosition = tempVector3
    self:Hide(self.goBtn)
    self:Hide(self.useTicketBar)
    self:Hide(self.consumeHelpBtn)
  elseif status == PetAdventureProxy.QuestPhase.UNDERWAY then
    if 1 == questType then
      self.rewardTitle.text = ZhString.PetAdventure_GetRewardWhenFinshed
    else
      self.rewardTitle.text = ZhString.PetAdventure_Reward
    end
    self:Hide(self.getRewardBtn)
    self:Hide(self.goBtn)
    self:Hide(self.useTicketBar)
    self:Hide(self.consumeHelpBtn)
  end
  if self.useTicketBar.activeSelf then
    self.useTicketBar:SetActive(self:IsEnableTicket())
  end
  self.useTicketToggle.value = self:IsEnableTicket() and 0 < self:GetAdvTicketNum()
  local textureName = staticdata.TextureName
  UIMultiModelUtil.Instance:ChangeMat(textureName, self.petTexture)
  self:_refreshPetModel(data.petEggs)
  self:_updateInfoByState()
end

function PetAdventureView:UpdatePetQuestInfoOnUseTicketChange()
  self:_updateConsumeFightTimeLab()
  self:_updateInfoByState()
end

function PetAdventureView:_updateConsumeFightTimeLab()
  if self:UseTicketValid() then
    self.consumeFightTimeLab.text = ISNoviceServerType and ZhString.PetAdventure_NoConsumeFightTime_Novice or ZhString.PetAdventure_NoConsumeFightTime
  else
    local fT = self.fTShowCache or 0
    local str = ISNoviceServerType and ZhString.PetAdventure_ConsumeFightTime_Novice or ZhString.PetAdventure_ConsumeFightTime
    self.consumeFightTimeLab.text = string.format(str, math.ceil(fT / 60))
  end
end

function PetAdventureView:_setAdventureName(id)
  if nil == id or 0 == id then
    self.adventureNameLab.text = string.format(ZhString.PetAdventure_NewAdventureName, self.ChooseQuestData.staticData.NameZh, "-All")
  else
    local name = Table_Monster[id] and Table_Monster[id].NameZh
    self.adventureNameLab.text = string.format(ZhString.PetAdventure_NewAdventureName, self.ChooseQuestData.staticData.NameZh, name)
  end
end

function PetAdventureView:_updateDropItem(rewardData)
  local efficiency = 0
  local phase = self.ChooseQuestData.status
  local bSpecialQuest = 1 == self.ChooseQuestData.staticData.QuestType
  if self.ChooseQuestData.multiMonsterReward then
    efficiency = self:_refreshEfficiency()
  else
    self:Hide(self.curFightEfficiency)
  end
  for k, v in pairs(rewardData) do
    if self.ChooseQuestData.multiMonsterReward and not v.Rare then
      local n = math.floor(v.rewardCount * efficiency)
      local num = n < 1 and 0 or n
      v:SetCount(nil, num)
    end
  end
  if not bSpecialQuest then
    table.sort(rewardData, function(l, r)
      local lid = l.staticData.id
      local rid = r.staticData.id
      if l.Rare or r.Rare then
        return l.Rare and not r.Rare
      end
      if lid == Zeny or rid == Zeny then
        return lid == Zeny and rid ~= Zeny
      end
      if lid == jobBase or rid == jobBase then
        return lid == jobBase and rid ~= jobBase
      end
      if lid == base or rid == base then
        return lid == base and rid ~= base
      end
      if l.num == r.num then
        return lid > rid
      else
        return l.num > r.num
      end
    end)
  end
  if nil == self.drop then
    local dropScrollObj = self:FindGO("RewardItemScroll")
    self.dropScroll = dropScrollObj:GetComponent(UIScrollView)
    local dropGrid = self:FindGO("Grid", dropScrollObj):GetComponent(UIGrid)
    self.drop = UIGridListCtrl.new(dropGrid, PetDropItemCell, "PetDropItemCell")
    self.drop:AddEventListener(MouseEvent.MouseClick, self.ClickDropItem, self)
  end
  self.drop:ResetDatas(rewardData)
  self.dropScroll:ResetPosition()
end

function PetAdventureView:_refreshAdventureTime()
  if self.startTime + self.ConsumeTime <= ServerTime.CurServerTime() / 1000 then
    local v = PetAdventureProxy.Instance:HandleFinished()
    self:Hide(self.PetStatusTitle)
    self:InitQuestData()
    self:UpdatePetQuestInfo(v)
    self:_ClearTickEff()
    return
  end
  local deltaTime = math.abs(self.startTime + self.ConsumeTime - ServerTime.CurServerTime() / 1000)
  local hour = math.floor(deltaTime / 3600)
  local timeStr
  if hour == 0 then
    timeStr = "00"
  elseif hour < 10 then
    timeStr = "0" .. hour
  else
    timeStr = hour
  end
  timeStr = timeStr .. ":"
  local minute = math.floor((deltaTime - hour * 3600) / 60)
  if minute == 0 then
    timeStr = timeStr .. "00"
  elseif minute < 10 then
    timeStr = timeStr .. "0" .. minute
  else
    timeStr = timeStr .. minute
  end
  timeStr = timeStr .. ":"
  local second = math.floor(deltaTime - hour * 3600 - minute * 60)
  if second == 0 then
    timeStr = timeStr .. "00"
  elseif second < 10 then
    timeStr = timeStr .. "0" .. second
  else
    timeStr = timeStr .. second
  end
  self.PetStatusTitle.text = string.format(ZhString.PetAdventure_OnAdventureTime, timeStr)
  self:Show(self.PetStatusTitle)
  local chooseData = self.ChooseQuestData
  local reachedRewardData = {}
  if chooseData and chooseData.staticData.QuestType == 2 then
    local chooseData = self.ChooseQuestData
    local startTime = chooseData.startTime
    local consumeTime = chooseData.staticData.ConsumeTime
    local times = chooseData.staticData.Times
    local interval = PetAdventureView.calcInterval(consumeTime, times)
    local steps = consumeTime / interval
    local rewardCount = #chooseData.rewardMap
    interval = consumeTime / math.min(rewardCount, steps)
    local passedTime = ServerTime.CurServerTime() / 1000 - startTime
    if interval < passedTime then
      local reached = math.floor(passedTime / interval)
      if self.reachedGap ~= reached then
        self.reachedGap = reached
        self.bDirty = true
        for i = 1, self.reachedGap do
          if chooseData.rewardMap then
            local cell = chooseData.rewardMap[i]
            cell:SetRare(false)
            cell:SetCount(nil, cell.num)
            table.insert(reachedRewardData, cell)
          end
        end
      end
    end
    if self.bDirty then
      self:_updateDropItem(reachedRewardData)
      self.bDirty = false
    end
  end
end

function PetAdventureView:_refreshSpecQuestReward()
  local reachedRewardData = {}
  for i = 1, #self.ChooseQuestData.rewardMap do
    local cell = self.ChooseQuestData.rewardMap[i]
    cell:SetRare(false)
    cell:SetCount(nil, cell.num)
    table.insert(reachedRewardData, cell)
  end
  self:_updateDropItem(reachedRewardData)
end

function PetAdventureView.calcInterval(consumeTime, times)
  return consumeTime / times * 100
end

function PetAdventureView:ClickDropItem(cellctl)
  if cellctl and cellctl ~= self.chooseRewardItem then
    local data = cellctl.data
    local stick = cellctl.gameObject:GetComponentInChildren(UISprite)
    if data then
      local callback = function()
        self:CancelChooseReward()
      end
      local sdata = {
        itemdata = data,
        funcConfig = {},
        callback = callback,
        ignoreBounds = {
          cellctl.gameObject
        }
      }
      self:ShowItemTip(sdata, stick, NGUIUtil.AnchorSide.Left, {-200, 0})
    end
    self.chooseRewardItem = cellctl
  else
    self:CancelChooseReward()
  end
end

function PetAdventureView:CancelChooseReward()
  self.chooseRewardItem = nil
  self:ShowItemTip()
end

PetAdventureView.petModelTrans = {
  [1] = {
    position = LuaVector3(3.13, 3.4, 4.6),
    rotation = LuaVector3(-8.3, -24, 0),
    petEmojiRotation = LuaVector3(-3.28, 136, 3.18)
  },
  [2] = {
    position = LuaVector3(-1.9, 3.37, 2.89),
    rotation = LuaVector3(-3.8, -26, 0),
    petEmojiRotation = LuaVector3(0, -180, 0)
  },
  [3] = {
    position = LuaVector3(-6.75, 3.52, 2.19),
    rotation = LuaVector3(-4.7, -21, 0),
    petEmojiRotation = LuaVector3(2.91, 180, 7.06)
  },
  [4] = {
    position = LuaVector3(2.1, 2.67, 3.41),
    rotation = LuaVector3(-3.3, -26, 0),
    petEmojiRotation = LuaVector3(-1.76, 157, 2.58)
  },
  [5] = {
    position = LuaVector3(-4.22, 2.58, 1.56),
    rotation = LuaVector3(-7, -20, 0),
    petEmojiRotation = LuaVector3(0, -180, 0)
  }
}
local args = {}
local action = {}
local matchPetID = 0

function PetAdventureView:ShowPetModel(index)
  local matchPet = PetAdventureProxy.Instance:GetMatchPetData()
  if index > #matchPet or 0 == matchPet[index] then
    matchPetID = 0
  elseif matchPet[index].body and matchPet[index].body ~= 0 then
    matchPetID = matchPet[index].body
  else
    matchPetID = matchPet[index].petid
  end
  local chooseData = self.ChooseQuestData
  local petNum = chooseData.staticData.PetNum
  local status = chooseData and chooseData.status
  local parts = 0 ~= matchPetID and Asset_RoleUtility.CreateMonsterRoleParts(matchPetID) or nil
  local randomEmojiDuation = GameConfig.PetRandomEmoji[4]
  local pos, rotation, scale, emoji, emojiRotation
  local modelPosConfig = GameConfig.petModelTrans or PetAdventureView.petModelTrans
  if parts then
    if 3 == petNum then
      pos = modelPosConfig[index].position
      rotation = modelPosConfig[index].rotation
      emojiRotation = modelPosConfig[index].petEmojiRotation
    elseif 2 == petNum then
      pos = modelPosConfig[index + 3].position
      rotation = modelPosConfig[index + 3].rotation
      emojiRotation = modelPosConfig[index + 3].petEmojiRotation
    elseif 1 == petNum then
      pos = modelPosConfig[2].position
      rotation = modelPosConfig[2].rotation
      emojiRotation = modelPosConfig[2].petEmojiRotation
    end
    local staticSize = Table_Monster[matchPetID] and Table_Monster[matchPetID].LoadShowSize or 1
    scale = 3 * staticSize
    action.name = GameConfig.PetAdventureAction[status]
    action.loop = status ~= PetAdventureProxy.QuestPhase.MATCH
    emoji = GameConfig.PetRandomEmoji[status]
  end
  LuaQuaternion.Better_SetEulerAngles(tempRot1, rotation or tempPos)
  LuaQuaternion.Better_SetEulerAngles(tempRot2, emojiRotation or tempPos)
  TableUtility.TableClear(args)
  args[1] = parts
  args[2] = self.petTexture
  args[3] = pos
  args[4] = tempRot1
  args[5] = scale
  args[6] = action
  args[7] = emoji
  args[8] = tempRot2
  args[9] = randomEmojiDuation
  args[10] = true
  UIMultiModelUtil.Instance:SetModels(index, args)
  local bExist = UIMultiModelUtil.Instance:bPetModelExistByIndex(index)
  if status == PetAdventureProxy.QuestPhase.MATCH then
    for i = 1, petNum do
      self.petChooseBtn[i]:SetActive(true)
    end
    self.petChooseBg[index]:SetActive(not bExist)
  else
    for i = 1, #self.petChooseBtn do
      self.petChooseBtn[i]:SetActive(false)
    end
  end
end

function PetAdventureView:OnEnter()
  self.super.OnEnter(self)
  BattleTimeDataProxy.QueryBattleTimelenUserCmd()
  ServiceScenePetProxy.Instance:CallQueryPetAdventureListPetCmd()
  ServiceScenePetProxy.Instance:CallQueryBattlePetCmd()
end

function PetAdventureView:_ClearTickEff()
  if self.timeTick then
    self.timeTick = nil
    TimeTickManager.Me():ClearTick(self)
  end
  if self.rewardEff then
    self.rewardEff:Destroy()
    self.rewardEff = nil
  end
end

function PetAdventureView:OnExit()
  RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_PET_ADVENTURE)
  self:_ClearTickEff()
  TipManager.Instance:HidePetEffTip()
  UIMultiModelUtil.Instance:RemoveModels()
  UIMultiModelUtil.Instance:ResetModelCell()
  TableUtility.TableClear(args)
  self.super.OnExit(self)
end

function PetAdventureView:OnDestroy()
  self.areaFilter = nil
  self.petQuestlist:Destroy()
  self.petlist:Destroy()
  PetAdventureView.super.OnDestroy(self)
end

function PetAdventureView:IsEnableTicket()
  return GameConfig.Pet.pet_adventure_ticket_switch ~= 1
end
