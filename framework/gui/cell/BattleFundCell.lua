autoImport("UIAutoScrollCtrl")
BattleFundCell = class("BattleFundCell", CoreView)

function BattleFundCell:ctor(obj)
  BattleFundCell.super.ctor(self, obj)
  self:Init()
  self:AddGameObjectComp()
end

function BattleFundCell:Init()
  self.funcBtnGO = self:FindGO("FuncBtn")
  self:AddClickEvent(self.funcBtnGO, function()
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
  self.funcLabel = self:FindComponent("Label", UILabel, self.funcBtnGO)
  self.funcBtnDisabledGO = self:FindGO("FuncBtnDIsabled")
  self.finishGO = self:FindGO("FinishSymbol")
  self.freeBgGO = self:FindGO("FreeBG")
  self.purchasedBgGO = self:FindGO("PurchasedBG")
  self.conditionScroll = self:FindComponent("ConditionPanel", UIScrollView)
  self.conditionLabel = self:FindComponent("ConditionLabel", UILabel, self.conditionScroll.gameObject)
  self.conditionLabelCtrl = UIAutoScrollCtrl.new(self.conditionScroll, self.conditionLabel, 8, 40)
  self.itemIcon = self:FindComponent("ItemIcon", UISprite)
  self.itemNumLabel = self:FindComponent("ItemNum", UILabel)
end

function BattleFundCell:OnEnable()
  BattleFundCell.super.OnEnable(self)
  if self.conditionLabelCtrl then
    self.conditionLabelCtrl:Start(false, true)
  end
end

function BattleFundCell:OnDisable()
  BattleFundCell.super.OnDisable(self)
  if self.conditionLabelCtrl then
    self.conditionLabelCtrl:Stop(true)
  end
end

function BattleFundCell:OnDestroy()
  BattleFundCell.super.OnDestroy(self)
  if self.conditionLabelCtrl then
    self.conditionLabelCtrl:Destroy()
  end
end

local RewardState = BattleFundData.RewardState

function BattleFundCell:SetData(data)
  self.data = data
  if data.free then
    self.freeBgGO:SetActive(true)
    self.purchasedBgGO:SetActive(false)
    self.funcLabel.text = ZhString.BattleFundTakeFreeReward
  else
    self.freeBgGO:SetActive(false)
    self.purchasedBgGO:SetActive(true)
    self.funcLabel.text = ZhString.BattleFundTakeReward
  end
  self.conditionLabel.text = string.format(ZhString.ReturnActivityPanel_LoginDays, self.data.day)
  if self.gameObject.activeInHierarchy then
    self.conditionLabel:ProcessText()
    if self.conditionLabelCtrl then
      self.conditionLabelCtrl:Start(false, true)
    end
  end
  local itemConfig = Table_Item[data and data.itemId]
  IconManager:SetItemIcon(itemConfig and itemConfig.Icon or "item_151", self.itemIcon)
  self.itemNumLabel.text = "x" .. data.itemNum
  if data.state == RewardState.UnTaken then
    self.finishGO:SetActive(false)
    self.funcBtnGO:SetActive(true)
    self.funcBtnDisabledGO:SetActive(false)
  elseif data.state == RewardState.Taken then
    self.finishGO:SetActive(true)
    self.funcBtnGO:SetActive(false)
    self.funcBtnDisabledGO:SetActive(false)
  elseif data.state == RewardState.CannotTake then
    self.finishGO:SetActive(false)
    self.funcBtnGO:SetActive(false)
    self.funcBtnDisabledGO:SetActive(true)
  end
end
