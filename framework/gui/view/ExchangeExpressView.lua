autoImport("EffectShowDataWraper")
ExchangeExpressView = class("ExchangeExpressView", ContainerView)
ExchangeExpressView.ViewType = UIViewType.PopUpLayer

function ExchangeExpressView:Init()
  self:FindObj()
  self:AddBtnEvt()
  self:AddViewEvt()
  self:InitShow()
end

function ExchangeExpressView:FindObj()
  self.credit = self:FindGO("Credit"):GetComponent(UILabel)
  self.toName = self:FindGO("ToName"):GetComponent(UILabel)
  self.fromName = self:FindGO("FromName"):GetComponent(UILabel)
  self.contentInput = self:FindGO("ContentInput"):GetComponent(UIInput)
  UIUtil.LimitInputCharacter(self.contentInput, 45)
  self.expressCost = self:FindGO("ExpressCost"):GetComponent(UILabel)
  self.editBtn = self:FindGO("EditBtn"):GetComponent(UISprite)
  self.iconContainer = self:FindGO("IconContainer")
  self.modelContainer = self:FindGO("ModelContainer")
  self.modelRoot = self:FindGO("ModelRoot")
  self.turnLeft = self:FindGO("TurnLeft")
  self.turnRight = self:FindGO("TurnRight")
end

function ExchangeExpressView:AddBtnEvt()
  local addBtn = self:FindGO("AddBtn")
  self:AddClickEvent(addBtn, function()
    FriendProxy.Instance:SetPresentMode(FriendProxy.PresentMode.Exchange)
    self:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.ExchangeFriendView,
      viewdata = {
        filterFunc = self.FilterFriendList,
        filterArg = self
      }
    })
  end)
  local expressBtn = self:FindGO("ExpressBtn")
  self:AddClickEvent(expressBtn, function()
    self:Express()
  end)
  self:AddClickEvent(self.turnLeft, function()
    self:TurnLeft()
  end)
  self:AddClickEvent(self.turnRight, function()
    self:TurnRight()
  end)
  self:AddClickEvent(self.modelRoot, function()
    self:ClickCell()
  end)
  self:AddClickEvent(self.iconContainer, function()
    self:ClickCell()
  end)
end

function ExchangeExpressView:AddViewEvt()
  self:AddListenEvt(ShopMallEvent.ExchangeSelectFriend, self.HandleSelectFriend)
end

function ExchangeExpressView:InitShow()
  if self.viewdata and self.viewdata.viewdata then
    local data = self.viewdata.viewdata
    local count = data.count
    self.itemId = data.itemid
    self.logId = data.id
    self.logtype = data.type
    self.tradetime = data.tradetime
    local itemData = data:GetItemData()
    local showType = ShopMallProxy.Instance:CheckItemType(itemData)
    if showType then
      self.itemShowWraper = EffectShowDataWraper.new(itemData, nil, showType, nil)
      self:ShowItem()
    else
      self.modelRoot:SetActive(false)
      local obj = self:LoadPreferb("cell/ItemCell", self.iconContainer)
      obj.transform.localPosition = LuaGeometry.GetTempVector3()
      local itemCell = BaseItemCell.new(obj)
      itemCell:SetData(itemData)
    end
    self.needCredit = data.price * count
    self.totalCredit = MyselfProxy.Instance:GetQuota()
    self.currentBgIndex = 1
    self.fromName.text = string.format(ZhString.ShopMall_ExchangeExpressFrom, Game.Myself.data:GetName())
    self.credit.text = string.format(ZhString.ShopMall_ExchangeExpressCredit, StringUtil.NumThousandFormat(self.needCredit), StringUtil.NumThousandFormat(self.totalCredit))
    self:UpdateCost()
    self.contentInput.value = GameConfig.Exchange.SendMessage
    self.bgMap = {}
    self:UpdateBg(self.currentBgIndex)
    self.tipData = {}
    self.tipData.funcConfig = {}
  end
end

function ExchangeExpressView:HandleSelectFriend(note)
  local data = note.body
  if data then
    local friendData = FriendProxy.Instance:GetFriendById(data)
    if friendData then
      self.friendId = friendData.guid
      self.toName.text = friendData.name
    end
  end
end

function ExchangeExpressView:ShowItem()
  if self.itemShowWraper then
    local obj = self.itemShowWraper:getModelObj(self.modelContainer)
    if self.itemShowWraper.showType == FloatAwardView.ShowType.ModelType then
      self:ShowItemModel(obj)
    end
  end
end

local posVec = LuaVector3.Zero()
local rotVec = LuaVector3.Zero()
local scaleVec = LuaVector3.Zero()
local rotationQua = LuaQuaternion.Identity()

function ExchangeExpressView:ShowItemModel(obj)
  if self.itemShowWraper.itemData.equipInfo then
    LuaVector3.Better_Set(posVec, 0, 0, 0)
    LuaQuaternion.Better_Set(rotationQua, 0, 0, 0, 0)
    LuaVector3.Better_Set(scaleVec, 1, 1, 1)
    local itemModelName = self.itemShowWraper.itemData.equipInfo.equipData.Model
    local modelConfig = ModelShowConfig[itemModelName]
    if modelConfig then
      local position = modelConfig.localPosition
      LuaVector3.Better_Set(posVec, position[1], position[2], position[3])
      local rotation = modelConfig.localRotation
      LuaQuaternion.Better_Set(rotationQua, rotation[1], rotation[2], rotation[3], rotation[4])
      local scale = modelConfig.localScale
      LuaVector3.Better_Set(scaleVec, scale[1], scale[2], scale[3])
    end
    obj:ResetLocalPosition(posVec)
    LuaQuaternion.Better_GetEulerAngles(rotationQua, rotVec)
    obj:ResetLocalEulerAngles(rotVec)
    obj:ResetLocalScale(scaleVec)
  end
