autoImport("InheritSkillCostPointCell")
autoImport("InheritSkillDragCell")
autoImport("InheritJobSkillCombineCell")
autoImport("InheritSkillMaterialCell")
autoImport("InheritSkillCostPointAttrCell")
InheritSkillView = class("InheritSkillView", ContainerView)
InheritSkillView.ViewType = UIViewType.NormalLayer
local BgName = "skill_inherit_bg_00"
local SkillBgName = "skill_inherit_bg_04"

function InheritSkillView:Init()
  self:FindObjs()
  self:AddListenEvts()
  self.tipData = {}
  self.tipData.funcConfig = {}
  self.lackMats = {}
end

function InheritSkillView:FindObjs()
  self.bg = self:FindComponent("Bg", UITexture)
  self.skillBg = self:FindComponent("SkillBg", UITexture)
  self.costPointLabel = self:FindComponent("CostPoint", UILabel)
  local grid = self:FindComponent("CostPointGrid", UIGrid)
  self.costPointListCtrl = UIGridListCtrl.new(grid, InheritSkillCostPointCell, "InheritSkillCostPointCell")
  grid = self:FindComponent("EquipSkillGrid", UIGrid)
  self.equipSkillListCtrl = UIGridListCtrl.new(grid, InheritSkillDragCell, "InheritSkillDragCell")
  self.equipSkillListCtrl:AddEventListener(DragDropEvent.SwapObj, self.SwapSkill, self)
  self.equipSkillListCtrl:AddEventListener(DragDropEvent.DropEmpty, self.TakeOffSkill, self)
  self.equipSkillListCtrl:AddEventListener(MouseEvent.MouseClick, self.OnEquipSkillClick, self)
  self.addCostBtn = self:FindGO("AddCostBtn")
  self:AddClickEvent(self.addCostBtn, function()
    self:OnAddCostBtnClick()
  end)
  local gotoBtn = self:FindGO("GotoBtn")
  self:AddClickEvent(gotoBtn, function()
    self:OnGotoBtnClick()
  end)
  self.skillScrollView = self:FindComponent("SkillPanel", UIScrollView)
  grid = self:FindGO("SkillGrid")
  self.skillListCtrl = ListCtrl.new(grid, InheritJobSkillCombineCell, "InheritJobSkillCombineCell")
  self.skillListCtrl:AddEventListener(MouseEvent.MouseClick, self.OnInheritSkillSelect, self)
  self.skillListCtrl:AddEventListener(InheritSkillEvent.ExpendSkill, self.OnExpendSkill, self)
  local selectSkillCell = self:FindGO("SelectInheritSkillCell")
  self.selectInheritSkillCell = InheritSkillDragCell.new(selectSkillCell)
  self.selectSkillName = self:FindComponent("SelectSkillName", UILabel)
  self.upgradePart = self:FindGO("UpgradeDescPart")
  self.oldDesc = self:FindComponent("OldDesc", UILabel)
  self.oldLv = self:FindComponent("OldLv", UILabel)
  self.newDesc = self:FindComponent("NewDesc", UILabel)
  self.newLv = self:FindComponent("NewLv", UILabel)
  self.noEffectTip = self:FindGO("NoEffectTip")
  self.maxLvPart = self:FindGO("MaxLvPart")
  self.maxLv = self:FindComponent("MaxLv", UILabel)
  self.maxLvDesc = self:FindComponent("MaxLvDesc", UILabel)
  self.materialPart = self:FindGO("MaterialPart")
  self.materialTipLabel = self:FindComponent("MaterialTip", UILabel)
  grid = self:FindComponent("MaterialGrid", UIGrid)
  self.materialListCtrl = UIGridListCtrl.new(grid, InheritSkillMaterialCell, "InheritSkillMaterialCell")
  self.materialListCtrl:AddEventListener(MouseEvent.MouseClick, self.OnMaterialItemClick, self)
  self.upgradeBtn = self:FindGO("UpgradeBtn")
  self:AddClickEvent(self.upgradeBtn, function()
    self:OnUpgradeBtnClick()
  end)
  self.upgradeLabel = self:FindComponent("Label", UILabel, self.upgradeBtn)
  self.upgradeTipLabel = self:FindComponent("UpgradeTip", UILabel)
  self.upgradeTip = self:FindGO("UpgradeTipBg")
  local helpBtn = self:FindGO("HelpBtn")
  self:RegistShowGeneralHelpByHelpID(32634, helpBtn)
  self.effectContainer = self:FindGO("effectContainer")
  local attrGrid = self:FindComponent("AttrGrid", UIGrid)
  self.costPointAttrListCtrl = UIGridListCtrl.new(attrGrid, InheritSkillCostPointAttrCell, "InheritSkillCostPointAttrCell")
  self.costPointMax = self:FindGO("CostPointMax")
  self.tipLabel = self:FindComponent("TipLabel", UILabel)
  self.tipLabel.text = ZhString.InheritSkill_Tip
  self.materialProgressBar = self:FindComponent("MaterialBar", UIProgressBar)
  self.progressLabel = self:FindComponent("Progress", UILabel)
  self.barSp = self:FindComponent("Foreground", UIMultiSprite)
