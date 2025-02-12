autoImport("WrapListCtrl")
autoImport("GemCell")
autoImport("GemCombineCell")
autoImport("GemExhibitChooseCell")
autoImport("ItemTipGemExhibitCell")
GemFunctionPage = class("GemFunctionPage", SubView)
GemFunctionState = {
  Default = 1,
  SameName = 0,
  RandomProf = 1,
  CurrentProf = 2,
  Sculpt = 3,
  Smelt = 4
}
GemFunctionTitle = {
  [GemFunctionState.RandomProf] = Table_NpcFunction[10026].NameZh,
  [GemFunctionState.CurrentProf] = Table_NpcFunction[10027].NameZh,
  [GemFunctionState.SameName] = Table_NpcFunction[10028].NameZh,
  [GemFunctionState.Sculpt] = Table_NpcFunction[10033].NameZh,
  [GemFunctionState.Smelt] = Table_NpcFunction[10037].NameZh
}
GemFunctionHelpId = {
  [GemFunctionState.RandomProf] = 1003,
  [GemFunctionState.CurrentProf] = 1004,
  [GemFunctionState.SameName] = 1005,
  [GemFunctionState.Sculpt] = 1009,
  [GemFunctionState.Smelt] = 1010
}
GemFunctionCostZeny = {
  [GemFunctionState.RandomProf] = GameConfig.Gem.ThreeCostZeny,
  [GemFunctionState.CurrentProf] = GameConfig.Gem.FiveCostZeny,
  [GemFunctionState.SameName] = GameConfig.Gem.SameNameCost,
  [GemFunctionState.Smelt] = GameConfig.Gem.SmeltCostZeny
}
GemFunctionMainLabel = {
  [GemFunctionState.RandomProf] = ZhString.Gem_Compose3to1Tip,
  [GemFunctionState.CurrentProf] = ZhString.Gem_Compose5to1Tip,
  [GemFunctionState.SameName] = ZhString.Gem_ComposeSameNameTip,
  [GemFunctionState.Sculpt] = ZhString.Gem_SculptMainTip,
  [GemFunctionState.Smelt] = ZhString.Gem_SmeltTipWithoutTarget
}
GemFunctionCtrl = {
  TargetSelect = {
    [GemFunctionState.Smelt] = true
  },
  MaterialSelect = {
    [GemFunctionState.RandomProf] = true,
    [GemFunctionState.CurrentProf] = true,
    [GemFunctionState.SameName] = true,
    [GemFunctionState.Sculpt] = true
  },
  ComposeCtrl = {
    [GemFunctionState.RandomProf] = true,
    [GemFunctionState.CurrentProf] = true,
    [GemFunctionState.SameName] = true
  },
  SculptCtrl = {
    [GemFunctionState.Sculpt] = true
  },
  SmeltCtrl = {
    [GemFunctionState.Smelt] = true
  }
}
local tempTable, gemProxyIns, tickManager = {}
local smeltQualitiesToShow = {3, 4}

function GemFunctionPage:Init()
  if not gemProxyIns then
    gemProxyIns = GemProxy.Instance
  end
  if not tickManager then
    tickManager = TimeTickManager.Me()
  end
  self:ReLoadPerferb("view/GemFunctionPage")
  self.trans:SetParent(self.container.pageContainer.transform, false)
  for name, _ in pairs(GemFunctionCtrl) do
    self[name] = self:FindGO(name)
  end
  self:AddEvents()
  self:InitData()
  self:InitTabs()
  self:InitRight()
  self:InitLeft()
  self.pageState = GemFunctionState.Default
end

function GemFunctionPage:AddEvents()
  self:AddListenEvt(MyselfEvent.ZenyChange, self.UpdateCostLabelColor)
  self:AddListenEvt(ItemEvent.GemUpdate, self.OnGemUpdate)
  self:AddListenEvt(ItemEvent.ItemUpdate, self.OnItemUpdate)
  self:AddListenEvt(ServiceEvent.ItemGemDataUpdateItemCmd, self.OnGemDataUpdate)
  self:AddListenEvt(GemEvent.ProfessionChanged, self.OnProfessionChanged)
  self:AddListenEvt(GemEvent.ChooseTargetProfession, self.OnChooseTargetProfession)
end

function GemFunctionPage:OnProfessionChanged()
  self.curSkillProfessionFilterPopData = GemProxy.Instance:GetCurNewProfessionFilterData()
  local curProfressionName = GemProxy.Instance:GetCurProfressionName()
  if self.TargetSelect.activeInHierarchy then
    self.professionFilterLab.text = curProfressionName
    self:UpdateTargetSelectList()
  elseif self.MaterialSelect.activeInHierarchy then
    self.curProfessionFilterLab.text = curProfressionName
    self:UpdateMaterialSelectList()
  end
end

function GemFunctionPage:OnChooseTargetProfession(note)
  local classId = note.body
  self.targetProfession = classId
  redlog("---OnChooseTargetProfession : ", self.targetProfession)
  local className = ProfessionProxy.GetProfessionName(self.targetProfession, MyselfProxy.Instance:GetMySex())
  self.targetProfessionLab.text = ZhString.Gem_FixedTargetPro .. " " .. "[c][000000]" .. className .. "[-][/c]"
  self.targetProfessionBg.width = 100 + self.targetProfessionLab.width
  local skillConfig = Table_Class[self.targetProfession]
  IconManager:SetProfessionIcon(skillConfig.icon, self.targetProfessionIcon)
  self:SwitchMultiFunction(self.isMultiActive)
end

function GemFunctionPage:InitData()
  self.curSkillProfessionFilterPopData = {}
  self.selectedMaterialData = {}
  self.multiFunctionMaterialData = {}
  self.sculptCostConfig = GameConfig.Gem.CarveCost[1]
  local funcStateId, param, index = GemProxy.BannedQualityFuncStateId
  if FunctionNpcFunc.Me():CheckSingleFuncForbidState(funcStateId) then
    param = Table_FuncState[funcStateId] and Table_FuncState[funcStateId].Param
    if param then
      for i = 1, #param do
        index = TableUtility.ArrayFindIndex(smeltQualitiesToShow, param[i])
        if 0 < index then
          table.remove(smeltQualitiesToShow, index)
        end
      end
    end
  end
end

function GemFunctionPage:InitTabs()
  self.tabGOs = {}
  self.tabIconSps = {}
  local tabGO, longPress
  for name, state in pairs(GemFunctionState) do
    tabGO = self:FindGO(name .. "Tab")
    if tabGO then
      self:AddClickEvent(tabGO, function(go)
        self:UpdatePageState(state)
      end)
      self.tabGOs[state] = tabGO
      self.tabIconSps[state] = self:FindComponent("Icon", UISprite, tabGO)
      longPress = tabGO:GetComponent(UILongPress)
      
      function longPress.pressEvent(obj, pressState)
        self:PassEvent(TipLongPressEvent.GemFunctionPage, {pressState, state})
      end
    end
  end
  self:AddEventListener(TipLongPressEvent.GemFunctionPage, self.OnTabLongPress, self)
end

local skipAnimTipOffset = {90, -75}