end

function ExchangeExpressView:Express()
  if self.friendId == nil then
    MsgManager.ShowMsgByID(25006)
    return
  end
  if self.givefee > MyselfProxy.Instance:GetROB() then
    MsgManager.ShowMsgByID(1)
    return
  end
  if self.needCredit > self.totalCredit then
    MsgManager.ShowMsgByID(25003)
    return
  end
  local itemName = ""
  if self.itemId then
    local itemData = Table_Item[self.itemId]
    if itemData then
      itemName = itemData.NameZh
    end
  end
  local viewData = {
    viewname = "ToggleConfirmView",
    content = string.format(ZhString.ShopMall_ExchangeExpressConfirmTip, itemName, self.toName.text),
    checkLabel = ZhString.ShopMall_ExchangeExpressConfirmToggle,
    confirmtext = ZhString.ShopMall_ExchangeExpressConfirmBtn,
    canceltext = ZhString.UniqueConfirmView_CanCel,
    confirmHandler = function(isToggle)
      if self.logId and self.logtype then
        ServiceRecordTradeProxy.Instance:CallGiveTradeCmd(self.logId, self.logtype, self.friendId, self.contentInput.value, isToggle, self.currentBgIndex)
        self:CloseSelf()
      end
    end
  }
  self:sendNotification(UIEvent.ShowUI, viewData)
end

function ExchangeExpressView:TurnLeft()
  local index = self.currentBgIndex - 1
  self:UpdateBg(index)
  self:UpdateCost()
end

function ExchangeExpressView:TurnRight()
  local index = self.currentBgIndex + 1
  self:UpdateBg(index)
  self:UpdateCost()
end

function ExchangeExpressView:ClickCell()
  self.tipData.itemdata = self.viewdata.viewdata:GetItemData()
  self:ShowItemTip(self.tipData, self.editBtn, NGUIUtil.AnchorSide.Right, {150, 0})
end

function ExchangeExpressView:UpdateBg(index)
  local isSuccess = self:SetBg(index)
  if isSuccess then
    self:UpdateTurn(index)
    self:UpdateLabel(index)
  end
end

function ExchangeExpressView:SetBg(index)
  local sendMoney = GameConfig.Exchange.SendMoney
  if sendMoney[index] == nil then
    return false
  end
  local lastIndex = self.currentBgIndex
  local bgMap = self.bgMap
  if bgMap[lastIndex] then
    bgMap[lastIndex]:SetActive(false)
  end
  if bgMap[index] == nil then
    local uiName = sendMoney[index].Resourse
    bgMap[index] = self:LoadPreferb("cell/" .. uiName, self.gameObject, true)
    if uiName == "ExchangeExpressBg1" then
      local uiEffectParent = Game.GameObjectUtil:DeepFind(bgMap[index].gameObject, "lizi")
      if uiEffectParent then
        self:PlayUIEffect(EffectMap.UI.ExchangeExpressBg1, uiEffectParent.transform)
      end
    elseif uiName == "ExchangeExpressBg2" then
      local uiEffectParent1 = Game.GameObjectUtil:DeepFind(bgMap[index].gameObject, "Effect0")
      if uiEffectParent1 then
        self:PlayUIEffect(EffectMap.UI.sakura_gift_ui_85, uiEffectParent1.transform)
      end
      local uiEffectParent2 = Game.GameObjectUtil:DeepFind(uiEffectParent1, "Effect1")
      if uiEffectParent2 then
        self:PlayUIEffect(EffectMap.UI.ExchangeExpressBg2, uiEffectParent2.transform)
      end
      local uiEffectParent3 = Game.GameObjectUtil:DeepFind(bgMap[index].gameObject, "Effect2")
      if uiEffectParent3 then
        self:PlayUIEffect(EffectMap.UI.sakura_gift_shine_86, uiEffectParent3.transform)
      end
    end
  end
  bgMap[index]:SetActive(true)
  self.currentBgIndex = index
  return true
end

function ExchangeExpressView:UpdateTurn(index)
  local sendMoney = GameConfig.Exchange.SendMoney
  self.turnLeft:SetActive(sendMoney[index - 1] ~= nil)
  self.turnRight:SetActive(sendMoney[index + 1] ~= nil)
end

function ExchangeExpressView:UpdateLabel(index)
  local color = GameConfig.Exchange.SendMoney[index].fontcolor
  local hasc, rc = ColorUtil.TryParseHexString(color)
  self.credit.color = rc
  self.toName.color = rc
  self.editBtn.color = rc
  self.fromName.color = rc
end

function ExchangeExpressView:UpdateCost()
  self.givefee = CommonFun.calcTradeGiveFee(self.needCredit, self.currentBgIndex)
  self.expressCost.text = StringUtil.NumThousandFormat(self.givefee)
end

function ExchangeExpressView.FilterFriendList(list, result, arg)
  for i = 1, #list do
    local friend = list[i]
    if friend:GetCreatetime(SocialManager.SocialRelation.Friend) < arg.tradetime and friend:isSameTradeGroup() then
      result[#result + 1] = friend
    end
  end
end
