autoImport("PurchaseDeltaTimeLimit")
autoImport("FuncPurchase")
UVC_AppStorePurchase = class("UVC_AppStorePurchase", BaseView)
UVC_AppStorePurchase.ViewType = UIViewType.PopUpLayer

function UVC_AppStorePurchase:Init()
  self.productID = self.viewdata.viewdata
  if not self.init then
    self:GetGameObjects()
    self:GetModelSet()
    self:LoadView()
    self:RegisterButtonClickEvent()
    self:ListenServerResponse()
    self.init = true
  else
    self:ReInit()
  end
end

function UVC_AppStorePurchase:OnExit()
  self:CancelListenServerResponse()
end

function UVC_AppStorePurchase:ReInit()
  self:GetModelSet()
  self:LoadView()
end

function UVC_AppStorePurchase:GetGameObjects()
  self.spItemIcon = self:FindGO("Icon"):GetComponent(UISprite)
  self.goBTNPurchaseLuckyBag = self:FindGO("BTN_Purchase")
  self.bcBTNPurchaseLuckyBag = self.goBTNPurchaseLuckyBag:GetComponent(BoxCollider)
  self.labTitleBTNPurchaseLuckyBag = self:FindGO("Title", self.goBTNPurchaseLuckyBag):GetComponent(UILabel)
  self.spNormalBTNPurchaseLuckyBag = self:FindGO("Normal", self.goBTNPurchaseLuckyBag):GetComponent(UISprite)
  self.goProductName = self:FindGO("Name", self.gameObject)
  self.labProductName = self:FindGO("Lab", self.goProductName):GetComponent(UILabel)
  self.goBTNClose = self:FindGO("BTN_Close")
end

function UVC_AppStorePurchase:GetModelSet()
  for k, v in pairs(Table_Deposit) do
    if v.ProductID == self.productID then
      self.productConf = v
      break
    end
  end
  if self.productConf.ActivityDiscount == 1 then
    local discountActivity = NewRechargeProxy.Ins:Deposit_GetProductActivity_Discount(self.productConf.id)
    local isDiscount = false
    if discountActivity ~= nil then
      local dActivityEndTime = discountActivity[5]
      local serverTime = ServerTime.CurServerTime() / 1000
      if dActivityEndTime > serverTime then
        local activityTimes = discountActivity[1]
        local activityUsedTimes = discountActivity[3]
        if activityTimes > activityUsedTimes then
          isDiscount = true
        end
      end
    end
    if not isDiscount then
      self.productConf = Table_Deposit[self:GetOriginProduct(self.productConf.id)]
      self.productID = self.productConf.ProductID
    end
  end
end

function UVC_AppStorePurchase:LoadView()
  self.labProductName.text = self.productConf.Desc
  IconManager:SetZenyShopItem(self.productConf.Picture, self.spItemIcon)
  self.spItemIcon:MakePixelPerfect()
  local rmb = self.productConf.Rmb
  if math.floor(rmb) == rmb then
    rmb = rmb .. ".00"
  end
  self.labTitleBTNPurchaseLuckyBag.text = "Â¥ " .. rmb
end

function UVC_AppStorePurchase:RegisterButtonClickEvent()
  self:AddClickEvent(self.goBTNPurchaseLuckyBag, function()
    self:OnClickForButtonPurchase()
  end)
  self:AddClickEvent(self.goBTNClose, function()
    self:OnClickForButtonClose()
  end)
end

function UVC_AppStorePurchase:OnClickForButtonPurchase()
  if self.productConf.ActivityDiscount == 1 then
    self:GetModelSet()
    self:LoadView()
  end
  if self.productConf.ActivityDiscount == 1 then
    self:Purchase()
  else
    self:RequestQueryChargeCnt()
    self.requestIsForVerifyPurchase = true
  end
end

function UVC_AppStorePurchase:OnClickForButtonClose()
  self:CloseSelf()
end

