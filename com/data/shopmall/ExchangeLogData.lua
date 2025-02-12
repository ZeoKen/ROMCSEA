autoImport("ExchangeLogNameData")
ExchangeLogData = class("ExchangeLogData")
ExchangeLogData.ReceiveEnum = {
  Money = 0,
  Goods = 1,
  All = 2
}

function ExchangeLogData:ctor(data)
  self:SetData(data)
end

function ExchangeLogData:SetData(data)
  self.id = data.id
  self.status = data.status
  self.type = data.logtype
  self.itemid = data.itemid
  self.refineLv = data.refine_lv
  self.damage = data.damage
  self.tradetime = data.tradetime
  self.count = data.count
  self.price = data.price
  self.tax = data.tax
  self.getmoney = data.getmoney
  self.costmoney = data.costmoney
  self.failcount = data.failcount
  self.retmoney = data.retmoney
  self.totalcount = data.totalcount
  self.endtime = data.endtime
  if data.name_info then
    data.name_info.name = AppendSpace2Str(data.name_info.name)
    self.nameInfo = ExchangeLogNameData.new(data.name_info)
  end
  self.isManyPeople = data.is_many_people
  self.receiverid = data.receiverid
  self.receivername = data.receivername
  self.receivername = AppendSpace2Str(self.receivername)
  self.receiverzoneid = data.receiverzoneid
  self.quota = data.quota
  self.background = data.background
  self.cangive = data.cangive
  if data.itemdata and data.itemdata.base and data.itemdata.base.id ~= 0 then
    self.itemData = ItemData.new(data.itemdata.base.guid, data.itemdata.base.id)
    self.itemData:ParseFromServerData(data.itemdata)
  else
    self.itemData = ItemData.new("ExchangeLog", self.itemid)
  end
  self.itemData.num = data.count
  if self.type == ShopMallLogTypeEnum.NormalSell or self.type == ShopMallLogTypeEnum.PublicitySellSuccess then
    self.receiveEnum = self.ReceiveEnum.Money
  elseif self.type == ShopMallLogTypeEnum.NormalBuy then
    self.receiveEnum = self.ReceiveEnum.Goods
  elseif self.type == ShopMallLogTypeEnum.PublicityBuySuccess then
    self.receiveEnum = self.ReceiveEnum.Goods
  elseif self.type == ShopMallLogTypeEnum.PublicityBuyFail then
    self.receiveEnum = self.ReceiveEnum.Money
  elseif self.type == ShopMallLogTypeEnum.AutoOff then
    self.receiveEnum = self.ReceiveEnum.All
  end
  self.tradeType = data.trade_type
  self.quotaCost = data.quota_cost
  self.preorderid = data.preorderid
  self.preorderstatus = data.preorderstatus
end

function ExchangeLogData:SetStatus(status)
  self.status = status
end

function ExchangeLogData:GetRefineLvString()
  if self.refineLv and self.refineLv > 0 then
    return "+" .. self.refineLv
  end
  return ""
end

function ExchangeLogData:GetCount()
  return self.count or 0
end

function ExchangeLogData:GetTax()
  return self.tax or 0
end

function ExchangeLogData:GetGetmoney()
  return self.getmoney or 0
end

function ExchangeLogData:GetCostmoney()
  return self.costmoney or 0
end

function ExchangeLogData:GetFailcount()
  return self.failcount or 0
end

function ExchangeLogData:GetRetmoney()
  return self.retmoney or 0
end

function ExchangeLogData:GetTotalcount()
  return self.totalcount or 0
end

function ExchangeLogData:CanReceive()
  return self.type ~= ShopMallLogTypeEnum.PublicityBuying and self.status == ShopMallLogReceiveEnum.ReceiveGive
end

function ExchangeLogData:GetExchangeFirstNameData()
  return self.nameInfo
end

function ExchangeLogData:IsManyPeople()
  return self.isManyPeople or false
end

function ExchangeLogData:GetReceiverName()
  return self.receivername or ""
end

function ExchangeLogData:GetReceiverZoneid()
  if self.receiverzoneid then
    local zoneid = self.receiverzoneid % 10000
    return ChangeZoneProxy.Instance:ZoneNumToString(zoneid)
  end
  return 0
end

function ExchangeLogData:GetBg()
  return self.background or 0
end

function ExchangeLogData:GetItemData()
  return self.itemData
end

function ExchangeLogData:GetTotalQuota()
  return self.quotaCost
end
