AuctionSignUpCell = class("AuctionSignUpCell", ItemCell)

function AuctionSignUpCell:Init()
  self.cellContainer = self:FindGO("CellContainer")
  if self.cellContainer then
    local obj = self:LoadPreferb("cell/ItemCell", self.cellContainer)
    obj.transform.localPosition = LuaGeometry.GetTempVector3()
  end
  AuctionSignUpCell.super.Init(self)
  self:FindObjs()
  self:AddEvts()
  self:SetIgnoreClickEventInterval(true)
end

function AuctionSignUpCell:FindObjs()
  self.money = self:FindGO("Money"):GetComponent(UILabel)
  self.signUpBtn = self:FindGO("SignUpBtn"):GetComponent(UIMultiSprite)
  self.signUpLabel = self:FindGO("Label", self.signUpBtn.gameObject):GetComponent(UILabel)
  self.state = self:FindGO("State")
  self.close = self:FindGO("Close")
  self.priceRoot = self:FindGO("PriceRoot")
  self.signUpLabel.text = ZhString.Auction_Register
end

function AuctionSignUpCell:AddEvts()
  self:AddClickEvent(self.cellContainer, function()
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
  self:AddClickEvent(self.signUpBtn.gameObject, function()
    self:SignUp()
  end)
end

function AuctionSignUpCell:SetData(data)
  self.gameObject:SetActive(data ~= nil)
  if data then
    AuctionSignUpCell.super.SetData(self, data:GetItemData())
    local isNeedEnchant = data:IsNeedEnchant()
    if isNeedEnchant then
      self.priceRoot:SetActive(false)
    else
      self.priceRoot:SetActive(true)
      if data.price then
        self.money.text = StringUtil.NumThousandFormat(data.price)
      end
    end
    if data.state == AuctionSignUpState.Close then
      self.signUpBtn.gameObject:SetActive(false)
      self.state:SetActive(false)
      self.close:SetActive(true)
    elseif data.state == AuctionSignUpState.SignUp then
      self.signUpBtn.gameObject:SetActive(true)
      self.state:SetActive(false)
      self.close:SetActive(false)
      self:SetSignUp(not data:CanSignUp())
    elseif data.state == AuctionSignUpState.Signed then
      self.signUpBtn.gameObject:SetActive(false)
      self.state:SetActive(true)
      self.close:SetActive(false)
    end
  end
  self.data = data
end

function AuctionSignUpCell:SignUp()
  if self.data then
    if AuctionProxy.Instance:GetItemNumByStaticIDExceptNonMaterialFavorite(self.data.itemid) > 0 then
      local isNeedEnchant = self.data:IsNeedEnchant()
      if isNeedEnchant then
        local list = self.data:GetSignUpItemList()
        local count = #list
        if count == 0 then
          MsgManager.ShowMsgByID(25607)
          return
        elseif count == 1 then
          if self.data:HasQuench() then
            MsgManager.ConfirmMsgByID(43332, function()
              FuncShortCutFunc.Me():CallByID(20)
            end)
            return
          end
          FunctionSecurity.Me():NormalOperation(function(arg)
            self:sendNotification(UIEvent.JumpPanel, {
              view = PanelConfig.AuctionSignUpDetailView,
              viewdata = {
                itemdata = BagProxy.Instance:GetItemByGuid(arg)
              }
            })
          end, list[1])
          return
        elseif 1 < count then
          FunctionSecurity.Me():NormalOperation(function(arg)
            self:sendNotification(UIEvent.JumpPanel, {
              view = PanelConfig.AuctionSignUpSelectView,
              viewdata = arg
            })
          end, list)
          return
        end
      end
      FunctionSecurity.Me():NormalOperation(function(arg)
        self:sendNotification(UIEvent.JumpPanel, {
          view = PanelConfig.AuctionSignUpDetailView,
          viewdata = {
            itemdata = arg:GetItemData(),
            price = arg.price
          }
        })
      end, self.data)
    else
      MsgManager.ShowMsgByID(9502)
    end
  end
end

function AuctionSignUpCell:SetSignUp(isGray)
  if isGray then
    self.signUpBtn.CurrentState = 1
    self.signUpLabel.effectStyle = UILabel.Effect.None
  else
    self.signUpBtn.CurrentState = 0
    self.signUpLabel.effectStyle = UILabel.Effect.Outline
  end
end
