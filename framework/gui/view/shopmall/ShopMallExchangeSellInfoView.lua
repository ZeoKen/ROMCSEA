autoImport("ExchangeIntroduceData")
autoImport("ShopMallExchangeSellInfoCell")
autoImport("ExchangeSellIntroduceCell")
ShopMallExchangeSellInfoView = class("ShopMallExchangeSellInfoView", ContainerView)
ShopMallExchangeSellInfoView.ViewType = UIViewType.PopUpLayer

function ShopMallExchangeSellInfoView:OnExit()
  if self.sellCell then
    self.sellCell:Exit()
  end
  if self.introCell then
    self.introCell:OnDestroy()
  end
  ShopMallExchangeSellInfoView.super.OnExit(self)
end

function ShopMallExchangeSellInfoView:Init()
  self:FindObjs()
  self:AddEvts()
  self:AddViewEvts()
  self:InitShow()
end

function ShopMallExchangeSellInfoView:FindObjs()
  self.title = self:FindGO("Title"):GetComponent(UILabel)
  self.name = self:FindGO("Name"):GetComponent(UILabel)
  self.sellingScrollView = self:FindGO("ScrollView").transform
  self.helpButton = self:FindGO("HelpButton")
end

function ShopMallExchangeSellInfoView:AddEvts()
end

function ShopMallExchangeSellInfoView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.RecordTradeReqServerPriceRecordTradeCmd, self.RecvItemPrice)
  self:AddListenEvt(ServiceEvent.RecordTradeSellItemRecordTradeCmd, self.RecvSellItem)
  self:AddListenEvt(ServiceEvent.RecordTradeCancelItemRecordTrade, self.RecvCancel)
  self:AddListenEvt(ServiceEvent.RecordTradeQuerySelledItemCountTradeCmd, self.RecvTradeCount)
end

function ShopMallExchangeSellInfoView:InitShow()
  if self.viewdata.viewdata and self.viewdata.viewdata.data and self.viewdata.viewdata.type then
    self.itemData = self.viewdata.viewdata.data
    self.type = self.viewdata.viewdata.type
    local cell = self.viewdata.viewdata.cell
    local go
    if self.type == ShopMallExchangeSellEnum.Sell then
      local data = Table_Exchange[self.itemData.staticData.id]
      if data and data.Overlap == 1 then
        go = self:LoadPreferb("cell/SellOverLapCell")
      else
        go = self:LoadPreferb("cell/SellNotOverLapCell")
      end
    elseif self.type == ShopMallExchangeSellEnum.Resell then
      go = self:LoadPreferb("cell/ExchangeResellCell")
    elseif self.type == ShopMallExchangeSellEnum.Cancel then
      local data = Table_Exchange[self.itemData.staticData.id]
      if data and data.Overlap == 1 then
        go = self:LoadPreferb("cell/CancelSellOverLapCell")
      else
        go = self:LoadPreferb("cell/CancelSellNotOverLapCell")
      end
    end
    FunctionItemTrade.Me():GetTradePrice(self.itemData, true, true)
    self.sellCell = ShopMallExchangeSellInfoCell.new(go)
    self.itemData.sellType = self.type
    if cell then
      self.itemData.shopMallItemData = cell.data
    end
    self.sellCell:SetData(self.itemData)
    self.sellCell:AddEventListener(ShopMallEvent.ExchangeCloseSellInfo, self.CloseSelf, self)
    self.name.text = self.itemData.staticData.NameZh
    self.helpButton:SetActive(false)
  else
  end
end

function ShopMallExchangeSellInfoView:RecvItemPrice(note)
  local data = note.body
  if data then
    if data.itemData and data.itemData.base and self.itemData.staticData.id ~= data.itemData.base.id then
      return
    end
    local introData = ExchangeIntroduceData.new(data)
    self.sellCell:SetPrice(data.price)
    self.sellCell:SetPublicity(data.statetype)
    local go
    if data.statetype == ShopMallStateTypeEnum.WillPublicity or data.statetype == ShopMallStateTypeEnum.InPublicity then
      self.title.text = ZhString.ShopMall_ExchangePublicityTitle
      self.helpButton:SetActive(true)
      if data.statetype == ShopMallStateTypeEnum.WillPublicity then
        go = self:LoadPreferb("cell/SellFirstPublicityCell", self.sellingScrollView)
      else
        go = self:LoadPreferb("cell/SellPublicityCell", self.sellingScrollView)
      end
    else
      self.title.text = ZhString.ShopMall_ExchangeNormalTitle
      local staticData = Table_Exchange[self.itemData.staticData.id]
      if self.itemData.enchantInfo and #self.itemData.enchantInfo:GetEnchantAttrs() > 0 then
        go = self:LoadPreferb("cell/SellNormalEnchantCell", self.sellingScrollView)
      elseif staticData and staticData.Overlap == 1 then
        go = self:LoadPreferb("cell/SellNormalOverLapCell", self.sellingScrollView)
      else
        go = self:LoadPreferb("cell/SellNormalNotOverLapCell", self.sellingScrollView)
      end
    end
    self.introCell = ExchangeSellIntroduceCell.new(go)
    self.introCell:SetData(introData)
    if ISNoviceServerType then
      QuickBuyProxy.Instance:CallQuerySelledItemCountTradeCmd(self.itemData.staticData.id)
    end
  end
end

function ShopMallExchangeSellInfoView:RecvSellItem(note)
  local data = note.body
  if data.type == BoothProxy.TradeType.Exchange and data.ret == ProtoCommon_pb.ETRADE_RET_CODE_SUCCESS then
    self:CloseSelf()
    ServiceRecordTradeProxy.Instance:CallMyPendingListRecordTradeCmd(nil, Game.Myself.data.id)
  end
end

function ShopMallExchangeSellInfoView:RecvCancel(note)
  local data = note.body
  if data.type == BoothProxy.TradeType.Exchange and data.ret == ProtoCommon_pb.ETRADE_RET_CODE_SUCCESS then
    ServiceRecordTradeProxy.Instance:CallMyPendingListRecordTradeCmd(nil, Game.Myself.data.id)
    self:CloseSelf()
  end
end

function ShopMallExchangeSellInfoView:RecvTradeCount(note)
  local data = note.body
  if data and self.introCell then
    self.introCell:UpdateTradeCount(self.itemData.staticData.id, self.sellCell and self.sellCell:GetOrderID())
  end
end