function GemFunctionPage:InitRight()
  self.helpBtn = self:FindGO("HelpBtn")
  local skipBtnSp = self:FindComponent("SkipBtn", UISprite)
  self:AddClickEvent(skipBtnSp.gameObject, function()
    TipManager.Instance:ShowSkipAnimationTip(SKIPTYPE.GemFunction, skipBtnSp, NGUIUtil.AnchorSide.Right, skipAnimTipOffset)
  end)
  self.titleLabel = self:FindComponent("TitleLabel", UILabel)
  self.effectContainer = self:FindGO("EffectContainer")
  self.needGemSps = {}
  local needGemGO
  for i = 1, 3 do
    needGemGO = self:FindGO("NeedGem" .. i)
    self.needGemSps[i] = self:FindComponent("IconSprite", UISprite, needGemGO)
    self:AddClickEvent(needGemGO, function()
      self:OnClickNeedGem(i)
    end)
  end
end

function GemFunctionPage:InitLeft()
  self:InitMaterialSelect()
  self:InitTargetSelect()
  self.normalStick = self:FindComponent("NormalStick", UIWidget)
end

function GemFunctionPage:InitSkillQualityFilter()
  local obsoleteSkillClassFilterPopObj = self:FindGO("SkillClassFilterPop")
  if obsoleteSkillClassFilterPopObj then
    self:Hide(obsoleteSkillClassFilterPopObj)
  end
  self.curSkillClassFilterPopData = 0
  local qualityTabRoot = self:FindGO("FunctionSkillQualityTabRoot")
  self:Show(qualityTabRoot)
  for togName, tableData in pairs(GemProxy.QualityTogs) do
    self[togName] = self:FindGO(togName, qualityTabRoot)
    self[togName .. "lab1"] = self:FindComponent("Label1", UILabel, self[togName])
    self[togName .. "lab1"].text = tableData.value
    self[togName .. "lab2"] = self:FindComponent("Label2", UILabel, self[togName])
    self[togName .. "lab2"].text = tableData.value
    self:AddClickEvent(self[togName], function()
      local key = GemProxy.QualityTogs[togName].key
      if self.curSkillClassFilterPopData == key then
        return
      end
      self.curSkillClassFilterPopData = key
      self:UpdateMaterialSelectList()
    end)
  end
end

function GemFunctionPage:InitProfessionFilter()
  local obsoleteSkillProfessionFilterPop = self:FindGO("SkillProfessionFilterPop")
  if obsoleteSkillProfessionFilterPop then
    self:Hide(obsoleteSkillProfessionFilterPop)
  end
  self.professionTipStick = self:FindComponent("FunctionProfessionTipStick", UIWidget)
  self.curProfessionFilterLab = self:FindComponent("FunctionCurProfessionFilterLab", UILabel)
  self:AddClickEvent(self.curProfessionFilterLab.gameObject, function()
    TipManager.Instance:SetGemProfessionTip(NewGemSkillProfessionData, self.professionTipStick)
  end)
end

function GemFunctionPage:InitMaterialSelect()
  self:InitSkillQualityFilter()
  self:InitProfessionFilter()
  self.materialFilterParent = self:FindGO("FilterCtrl", self.MaterialSelect)
  self.materialContainer = self:FindGO("ItemContainer", self.MaterialSelect)
  self.materialSelectCtrl = WrapListCtrl.new(self.materialContainer, GemCell, "GemCell", WrapListCtrl_Dir.Vertical, 5, 100, true)
  self.materialSelectCtrl:AddEventListener(MouseEvent.MouseClick, self.OnClickMaterialSelectCell, self)
  self.materialSelectCtrl:AddEventListener(MouseEvent.LongPress, self.OnLongPressMaterialSelectCell, self)
  self.materialSelectCtrl:AddEventListener(ItemEvent.GemDelete, self.OnGemDelete, self)
  self.materialSelectCells = self.materialSelectCtrl:GetCells()
  for _, cell in pairs(self.materialSelectCells) do
    cell:SetShowDeleteIcon(true)
    cell:SetMultiSelectStyle(GemCell.MultiSelectStyle.HideSelectedCount)
  end
end

function GemFunctionPage:InitTargetProfessionFilter()
  local targetProfessionFilterPop = self:FindGO("TargetProfessionFilterPop")
  if targetProfessionFilterPop then
    self:Hide(targetProfessionFilterPop)
  end
  self.targetProfessionTipStick = self:FindComponent("ProfessionTipStick", UIWidget)
  self.professionFilterLab = self:FindComponent("ProfessionFilterLab", UILabel)
  self:AddClickEvent(self.professionFilterLab.gameObject, function()
    TipManager.Instance:SetGemProfessionTip(NewGemSkillProfessionData, self.targetProfessionTipStick)
  end)
end

function GemFunctionPage:InitTargetSelect()
  self:InitTargetProfessionFilter()
  self.targetContainer = self:FindGO("TargetContainer", self.TargetSelect)
  self.targetSelectCtrl = WrapListCtrl.new(self.targetContainer, GemExhibitChooseCell, "GemExhibitChooseCell", WrapListCtrl_Dir.Vertical)
  self.targetSelectCtrl:AddEventListener(MouseEvent.MouseClick, self.OnClickExhibitChooseCell, self)
  self.targetSelectCtrl:AddEventListener(GemExhibitChooseCellEvent.ClickGem, self.OnClickExhibitChooseGem, self)
  self.targetSelectCells = self.targetSelectCtrl:GetCells()
  self.targetExhibitTip = ItemTipGemExhibitCell.new(self:FindGO("ExhibitTipContainer"))
  for _, cell in pairs(self.targetSelectCells) do
    self.targetExhibitTip:AddCloseCompTarget(cell)
  end
end

function GemFunctionPage:OnActivate()
  self.targetExhibitTip:SetActive(false)
  self:UpdatePageState(self.pageState)
end

function GemFunctionPage:OnDeactivate()
  TipManager.CloseTip()
end

function GemFunctionPage:OnExit()
  tickManager:ClearTick(self)
  if self.curMaterialCombineCell then
    self.curMaterialCombineCell:OnCellDestroy()
  end
  GemFunctionPage.super.OnExit(self)
end

function GemFunctionPage:OnClickFakeGemCell()
  self.MaterialSelect:SetActive(false)
  self.TargetSelect:SetActive(true)
  self:UpdateTargetSelectList()
end

function GemFunctionPage:OnClickMaterialCell(cellCtl)
  if self.pageState == GemFunctionState.Smelt and not self.targetGemStaticId then
    MsgManager.FloatMsg(nil, ZhString.Gem_SmeltNoTargetCellTip)
    return
  end
  if self.isWorking then
    return
  end
  self.TargetSelect:SetActive(false)
  self.MaterialSelect:SetActive(true)
  local data = cellCtl.data
  TableUtility.ArrayRemoveByPredicate(self.selectedMaterialData, function(item)
    return BagItemCell.CheckData(data) and data.id == item.id
  end)
  self:UpdateSelectedMaterial()
  self:UpdateMaterialSelectList(true)
end

