autoImport("UIListItemCtrlLuckyBag")
autoImport("UIListItemViewControllerZenyShopItem")
autoImport("UIModelZenyShop")
autoImport("UIModelMonthlyVIP")
autoImport("UISubViewControllerMonthlyVIP")
autoImport("UISubViewControllerZenyList")
autoImport("UISubViewControllerGachaCoin")
autoImport("UISubViewControllerZenyShopItem")
autoImport("FuncZenyShop")
UIViewControllerZenyShop = class("UIViewControllerZenyShop", ContainerView)
UIViewControllerZenyShop.ViewType = UIViewType.NormalLayer
UIViewControllerZenyShop.instance = nil

function UIViewControllerZenyShop:Init()
  UIViewControllerZenyShop.instance = self
  self:GetGameObjects()
  self:RegisterButtonClickEvent()
  self:LoadView()
  self.zenyController = self:AddSubView("UISubViewControllerZenyList", UISubViewControllerZenyList)
  self.monthlyVIPController = self:AddSubView("UISubViewControllerMonthlyVIP", UISubViewControllerMonthlyVIP)
  self.gachaCoinController = self:AddSubView("UISubViewControllerGachaCoin", UISubViewControllerGachaCoin)
  self.itemController = self:AddSubView("UISubViewControllerZenyShopItem", UISubViewControllerZenyShopItem)
  local tabZeny = PanelConfig.ZenyShop.tab
  local tabMonthlyVIP = PanelConfig.ZenyShopMonthlyVIP.tab
  local tabGachaCoin = PanelConfig.ZenyShopGachaCoin.tab
  local tabItem = PanelConfig.ZenyShopItem.tab
  self.subViewControllers = {}
  self.subViewControllers[tabZeny] = self.zenyController
  self.subViewControllers[tabMonthlyVIP] = self.monthlyVIPController
  self.subViewControllers[tabGachaCoin] = self.gachaCoinController
  self.subViewControllers[tabItem] = self.itemController
  self:AddTabChangeEvent(self.sGOSelection[tabZeny], nil, tabZeny)
  self:AddTabChangeEvent(self.sGOSelection[tabMonthlyVIP], nil, tabMonthlyVIP)
  self:AddTabChangeEvent(self.sGOSelection[tabGachaCoin], nil, tabGachaCoin)
  self:AddTabChangeEvent(self.sGOSelection[tabItem], nil, tabItem)
  local goodsType = self.viewdata.view.tab
  goodsType = not BranchMgr.IsChina() and not BranchMgr.IsTW() and goodsType == PanelConfig.ZenyShop.tab and PanelConfig.ZenyShopGachaCoin.tab or goodsType
  self:TabChangeHandler(goodsType)
  self:ListenServerResponse()
  if BranchMgr.IsJapan() then
    self.laws = self:LoadPreferb("cell/laws", self.gameObject)
    self.laws.transform.localPosition = LuaGeometry.GetTempVector3(427, 227, 0)
    local lawsW = self.laws:GetComponent(UIWidget)
    OverseaHostHelper:FixAnchor(lawsW.topAnchor, self.gameObject.transform, 1, 90)
    OverseaHostHelper:FixAnchor(lawsW.rightAnchor, self.gameObject.transform, 1, -290)
    local law1 = self:FindGO("laws1", self.laws)
    self:AddClickEvent(law1, function(go)
      OverseaHostHelper:OpenWebView("https://mobile.gungho.jp/reg/shikin")
    end)
    local law2 = self:FindGO("laws2", self.laws)
    self:AddClickEvent(law2, function(go)
      OverseaHostHelper:OpenWebView("https://mobile.gungho.jp/reg/trade")
    end)
  end
end

function UIViewControllerZenyShop:ShowAgeSelect()
  if not BranchMgr.IsJapan() then
    return
  end
  helplog("UIViewControllerZenyShop:ShowAgeSelect")
  if not OverseaHostHelper.hasShowAge then
    OverseaHostHelper.hasShowAge = true
    GameFacade.Instance:sendNotification(UIEvent.ShowUI, {
      viewname = "ChargeLimitPanel"
    })
  end
end