end

function InheritSkillView:AddListenEvts()
  self:AddListenEvt(ServiceEvent.SkillUpdateInheritSkillCmd, self.HandleInheritSkillUpdate)
  self:AddListenEvt(ServiceEvent.SkillExtendInheritSkillCmd, self.HandleExtendCostPoint)
  self:AddListenEvt(ItemEvent.ItemUpdate, self.HandleItemUpdate)
end

function InheritSkillView:OnEnter()
  PictureManager.Instance:SetInheritSkillTexture(BgName, self.bg)
  PictureManager.Instance:SetInheritSkillTexture(SkillBgName, self.skillBg)
  self:RefreshView()
end

function InheritSkillView:OnExit()
  PictureManager.Instance:UnloadInheritSkillTexture(BgName, self.bg)
  PictureManager.Instance:UnloadInheritSkillTexture(SkillBgName, self.skillBg)
end

function InheritSkillView:HandleInheritSkillUpdate()
  self:RefreshView()
  if self.isLvUp then
    self:PlayUIEffect(EffectMap.UI.EquipUpgrade_Success, self.effectContainer, true)
    self.isLvUp = nil
  end
end

function InheritSkillView:HandleExtendCostPoint()
  self:RefreshCostPoint()
end

function InheritSkillView:RefreshView()
  self:RefreshSkills()
  self:RefreshCostPoint()
  local selectCell
  local cells = self.skillListCtrl:GetCells()
  if not self.selectSkillItemData then
    selectCell = cells[1]:GetSkillCells()[1]
  else
    for i = 1, #cells do
      local skillCells = cells[i]:GetSkillCells()
      for j = 1, #skillCells do
        if skillCells[j].data == self.selectSkillItemData then
          selectCell = skillCells[j]
          break
        end
      end
    end
  end
  self:OnInheritSkillSelect(selectCell)
end

function InheritSkillView:SwapSkill(obj)
  local source = obj.data.source
  local target = obj.data.target
  redlog("InheritSkillView:SwapSkill", source and source.data.id, target and target.data.id)
  if not (source and source.data) or source.data == InheritSkillDragCell.Empty or source.data.isLoad then
    return
  end
  if source.data:IsProfessionForbid() then
    MsgManager.ShowMsgByID(43612)
    return
  end
  local costPoint = source.data:GetCostPoint()
  if not InheritSkillProxy.Instance:IsCostPointsEnough(costPoint) then
    MsgManager.ShowMsgByID(43613)
    local cells = self.costPointListCtrl:GetCells()
    for i = 1, #cells do
      local cell = cells[i]
      if cell.data == 0 or cell.data == 1 then
        cell:PlayEffect(EffectMap.UI.SkillInherit_CostPointRed)
      end
    end
    return
  end
  if target then
    if target.data == InheritSkillDragCell.Empty then
      redlog("CallLoadInheritSkillCmd", source.data.id)
      ServiceSkillProxy.Instance:CallLoadInheritSkillCmd(source.data.id, nil, 0)
    else
      ServiceSkillProxy.Instance:CallLoadInheritSkillCmd(source.data.id, target.data.id, 0)
    end
  end
end

function InheritSkillView:TakeOffSkill(obj)
  local source = obj.data
  if not (source and source.data) or source.data == InheritSkillDragCell.Empty then
    return
  end
  redlog("InheritSkillView:TakeOffSkill", source.data.id)
  source.dragDrop:SetDragEnable(false)
  ServiceSkillProxy.Instance:CallLoadInheritSkillCmd(source.data.id, nil, 1)
end

function InheritSkillView:OnEquipSkillClick(cell)
  if cell.data and cell.data ~= InheritSkillDragCell.Empty then
    self:ScrollToSkill(cell.data.sortID)
  end
end

