autoImport("GemCell")
GemContainerView = class("GemContainerView", ContainerView)
GemContainerView.ViewType = UIViewType.NormalLayer
GemContainerView.TogglePageNameMap = {
  EmbedTab = "GemEmbedPage",
  AppraiseTab = "GemAppraisePage",
  UpgradeTab = "GemUpgradePage",
  FunctionTab = "GemFunctionPage",
  SecretLandTab = "SecretLandGemOptionalPage"
}
local _TabNamePrefix = "GemContainer_TabName_"
local _Single_Tab_Width = 160

function GemContainerView:Init()
  GemProxy.Instance:InitSkillProfessionFilter()
  self.pageContainer = self:FindGO("PageContainer")
  if not self.pageContainer then
    LogUtility.Error("Cannot find PageContainer!")
    return
  end
  self.tabLineBg = self:FindComponent("TabLineBg", UISprite)
  self.gem_forbidden_count = 0
  for toggleName, pageName in pairs(self.TogglePageNameMap) do
    autoImport(pageName)
    self:AddSubView(pageName, _G[pageName])
    self:FindAndAddToggle(toggleName, pageName)
  end
  if self.tabLineBg then
    self.tabLineBg.width = (5 - self.gem_forbidden_count) * _Single_Tab_Width
  end
  self:AddEvents()
end

function GemContainerView:FindAndAddToggle(toggleName, pageName)
  local toggleGO = self:FindGO(toggleName)
  local togName1 = self:FindComponent("Label1", UILabel, toggleGO)
  if togName1 and ZhString[_TabNamePrefix .. toggleName] then
    togName1.text = ZhString[_TabNamePrefix .. toggleName]
  end
  local togName2 = self:FindComponent("Label2", UILabel, toggleGO)
  if togName2 and ZhString[_TabNamePrefix .. toggleName] then
    togName2.text = ZhString[_TabNamePrefix .. toggleName]
  end
  self:AddClickEvent(toggleGO, function(go)
    self:SwitchToPage(self.TogglePageNameMap[go.name])
  end)
  self.toggleMap = self.toggleMap or {}
  local toggle = toggleGO:GetComponent(UIToggle)
  if toggle then
    self.toggleMap[pageName] = toggle
  end
  if pageName == "SecretLandGemOptionalPage" and (not FunctionUnLockFunc.Me():CheckCanOpen(GameConfig.Gem.SecretlandGemMenuID) or GemProxy.CheckGemForbidden(SceneItem_pb.EPACKTYPE_GEM_SECRETLAND)) then
    toggle.gameObject:SetActive(false)
    self.gem_forbidden_count = self.gem_forbidden_count + 1
  end
  if pageName == "GemFunctionPage" and GemProxy.CheckGemForbidden(SceneItem_pb.EPACKTYPE_GEM_SKILL) then
    toggle.gameObject:SetActive(false)
    self.gem_forbidden_count = self.gem_forbidden_count + 1
  end
  if pageName == "GemUpgradePage" and GemProxy.CheckGemForbidden(SceneItem_pb.EPACKTYPE_GEM_ATTR) then
    toggle.gameObject:SetActive(false)
    self.gem_forbidden_count = self.gem_forbidden_count + 1
  end
  return toggle
end

function GemContainerView:SwitchToPage(targetPageName)
  local toggle = self.toggleMap[targetPageName]
  if toggle then
    toggle.value = true
  end
  local isActive
  for pageName, pageClass in pairs(self.viewMap) do
    isActive = pageName == targetPageName
    pageClass.gameObject:SetActive(isActive)
    if isActive then
      self.activePageName = pageName
      if pageClass.OnActivate then
        pageClass:OnActivate()
      end
    end
    if not isActive and pageClass.OnDeactivate then
      pageClass:OnDeactivate()
    end
  end
end

function GemContainerView:OnEnter()
  GemContainerView.super.OnEnter(self)
  local targetPageName = self.viewdata.viewdata and self.viewdata.viewdata.page
  targetPageName = targetPageName or self:GetDefaultPageName()
  self:SwitchToPage(targetPageName)
  GemProxy.Instance:SetContainerViewOpen(true)
end

function GemContainerView:GetDefaultPageName()
  return self.TogglePageNameMap.EmbedTab
end

function GemContainerView:OnExit()
  GemProxy.Instance:SetContainerViewOpen(false)
  GemContainerView.super.OnExit(self)
end

function GemContainerView:AddEvents()
end