function UIViewControllerZenyShop:GetGameObjects()
  self.goBTNBack = self:FindGO("BTN_Back", self.gameObject)
  self.goZenyBalance = self:FindGO("ZenyBalance", self.gameObject)
  self.goLabZenyBalance = self:FindGO("Lab", self.goZenyBalance)
  self.labZenyBalance = self.goLabZenyBalance:GetComponent(UILabel)
  self.spZeny = self:FindGO("Icon", self.goZenyBalance):GetComponent(UISprite)
  IconManager:SetItemIcon("item_100", self.spZeny)
  self.goGachaCoinBalance = self:FindGO("GachaCoinBalance", self.gameObject)
  self.goLabGachaCoinBalance = self:FindGO("Lab", self.goGachaCoinBalance)
  self.labGachaCoinBalance = self.goLabGachaCoinBalance:GetComponent(UILabel)
  self.spGachaCoin = self:FindGO("Icon", self.goGachaCoinBalance):GetComponent(UISprite)
  IconManager:SetItemIcon("item_151", self.spGachaCoin)
  self.goZenyIconRoots = self:FindGO("ZenyIconRoots", self.gameObject)
  self.goRootTemplate = self:FindGO("RootTemplate", self.gameObject)
  self.goPanelDynamicNPC = self:FindGO("PanelDynamicNPC", self.gameObject)
  self.goDynamicNPC = self:FindGO("DynamicNPC", self.goPanelDynamicNPC)
  self.texDynamicNPC = self.goDynamicNPC:GetComponent(UITexture)
  self.widgetTipRelative = self:FindGO("TipRelativeWidget", self.gameObject):GetComponent(UIWidget)
  self.texBG = self:FindComponent("BG", UITexture, self.gameObject)
  self.goTip = self:FindGO("Tip", self.gameObject)
  self.spFrame = self:FindGO("Frame", self.goTip):GetComponent(UISprite)
  self.goSelections = self:FindGO("Selections")
  self.goSelectionTemplate = self:FindGO("Selection", self.goSelections)
  self.helpButton = self:FindGO("HelpBtn", self.gameObject)
  self.StopAll = self:FindGO("StopAll", self.gameObject)
  self:CloseBoxCollider()
  self.tipsLabel = self:FindGO("GameObject", self.gameObject):GetComponent(UILabel)
  if BranchMgr.IsSEA() or BranchMgr.IsNA() then
    self.tipsLabel.gameObject:SetActive(false)
  end
end

function UIViewControllerZenyShop:RegisterButtonClickEvent()
  self:AddClickEvent(self.goBTNBack, function()
    self:OnClickForButtonBack()
  end)
  self:TryOpenHelpViewById(40000, nil, self.helpButton)
  EventManager.Me():AddEventListener(ZenyShopEvent.OpenBoxCollider, self.OpenBoxCollider, self)
  EventManager.Me():AddEventListener(ZenyShopEvent.CloseBoxCollider, self.CloseBoxCollider, self)
end

function UIViewControllerZenyShop:OpenBoxCollider()
  if self.StopAll and ApplicationInfo.IsWindows() then
    self.StopAll.gameObject:SetActive(true)
  end
end

function UIViewControllerZenyShop:CloseBoxCollider()
  if self.StopAll then
    self.StopAll.gameObject:SetActive(false)
  end
end

function UIViewControllerZenyShop:GetMonthCardConfigure()
  local year = UIModelMonthlyVIP.YearOfServer(-18000)
  local month = UIModelMonthlyVIP.MonthOfServer(-18000)
  for _, v in pairs(Table_MonthCard) do
    if v.Year == year and v.Month == month then
      return v
    end
  end
  redlog("not find MonthCardConfigure", year, month)
  return nil
end

function UIViewControllerZenyShop:LoadView()
  self:LoadZenyBalanceView()
  if self.goSelections.transform.childCount <= 1 then
    self.sGOSelection = {}
    self.sSpBGSelection = {}
    self.sLabTitleSelection = {}
    local functionCount = 0
    local functions = GameConfig.ZenyShop.Functions
    for i = 1, #functions do
      local tab = functions[i].Tab
      local isForbid = false
      if tab == PanelConfig.ZenyShop.tab then
        isForbid = GameConfig.SystemForbid.ZenyPurchase
      elseif tab == PanelConfig.ZenyShopMonthlyVIP.tab then
        isForbid = GameConfig.SystemForbid.CardPurchase
      elseif tab == PanelConfig.ZenyShopGachaCoin.tab then
        isForbid = GameConfig.SystemForbid.GoldPurchase
      elseif tab == PanelConfig.ZenyShopItem.tab then
        isForbid = GameConfig.SystemForbid.ItemPurchase
      end
      if not isForbid then
        functionCount = functionCount + 1
        local functionName = functions[i].Title
        local goSelection = GameObject.Instantiate(self.goSelectionTemplate)
        goSelection.transform:SetParent(self.goSelections.transform, false)
        goSelection.name = tab
        goSelection:SetActive(true)
        local labTitle = self:FindGO("Title", goSelection):GetComponent(UILabel)
        labTitle.text = functionName
        self.sGOSelection[tab] = goSelection
        self.sSpBGSelection[tab] = self:FindGO("BG", goSelection):GetComponent(UISprite)
        self.sLabTitleSelection[tab] = labTitle
        if tab == PanelConfig.ZenyShopItem.tab then
          self:RegisterRedTipCheck(UIModelZenyShop.DailyOneZenyRedTipID, self.sSpBGSelection[tab].gameObject, 9, {-6, -4})
        end
      end
    end
    self.goSelections:GetComponent(UIGrid).repositionNow = true
    local widthOfTipFrame = self.spFrame.width
    widthOfTipFrame = widthOfTipFrame + functionCount * 180
    self.spFrame.width = widthOfTipFrame
  end
  local monthCardConfigure = self:GetMonthCardConfigure()
  if monthCardConfigure and monthCardConfigure.NpcPicture then
    PictureManager.Instance:SetZenyShopNPC(monthCardConfigure.NpcPicture, self.texDynamicNPC)
    self.monthCardNpcPictureName = monthCardConfigure.NpcPicture
  else
    helplog("!!!!!  UIViewControllerZenyShop:LoadView() monthCardConfigure == nil !!")
    PictureManager.Instance:SetZenyShopNPC("Kapla", self.texDynamicNPC)
    self.monthCardNpcPictureName = "Kapla"
  end
  if BranchMgr.IsJapan() then
    self.helpButton.gameObject:SetActive(false)
  end