function GemFunctionPage:OnClickMultiFunctionCell(cellCtl)
  if self.pageState == GemFunctionState.Smelt and not self.targetGemStaticId then
    MsgManager.FloatMsg(nil, ZhString.Gem_SmeltNoTargetCellTip)
    return
  end
  if self.isWorking then
    return
  end
  self.TargetSelect:SetActive(false)
  self.MaterialSelect:SetActive(true)
  local index = cellCtl.indexInTable
  if index then
    self.multiFunctionMaterialData[index] = nil
  else
    LogUtility.Error("Cannot get indexInTable of GemCell")
    return
  end
  self.chooseMultiFunctionCellIndex = index
  self.multiFunctionMaterialData[index] = nil
  self:UpdateMultiFunctionMaterial()
  self:UpdateMaterialSelectList(true)
  cellCtl.chooseSymbol:SetActive(true)
end

function GemFunctionPage:OnClickExhibitChooseCell(cellCtl)
  local data = cellCtl and cellCtl.data
  self.TargetSelect:SetActive(false)
  self:SetItemToSmelt(data)
  self.targetExhibitTip:SetActive(false)
  self.MaterialSelect:SetActive(true)
  self:UpdateMaterialSelectList()
end

function GemFunctionPage:OnClickExhibitChooseGem(cellCtl)
  local data = cellCtl and cellCtl.data
  if not data then
    return
  end
  self.targetExhibitTip:SetActive(true)
  self.targetExhibitTip:SetData(data)
end

function GemFunctionPage:OnClickNeedGem(index)
  self.selectedSculpt = index
  self.chooseSymbol:SetActive(index ~= nil and 0 < index)
  if self.chooseSymbol.activeSelf then
    self.chooseSymbol.transform.position = LuaGeometry.GetTempVector3(LuaGameObject.GetPosition(self.needGemSps[index].transform))
  end
end

function GemFunctionPage:OnClickMaterialSelectCell(cellCtl)
  if self.isWorking then
    return
  end
  if self.isClickOnMaterialSelectCtrlDisabled then
    self.isClickOnMaterialSelectCtrlDisabled = nil
    return
  end
  if cellCtl:CheckDataIsNilOrEmpty() then
    return
  end
  local data = cellCtl and cellCtl.data
  for _, cell in pairs(self.materialSelectCells) do
    cell:SetChoose(data and data.id or 0)
  end
  if self.pageState == GemFunctionState.Sculpt then
    self:SetItemToSculpt(data)
    TipManager.CloseTip()
  elseif self.pageState == GemFunctionState.Smelt then
    if data.staticData.id == self.targetGemStaticId then
      MsgManager.ConfirmMsgByID(36012, function()
        self:_OnClickMaterialSelectCell(cellCtl)
      end)
    else
      self:_OnClickMaterialSelectCell(cellCtl)
    end
  else
    self:_OnClickMaterialSelectCell(cellCtl)
  end
  cellCtl:TryClearNewTag()
end

function GemFunctionPage:_OnClickMaterialSelectCell(cellCtl)
  local data = cellCtl and cellCtl.data
  if data.num > cellCtl.selectedCount then
    local cloneData = data:Clone()
    cloneData:SetItemNum(1)
    cloneData.gemSkillData = data.gemSkillData
    if self.curMultiFunctionGO.activeSelf and self.chooseMultiFunctionCellIndex then
      self.multiFunctionMaterialData[self.chooseMultiFunctionCellIndex] = cloneData
      self:UpdateMultiFunctionMaterial()
      self:SetMultiFunctionCellChooseToFirstEmpty()
      self:UpdateMaterialSelectList(true)
    elseif #self.selectedMaterialData < self.maxMaterialCount then
      TableUtility.ArrayPushBack(self.selectedMaterialData, cloneData)
      self:UpdateSelectedMaterial()
      self:UpdateMaterialSelectList(true)
    end
  end
end

function GemFunctionPage:OnLongPressMaterialSelectCell(param)
  local isPressing, cellCtl = param[1], param[2]
  if isPressing and cellCtl then
    self:ShowGemTip(cellCtl.gameObject, cellCtl.data)
    self.isClickOnMaterialSelectCtrlDisabled = true
  end
end

function GemFunctionPage:OnTabLongPress(param)
  local isPressing, state = param[1], param[2]
  TabNameTip.OnLongPress(isPressing, GemFunctionTitle[state], false, self.tabIconSps[state])
end

function GemFunctionPage:OnGemDelete(cellCtl)
  if self.curMultiFunctionGO.activeSelf then
    TableUtility.TableRemoveByPredicate(self.multiFunctionMaterialData, function(index, item)
      return not cellCtl:CheckDataIsNilOrEmpty() and cellCtl.data.id == item.id
    end)
    self:UpdateMultiFunctionMaterial()
    if self.chooseMultiFunctionCellIndex then
      self:SetMultiFunctionCellChoose(self.chooseMultiFunctionCellIndex)
    else
      self:SetMultiFunctionCellChooseToFirstEmpty()
    end
    self:UpdateMaterialSelectList(true)
  else
    self:OnClickMaterialCell(cellCtl)
  end
end

function GemFunctionPage:OnGemUpdate()
  if not self.gameObject.activeInHierarchy then
    return
  end
  if self.pageState == GemFunctionState.Sculpt then
    TipManager.CloseTip()
    self:UpdateMaterialSelectList(true)
    if self.targetCell.data then
      local guid = self.targetCell.data.id
      local newTarget = BagProxy.Instance:GetItemByGuid(guid, SceneItem_pb.EPACKTYPE_GEM_SKILL)
      self:SetItemToSculpt(newTarget)
    end
    return
  end
  if self.curMultiFunctionGO.activeSelf then
    local data, realData, index, isArranged
    for i = 1, self:GetMaxMultiFunctionCellCount() do
      data = self.multiFunctionMaterialData[i]
      if data then
        realData = BagProxy.Instance:GetItemByGuid(data.id, SceneItem_pb.EPACKTYPE_GEM_SKILL)
        if not realData or GemProxy.CheckIsFavorite(realData) then
          self.multiFunctionMaterialData[i] = nil
        end
      end
    end
    TableUtility.TableClear(tempTable)
    for i = 1, self:GetMaxMultiFunctionCellCount() do
      data = self.multiFunctionMaterialData[i]
      if data then
        TableUtility.ArrayPushBack(tempTable, data)
      end
    end
    TableUtility.TableClear(self.multiFunctionMaterialData)
    if self.pageState == GemFunctionState.SameName then
      local arrangedRowCount = 0
      for i = 1, #tempTable do
        data = tempTable[i]
        isArranged = false
        for j = 1, arrangedRowCount do
          if GemProxy.CheckIsSameName(data, self.multiFunctionMaterialData[self.maxMaterialCount * (j - 1) + 1]) then
            for k = 2, self.maxMaterialCount do
              index = self.maxMaterialCount * (j - 1) + k
              if not self.multiFunctionMaterialData[index] then
                self.multiFunctionMaterialData[index] = data
                isArranged = true
                break
              end
            end
          end
          if isArranged then
            break
          end
        end
        if not isArranged then
          if arrangedRowCount < GemProxy.MultiComposeRowCount then
            self.multiFunctionMaterialData[self.maxMaterialCount * arrangedRowCount + 1] = data
            arrangedRowCount = arrangedRowCount + 1
          else
            break
          end
        end
      end
    else
      TableUtility.ArrayShallowCopy(self.multiFunctionMaterialData, tempTable)
    end
    self:UpdateMultiFunctionMaterial()
    self:SetMultiFunctionCellChooseToFirstEmpty()
  else
    TableUtility.ArrayClear(self.selectedMaterialData)
    self:UpdateSelectedMaterial()
  end
  self:UpdateMaterialSelectList()
