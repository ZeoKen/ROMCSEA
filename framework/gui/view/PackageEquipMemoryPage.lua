PackageEquipMemoryPage = class("PackageEquipMemoryPage", SubView)
PackageEquipMemoryPage.PfbPath = "view/PackageEquipMemoryPage"
autoImport("EquipMemoryAttrCell")
autoImport("EquipMemoryAttrDetailCell")

function PackageEquipMemoryPage:Init()
  self:AddEvts()
  self.initPage = false
end

function PackageEquipMemoryPage:AddEvts()
  self:AddListenEvt(ServiceEvent.ItemUpdateMemoryPosItemCmd, self.UpdateView)
end

function PackageEquipMemoryPage:InitPage()
  self.initPage = true
  self.holder = self:FindGO("EquipMemoryHolder")
  self.gameObject = self:LoadPreferb(PackageEquipMemoryPage.PfbPath, self.holder, true)
  local togGrid = self:FindGO("TogGrid"):GetComponent(UIGrid)
  self.tog1 = self:FindGO("Tog1"):GetComponent(UIToggle)
  self.tog2 = self:FindGO("Tog2"):GetComponent(UIToggle)
  self.tog1.value = true
  self.scrollView = self:FindGO("ScrollView"):GetComponent(UIScrollView)
  self.effectGrid = self:FindGO("EffectGrid"):GetComponent(UITable)
  self.effectCtrl = UIGridListCtrl.new(self.effectGrid, EquipMemoryAttrCellType3, "EquipMemoryAttrCellType3")
  self.effectCtrl:AddEventListener(MouseEvent.MouseClick, self.HandleSwitchSingle, self)
  self.closeButton = self:FindGO("CloseButton", self.holder)
  self:AddClickEvent(self.closeButton, function()
    self.container:SetLeftViewState(PackageView.LeftViewState.Default)
  end)
end

function PackageEquipMemoryPage:InitView()
end

function PackageEquipMemoryPage:UpdateView()
  xdlog("UpdateView")
  if self.initPage then
    self:UpdateActiveEffect()
  end
end

function PackageEquipMemoryPage:UpdateActiveEffect()
  local result = {}
  local memoryLevels = EquipMemoryProxy.Instance:GetTotalEquipMemoryLevels() or {}
  for _attrid, _level in pairs(memoryLevels) do
    local _tempData = {id = _attrid, level = _level}
    table.insert(result, _tempData)
  end
  table.sort(result, function(l, r)
    return l.id < r.id
  end)
  self.effectCtrl:ResetDatas(result)
  self.scrollView:ResetPosition()
end

function PackageEquipMemoryPage:UpdateEffectPreview()
  if not Game.ItemMemoryEffect then
    return
  end
  local result = {}
  for _attrid, _info in pairs(Game.ItemMemoryEffect) do
    local _tempData = {attrid = _attrid}
    table.insert(result, _tempData)
  end
  self.detailCtrl:ResetDatas(result)
end

function PackageEquipMemoryPage:Switch(show)
  if show then
    if not self.initPage then
      self:InitPage()
    end
    self.holder:SetActive(true)
    self:UpdateView()
  elseif self.initPage then
    self.holder:SetActive(false)
  end
end

function PackageEquipMemoryPage:Open()
  if self.initPage == false then
    self:InitPage()
  end
end

function PackageEquipMemoryPage:Close()
end

function PackageEquipMemoryPage:HandleSwitchSingle(cell)
  if cell then
    cell:SwitchFolderState()
  end
  self.effectGrid:Reposition()
end