function InheritSkillView:RefreshCostPoint()
  local datas = {}
  local initPoint = GameConfig.SkillInherit and GameConfig.SkillInherit.InitPointMax or 0
  local extendPointCost = GameConfig.SkillInherit and GameConfig.SkillInherit.PointExtendCost
  local max = initPoint
  if extendPointCost then
    max = max + #extendPointCost
  end
  local extendedCostPoints = InheritSkillProxy.Instance:GetExtendedCostPoints()
  redlog("InheritSkillView:RefreshCostPoint", extendedCostPoints)
  local costPoints = extendedCostPoints + initPoint
  local loadSkills = InheritSkillProxy.Instance:GetLoadSkills()
  local loadCostPoint = 0
  for i = 1, #loadSkills do
    local loadSkill = loadSkills[i]
    loadCostPoint = loadCostPoint + loadSkill:GetCostPoint()
  end
  for i = 1, max do
    local state = i <= loadCostPoint and 2 or i <= costPoints and 1 or 0
    datas[#datas + 1] = state
  end
  self.costPointListCtrl:ResetDatas(datas)
  self.costPointLabel.text = string.format("(%d/%d)", loadCostPoint, costPoints)
  local attrs = InheritSkillProxy.Instance:GetCurCostPointAttrs()
  self.costPointAttrListCtrl:ResetDatas(attrs)
  self.costPointMax:SetActive(max <= costPoints)
  self.addCostBtn:SetActive(max > costPoints)
end

local sortFunc = function(l, r)
  if l.profession > 0 and r.profession > 0 then
    return l.profession < r.profession
  end
  return l.profession > 0
end

function InheritSkillView:RefreshSkills()
  local professDatas = InheritSkillProxy.Instance:GetSkillProfessDatas()
  table.sort(professDatas, sortFunc)
  self.skillListCtrl:ResetDatas(professDatas, nil, false)
  self:LayoutSkills()
  self:RefreshLoadSkills()
end

local CellSpace = 10

function InheritSkillView:LayoutSkills()
  local cells = self.skillListCtrl:GetCells()
  local posY = 0
  for i = 1, #cells do
    local cell = cells[i]
    LuaGameObject.SetLocalPositionGO(cell.gameObject, 0, posY, 0)
    posY = posY - cell.height - CellSpace
  end
end

function InheritSkillView:RefreshLoadSkills()
  local datas = {}
  local skills = InheritSkillProxy.Instance:GetLoadSkills()
  local count = #skills < 3 and 3 or math.min(#skills + 1, 8)
  for i = 1, count do
    local data = skills[i] or InheritSkillDragCell.Empty
    datas[#datas + 1] = data
  end
  self.equipSkillListCtrl:ResetDatas(datas)
end

function InheritSkillView:OnInheritSkillSelect(cell)
  if not cell then
    return
  end
  cell:SetSelect(true)
  local cells = self.skillListCtrl:GetCells()
  for i = 1, #cells do
    local skillCells = cells[i]:GetSkillCells()
    for j = 1, #skillCells do
      if skillCells[j].data ~= cell.data then
        skillCells[j]:SetSelect(false)
      end
    end
  end
  self:RefreshSelectSkillInfo(cell.data)
end

function InheritSkillView:OnExpendSkill(cell)
  self:LayoutSkills()
end

function InheritSkillView:RefreshSelectSkillInfo(data)
  self.selectSkillItemData = data
  self.selectInheritSkillCell:SetData(data)
  self.selectInheritSkillCell:UpdateDragable(false)
  self.selectSkillName.text = OverSea.LangManager.Instance():GetLangByKey(data.staticData.NameZh)
  local isMaxLv = data:IsMaxLevel()
  self.upgradePart:SetActive(not isMaxLv)
  self.maxLvPart:SetActive(isMaxLv)
  self.materialPart:SetActive(not isMaxLv and data.isUnlock or false)
  self.upgradeTip:SetActive(isMaxLv or not data.isUnlock)
  self.noEffectTip:SetActive(not data.isInherited)
  self.upgradeLabel.text = data.isInherited and ZhString.InheritSkill_Upgrade or ZhString.InheritSkill_Inherit
  if isMaxLv then
    self.upgradeTipLabel.text = ZhString.InheritSkill_MaxLevel
    self.maxLv.text = string.format(ZhString.InheritSkill_MaxLv, data.maxLevel)
    self.maxLvDesc.text = SkillProxy.GetDesc(data.id)
  elseif not data.isUnlock then
    local config = Table_Class[data.unlockProfess]
    local className = config and config.NameZh or ""
    self.upgradeTipLabel.text = string.format(ZhString.InheritSkill_UnlockTip, className)
    self:UpdateCurLevelSkillInfo(data)
    self:UpdateNextLevelSkillInfo(data)
  else
    self:UpdateCurLevelSkillInfo(data)
    self:UpdateNextLevelSkillInfo(data)
    self:UpdateMaterialInfo(data)
  end
end

function InheritSkillView:UpdateCurLevelSkillInfo(data)
  if data then
    self.oldLv.text = data.level > 0 and string.format("Lv.%d", data.level) or ""
    self.oldDesc.text = data.level > 0 and SkillProxy.GetDesc(data.id) or ""
  end
end

function InheritSkillView:UpdateNextLevelSkillInfo(data)
  if data then
    local nextId = data.level > 0 and data:GetNextID() or data.id + 1
    local config = Table_Skill[nextId]
    if config then
      self.newLv.text = string.format("Lv.%d", config.Level)
      self.newDesc.text = SkillProxy.GetDesc(nextId)
    end
  end
end

local NormalColor = Color(0.3333333333333333, 0.3568627450980392, 0.43137254901960786, 1)
local LackColor = Color(0.9333333333333333, 0.3568627450980392, 0.3568627450980392, 1)

function InheritSkillView:UpdateMaterialInfo(data)
  local materials = data and data.inheritStaticData and data.inheritStaticData.Materials
  if materials then
    local quality = data.inheritStaticData and data.inheritStaticData.Quality
    local matNum
    if GameConfig.SkillInherit and GameConfig.SkillInherit.Quality then
      local qualityConf = GameConfig.SkillInherit.Quality[quality]
      if qualityConf then
        matNum = qualityConf.LvUpCost[data.level + 1]
      end
    end
    if matNum then
      local datas = {}
      local str = ""
      local count = #materials
      local totalNum = 0
      local checkPackage = GameConfig.PackageMaterialCheck.inherit_skill
      for i = 1, count do
        local itemId = materials[i]
        local itemData = ItemData.new("", itemId)
        local num = BagProxy.Instance:GetItemNumByStaticID(itemId, checkPackage)
        itemData.num = num
        str = str .. itemData:GetName()
        if i < count then
          str = str .. "/"
        end
        datas[#datas + 1] = itemData
        totalNum = totalNum + num
      end
      self.materialListCtrl:ResetDatas(datas)
      TableUtility.ArrayClear(self.lackMats)
      self.materialTipLabel.text = string.format(ZhString.InheritSkill_MaterialTip, str, matNum)
      local isLack = matNum > totalNum
      local cells = self.materialListCtrl:GetCells()
      for i = 1, #cells do
        local cell = cells[i]
        cell:SetNumLabelState(isLack)
        if isLack and ItemData.CheckItemCanTrade(cell.data.staticData.id) then
          self.lackMats[#self.lackMats + 1] = {
            id = cell.data.staticData.id,
            count = matNum - totalNum
          }
        end
      end
      self.materialProgressBar.value = math.clamp(totalNum / matNum, 0, 1)
      self.progressLabel.text = string.format("%d/%d", totalNum, matNum)
      self.progressLabel.color = isLack and LackColor or NormalColor
      self.barSp.CurrentState = isLack and 0 or 1
    end
  end
end

function InheritSkillView:OnAddCostBtnClick()
  self:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.InheritSkillExtendCostPointPopUp
  })
end

function InheritSkillView:OnGotoBtnClick()
  MsgManager.ConfirmMsgByID(43611, function()
    self:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.CharactorAdventureSkill
    })
  end)