end

function GemFunctionPage:OnItemUpdate()
  if not self.gameObject.activeInHierarchy then
    return
  end
  self:UpdateSculptCost()
end

function GemFunctionPage:OnGemDataUpdate(note)
  if not self.gameObject.activeInHierarchy then
    return
  end
  TipManager.CloseTip()
  self.targetExhibitTip:SetActive(false)
  gemProxyIns:ShowNewGemResults(note.body and note.body.items)
end

function GemFunctionPage:UpdatePageState(state)
  if state then
    self.pageState = state
  end
  if not self.pageState then
    return
  end
  TableUtility.TableClear(self.selectedMaterialData)
  TableUtility.TableClear(self.multiFunctionMaterialData)
  self.titleLabel.text = GemFunctionTitle[self.pageState]
  self.materialFilterParent:SetActive(self.pageState ~= GemFunctionState.Smelt)
  self:SetCurrentTabIconColor()
  for name, cfg in pairs(GemFunctionCtrl) do
    if cfg[self.pageState] then
      self[name]:SetActive(true)
      if string.find(name, "Ctrl") then
        self.curCtrl = self[name]
      end
    else
      self[name]:SetActive(false)
    end
  end
  self.helpId = GemFunctionHelpId[self.pageState]
  self:TryOpenHelpViewById(self.helpId, nil, self.helpBtn)
  self.mainLabel = self:FindComponent("MainLabel", UILabel, self.curCtrl)
  self.mainLabel.text = GemFunctionMainLabel[self.pageState]
  self.costGO = self:FindGO("Cost", self.curCtrl)
  self.costLabel = self:FindComponent("CostLabel", UILabel, self.costGO)
  self.sculptWorkbench = self:FindGO("SculptWorkbench", self.curCtrl)
  self.chooseSymbol = self.sculptWorkbench and self:FindGO("ChooseSymbol", self.sculptWorkbench)
  self:SetFunctionBtnActive()
  self.curSkillProfessionFilterPopData = GemProxy.Instance:GetCurNewProfessionFilterData()
  local curProfressionName = GemProxy.Instance:GetCurProfressionName()
  if self.TargetSelect.activeInHierarchy then
    self.professionFilterLab.text = curProfressionName
    self:UpdateTargetSelectList()
  elseif self.MaterialSelect.activeInHierarchy then
    self.curProfessionFilterLab.text = curProfressionName
    self:UpdateMaterialSelectList()
  end
  self:ResetCurCtrl()
end

function GemFunctionPage:ResetCurCtrl()
  self:ResetTargetCell()
  self:ResetRightMaterialGO()
  local exEffectName = self.effectName
  self.effectName = self.pageState == GemFunctionState.SameName and EffectMap.UI.GemViewReset or EffectMap.UI.GemViewSynthetic
  if exEffectName ~= self.effectName then
    if self.backEffect then
      self.backEffect:Stop()
    end
    if self.foreEffect then
      self.foreEffect:Stop()
    end
    self:PlayUIEffect(self.effectName, self.effectContainer, false, function(obj, args, assetEffect)
      self.backEffect = assetEffect
      self.backEffect:ResetAction("ronghe_1", 0, true)
    end)
  elseif self.backEffect then
    self.backEffect:ResetAction("ronghe_1", 0, true)
  end
end

function GemFunctionPage:ResetTargetCell()
  self.targetCellGO = self:FindGO("TargetCell", self.curCtrl)
  self.fakeGemCell = self:FindGO("FakeGemCell", self.curCtrl)
  if not self.targetCellGO then
    self.targetCell = nil
    return
  end
  if self.fakeGemCell then
    self.fakeGemCellBgSp = self:FindComponent("GemBg", UISprite, self.fakeGemCell)
    self.fakeGemCellSp = self:FindComponent("GemIcon", UISprite, self.fakeGemCell)
    self.fakeGemCellQualitySp = self:FindComponent("GemQuality", UISprite, self.fakeGemCell)
    self.fakeGemCellNameLabel = self:FindComponent("GemMicroNameLabel", UILabel, self.fakeGemCell)
    self:AddClickEvent(self.targetCellGO, function()
      self:OnClickFakeGemCell()
    end)
  else
    local c = self:FindGO("GemCell", self.targetCellGO)
    if not c then
      self:LoadPreferb_ByFullPath(ResourcePathHelper.UICell("GemCell"), self.targetCellGO)
    end
    self.targetCell = GemCell.new(self.targetCellGO)
    self.targetCell:SetData()
    self.targetCell:SetShowBagSlot(true)
    self.targetCell:SetShowNewTag(false)
    self.targetCell:SetShowEmbeddedTip(false)
  end
  self.gemLabel = self:FindComponent("GemLabel", UILabel, self.curCtrl)
end

