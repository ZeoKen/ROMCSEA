local baseCell = autoImport("BaseCell")
ExchangeSellIntroduceCell = class("ExchangeSellIntroduceCell", baseCell)

function ExchangeSellIntroduceCell:Init()
  self:FindObjs()
  self:InitShow()
end

function ExchangeSellIntroduceCell:FindObjs()
  self.countDown = self:FindGO("CountDown")
  if self.countDown then
    self.countDown = self.countDown:GetComponent(UILabel)
  end
  self.count = self:FindGO("Count")
  if self.count then
    self.count = self.count:GetComponent(UILabel)
  end
  self.buyerCount = self:FindGO("BuyerCount")
  if self.buyerCount then
    self.buyerCount = self.buyerCount:GetComponent(UILabel)
  end
  self.info = self:FindGO("Info")
  if self.info then
    self.info = self.info:GetComponent(UILabel)
  end
  self.info2 = self:FindGO("Info2")
  if self.info2 then
    self.info2 = self.info2:GetComponent(UILabel)
  end
  self.info3 = self:FindGO("Info3")
  if self.info3 then
    self.info3 = self.info3:GetComponent(UILabel)
  end
  self.table = self:FindGO("Table")
  if self.table then
    self.table = self.table:GetComponent(UITable)
  end
  self.rate = self:FindGO("Rate")
  if self.rate then
    self.rate = self.rate:GetComponent(UILabel)
  end
  self.tip = self:FindGO("Tip")
  self.tradeCount = self:FindGO("TradeCount"):GetComponent(UILabel)
end

function ExchangeSellIntroduceCell:InitShow()
end

function ExchangeSellIntroduceCell:SetData(data)
  self.data = data
  self.tradeCount.text = ""
  if data then
    local type = data.type
    local itemData = data.itemData
    local staticData = itemData.staticData
    local isShowEnchant = self:IsShowEnchant(itemData)
    if self.rate then
      self.rate.text = string.format(ZhString.ShopMall_ExchangeRateTitle, CommonFun.calcTradeTax(data.price))
    end
    if type == ShopMallStateTypeEnum.WillPublicity then
      local showTime = Table_Exchange[staticData.id] and Table_Exchange[staticData.id].ShowTime or 0
      if self.info then
        self.info.text = string.format(GameConfig.Exchange.SellShow1, staticData.NameZh)
      end
      if self.info2 then
        self.info2.text = string.format(GameConfig.Exchange.SellShow3, staticData.NameZh, math.ceil(showTime / 60))
      end
      if self.info3 then
        self.info3.gameObject:SetActive(isShowEnchant)
        if isShowEnchant then
          self:SetEnchantLabel(itemData, self.info3)
        end
      end
      if self.tip then
        self.tip:SetActive(isShowEnchant)
      end
      if self.table then
        self.table:Reposition()
      end
    elseif type == ShopMallStateTypeEnum.InPublicity then
      if self.timeTick == nil then
        self.timeTick = TimeTickManager.Me():CreateTick(0, 1000, self.UpdateCountDown, self)
      end
      if self.count then
        self.count.text = string.format(ZhString.ShopMall_IntroduceCount, data.count)
      end
      if self.buyerCount then
        self.buyerCount.text = string.format(ZhString.ShopMall_IntroduceBuyerCount, data.buyerCount)
      end
      if self.info then
        self.info.text = string.format(GameConfig.Exchange.SellShow4, staticData.NameZh)
      end
      if self.info2 then
        self.info2.gameObject:SetActive(isShowEnchant)
        if isShowEnchant then
          self:SetEnchantLabel(itemData, self.info2)
        end
      end
      if self.tip then
        self.tip:SetActive(isShowEnchant)
      end
      if self.table then
        self.table:Reposition()
      end
    else
      if self.count then
        self.count.text = data.count
      end
      if self.info and isShowEnchant then
        self:SetEnchantLabel(itemData, self.info)
      end
    end
  end
end

function ExchangeSellIntroduceCell:UpdateCountDown()
  if self.data then
    local time = self.data.endTime - ServerTime.CurServerTime() / 1000
    local min, sec
    if 0 < time then
      min, sec = ClientTimeUtil.GetFormatSecTimeStr(time)
    else
      min = 0
      sec = 0
    end
    self.countDown.text = string.format(ZhString.ShopMall_ExchangePublicityCountDown, min, sec)
  end
end

function ExchangeSellIntroduceCell:OnDestroy()
  TimeTickManager.Me():ClearTick(self)
end

function ExchangeSellIntroduceCell:IsShowEnchant(itemData)
  return itemData and itemData.enchantInfo and #itemData.enchantInfo:GetEnchantAttrs() > 0 or false
end

function ExchangeSellIntroduceCell:SetEnchantLabel(itemData, uiLabel)
  if itemData.enchantInfo:IsShowWhenTrade() then
    uiLabel.text = ZhString.ShopMall_ExchangeEnchant
  else
    uiLabel.text = ZhString.ShopMall_ExchangeHideEnchant
  end
end

function ExchangeSellIntroduceCell:UpdateTradeCount(itemID, orderID)
  if not itemID then
    return
  end
  local left, limit = QuickBuyProxy.Instance:GetSellTradeCount(itemID)
  local time = ShopMallProxy.Instance:GetOrderAddTime(orderID)
  local timeStr, timeStrTemp, tipStr = "", "", ""
  if time then
    timeStrTemp = os.date("%Y-%m-%d", time)
    timeStr = string.format(GameConfig.Exchange.ShopMallPreorder_SaleTime, timeStrTemp)
  end
  if limit and 0 < limit then
    tipStr = string.format(GameConfig.Exchange.ShopMallPreorder_SellCount, left, math.max(0, limit - left))
  end
  self.tradeCount.text = string.format(ZhString.ShopMallPreorder_TradeTip, tipStr, timeStr)
end