function UVC_AppStorePurchase:ListenServerResponse()
  EventManager.Me():AddEventListener(ServiceEvent.UserEventQueryChargeCnt, self.OnReceiveQueryChargeCnt, self)
  EventManager.Me():AddEventListener(ServiceEvent.UserEventChargeNtfUserEvent, self.OnReceivePurchaseSuccess, self)
  EventManager.Me():AddEventListener(ServiceEvent.UserEventUpdateActivityCnt, self.OnReceiveQueryChargeCnt, self)
end

function UVC_AppStorePurchase:CancelListenServerResponse()
  EventManager.Me():RemoveEventListener(ServiceEvent.UserEventQueryChargeCnt, self.OnReceiveQueryChargeCnt, self)
  EventManager.Me():RemoveEventListener(ServiceEvent.UserEventChargeNtfUserEvent, self.OnReceivePurchaseSuccess, self)
  EventManager.Me():RemoveEventListener(ServiceEvent.UserEventUpdateActivityCnt, self.OnReceiveQueryChargeCnt, self)
end

function UVC_AppStorePurchase:RequestQueryChargeCnt()
  ServiceUserEventProxy.Instance:CallQueryChargeCnt()
end

function UVC_AppStorePurchase:OnReceiveQueryChargeCnt(data)
  if self.requestIsForVerifyPurchase then
    local purchaseTimes = NewRechargeProxy.Ins:Deposit_GetLuckyBagPurchaseTimes(self.productConf.id)
    if purchaseTimes < self.productConf.MonthLimit then
      self:Purchase()
    else
      local purchaseLimit = self.productConf.MonthLimit
      local tabFormatParams = {purchaseLimit}
      if self.productConf and self.productConf.Desc then
        MsgManager.ShowMsgByIDTable(4101, self.productConf.Desc)
      end
    end
    self.requestIsForVerifyPurchase = false
  end
end

function UVC_AppStorePurchase:OnReceivePurchaseSuccess(message)
  local confID = message.dataid
  if confID == self.productConf.id then
    NewRechargeProxy.Ins:Deposit_AddLuckyBagPurchaseTimes(self.productConf.id)
    PurchaseDeltaTimeLimit.Instance():End(self.productID)
  end
end

function UVC_AppStorePurchase:OnReceiveUpdateActivityCnt(data)
  self:GetModelSet()
  self:LoadView()
end

function UVC_AppStorePurchase:Purchase()
  if ApplicationInfo.IsPcWebPay() then
    if productConf.PcEnable == 1 then
      MsgManager.ConfirmMsgByID(43467, function()
        ApplicationInfo.OpenPCRechargeUrl()
      end, nil, nil, nil)
    else
      MsgManager.ShowMsgByID(43466)
    end
    return
  end
  if PurchaseDeltaTimeLimit.Instance():IsEnd(self.productID) then
    local callbacks = {}
    callbacks[1] = function(x)
      PurchaseDeltaTimeLimit.Instance():End(self.productID)
    end
    callbacks[2] = function(x)
      PurchaseDeltaTimeLimit.Instance():End(self.productID)
    end
    callbacks[3] = function(x)
      PurchaseDeltaTimeLimit.Instance():End(self.productID)
    end
    callbacks[4] = function(x)
      PurchaseDeltaTimeLimit.Instance():End(self.productID)
    end
    callbacks[5] = function(x)
      PurchaseDeltaTimeLimit.Instance():End(self.productID)
    end
    FuncPurchase.Instance():Purchase(self.productConf.id, callbacks)
    local interval = GameConfig.PurchaseMonthlyVIP.interval / 1000
    PurchaseDeltaTimeLimit.Instance():Start(self.productID, interval)
  else
    MsgManager.ShowMsgByID(49)
  end
end

function UVC_AppStorePurchase:GetOriginProduct(activity_product)
  local productID = Table_Deposit[activity_product].ProductID
  for k, v in pairs(Table_Deposit) do
    if string.find(productID, v.ProductID) ~= nil then
      return k
    end
  end
  return nil
end