function GemFunctionPage:ResetRightMaterialGO()
  local material3GO = self:FindGO("3Material", self.curCtrl)
  local material5GO = self:FindGO("5Material", self.curCtrl)
  self.material5GO_TargetRoot = self:FindGO("5ProfessionTargetRoot")
  self.targetProfessionLab = self:FindComponent("TargetProfessionLab", UILabel, self.material5GO_TargetRoot)
  self.targetProfessionBg = self:FindComponent("Bg", UISprite, self.targetProfessionLab.gameObject)
  self.targetProfessionIcon = self:FindComponent("TargetSkillIcon", UISprite, self.material5GO_TargetRoot)
  self.targetProfessionColider = self:FindComponent("TargetSkillIconColider", UISprite, self.material5GO_TargetRoot)
  self.targetProfessionStick = self:FindComponent("TargetProfessionTipStick", UIWidget)
  self:AddClickEvent(self.targetProfessionColider.gameObject, function()
    GemProxy.Instance:SetTargetProChooseFlag()
    TipManager.Instance:SetGemProfessionTip(NewGemSkillProfessionData, self.targetProfessionStick)
  end)
  local multiFunction3GO = self:FindGO("3MultiFunctionPanel", self.curCtrl)
  local multiFunction5GO = self:FindGO("5MultiFunctionPanel", self.curCtrl)
  if material3GO then
    material3GO:SetActive(false)
    multiFunction3GO:SetActive(false)
  end
  if material5GO then
    material5GO:SetActive(false)
    multiFunction5GO:SetActive(false)
  end
  local isCurrentProf = self.pageState == GemFunctionState.CurrentProf
  if isCurrentProf then
    self.curMaterialGO = material5GO
    self.targetProfession = GemProxy.Instance:GetMyFirstProfession()
    GemProxy.Instance:SetCurTargetProfession(self.targetProfession)
    if self.targetProfession then
      local className = ProfessionProxy.GetProfessionName(self.targetProfession, MyselfProxy.Instance:GetMySex())
      self.targetProfessionLab.text = ZhString.Gem_FixedTargetPro .. " " .. "[c][000000]" .. className .. "[-][/c]"
      local skillConfig = Table_Class[self.targetProfession]
      self:Show(self.targetProfessionIcon)
      IconManager:SetProfessionIcon(skillConfig.icon, self.targetProfessionIcon)
    else
      self:Hide(self.targetProfessionIcon)
      self.targetProfessionLab.text = ZhString.Gem_FixedTargetPro .. " " .. ZhString.GemTodoTargetProfession
    end
    self.targetProfessionBg.width = 100 + self.targetProfessionLab.width
    self.curMultiFunctionGO = multiFunction5GO
  else
    self.curMaterialGO = material3GO
    self.curMultiFunctionGO = multiFunction3GO
  end
  local curMaterialCellName = isCurrentProf and "GemCombine5Cell" or "GemCombine3Cell"
  self.maxMaterialCount = isCurrentProf and 5 or 3
  if self.curMaterialGO then
    local curMaterialCellObj = self:FindGO(curMaterialCellName, self.curMaterialGO)
    if curMaterialCellObj then
      GameObject.DestroyImmediate(curMaterialCellObj)
    end
    curMaterialCellObj = self:LoadPreferb("cell/" .. curMaterialCellName, self:FindGO("MaterialPanel", self.curMaterialGO))
    self.curMaterialCombineCell = _G[curMaterialCellName].new(curMaterialCellObj)
    self.curMaterialCombineCell:AddEventListener(MouseEvent.MouseClick, self.OnClickMaterialCell, self)
    self.curMaterialCombineCell:AddEventListener(ItemEvent.GemDelete, self.OnClickMaterialCell, self)
    self:AddClickEvent(self:FindGO("ExpandBtn", self.curMaterialGO), function()
      self:SwitchMultiFunction(true)
    end)
  end
  if self.curMultiFunctionGO then
    self:AddClickEvent(self:FindGO("ShrinkBtn", self.curMultiFunctionGO), function()
      self:SwitchMultiFunction(false)
    end)
    local multiFunctionTable = self:FindComponent("Table", UITable, self.curMultiFunctionGO)
    GameObjectUtil.Instance:DestroyAllChildren(multiFunctionTable.gameObject)
    self.multiFunctionScrollView = multiFunctionTable.transform.parent:GetComponent(UIScrollView)
    self.curMultiFunctionListCtrl = UIGridListCtrl.new(multiFunctionTable, _G[curMaterialCellName], curMaterialCellName)
    self.curMultiFunctionListCtrl:AddEventListener(MouseEvent.MouseClick, self.OnClickMultiFunctionCell, self)
    self.curMultiFunctionListCtrl:AddEventListener(ItemEvent.GemDelete, self.OnClickMultiFunctionCell, self)
    self:SwitchMultiFunction(false)
  end
  if self.pageState == GemFunctionState.Sculpt then
    self:SetItemToSculpt()
  elseif self.pageState == GemFunctionState.Smelt then
    self:SetItemToSmelt()
  end
end

local targetSelectComparer = function(l, r)
  if l.Quality ~= r.Quality then
    return l.Quality > r.Quality
  end
  return l.id < r.id
end

function GemFunctionPage:UpdateTargetSelectList()
  local staticDataArr = ReusableTable.CreateArray()
  local p = GemProxy.Instance:GetCurNewProfessionFilterData()
  local isProfessionFilterExist = p and type(p) == "table" and next(p)
  for _, data in pairs(Table_GemRate) do
    if TableUtility.ArrayFindIndex(smeltQualitiesToShow, data.Quality) > 0 and (not isProfessionFilterExist or gemProxyIns:CheckIfSkillGemHasSameProfessions(data.id, p)) then
      TableUtility.ArrayPushBack(staticDataArr, data)
    end
  end
  table.sort(staticDataArr, targetSelectComparer)
  self.targetSelectCtrl:ResetDatas(staticDataArr, true)
  ReusableTable.DestroyAndClearArray(staticDataArr)
end

local materialSelectComparer = function(l, r)
  local comp1 = GemProxy.PredicateComparer(l, r, GemProxy.CheckIsFavorite)
  if comp1 ~= nil then
    return comp1
  end
  local comp2 = GemProxy.PredicateComparer(l, r, GemProxy.CheckIsEmbedded)
  if comp2 ~= nil then
    return comp2
  end
  return GemProxy.BasicComparer(l, r)
end

function GemFunctionPage:UpdateMaterialSelectList(noResetPos)
  local gems
  if self.pageState == GemFunctionState.Smelt then
    if not self.MaterialSelect.activeSelf then
      return
    end
    if not self.targetGemStaticId then
      LogUtility.Error("Cannot get materials when targetGem is nil")
      return
    end
    gems = GemProxy.GetSkillItemDataByQualityAndProfession(smeltQualitiesToShow, Table_GemRate[self.targetGemStaticId].ClassType)
  else
    gems = GemProxy.GetSkillItemDataByFilterDatasOfView(self)
  end
  if self.pageState ~= GemFunctionState.Sculpt then
    GemProxy.RemoveEmbedded(gems)
  end
  table.sort(gems, materialSelectComparer)
  self.materialSelectCtrl:ResetDatas(gems, not noResetPos)
end

function GemFunctionPage:UpdateSelectedMaterial()
  if self.pageState == GemFunctionState.Sculpt then
    return
  end
  self.targetExhibitTip:SetActive(false)
  TableUtility.TableClear(tempTable)
  TableUtility.ArrayShallowCopy(tempTable, self.selectedMaterialData)
  for i = #self.selectedMaterialData + 1, self.maxMaterialCount do
    TableUtility.ArrayPushBack(tempTable, BagItemEmptyType.Empty)
  end
  self.curMaterialCombineCell:SetData(tempTable)
  local cells = self.curMaterialCombineCell:GetCells()
  for _, cell in pairs(cells) do
    cell:SetShowNewTag(false)
    if not cell:CheckDataIsNilOrEmpty() then
      cell:ForceShowDeleteIcon()
    end
  end
  self:CheckFunctionReady()
end

function GemFunctionPage:UpdateMultiFunctionMaterial()
  if self.pageState == GemFunctionState.Sculpt then
    return
  end
  TipManager.CloseTip()
  self.targetExhibitTip:SetActive(false)
  self.curMultiFunctionListCtrl:ResetDatas(self:ReUnitMultiFunctionData())
  local combineCells = self.curMultiFunctionListCtrl:GetCells()
  for _, combineCell in pairs(combineCells) do
    combineCell:SetShowNewTag(false)
    combineCell:SetCheckTipEnablePredicate(self:GetCheckTipEnablePredicate())
    combineCell:ForceShowDeleteIcon()
  end
  self:CheckFunctionReady()
end

local costLabelColor = LuaColor.New(0.37254901960784315, 0.37254901960784315, 0.37254901960784315, 1)

function GemFunctionPage:UpdateCostLabelColor()
  if not self.costLabel then
    return
  end
  self.costLabel.color = not self:CheckZeny() and ColorUtil.Red or costLabelColor
end

