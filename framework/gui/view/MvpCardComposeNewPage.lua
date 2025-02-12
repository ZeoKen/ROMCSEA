autoImport("BossComposeCardCell")
autoImport("BossCardComposeMaterialCell")
autoImport("CardMakeRateUpCell")
MvpCardComposeNewPage = class("MvpCardComposeNewPage", BossCardComposeNewPage)
local skipType = SKIPTYPE.MvpCardCompose
local Prefab_Path = ResourcePathHelper.UIView("MvpCardComposeNewPage")
local CardPartDefaultPosY = 250
local CardPartPosOffsetY = 14

function MvpCardComposeNewPage:Init(initParam)
  MvpCardComposeNewPage.super.Init(self, initParam)
  self.skipType = skipType
end

function MvpCardComposeNewPage:LoadPrefab()
  local obj = self:LoadPreferb_ByFullPath(Prefab_Path, self.container.container, true)
  obj.name = "MvpCardComposeNewPage"
  self.gameObject = obj
end

function MvpCardComposeNewPage:FindObjs()
  MvpCardComposeNewPage.super.FindObjs(self)
  self.rateUpCardsGo = self:FindGO("RateUpGrid")
  self.rateUpGrid = self.rateUpCardsGo:GetComponent(UIGrid)
  self.rateUpListCtrl = UIGridListCtrl.new(self.rateUpGrid, CardMakeRateUpCell, "CardMakeRateUpCell")
  self.rateUpListCtrl:AddEventListener(MouseEvent.LongPress, self.OnSelectLongPress, self)
  self.cardContainerBg = self:FindGO("CardContainerBg")
  self.cardContainerBg2 = self:FindGO("CardContainerBg2")
  self.upTipLabel = self:FindComponent("UpTip", UILabel)
  self.cardPartGo = self:FindGO("CardPart")
end

function MvpCardComposeNewPage:InitCardList()
  self:UpdateRateUpCardList()
  MvpCardComposeNewPage.super.InitCardList(self)
end

function MvpCardComposeNewPage:InitMaterial()
  local beCostItem = GameConfig.Card.MvpCardComposeMaterial
  if beCostItem then
    self.materialItems = {}
    for i = 1, #beCostItem do
      local costItem = beCostItem[i]
      local data = CardMakeMaterialData.new({
        id = costItem[1],
        num = costItem[2]
      }, i)
      TableUtility.ArrayPushBack(self.materialItems, data)
    end
  end
  self:UpdateMaterial()
end

function MvpCardComposeNewPage:UpdateCardList()
  local items = CardMakeProxy.Instance:FilterMvpComposeCardByTypes(self.filterTipData.curCustomProps)
  local data = AdventureDataProxy.Instance:getItemsByFilterData(nil, items, self.filterTipData.curPropData, self.filterTipData.curKeys)
  if data and 0 < #data then
    self.cardListCtl:ResetDatas(data)
  end
end

function MvpCardComposeNewPage:CallExchangeCardItem()
  local skipValue = CardMakeProxy.Instance:IsSkipGetEffect(skipType)
  ServiceItemProxy.Instance:CallExchangeCardItemCmd(CardMakeProxy.MakeType.MvpCardCompose, self.npcId, nil, nil, nil, not skipValue, nil, self.composeNum)
end

function MvpCardComposeNewPage:UpdateComposeNum()
  local count
  if self.materialItems then
    for i = 1, #self.materialItems do
      local material = self.materialItems[i]
      local ownNum = CardMakeProxy.Instance:GetItemNumByStaticID(material.id)
      local curCount = math.floor(ownNum / material.costNum)
      count = count or curCount
      count = math.min(curCount, count)
    end
  end
  self.composeNum = math.min(count, self.composeNum)
  self.composeNum = math.max(1, self.composeNum)
  self.composeNumLabel.text = self.composeNum
end

function MvpCardComposeNewPage:UpdateRateUpCardList()
  local rateUpCards = CardMakeProxy.Instance:GetRateUpCardList(CardMakeProxy.MakeType.MvpCardCompose)
  if rateUpCards then
    self.rateUpListCtrl:ResetDatas(rateUpCards)
  end
  local upCount = #rateUpCards
  self.rateUpCardsGo:SetActive(0 < upCount)
  self.cardContainerBg:SetActive(0 < upCount)
  self.cardContainerBg2:SetActive(0 < upCount)
  self.upTipLabel.gameObject:SetActive(0 < upCount)
  local myUpTimes = MyselfProxy.Instance:GetAccVarValueByType(Var_pb.EACCVARTYPE_BOSSCARD_MVPCOMPOSE_UPTIMES) or 0
  local safety_count = GameConfig.Card and GameConfig.Card.safety_count and GameConfig.Card.safety_count or 1
  local leftCount = safety_count - myUpTimes
  if leftCount <= 1 then
    self.upTipLabel.text = ZhString.CardMake_RateUpTipThisTime
  else
    self.upTipLabel.text = string.format(ZhString.CardMake_RateUpTip, leftCount)
  end
  if 0 < upCount then
    local posY = CardPartDefaultPosY - self.rateUpGrid.cellHeight * upCount - CardPartPosOffsetY
    LuaGameObject.SetLocalPositionGO(self.cardPartGo, 0, posY, 0)
  else
    LuaGameObject.SetLocalPositionGO(self.cardPartGo, 0, CardPartDefaultPosY, 0)
  end
  local cellChildInterval = 0 < upCount and 108 or 95
  self.cardListCtl.cellChildInterval = cellChildInterval
end