end

function InheritSkillView:OnMaterialItemClick(cell)
  self.tipData.itemdata = cell.data
  self:ShowItemTip(self.tipData, cell.bg, NGUIUtil.AnchorSide.Left, {-200, 0})
end

function InheritSkillView:OnUpgradeBtnClick()
  if self.selectSkillItemData then
    if #self.lackMats > 0 then
      QuickBuyProxy.Instance:TryOpenView(self.lackMats)
      return
    end
    local skillIds = {
      self.selectSkillItemData.id
    }
    redlog("CallLevelupSkill", self.selectSkillItemData.id)
    self.isLvUp = true
    ServiceSkillProxy.Instance:CallLevelupSkill(SceneSkill_pb.ELEVELUPTYPE_INHERIT, skillIds)
  end
end

function InheritSkillView:HandleItemUpdate()
  if self.selectSkillItemData then
    self:UpdateMaterialInfo(self.selectSkillItemData)
  end
end

function InheritSkillView:ScrollToSkill(familyId)
  local pro = InheritSkillProxy.GetSkillProfess(familyId)
  local index = 0
  if pro then
    local cells = self.skillListCtrl:GetCells()
    for i = 1, #cells do
      local cell = cells[i]
      if cell.data.profession == pro then
        index = i
        break
      end
    end
    if 0 < index then
      local totalY = cells[#cells].trans.localPosition.y - cells[#cells].height
      local targetY = cells[index].trans.localPosition.y - cells[index].height
      local per = targetY / totalY
      redlog("InheritSkillView:ScrollToSkill", per)
      per = math.clamp(per, 0, 1)
      self.skillScrollView:SetDragAmount(0, per, false)
    end
    local skillCells = cells[index]:GetSkillCells()
    local selectCell = TableUtility.ArrayFindByPredicate(skillCells, function(v, args)
      return v.data.sortID == args
    end, familyId)
    if selectCell then
      self:OnInheritSkillSelect(selectCell)
    end
  end
end