function GemFunctionPage:UpdateSculptCost()
  if self.pageState ~= GemFunctionState.Sculpt then
    return
  end
  if not self.costGO.activeInHierarchy then
    return
  end
  local costStaticId, costNum = self.sculptCostConfig[1], self.sculptCostConfig[2]
  IconManager:SetItemIcon(Table_Item[costStaticId].Icon, self:FindComponent("Sprite", UISprite, self.costGO))
  local realNum = BagProxy.Instance:GetItemNumByStaticID(costStaticId) or 0
  self.costLabel.text = string.format(ZhString.Gem_CountLabelFormat, realNum, costNum)
  self.costLabel.color = costNum > realNum and ColorUtil.Red or costLabelColor
end

local multiComposeClickDisablePredicate = function(gemCell, self)
  if GemProxy.CheckIsFavorite(gemCell.data) then
    return true
  end
  if gemCell.selectedCount > 0 then
    return false
  end
  local flag
  if self.pageState ~= GemFunctionState.SameName then
    local _, compareData = next(self.multiFunctionMaterialData)
    flag = gemCell.data and compareData and gemProxyIns:GetSkillQualityGroupFromItemData(gemCell.data) ~= gemProxyIns:GetSkillQualityGroupFromItemData(compareData)
    if self.pageState == GemFunctionState.CurrentProf and not flag and self.targetProfession and ProfessionProxy.IsHero(self.targetProfession) then
      local quality = GemProxy.GetSkillQualityFromItemData(gemCell.data)
      if quality == 1 or quality == 2 then
        flag = true
      end
    end
  end
  return flag
end
local singleComposeClickDisablePredicate = function(gemCell, self)
  if GemProxy.CheckIsFavorite(gemCell.data) then
    return true
  end
  if gemCell.selectedCount > 0 then
    return false
  end
  local flag
  if self.pageState == GemFunctionState.SameName then
    flag = gemCell.data and gemCell.selectedCount == 0 and 0 < #self.selectedMaterialData and gemCell.data.staticData.id ~= self.selectedMaterialData[1].staticData.id
  else
    flag = gemCell.data and 0 < #self.selectedMaterialData and gemProxyIns:GetSkillQualityGroupFromItemData(gemCell.data) ~= gemProxyIns:GetSkillQualityGroupFromItemData(self.selectedMaterialData[1])
    if self.pageState == GemFunctionState.CurrentProf and not flag and self.targetProfession and ProfessionProxy.IsHero(self.targetProfession) then
      local quality = GemProxy.GetSkillQualityFromItemData(gemCell.data)
      if quality == 1 or quality == 2 then
        flag = true
      end
    end
  end
  return flag
end
local smeltClickDisablePredicate = function(gemCell, self)
  if GemProxy.CheckIsFavorite(gemCell.data) then
    return true
  end
  if gemCell.selectedCount > 0 then
    return false
  end
  local isDifferentGroup = gemCell.data and self.targetGemStaticId and gemProxyIns:GetSkillQualityGroupFromItemData(gemCell.data) ~= gemProxyIns:GetSkillQualityGroupByStaticId(self.targetGemStaticId)
  return isDifferentGroup
end

function GemFunctionPage:SwitchMultiFunction(isMultiActive)
  self.isMultiActive = isMultiActive or false
  self.curMultiFunctionGO:SetActive(self.isMultiActive)
  self.material5GO_TargetRoot:SetActive(self.pageState == GemFunctionState.CurrentProf)
  self.curMaterialGO:SetActive(not self.isMultiActive)
  if self.isMultiActive then
    for _, cell in pairs(self.materialSelectCells) do
      cell:SetMultiSelectModel(self.multiFunctionMaterialData)
      cell:SetClickDisablePredicate(self.pageState == GemFunctionState.Smelt and smeltClickDisablePredicate or multiComposeClickDisablePredicate, self)
    end
    TableUtility.TableClear(self.multiFunctionMaterialData)
    for i = 1, self.maxMaterialCount do
      self.multiFunctionMaterialData[i] = self.selectedMaterialData[i]
    end
    self:UpdateMultiFunctionMaterial()
    self:SetMultiFunctionCellChooseToFirstEmpty()
    TableUtility.ArrayClear(self.selectedMaterialData)
  else
    self:SetCost(GemFunctionCostZeny[self.pageState])
    for _, cell in pairs(self.materialSelectCells) do
      cell:SetMultiSelectModel(self.selectedMaterialData)
      cell:SetClickDisablePredicate(self.pageState == GemFunctionState.Smelt and smeltClickDisablePredicate or singleComposeClickDisablePredicate, self)
    end
    TableUtility.ArrayClear(self.selectedMaterialData)
    for i = 1, self.maxMaterialCount do
      if self.multiFunctionMaterialData[i] then
        TableUtility.ArrayPushBack(self.selectedMaterialData, self.multiFunctionMaterialData[i])
      end
    end
    self:UpdateSelectedMaterial()
    TableUtility.TableClear(self.multiFunctionMaterialData)
  end
  self:UpdateMaterialSelectList()
end

function GemFunctionPage:TryPlayEffectThenCall(func)
  self.isWorking = true
  local delayedTime = 1000
  if LocalSaveProxy.Instance:GetSkipAnimation(SKIPTYPE.GemFunction) then
    func(self)
  else
    self:PlayUISound(AudioMap.UI.Gem)
    if self.foreEffect then
      self.foreEffect:Stop()
    end
    local actionName = "ronghe_2"
    self:PlayUIEffect(self.effectName, self.effectContainer, true, function(obj, args, assetEffect)
      self.foreEffect = assetEffect
      self.foreEffect:ResetAction(actionName, 0, true)
    end)
    if self.backEffect then
      self.backEffect:ResetAction(actionName, 0, true)
    end
    delayedTime = 4000
    tickManager:CreateOnceDelayTick(delayedTime, func, self, 1)
  end
  self:SetFunctionBtnActive(false)
  tickManager:CreateOnceDelayTick(delayedTime + 800, self.RestoreAfterAction, self, 2)
end

function GemFunctionPage:RestoreAfterAction()
  self.isWorking = nil
  if self.pageState == GemFunctionState.Sculpt then
    self:SetFunctionBtnActive(true)
  else
    self:CheckFunctionReady()
  end
end

function GemFunctionPage:TryUpdateComposeMainLabel(isReady)
  if self.curMultiFunctionGO.activeSelf then
    return
  end
  if self.pageState == GemFunctionState.SameName then
    self.mainLabel.text = isReady and self.selectedMaterialData[1] and self.selectedMaterialData[1]:GetName() or GemFunctionMainLabel[self.pageState]
  elseif self.pageState == GemFunctionState.RandomProf then
    local quality, weight = GemProxy.GetMaxQualityWeightOf3to1Compose(self.selectedMaterialData)
    self.mainLabel.text = isReady and quality and weight and string.format(ZhString.Gem_QualityComposeTip, quality, weight) or GemFunctionMainLabel[self.pageState]
  elseif self.pageState == GemFunctionState.CurrentProf then
    local quality, weight = GemProxy.GetMaxQualityWeightOf5to1Compose(self.selectedMaterialData)
    self.mainLabel.text = isReady and quality and weight and string.format(ZhString.Gem_QualityComposeTip, quality, weight) or GemFunctionMainLabel[self.pageState]
  end
