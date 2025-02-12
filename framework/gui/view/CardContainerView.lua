autoImport("CardDecomposeNewPage")
autoImport("CardRandomMakeNewPage")
autoImport("BossCardComposeNewPage")
autoImport("CardMakeNewPage")
autoImport("MvpCardComposeNewPage")
autoImport("CardTabCell")
CardContainerView = class("CardContainerView", ContainerView)
CardContainerView.ViewType = UIViewType.NormalLayer
local SubViewEnum = {
  CARDMAKE = 1701,
  BOSSCARDCOMPOSE = 1703,
  MVPCARDCOMPOSE = 1704,
  CARDRANDOMMAKE = 1700,
  CARDDECOMPOSE = 1702
}

function CardContainerView:Init()
  self.npcId = self.viewdata.viewdata.npcdata.data.id
  self.npcFunction = self.viewdata.viewdata.npcdata.data.staticData.NpcFunction
  self.tabIndex = self.viewdata.viewdata.tabIndex
  self.subViews = {}
  self:FindObjs()
  self:AddViewEvts()
  ServiceItemProxy.Instance:CallQueryBossCardComposeRateCmd()
end

function CardContainerView:FindObjs()
  self.container = self:FindGO("Container")
  self.tabs = {}
  self.toggles = {}
  self.sps = {}
  local grid = self:FindComponent("Grid", UIGrid)
  self.tabList = UIGridListCtrl.new(grid, CardTabCell, "CardTabCell")
  self:AddButtonEvent("CloseButton", function()
    self:CloseSelf()
  end)
  self.skipBtn = self:FindComponent("skipBtn", UIMultiSprite)
  self.skipBtnIcon = self:FindComponent("Icon", UISprite, self.skipBtn.gameObject)
  self.skipTip = self:FindGO("tip", self.skipBtn.gameObject)
  self:AddClickEvent(self.skipBtn.gameObject, function()
    self:OnSkip()
  end)
end

function CardContainerView:AddViewEvts()
  self:AddListenEvt(MyselfEvent.MyDataChange, self.UpdateTotalCost)
  self:AddListenEvt(ItemEvent.ItemUpdate, self.HandleItemUpdate)
  self:AddListenEvt(ServiceEvent.ItemExchangeCardItemCmd, self.HandleExchangeCardItem)
  self:AddListenEvt(ServiceEvent.RecordTradeQueryItemPriceRecordTradeCmd, self.OnTradeReqPrice)
  self:AddListenEvt(ServiceEvent.ItemQueryBossCardComposeRateCmd, self.OnBossCardRateQuery)
end

function CardContainerView:TabChangeHandler(key)
  if self.curTab == key then
    return
  end
  self.curTab = key
  local cells = self.tabList:GetCells()
  if not self.subViews[key] then
    local id = cells[key].id
    if id == SubViewEnum.CARDMAKE then
      self.subViews[key] = self:AddSubView("CardMakeNewPage", CardMakeNewPage, id)
    elseif id == SubViewEnum.BOSSCARDCOMPOSE then
      self.subViews[key] = self:AddSubView("BossCardComposeNewPage", BossCardComposeNewPage, id)
    elseif id == SubViewEnum.CARDRANDOMMAKE then
      self.subViews[key] = self:AddSubView("CardRandomMakeNewPage", CardRandomMakeNewPage, id)
    elseif id == SubViewEnum.CARDDECOMPOSE then
      self.subViews[key] = self:AddSubView("CardDecomposeNewPage", CardDecomposeNewPage, id)
    elseif id == SubViewEnum.MVPCARDCOMPOSE then
      self.subViews[key] = self:AddSubView("MvpCardComposeNewPage", MvpCardComposeNewPage, id)
    end
  else
    self.subViews[key]:Show()
  end
  for k, subView in pairs(self.subViews) do
    if k ~= key then
      subView:Hide()
    end
  end
  cells[key].toggle.value = true
  local skipType = self.subViews[key].skipType
  local value = LocalSaveProxy.Instance:GetSkipAnimation(skipType)
  self:SetSkipBtnState(value)
end

function CardContainerView:OnSkip()
  local skipType = self.subViews[self.curTab].skipType
  local value = LocalSaveProxy.Instance:GetSkipAnimation(skipType)
  value = not value
  LocalSaveProxy.Instance:SetSkipAnimation(skipType, value)
  self:SetSkipBtnState(value)
end

function CardContainerView:OnEnter()
  CardContainerView.super.OnEnter(self)
  if self.npcFunction then
    local datas = ReusableTable.CreateArray()
    for i = 1, #self.npcFunction do
      local func = self.npcFunction[i]
      local id = func.type
      if 1 < id then
        datas[#datas + 1] = id
      end
    end
    self.tabList:ResetDatas(datas)
    ReusableTable.DestroyArray(datas)
  end
  local tab = self.tabIndex or SubViewEnum.CARDRANDOMMAKE
  local cells = self.tabList:GetCells()
  for i = 1, #cells do
    local cell = cells[i]
    self:AddTabChangeEvent(cell.gameObject, nil, i)
    if tab == cell.id then
      tab = i
    end
  end
  self:TabChangeHandler(tab)
end

function CardContainerView:SetSkipBtnState(state)
  self.skipBtn.CurrentState = state and 1 or 0
  local _, color = ColorUtil.TryParseHexString(state and "B8BDDC" or "3A4073")
  self.skipBtnIcon.color = color
  self.skipTip:SetActive(state)
end

function CardContainerView:UpdateTotalCost()
  local cells = self.tabList:GetCells()
  local id = cells[self.curTab].id
  if id == SubViewEnum.CARDDECOMPOSE then
    self.subViews[self.curTab]:UpdateTotalCost()
  end
end

function CardContainerView:HandleItemUpdate()
  for _, subView in pairs(self.subViews) do
    subView:HandleItemUpdate()
  end
end

function CardContainerView:HandleExchangeCardItem(note)
  local data = note.body
  if data ~= nil and data.charid == Game.Myself.data.id then
    local skipType = self.subViews[self.curTab].skipType
    local value = LocalSaveProxy.Instance:GetSkipAnimation(skipType)
    if not value then
      self:CloseSelf()
    end
  end
end

function CardContainerView:OnTradeReqPrice(note)
  local cells = self.tabList:GetCells()
  local id = cells[self.curTab].id
  if id == SubViewEnum.CARDDECOMPOSE or id == SubViewEnum.CARDRANDOMMAKE then
    self.subViews[self.curTab]:OnTradeReqPrice(note)
  end
end

function CardContainerView:OnBossCardRateQuery(note)
  local cells = self.tabList:GetCells()
  local id = cells[self.curTab].id
  if id == SubViewEnum.BOSSCARDCOMPOSE or id == SubViewEnum.MVPCARDCOMPOSE then
    self.subViews[self.curTab]:InitCardList()
  end
  for i = 1, #cells do
    cells[i]:CheckRateUp()
  end
end
