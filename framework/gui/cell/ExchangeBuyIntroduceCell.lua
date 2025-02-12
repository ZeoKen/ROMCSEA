autoImport("ExchangeBuyNormalInfoCell")
local baseCell = autoImport("BaseCell")
ExchangeBuyIntroduceCell = class("ExchangeBuyIntroduceCell", baseCell)

function ExchangeBuyIntroduceCell:Init()
  self:FindObjs()
  self:InitShow()
end

function ExchangeBuyIntroduceCell:FindObjs()
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
  self.table = self:FindGO("Table")
  if self.table then
    self.table = self.table:GetComponent(UITable)
  end
  self.sendRoot = self:FindGO("SendRoot")
  self.send = self:FindGO("Send", self.sendRoot):GetComponent(UILabel)
  self.sendHelp = self:FindGO("SendHelp", self.sendRoot):GetComponent(UISprite)
  self.sendLine = self:FindGO("Line", self.sendRoot)
  self.boothFromRoot = self:FindGO("RootBoothFrom")
  self.boothFrom = self:FindGO("BoothFrom"):GetComponent(UILabel)
  self.tradeCount = self:FindGO("TradeCount"):GetComponent(UILabel)
end

function ExchangeBuyIntroduceCell:InitShow()
  local grid = self:FindGO("Grid")
  if grid then
    grid = grid:GetComponent(UIGrid)
    self.briefCtl = UIGridListCtrl.new(grid, ExchangeBuyNormalInfoCell, "BuyNormalInfoCell")
  end
  self:RegistShowGeneralHelpByHelpID(10001, self.sendHelp.gameObject)
end

function ExchangeBuyIntroduceCell:SetData(data)
  self.data = data
  self.tradeCount.text = ""
  if data then
    local shopMallItemData = data.shopMallItemData
    local staticData = Table_Item[shopMallItemData.itemid]
    if shopMallItemData.isBooth then
      self.boothFromRoot:SetActive(true)
      self.boothFrom.text = string.format(ZhString.Booth_IntroduceFrom, shopMallItemData.name)
    else
      self.boothFromRoot:SetActive(false)
    end
    if data.type == ShopMallStateTypeEnum.InPublicity then
      if self.timeTick == nil then
        self.timeTick = TimeTickManager.Me():CreateTick(0, 1000, self.UpdateCountDown, self)
      end
      self:UpdateCount()
      self.buyerCount.text = string.format(ZhString.ShopMall_IntroduceBuyerCount, data.buyerCount)
      if shopMallItemData.isBooth then
        local sb = LuaStringBuilder.CreateAsTable()
        sb:AppendLine(string.format(ZhString.Booth_IntroducePublicity, staticData.NameZh or ""))
        sb:AppendLine(ZhString.Booth_IntroducePublicityTip)
        sb:AppendLine(ZhString.Booth_IntroduceSendTip)
        sb:Append(string.format(ZhString.Booth_IntroduceBuyTip, 1 / GameConfig.Booth.quota_zeny_discount * 100))
        self.info.text = sb:ToString()
        sb:Destroy()
      else
        self.info.text = string.format(GameConfig.Exchange.SellShow4, staticData.NameZh or "")
      end
    else
      local config = Table_Exchange[staticData.id]
      if config and config.Overlap == 1 then
        self.count.gameObject:SetActive(true)
        self.sendLine:SetActive(true)
        self:UpdateCount()
      else
        self.count.gameObject:SetActive(false)
        self.sendLine:SetActive(false)
      end
      if data.buyInfo then
        self.briefCtl:ResetDatas(data.buyInfo)
      end
      self.table:Reposition()
    end
    self.sendRoot:SetActive(false)
  end
end

function ExchangeBuyIntroduceCell:UpdateCountDown()
  if self.data then
    local time = self.data.shopMallItemData.endTime - ServerTime.CurServerTime() / 1000
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

function ExchangeBuyIntroduceCell:UpdateSend(canExpress, isQuotaEnough)
  if self.data.shopMallItemData.isBooth then
    return
  end
  self.sendRoot:SetActive(canExpress)
  if isQuotaEnough then
    self.send.text = ZhString.ShopMall_ExchangeExpressCan
  else
    self.send.text = ZhString.ShopMall_ExchangeExpressCannot
  end
  self.sendHelp:UpdateAnchors()
  self.table:Reposition()
  if GameConfig.Exchange.SendLimitLv and Game.Myself.data.userdata:Get(UDEnum.ROLELEVEL) < GameConfig.Exchange.SendLimitLv then
    self:FindGO("Send", self.sendRoot):SetActive(false)
    self:FindGO("SendHelp", self.sendRoot):SetActive(false)
  end
end

function ExchangeBuyIntroduceCell:UpdateCount()
  local data = self.data
  if data then
    if data.shopMallItemData.isBooth then
      self.count.text = string.format(ZhString.Booth_IntroduceCount, data.count)
    else
      self.count.text = string.format(ZhString.ShopMall_IntroduceCount, data.count)
    end
  end
end

function ExchangeBuyIntroduceCell:OnDestroy()
  TimeTickManager.Me():ClearTick(self)
end

function ExchangeBuyIntroduceCell:UpdateTradeCount(itemID)
  if not itemID then
    return
  end
  local left, holding, limit = QuickBuyProxy.Instance:GetTradeCount(itemID)
  if limit and 0 < limit then
    self.tradeCount.text = string.format(GameConfig.Exchange.ShopMallPreorder_TradeCount, left, holding, math.max(0, limit - left - holding))
  end
end