end

local gemFunctionStateKeyMap = {}

function GemFunctionPage:TryDoFunction()
  if not self.isFunctionBtnActive then
    return
  end
  if not next(gemFunctionStateKeyMap) then
    for k, v in pairs(GemFunctionState) do
      if k ~= "Default" then
        gemFunctionStateKeyMap[v] = k
      end
    end
  end
  local stateKey = gemFunctionStateKeyMap[self.pageState]
  if stateKey and self[stateKey] then
    self[stateKey](self)
  end
end

function GemFunctionPage:RandomProf()
  if self:CheckMaterial4S() and ProfessionProxy.GetJobDepth(MyselfProxy.Instance:GetMyProfession()) ~= 5 then
    MsgManager.ShowMsgByID(36013)
    return
  end
  self:Compose(function(data)
    GemProxy.CallSkill3to1Compose(data)
  end)
end

function GemFunctionPage:CurrentProf()
  if not gemProxyIns:CheckIsMyProfessionAvailable() then
    MsgManager.ShowMsgByID(36007)
    return
  end
  if self:CheckMaterial4S() then
    local myProf = MyselfProxy.Instance:GetMyProfession()
    if ProfessionProxy.GetJobDepth(myProf) == 5 then
      if not gemProxyIns:GetAllGemIdsBySkillQualityGroupAndProfession(2, myProf) then
        MsgManager.ShowMsgByID(36014)
        return
      end
    else
      MsgManager.ShowMsgByID(36013)
      return
    end
  end
  local pro = self.targetProfession
  if not pro then
    return
  end
  local remainder = pro % 10
  if remainder ~= 5 then
    pro = pro - remainder + 5
  end
  self:Compose(function(data)
    GemProxy.CallSkill5to1Compose(data, pro)
  end)
end

function GemFunctionPage:SameName()
  self:Compose(function(data)
    GemProxy.CallSkillSameNameCompose(data)
  end)
end

function GemFunctionPage:Compose(callFunc)
  if not callFunc or not self:CheckZeny() then
    MsgManager.ShowMsgByID(1)
    return
  end
  FunctionSecurity.Me():NormalOperation(function(self)
    self:TryPlayEffectThenCall(function(self)
      callFunc(self.curMultiFunctionGO.activeSelf and self.multiFunctionMaterialData or self.selectedMaterialData)
      self.isWorking = nil
    end)
  end, self)
end

function GemFunctionPage:Sculpt()
  local itemData = self.targetCell.data
  if not itemData then
    MsgManager.FloatMsg(nil, ZhString.Gem_SculptNoTargetCellTip)
    return
  end
  local skillData = itemData.gemSkillData
  if not skillData or not next(skillData) then
    LogUtility.Error("Cannot sculpt gem while skillData is nil")
    return
  end
  if GemProxy.CheckSkillDataIsSculpted(skillData) then
    local sculptData = skillData:GetSculptData()
    MsgManager.ConfirmMsgByID(36009, function()
      if GemProxy.CheckIsFavorite(itemData) then
        MsgManager.FloatMsg(nil, ZhString.Gem_ResetSculptIsFavoriteTip)
        return
      end
      GemProxy.CallSculpt(itemData.id, sculptData[1].type, sculptData[1].pos, true)
    end)
    return
  end
  if not self.selectedSculpt then
    MsgManager.FloatMsg(nil, ZhString.Gem_SculptNoSelectedSculptTip)
    return
  end
  local realNum = BagProxy.Instance:GetItemNumByStaticID(self.sculptCostConfig[1]) or 0
  if realNum < self.sculptCostConfig[2] then
    MsgManager.ShowMsgByID(3554, Table_Item[self.sculptCostConfig[1]].NameZh)
    return
  end
  if GemProxy.CheckIsFavorite(itemData) then
    MsgManager.FloatMsg(nil, ZhString.Gem_SculptIsFavoriteTip)
    return
  end
  local selectedType = skillData.needAttributeGemTypes[self.selectedSculpt]
  MsgManager.ConfirmMsgByID(36010, function()
    FunctionSecurity.Me():NormalOperation(function(self)
      self:TryPlayEffectThenCall(function(self)
        GemProxy.CallSculpt(itemData.id, selectedType, self.selectedSculpt)
      end)
    end, self)
  end, nil, nil, ZhString["Gem_SkillDescNeedGemType" .. selectedType])
end

function GemFunctionPage:Smelt()
  if not self.targetGemStaticId then
    MsgManager.FloatMsg(nil, ZhString.Gem_SmeltNoTargetCellTip)
    return
  end
  if not self:CheckZeny() then
    MsgManager.ShowMsgByID(1)
    return
  end
  FunctionSecurity.Me():NormalOperation(function(self)
    self:TryPlayEffectThenCall(self._Smelt)
  end, self)
end

function GemFunctionPage:_Smelt()
  GemProxy.CallSmelt(self.targetGemStaticId, self.curMultiFunctionGO.activeSelf and self.multiFunctionMaterialData or self.selectedMaterialData)
  self.isWorking = nil
end

function GemFunctionPage:CheckZeny()
  return MyselfProxy.Instance:GetROB() >= (self.cost or math.huge)
end

function GemFunctionPage:CheckMaterial4S()
  local _, certainMaterial = next(self.curMultiFunctionGO.activeSelf and self.multiFunctionMaterialData or self.selectedMaterialData)
  return certainMaterial and gemProxyIns:GetSkillQualityGroupByStaticId(certainMaterial.staticData.id) == 2 or false
end

function GemFunctionPage:CheckFunctionReady()
  if self.pageState == GemFunctionState.Sculpt then
    return
  end
  local isReady, rowCount = false
  if self.curMultiFunctionGO.activeSelf then
    for _, cell in pairs(self.curMultiFunctionListCtrl:GetCells()) do
      rowCount = rowCount or 0
      if cell:GetCheckTipEnabled() then
        rowCount = rowCount + 1
      end
    end
    if rowCount and 0 < rowCount then
      isReady = true
    end
  else
    isReady = #self.selectedMaterialData == self.maxMaterialCount
    if isReady then
      if self.pageState == GemFunctionState.SameName then
        for i = 2, #self.selectedMaterialData do
          isReady = isReady and GemProxy.CheckIsSameName(self.selectedMaterialData[i], self.selectedMaterialData[1])
        end
      elseif self.pageState == GemFunctionState.CurrentProf then
        isReady = isReady and nil ~= self.targetProfession
      end
    end
  end
  self:TryUpdateComposeMainLabel(isReady)
  self:SetFunctionBtnActive(isReady)
  rowCount = rowCount or isReady and 1 or 0
  self:SetCost(GemFunctionCostZeny[self.pageState] * rowCount)
end

function GemFunctionPage:SetCost(cost)
  self.cost = cost
  self.costLabel.text = cost and StringUtil.NumThousandFormat(cost) or ""
  self:UpdateCostLabelColor()
end

local inactiveTabIconColor, activeTabIconColor = LuaColor.New(0.592156862745098, 0.6862745098039216, 0.9333333333333333, 1), LuaColor.New(0.12549019607843137, 0.4588235294117647, 0.7490196078431373, 1)

