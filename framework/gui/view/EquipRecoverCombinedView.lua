autoImport("CommonNewTabListCell")
EquipRecoverCombinedView = class("EquipRecoverCombinedView", BaseView)
EquipRecoverCombinedView.ViewType = UIViewType.NormalLayer

function EquipRecoverCombinedView:InitConfig()
  self.TabGOName = {
    "RecoveryTab",
    "DecomposeTab"
  }
  self.TabName = {
    ZhString.EquipRecover_EquipRecover,
    ZhString.EquipRecover_DeCompose
  }
end

function EquipRecoverCombinedView:Init()
  self:InitConfig()
  self:InitData()
  self:InitView()
end

function EquipRecoverCombinedView:InitData()
  local viewdata = self.viewdata.viewdata
  if viewdata then
    self.npcData = viewdata.npcdata
    self.index = viewdata.index or 1
    self.isFromBag = viewdata.isFromBag
  end
end

function EquipRecoverCombinedView:SetStackViewIndex(index)
  local viewdata = self.viewdata.viewdata
  if viewdata then
    viewdata.index = index
  end
end

function EquipRecoverCombinedView:InitView()
  self.grid = self:FindComponent("Grid", UIGrid)
  self.cells = {}
  local tabName, longPress
  for i = 1, #self.TabGOName do
    tabName = self.TabGOName[i]
    self.cells[i] = CommonNewTabListCell.new(self:FindGO(tabName))
    self:AddTabChangeEvent(self.cells[i].gameObject, nil, i)
    longPress = self.cells[i].gameObject:GetComponent(UILongPress)
    
    function longPress.pressEvent(obj, state)
      self:PassEvent(TipLongPressEvent.EnchantCombineView, {state, i})
    end
  end
  self:AddEventListener(TipLongPressEvent.EnchantCombineView, self.HandleLongPress, self)
end

function EquipRecoverCombinedView:HandleLongPress(param)
  local isPressing, index = param[1], param[2]
  TabNameTip.OnLongPress(isPressing, self.TabName[index], false, self.cells[index].sp)
end

function EquipRecoverCombinedView:TabChangeHandler(key)
  if not EquipRecoverCombinedView.super.TabChangeHandler(self, key) then
    return
  end
  self:JumpPanel(key)
  self.cells[key].toggle.value = true
end

local ReOpen = function(viewdata)
  FunctionNpcFunc.JumpPanel(PanelConfig.EquipRecoverCombinedView, viewdata)
end

function EquipRecoverCombinedView:JumpPanel(tabIndex)
  if tabIndex == 1 then
    self:SetStackViewIndex(1)
    self:_JumpPanel("EquipRecoverNewView", {
      npcdata = self.npcData,
      isFromHomeWorkbench = true,
      isCombine = true
    })
  elseif tabIndex == 2 then
    self:SetStackViewIndex(2)
    self:_JumpPanel("DeComposeNewView", {
      npcdata = self.npcData,
      isCombine = true,
      isnew = true
    })
  end
end

function EquipRecoverCombinedView:_JumpPanel(panelKey, viewData)
  if not panelKey or not PanelConfig[panelKey] then
    return
  end
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig[panelKey],
    viewdata = viewData
  })
end

function EquipRecoverCombinedView:OnEnter()
  EquipRecoverCombinedView.super.OnEnter(self)
  self:TabChangeHandler(self.index)
  self:SetPushToStack(true)
end

function EquipRecoverCombinedView:CloseSelf()
  self:SetPushToStack(false)
  EquipRecoverCombinedView.super.CloseSelf(self)
end

function EquipRecoverCombinedView:OnExit()
  EquipRecoverCombinedView.super.OnExit(self)
  self:sendNotification(UIEvent.CloseUI, {
    className = "EquipRecoverNewView",
    needRollBack = false
  })
  self:sendNotification(UIEvent.CloseUI, {
    className = "DeComposeNewView",
    needRollBack = false
  })
end
