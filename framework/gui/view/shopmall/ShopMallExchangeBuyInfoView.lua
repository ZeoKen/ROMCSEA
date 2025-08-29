autoImport("ExchangeIntroduceData")
autoImport("ShopMallExchangeBuyCell")
autoImport("ExchangeBuyIntroduceCell")
ShopMallExchangeBuyInfoView = class("ShopMallExchangeBuyInfoView", ContainerView)
ShopMallExchangeBuyInfoView.ViewType = UIViewType.PopUpLayer

function ShopMallExchangeBuyInfoView:OnExit()
  self.cell:Exit()
  if self.introCell then
    self.introCell:OnDestroy()
  end
  self:ShowItemTip()
  ShopMallExchangeBuyInfoView.super.OnExit(self)
end

function ShopMallExchangeBuyInfoView:Init()
  self:FindObjs()
  self:InitShow()
  self:AddViewEvts()
end

function ShopMallExchangeBuyInfoView:FindObjs()
  self.title = self:FindGO("Title"):GetComponent(UILabel)
  self.name = self:FindGO("Name"):GetComponent(UILabel)
  self.buyScrollView = self:FindGO("ScrollView").transform
  self.helpButton = self:FindGO("HelpButton")
end

function ShopMallExchangeBuyInfoView:InitShow()
  if self.viewdata.viewdata and self.viewdata.viewdata.data then
    self.currentDetalData = self.viewdata.viewdata.data
    self.cell = nil
    local offsetTip
    if self.currentDetalData.itemid and ShopMallProxy.IsForceOverlap(self.currentDetalData.itemid) then
      self.forceOverlap = true
    end
    if self.currentDetalData.overlap or self.forceOverlap then
      if self.buyOverLapCell == nil then
        local go
        if self.currentDetalData.isBooth then
          go = self:LoadPreferb("cell/BoothBuyOLCell")
        else
          go = self:LoadPreferb("cell/BuyOverLapCell")
        end
        self.buyOverLapCell = ShopMallExchangeBuyCell.new(go)
      end
      self.cell = self.buyOverLapCell
      offsetTip = {510, -208}
    else
      if self.buyNotOverLapCell == nil then
        local go
        if self.currentDetalData.isBooth then
          go = self:LoadPreferb("cell/BoothBuyNOLCell")
        else
          go = self:LoadPreferb("cell/BuyNotOverLapCell")
        end
        self.buyNotOverLapCell = ShopMallExchangeBuyCell.new(go)
      end
      self.cell = self.buyNotOverLapCell
      offsetTip = {490, -155}
    end
    self.cell:SetData(self.currentDetalData)
    self.cell:AddEventListener(ShopMallEvent.ExchangeCloseBuyInfo, self.CloseSelf, self)
    local staticData = Table_Item[self.currentDetalData.itemid]
    self.name.text = staticData and staticData.NameZh or ""
    self.helpButton:SetActive(false)
    ServiceRecordTradeProxy.Instance:CallItemSellInfoRecordTradeCmd(Game.Myself.data.id, self.currentDetalData.itemid, nil, self.currentDetalData.publicityId, nil, nil, nil, nil, self.currentDetalData.orderId, self.currentDetalData.type)
  else
  end
end

function ShopMallExchangeBuyInfoView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.RecordTradeBuyItemRecordTradeCmd, self.RecvBuyItem)
  self:AddListenEvt(ServiceEvent.RecordTradeItemSellInfoRecordTradeCmd, self.RecvInfo)
  self:AddListenEvt(ServiceEvent.RecordTradeQueryHoldedItemCountTradeCmd, self.RecvTradeCount)
end

function ShopMallExchangeBuyInfoView:RecvBuyItem(note)
  self.cell:SetBuyBtn(false)
  local data = note.body
  if data.ret == ProtoCommon_pb.ETRADE_RET_CODE_SUCCESS then
    if self.cell.InProcess then
      self.cell:ContinueBuying()
    else
      self:sendNotification(ShopMallEvent.ExchangeUpdateBuyView)
      self:CloseSelf()
    end
  elseif self.cell.InProcess then
    self.cell.InProcess = false
    self:CloseSelf()
  end
end

function ShopMallExchangeBuyInfoView:RecvInfo(note)
  local data = note.body
  if data then
    local introData = ExchangeIntroduceData.new(data)
    introData.shopMallItemData = self.currentDetalData
    local go
    if data.statetype == ShopMallStateTypeEnum.InPublicity then
      self.helpButton:SetActive(true)
      go = self:LoadPreferb("cell/BuyPublicityCell", self.buyScrollView)
    else
      go = self:LoadPreferb("cell/BuyNormalCell", self.buyScrollView)
    end
    self.introCell = ExchangeBuyIntroduceCell.new(go)
    self.introCell:SetData(introData)
    self.cell:SetCountChangeCallback(function(canExpress, isQuotaEnough)
      self.introCell:UpdateSend(canExpress, isQuotaEnough)
    end)
    if ISNoviceServerType then
      QuickBuyProxy.Instance:CallHoldedItemCountTrade(self.currentDetalData.itemid)
    end
  end
end

function ShopMallExchangeBuyInfoView:RecvTradeCount(note)
  local data = note.body
  if data and self.introCell then
    self.introCell:UpdateTradeCount(self.currentDetalData.itemid)
  end
end