function GemFunctionPage:SetCurrentTabIconColor()
  for _, sp in pairs(self.tabIconSps) do
    sp.color = inactiveTabIconColor
  end
  local icon = self:FindComponent("Icon", UISprite, self.tabGOs[self.pageState])
  if icon then
    icon.color = activeTabIconColor
  end
end

function GemFunctionPage:SetFunctionBtnActive(isActive)
  self.isFunctionBtnActive = isActive and true or false
  self.functionBtn = self:FindGO("FunctionBtn", self.curCtrl)
  if isActive then
    self:AddClickEvent(self.functionBtn, function()
      self:TryDoFunction()
    end)
  end
  self.functionBtnBgSp = self.functionBtn:GetComponent(UISprite)
  self.functionBtnBgSp.spriteName = isActive and "com_btn_1" or "com_btn_13"
  self.functionBtnLabel = self:FindComponent("Label", UILabel, self.functionBtn)
  self.functionBtnLabel.effectColor = isActive and ColorUtil.ButtonLabelBlue or ColorUtil.NGUIGray
end

function GemFunctionPage:SetItemToSculpt(data)
  if self.pageState ~= GemFunctionState.Sculpt then
    return
  end
  self.mainLabel.gameObject:SetActive(data == nil)
  self.sculptWorkbench:SetActive(data ~= nil)
  self:SetFunctionBtnActive(data ~= nil)
  self.targetCell:SetData(data)
  if not data then
    return
  end
  self.gemLabel.text = data.staticData.NameZh
  if not GemProxy.CheckContainsGemSkillData(data) then
    LogUtility.Error("Cannot find GemSkillData while updating item to sculpt")
    return
  end
  local needGem, pos = data.gemSkillData.needAttributeGemTypes
  local tempArr = ReusableTable.CreateArray()
  TableUtility.ArrayShallowCopy(tempArr, needGem)
  local isSculpted = GemProxy.CheckSkillDataIsSculpted(data.gemSkillData)
  if isSculpted then
    local sculptData = data.gemSkillData:GetSculptData()
    if next(sculptData) then
      pos = sculptData[1].pos
      tempArr[pos] = 0
    end
  end
  for i = 1, #self.needGemSps do
    self.needGemSps[i].spriteName = GemProxy.SculptNeedGemSpriteNames[tempArr[i]]
    self.needGemSps[i]:MakePixelPerfect()
  end
  self.costGO:SetActive(not isSculpted)
  self:UpdateSculptCost()
  self.functionBtnLabel.text = isSculpted and ZhString.Gem_ResetSculpt or ZhString.Gem_Sculpt
  ReusableTable.DestroyAndClearArray(tempArr)
end

function GemFunctionPage:SetItemToSmelt(data)
  if self.pageState ~= GemFunctionState.Smelt then
    return
  end
  self.mainLabel.text = data == nil and ZhString.Gem_SmeltTipWithoutTarget or ZhString.Gem_SmeltTipWithTarget
  self:SetFunctionBtnActive(data ~= nil)
  local oldTargetGemStaticId = self.targetGemStaticId
  self:SetFakeGemCellData(data)
  if not data then
    return
  end
  if self.targetGemStaticId ~= oldTargetGemStaticId then
    TableUtility.ArrayClear(self.selectedMaterialData)
    self:UpdateSelectedMaterial()
    TableUtility.TableClear(self.multiFunctionMaterialData)
    self:UpdateMultiFunctionMaterial()
  end
end

function GemFunctionPage:SetFakeGemCellData(data)
  self.fakeGemCell:SetActive(data ~= nil)
  self.targetGemStaticId = data and data.id
  local itemStaticData = data and Table_Item[data.id]
  self.gemLabel.text = data and itemStaticData and itemStaticData.NameZh or ""
  if not data then
    return
  end
  local success = IconManager:SetItemIcon(itemStaticData.Icon, self.fakeGemCellSp)
  if success then
    self.fakeGemCellSp:MakePixelPerfect()
  end
  success = IconManager:SetUIIcon(GemCell.SkillBgSpriteNames[data.Quality] or GemCell.AttrBgSpriteName, self.fakeGemCellBgSp)
  if success then
    self.fakeGemCellBgSp:MakePixelPerfect()
  end
  self.fakeGemCellQualitySp.spriteName = GemCell.SkillQualitySpriteNames[data.Quality]
  self.fakeGemCellNameLabel.text = string.sub(itemStaticData.NameZh, 1, 6)
end

function GemFunctionPage:GetMultiFunctionCell(index)
  index = index or 0
  local row, col = GemProxy.GetRowAndColFromIndexAndColumnCount(index, self.maxMaterialCount)
  local combineCells = self.curMultiFunctionListCtrl:GetCells()
  if combineCells and combineCells[row] then
    return combineCells[row]:GetCell(col)
  end
end

function GemFunctionPage:SetMultiFunctionCellChoose(newIndex)
  if not self.curMultiFunctionGO.activeSelf then
    return
  end
  self.chooseMultiFunctionCellIndex = newIndex
  local newChooseCell = self:GetMultiFunctionCell(self.chooseMultiFunctionCellIndex)
  if newChooseCell then
    newChooseCell.chooseSymbol:SetActive(true)
  else
    self.chooseMultiFunctionCellIndex = nil
  end
end

function GemFunctionPage:SetMultiFunctionCellChooseToFirstEmpty()
  if not self.curMultiFunctionGO.activeSelf then
    return
  end
  local newIndex
  for i = 1, self:GetMaxMultiFunctionCellCount() do
    if not self.multiFunctionMaterialData[i] then
      newIndex = i
      break
    end
  end
  if newIndex then
    local row, col = GemProxy.GetRowAndColFromIndexAndColumnCount(newIndex, self.maxMaterialCount)
    self.multiFunctionScrollView:SetDragAmount(0, math.clamp((row - 3) / (GemProxy.MultiComposeRowCount - 3), 0, 1), false)
  end
  self:SetMultiFunctionCellChoose(newIndex)
end

function GemFunctionPage:ShowGemTip(cellGO, data)
  local tip = GemCell.ShowGemTip(cellGO, data, self.normalStick)
  if not tip then
    return
  end
  tip:AddIgnoreBounds(self.materialContainer)
end

function GemFunctionPage:ReUnitMultiFunctionData()
  TableUtility.TableClear(tempTable)
  for i = 1, GemProxy.MultiComposeRowCount do
    for j = 1, self.maxMaterialCount do
      tempTable[i] = tempTable[i] or {}
      tempTable[i][j] = self.multiFunctionMaterialData[self.maxMaterialCount * (i - 1) + j] or BagItemEmptyType.Empty
    end
  end
  return tempTable
end

function GemFunctionPage:GetCheckTipEnablePredicate()
  return self.pageState == GemFunctionState.SameName and GemProxy.CheckComposeDataGroupIsSameName or GemProxy.CheckComposeDataGroup
end

function GemFunctionPage:GetMaxMultiFunctionCellCount()
  return GemProxy.GetMaxMultiFunctionCellCount(self.maxMaterialCount)
end