end

function UIViewControllerZenyShop:LoadZenyBalanceView()
  local milCommaBalance = FuncZenyShop.FormatMilComma(MyselfProxy.Instance:GetROB())
  if milCommaBalance then
    self.labZenyBalance.text = milCommaBalance
  end
  milCommaBalance = FuncZenyShop.FormatMilComma(MyselfProxy.Instance:GetLottery())
  if milCommaBalance then
    self.labGachaCoinBalance.text = milCommaBalance
  end
end

function UIViewControllerZenyShop:OnClickForButtonBack()
  if self.zenyController ~= nil then
    local purchasedShopItems = self.zenyController:GetCachedPurchaseItem()
    if purchasedShopItems ~= nil then
      self:ShowAnimationConfirmView()
    end
  end
  self:CloseSelf()
end

function UIViewControllerZenyShop:TabChangeHandler(tab)
  local subViewController = self.subViewControllers[tab]
  if not subViewController.isInit then
    subViewController:MyInit()
  end
  subViewController.gameObject:SetActive(true)
  if tab == PanelConfig.ZenyShopItem.tab then
    subViewController:ReInit()
  end
  if self.currentSubViewCtrl ~= nil then
    if self.currentSubViewCtrl == subViewController then
      return
    else
      self.currentSubViewCtrl.gameObject:SetActive(false)
    end
  end
  self.currentSubViewCtrl = subViewController
  self.goZenyBalance:SetActive(tab == PanelConfig.ZenyShop.tab or tab == PanelConfig.ZenyShopMonthlyVIP.tab)
  self.goGachaCoinBalance:SetActive(tab == PanelConfig.ZenyShopGachaCoin.tab or tab == PanelConfig.ZenyShopItem.tab)
  self:ChangeSelection(self.sSpBGSelection[tab], self.sLabTitleSelection[tab])
  if tab == PanelConfig.ZenyShopMonthlyVIP.tab or tab == PanelConfig.ZenyShopGachaCoin.tab then
    UIViewControllerZenyShop:ShowAgeSelect()
  end
end

function UIViewControllerZenyShop:ListenServerResponse()
  self:AddListenEvt(MyselfEvent.MyDataChange, self.OnReceiveEventMyDataChange)
  self:AddListenEvt(ServiceEvent.SessionShopQueryShopConfigCmd, nil)
  self:AddListenEvt(ServiceEvent.ItemGetCountItemCmd, nil)
  self:AddListenEvt(ServiceEvent.NUserUpdateShopGotItem, nil)
end

function UIViewControllerZenyShop:OnReceiveEventMyDataChange(data)
  self:LoadZenyBalanceView()
end

function UIViewControllerZenyShop:RegisterZenyIconTargetPosition()
  if self.itemsController then
    for _, v in pairs(self.itemsController) do
      local itemController = v
      itemController:RegisterZenyIconTargetPosition(self.goZenyBalance.transform.position)
    end
  end
end

function UIViewControllerZenyShop:SetZenyIconRoot(trans)
  if self.itemsController then
    for _, v in pairs(self.itemsController) do
      local itemController = v
      local goCopyRootTemplate = GameObject.Instantiate(self.goRootTemplate)
      local transCopyRootTemplate = goCopyRootTemplate.transform
      transCopyRootTemplate:SetParent(self.goZenyIconRoots.transform)
      local pos = transCopyRootTemplate.localPosition
      pos.x = 0
      pos.y = 0
      pos.z = 0
      transCopyRootTemplate.localPosition = pos
      local rotation = transCopyRootTemplate.localRotation
      local eulerAngles = rotation.eulerAngles
      eulerAngles.x = 0
      eulerAngles.y = 0
      eulerAngles.z = 0
      rotation.eulerAngles = eulerAngles
      transCopyRootTemplate.localRotation = rotation
      local scale = transCopyRootTemplate.localScale
      scale.x = 1
      scale.y = 1
      scale.z = 1
      transCopyRootTemplate.localScale = scale
      itemController:SetZenyIconRoot(transCopyRootTemplate)
    end
  end
end

function UIViewControllerZenyShop:SetZenyIconCount()
  if self.itemsController then
    for _, v in pairs(self.itemsController) do
      local itemController = v
      itemController:SetZenyIconCount()
    end
  end
end

local gColorNormal = Color32(62, 89, 167, 255)
local gColorSelected = Color32(182, 113, 42, 255)

function UIViewControllerZenyShop:ChangeSelection(sp_frame, lab_title)
  sp_frame.spriteName = "recharge_btn_1"
  if self.spBGCurrentSelection ~= nil and self.spBGCurrentSelection ~= sp_frame then
    self.spBGCurrentSelection.spriteName = "recharge_btn_2"
  end
  self.spBGCurrentSelection = sp_frame
  lab_title.color = gColorSelected
  if self.labTitleCurrentSelection ~= nil and self.labTitleCurrentSelection ~= lab_title then
    self.labTitleCurrentSelection.color = gColorNormal
  end
  self.labTitleCurrentSelection = lab_title
  if BranchMgr.IsJapan() then
    if sp_frame == self.sSpBGSelection[PanelConfig.ZenyShopItem.tab] then
      self.tipsLabel.gameObject:SetActive(true)
    else
      self.tipsLabel.gameObject:SetActive(false)
    end
  end
end

function UIViewControllerZenyShop:ShowAnimationConfirmView()
  MsgManager.ConfirmMsgByID(201, function()
    self:OnAnimationConfirm()
  end, function()
    self:OnAnimationCancel()
  end)
end

function UIViewControllerZenyShop:OnAnimationConfirm()
  local purchasedShopItems = self.zenyController:GetCachedPurchaseItem()
  self:RequestStartAnimation(purchasedShopItems)
end

function UIViewControllerZenyShop:OnAnimationCancel()
end

function UIViewControllerZenyShop:RequestStartAnimation(purchaseShopItems)
  ServiceNUserProxy.Instance:CallChargePlayUserCmd(purchaseShopItems)
end

function UIViewControllerZenyShop:OnShow()
  UIViewControllerZenyShop.super.OnShow(self)
  local camera = Game.GameObjectManagers[Game.GameObjectType.Camera]
  if camera ~= nil then
    camera:ActiveMainCamera(false)
  end
end

function UIViewControllerZenyShop:OnHide()
  UIViewControllerZenyShop.super.OnHide(self)
  local camera = Game.GameObjectManagers[Game.GameObjectType.Camera]
  if camera ~= nil then
    camera:ActiveMainCamera(true)
  end
end

function UIViewControllerZenyShop:OnEnter()
  UIViewControllerZenyShop.super.OnEnter(self)
  helplog("UIViewControllerZenyShop OnEnter")
  EventManager.Me():AddEventListener(ChargeLimitPanel.CloseZeny, self.OnClickForButtonBack, self)
  EventManager.Me():AddEventListener(ChargeLimitPanel.SelectEvent, self.ChargeLimitSelect, self)
  ServiceUserEventProxy.Instance:CallQueryChargeCnt()
  self.texBGName = "recharge_bg"
  if self.texBG then
    PictureManager.Instance:SetUI(self.texBGName, self.texBG)
    PictureManager.ReFitFullScreen(self.texBG, 1)
  end
end

function UIViewControllerZenyShop:OnExit()
  UIViewControllerZenyShop.super.OnExit(self)
  EventManager.Me():RemoveEventListener(ChargeLimitPanel.CloseZeny, self.OnClickForButtonBack, self)
  EventManager.Me():RemoveEventListener(ChargeLimitPanel.SelectEvent, self.ChargeLimitSelect, self)
  OverseaHostHelper.hasShowAge = false
  if self.texBG then
    PictureManager.Instance:UnLoadUI(self.texBGName, self.texBG)
  end
  if self.monthCardNpcPictureName then
    PictureManager.Instance:UnLoadZenyShopNPC(self.monthCardNpcPictureName, self.texDynamicNPC)
  end
  UIViewControllerZenyShop.instance = nil
  FuncZenyShop.Instance():ClearProductPurchase()
end

function UIViewControllerZenyShop:ChargeLimitSelect(id)
  helplog("UIViewControllerZenyShop:ChargeLimitSelect")
  GameFacade.Instance:sendNotification(UIEvent.ShowUI, {
    viewname = "ChargeComfirmPanel",
    cid = id
  })
end
