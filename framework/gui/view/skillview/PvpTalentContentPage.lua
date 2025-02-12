autoImport("SkillTip")
autoImport("PeakSkillPreviewTip")
autoImport("PvpTalentCell")
autoImport("SkillItemData")
autoImport("BalanceModeSkillCell")
PvpTalentContentPage = class("PvpTalentContentPage", SkillBaseContentPage)
local tmpPos = LuaVector3.Zero()

function PvpTalentContentPage:Init()
  self.gameObject = self:FindGO("PvpTalentContentPage", self:FindGO("SkillPages"))
  local useless, pwsConfig = next(GameConfig.PvpTeamRaid)
  self.pwsConfig = pwsConfig
  self.tipdata = {}
  self.usablePoints = 0
  self.maxPoints = 0
  self:FindObjs()
  self:InitTalentsList()
  self:AddViewListener()
  self:AddButtonEvts()
end

function PvpTalentContentPage:FindObjs()
  self.objLeftTopInfo = self:FindGO("Left", self:FindGO("Up"))
  self.objPwsTop = self:FindGO("pwsTop", self.objLeftTopInfo)
  self.objBalanceModeTop = self:FindGO("balanceModeTop", self.objLeftTopInfo)
  self.objContents = self:FindGO("Contents")
  self.objPwsContent = self:FindGO("PwsContent", self.objContents)
  self.objBalanceModeContent = self:FindGO("BalanceModeContent", self.objContents)
  self.labUsablePoints = self:FindComponent("labPvpTalentPoints", UILabel, self.objPwsTop)
  self.objRightButtons = self:FindGO("RightBtns")
  self.objBtnConfirm = self:FindGO("PvpTalentConfirmBtn", self.objRightButtons)
  self.objBtnCancel = self:FindGO("PvpTalentCancelBtn", self.objRightButtons)
  self.objScrollArea = self:FindGO("PvpTalentArea", self:FindGO("ScrollArea"))
  self.objBtnReset = self:FindGO("PvpTalentResetBtn", self.objPwsTop)
  self.contentPanel = self:FindComponent("PvpTalentContent", UIPanel, self.objPwsContent)
  self.contentScroll = self.contentPanel.gameObject:GetComponent(ScrollViewWithProgress)
  self.balanceModeType = {}
  self.balanceModeType[1] = self:FindGO("AttackType", self.objBalanceModeContent)
  self.balanceModeType[2] = self:FindGO("DefType", self.objBalanceModeContent)
  self.balanceModeType[3] = self:FindGO("ArtifactType", self.objBalanceModeContent)
  self.balanceModeScrollView = {}
  self.curSkillCell = {}
  self.curSkillCell_Bg = {}
  self.curSkillCell_Icon = {}
  self.curSkillCell_Empty = {}
  self.curSkillCell_HightLight = {}
  self.skillCtrl = {}
  self.dragDrop = {}
  for i = 1, 3 do
    self.balanceModeScrollView[i] = self:FindGO("TalentScrollView", self.balanceModeType[i]):GetComponent(UIScrollView)
    self.curSkillCell[i] = self:FindGO("CurSkill", self.balanceModeType[i])
    self.curSkillCell_Bg[i] = self.curSkillCell[i]:GetComponent(UISprite)
    self.curSkillCell_Icon[i] = self:FindGO("CurSkillIcon", self.curSkillCell[i]):GetComponent(UISprite)
    self.curSkillCell_Empty[i] = self:FindGO("EmptyTip", self.curSkillCell[i])
    self.curSkillCell_HightLight[i] = self:FindGO("HighLight", self.curSkillCell[i])
    self.curSkillCell_HightLight[i]:SetActive(false)
    local gridTalents = self:FindComponent("gridTalents", UIGrid, self.balanceModeType[i])
    self.skillCtrl[i] = UIGridListCtrl.new(gridTalents, BalanceModeSkillCell, "BalanceModeSkillCell")
    self.skillCtrl[i]:AddEventListener(MouseEvent.MouseClick, self.ShowBalanceModeSkillTipHandler, self)
    self.skillCtrl[i]:AddEventListener(MouseEvent.DoubleClick, self.HandleBalanceModelSkillDoubleClick, self)
    self.dragDrop[i] = DragDropCell.new(self.curSkillCell[i]:GetComponent(UIDragItem))
    self.dragDrop[i].dragDropComponent.OnCursor = DragCursorPanel.Instance.ShowItemCell_NoQuality
    self.dragDrop[i].dragDropComponent.OnReplace = function(obj)
      if obj then
        if obj.isArtifact then
          SkillProxy.Instance:CallBalanceModeChooseMess(nil, nil, obj.id)
        elseif obj.type == 1 then
          SkillProxy.Instance:CallBalanceModeChooseMess(obj.id, nil, nil)
        elseif obj.type == 2 then
          SkillProxy.Instance:CallBalanceModeChooseMess(nil, obj.id, nil)
        end
      end
    end
    self.dragDrop[i].dragDropComponent.OnDropEmpty = function(obj)
      if obj then
        redlog(obj, i)
      end
      if i == 1 then
        SkillProxy.Instance:CallBalanceModeChooseMess(0)
      elseif i == 2 then
        SkillProxy.Instance:CallBalanceModeChooseMess(nil, 0, nil)
      elseif i == 3 then
        SkillProxy.Instance:CallBalanceModeChooseMess(nil, nil, 0)
      end
    end
    self.dragDrop[i].dragDropComponent.GetObserved = function()
      return self
    end
    self.dragDrop[i].dragDropComponent.OnStart = function()
    end
    self:AddClickEvent(self.curSkillCell[i], function()
      local curEquipSkill = SkillProxy.Instance:GetBalanceModeChooseMess()
      if curEquipSkill and curEquipSkill[i] and curEquipSkill[i] ~= 0 then
        self:ShowCurEquipedBalanceModeSkill(self.curSkillCell_Icon[i], {
          isArtifact = i == 3 and true or false,
          id = curEquipSkill[i],
          type = i
        })
      end
    end)
    self:AddDoubleClickEvent(self.curSkillCell[i], function()
      local curEquipSkill = SkillProxy.Instance:GetBalanceModeChooseMess()
      if curEquipSkill and curEquipSkill[i] and curEquipSkill[i] ~= 0 then
        if i == 1 then
          SkillProxy.Instance:CallBalanceModeChooseMess(0)
        elseif i == 2 then
          SkillProxy.Instance:CallBalanceModeChooseMess(nil, 0, nil)
        elseif i == 3 then
          SkillProxy.Instance:CallBalanceModeChooseMess(nil, nil, 0)
        end
      end
    end)
  end
  self.toggles = self:FindGO("Toggles")
  self.pwsSkillTog = self:FindGO("PwsSkillTog", self.toggles)
  self.pwsSkillTog_Label = self:FindGO("NameLabel", self.pwsSkillTog):GetComponent(UILabel)
  self.pwsSkillTog_Checkmark = self:FindGO("Sprite", self.pwsSkillTog)
  self.balanceModeTog = self:FindGO("BalanceModeTog", self.toggles)
  self.balanceModeTog_Label = self:FindGO("NameLabel", self.balanceModeTog):GetComponent(UILabel)
  self.balanceModeTog_Checkmark = self:FindGO("Sprite", self.balanceModeTog)
  if ISNoviceServerType then
    self.balanceModeTog:SetActive(false)
  end
end

function PvpTalentContentPage:InitTalentsList()
  self.listTalents = ListCtrl.new(self:FindGO("pvpTalentGrid", self.objContents), PvpTalentCell, "PvpTalentCell")
  self.listTalents:AddEventListener(MouseEvent.MouseClick, self.ShowTipHandler, self)
  self.listTalents:AddEventListener(SkillCell.Click_PreviewPeak, self.ShowPeakTipHandler, self)
  self.listTalents:AddEventListener(SkillCell.SimulationUpgrade, self.SimulationUpgradeHandler, self)
  self.listTalents:AddEventListener(SkillCell.SimulationDowngrade, self.SimulationDowngradeHandler, self)
end

function PvpTalentContentPage:AddViewListener()
  self:AddListenEvt(SkillEvent.SkillUpdate, self.RefreshSkills)
  self:AddListenEvt(MyselfEvent.MyDataChange, self.HandleMyDataChange)
  self:AddListenEvt(ServiceEvent.MessCCmdBalanceModeChooseMessCCmd, self.HandleBalanceSkillUpdate)
  self:AddListenEvt(DragDropEvent.StartDrag, self.HandleBalanceSkillDragStart)
  self:AddListenEvt(DragDropEvent.EndDrag, self.HandleBalanceSkillDragEnd)
end

function PvpTalentContentPage:AddButtonEvts()
  self:AddClickEvent(self.objBtnCancel, function()
    self:ResetTalents()
    self:SetEditMode(false)
  end)
  self:AddClickEvent(self.objBtnConfirm, function()
    if Game.MapManager:IsTeamPwsFire() then
      MsgManager.ShowMsgByID(25932)
      return
    end
    local skillIDs = ReusableTable.CreateArray()
    local cells = self.listTalents:GetCells()
    local skills, id
    for i = 1, #cells do
      skills = cells[i].listTalents:GetCells()
      for j = 1, #skills do
        id = skills[j]:TryGetSimulateSkillID()
        if id then
          skillIDs[#skillIDs + 1] = id
        end
      end
    end
    self.container:CheckNeedShowOverFlow(skillIDs)
    ServiceSkillProxy.Instance:CallLevelupSkill(SceneSkill_pb.ELEVELUPTYPE_TALENT, skillIDs)
    ReusableTable.DestroyAndClearArray(skillIDs)
  end)
  self:AddClickEvent(self.objBtnReset, function()
    if self.usablePoints >= self.maxPoints then
      return
    end
    if Game.MapManager:IsTeamPwsFire() then
      MsgManager.ShowMsgByID(25932)
      return
    end
    MsgManager.ConfirmMsgByID(25933, function()
      ServiceSkillProxy.Instance:CallResetTalentSkillCmd()
    end, nil)
  end)
  self:AddClickEvent(self.pwsSkillTog, function()
    self.objPwsContent:SetActive(true)
    self.objPwsTop:SetActive(true)
    self.objBalanceModeContent:SetActive(false)
    self.objBalanceModeTop:SetActive(false)
    self.container:SwitchBG(1)
    self.container:ActiveBottom(true)
    self.pwsSkillTog_Label.alpha = 1
    self.pwsSkillTog_Checkmark:SetActive(true)
    self.balanceModeTog_Label.alpha = 0.4
    self.balanceModeTog_Checkmark:SetActive(false)
  end)
  self:AddClickEvent(self.balanceModeTog, function()
    self.objPwsContent:SetActive(false)
    self.objPwsTop:SetActive(false)
    self.objBalanceModeContent:SetActive(true)
    self.objBalanceModeTop:SetActive(true)
    self.container:SwitchBG(2)
    self.container:ActiveBottom(false)
    self.pwsSkillTog_Label.alpha = 0.4
    self.pwsSkillTog_Checkmark:SetActive(false)
    self.balanceModeTog_Label.alpha = 1
    self.balanceModeTog_Checkmark:SetActive(true)
    self:RefreshSkills()
  end)
end

function PvpTalentContentPage:InitShow()
  local subTab = self.viewdata and self.viewdata.viewdata and self.viewdata.viewdata.subtab or 1
  self.objPwsContent:SetActive(subTab == 1)
  self.objPwsTop:SetActive(subTab == 1)
  self.objBalanceModeContent:SetActive(subTab ~= 1)
  self.objBalanceModeTop:SetActive(subTab ~= 1)
  self.container:SwitchBG(subTab)
  self.pwsSkillTog_Label.alpha = subTab == 1 and 1 or 0.4
  self.pwsSkillTog_Checkmark:SetActive(subTab == 1)
  self.balanceModeTog_Label.alpha = subTab ~= 1 and 1 or 0.4
  self.balanceModeTog_Checkmark:SetActive(subTab ~= 1)
  self.container:SwitchBG(subTab)
  self.container:ActiveBottom(subTab == 1)
  for i = 1, 3 do
    self.balanceModeScrollView[i]:ResetPosition()
  end
end

function PvpTalentContentPage:OnEnter()
  PvpTalentContentPage.super.OnEnter(self)
  self.talentDatas = nil
  self.contentScroll:ResetPosition()
  self.contentScroll.panel.clipOffset = LuaGeometry.GetTempVector3()
  self.contentScroll.transform.localPosition = LuaGeometry.GetTempVector3()
  self:RefreshSkills()
  self:InitShow()
end

function PvpTalentContentPage:OnExit()
  self:ClearTalentDatas()
  PvpTalentContentPage.super.OnExit(self)
end

function PvpTalentContentPage:RefreshSkills()
  self:SetEditMode(false)
  self:SetTalentSkills()
  self:SetBalanceModeSkill(true)
  self:UpdateCurrentTalentSkillPoints()
end

function PvpTalentContentPage:ShowTipHandler(cell)
  self:_ShowTip(cell, SkillTip, "SkillTip")
end

function PvpTalentContentPage:ShowPeakTipHandler(cell)
  self:_ShowTip(cell, PeakSkillPreviewTip, "PeakSkillPreviewTip")
end

function PvpTalentContentPage:ShowBalanceModeSkillTipHandler(cell)
  self:ShowCurEquipedBalanceModeSkill(cell.skillIcon, cell.data)
end

function PvpTalentContentPage:ShowCurEquipedBalanceModeSkill(obj, data)
  local camera = NGUITools.FindCameraForLayer(obj.gameObject.layer)
  if camera then
    local viewPos = camera:WorldToViewportPoint(obj.gameObject.transform.position)
    self.tipdata.data = data
    local x = LuaGameObject.InverseTransformPointByTransform(UIManagerProxy.Instance.UIRoot.transform, obj.gameObject.transform, Space.World)
    TipsView.Me():ShowStickTip(BalanceModeSkillTip, self.tipdata, NGUIUtil.AnchorSide.Left, obj, 0 < x and {-200, -150} or {300, -150}, "SkillTip")
  end
end

function PvpTalentContentPage:_ShowTip(cell, tipCtrl, tipView)
  local camera = NGUITools.FindCameraForLayer(cell.gameObject.layer)
  if camera then
    local viewPos = camera:WorldToViewportPoint(cell.gameObject.transform.position)
    self.tipdata.data = cell:GetSimulateSkillItemData()
    TipsView.Me():ShowTip(tipCtrl, self.tipdata, tipView)
    local tip = TipsView.Me().currentTip
    if tip then
      tip:SetCheckClick(self:TipClickCheck())
      if viewPos.x <= 0.5 then
        tmpPos[1], tmpPos[2], tmpPos[3] = self.contentPanel.width / 4, 0, 0
      else
        tmpPos[1], tmpPos[2], tmpPos[3] = -self.contentPanel.width / 4, 0, 0
      end
      tip.gameObject.transform.localPosition = tmpPos
    end
  end
end

function PvpTalentContentPage:TipClickCheck()
  if self.tipCheck == nil then
    function self.tipCheck()
      local click = UICamera.selectedObject
      
      if click then
        local cells = self.listTalents:GetCells()
        if self:CheckIsClickCell(cells, click) then
          return true
        end
      end
      return false
    end
  end
  return self.tipCheck
end

function PvpTalentContentPage:CheckIsClickCell(cells, clickedObj)
  local skills
  for i = 1, #cells do
    skills = cells[i].listTalents:GetCells()
    for j = 1, #skills do
      if skills[j]:IsClickMe(clickedObj) then
        return true
      end
    end
  end
  return false
end

function PvpTalentContentPage:SimulationUpgradeHandler(cell)
  if Game.MapManager:IsTeamPwsFire() then
    MsgManager.ShowMsgByID(25932)
    return
  end
  if self.usablePoints < 1 then
    MsgManager.ShowMsgByID(604)
    return
  end
  local curLayer = cell.layer
  local cells = self.listTalents:GetCells()
  local curLayerLevel = cells[curLayer]:GetLayerSimulateLevel()
  if curLayerLevel >= self.pwsConfig.LayerNeedPoint then
    MsgManager.ShowMsgByID(25936)
    return
  end
  if cell:TrySimulateUpgrade() then
    if cells[curLayer]:GetLayerSimulateLevel() >= self.pwsConfig.LayerNeedPoint then
      cells[curLayer]:SetLayerUpdateEnable(false)
      if curLayer < #cells then
        cells[curLayer + 1]:SetLayerEnable(true)
      end
    end
    self:SetEditMode(true)
    self.usablePoints = self.usablePoints - 1
    self:UpdateCurrentTalentSkillPoints()
    if self.usablePoints < 1 then
      for i = 1, #cells do
        cells[i]:SetLayerUpdateEnable(false)
      end
    end
  end
end

function PvpTalentContentPage:SimulationDowngradeHandler(cell)
  if Game.MapManager:IsTeamPwsFire() then
    MsgManager.ShowMsgByID(25932)
    return
  end
  local cells = self.listTalents:GetCells()
  local curLayer, maxLayer = cell.layer, #cells
  local curLayerLevel = cells[curLayer]:GetLayerSimulateLevel()
  if curLayer < maxLayer and curLayerLevel <= self.pwsConfig.LayerNeedPoint and cells[curLayer + 1]:GetLayerSimulateLevel() > 0 then
    MsgManager.ShowMsgByID(25934)
    return
  end
  if cell:TrySimulateDowngrade() then
    local haveChange = false
    local cells = self.listTalents:GetCells()
    local skills
    for i = 1, #cells do
      skills = cells[i].listTalents:GetCells()
      for j = 1, #skills do
        if skills[j]:IsChanged() then
          haveChange = true
          break
        end
      end
      if haveChange then
        break
      end
    end
    if cells[curLayer]:GetLayerSimulateLevel() < self.pwsConfig.LayerNeedPoint then
      cells[curLayer]:SetLayerUpdateEnable(true)
      if curLayer < maxLayer then
        cells[curLayer + 1]:SetLayerEnable(false)
      end
    end
    self.usablePoints = self.usablePoints + 1
    self:UpdateCurrentTalentSkillPoints()
    for i = 1, #cells do
      cells[i]:SetLayerUpdateEnable(true)
    end
    if not haveChange then
      self:SetEditMode(false)
    end
  end
end

function PvpTalentContentPage:SetTalentSkills()
  if not Table_TalentSkill then
    return
  end
  self:ClearTalentDatas()
  local myProfess = SkillProxy.Instance:GetMyProfession()
  local learnedSkills = SkillProxy.Instance:GetPvpTalentSkillsData()
  self.maxPoints = Game.Myself.data.userdata:Get(UDEnum.TALENT_POINT) or 0
  self.usablePoints = self.maxPoints - (learnedSkills and learnedSkills.usedPoints or 0)
  self.talentDatas = ReusableTable.CreateTable()
  local isMyTalent = false
  local pvpTalentData
  for sortID, talent in pairs(Table_TalentSkill) do
    isMyTalent = talent.RequireProfession == nil
    if talent.RequireProfession then
      for i = 1, #talent.RequireProfession do
        if talent.RequireProfession[i] == myProfess then
          isMyTalent = true
          break
        end
      end
    end
    if isMyTalent then
      local layerTalentsData = self.talentDatas[talent.Layer]
      if not layerTalentsData then
        layerTalentsData = ReusableTable.CreateTable()
        layerTalentsData.layer = talent.Layer
        layerTalentsData.skills = ReusableTable.CreateArray()
        self.talentDatas[talent.Layer] = layerTalentsData
      end
      pvpTalentData = ReusableTable.CreateTable()
      pvpTalentData.layer = talent.Layer
      pvpTalentData.maxLevel = talent.MaxLevel
      if learnedSkills and learnedSkills.skills[sortID] then
        pvpTalentData.skill = learnedSkills.skills[sortID]
        pvpTalentData.level = pvpTalentData.skill.level
      else
        pvpTalentData.skill = SkillItemData.new(sortID * 1000 + 1, i, 0, myProfess, 0)
        pvpTalentData.skill:SetLearned(false)
        pvpTalentData.skill:SetActive(true)
        pvpTalentData.level = 0
      end
      layerTalentsData.skills[#layerTalentsData.skills + 1] = pvpTalentData
    end
  end
  for layer, talents in pairs(self.talentDatas) do
    table.sort(talents.skills, function(x, y)
      if not x then
        return true
      end
      if not y then
        return false
      end
      return x.skill.sortID < y.skill.sortID
    end)
  end
  self.listTalents:ResetDatas(self.talentDatas, true, false)
  local cells = self.listTalents:GetCells()
  if 1 < #cells then
    if 0 < self.usablePoints then
      cells[1]:SetLayerEnable(true)
      cells[1]:SetLayerUpdateEnable(true)
      for i = 2, #cells do
        cells[i]:SetLayerEnable(cells[i - 1]:GetLayerSimulateLevel() >= self.pwsConfig.LayerNeedPoint)
        cells[i]:SetLayerUpdateEnable(true)
      end
    else
      for i = 1, #cells do
        cells[i]:SetLayerDisableOperate()
      end
    end
  end
end

function PvpTalentContentPage:SetBalanceModeSkill(resetPos)
  local balanceSkillInfo = SkillProxy.Instance:GetBalanceModeChooseMess()
  local skillList = {}
  local atkEquip = GameConfig.BalanceMode and GameConfig.BalanceMode.EquipExtractionAtk or {}
  skillList[1] = {}
  for i = 1, #atkEquip do
    local tempSkill = {
      id = atkEquip[i],
      type = 1,
      isChoose = balanceSkillInfo[1] and balanceSkillInfo[1] == atkEquip[i] or false
    }
    table.insert(skillList[1], tempSkill)
  end
  local defEquip = GameConfig.BalanceMode and GameConfig.BalanceMode.EquipExtractionDef or {}
  skillList[2] = {}
  for i = 1, #defEquip do
    local tempSkill = {
      id = defEquip[i],
      type = 2,
      isChoose = balanceSkillInfo[2] and balanceSkillInfo[2] == defEquip[i] or false
    }
    table.insert(skillList[2], tempSkill)
  end
  local artifactEquip = GameConfig.BalanceMode and GameConfig.BalanceMode.PersonalArtifactCompose or {}
  skillList[3] = {}
  for i = 1, #artifactEquip do
    local tempSkill = {
      id = artifactEquip[i],
      isArtifact = 1,
      isChoose = balanceSkillInfo[3] and balanceSkillInfo[3] == artifactEquip[i] or false
    }
    table.insert(skillList[3], tempSkill)
  end
  for i = 1, 3 do
    if balanceSkillInfo[i] and balanceSkillInfo[i] ~= 0 then
      self.dragDrop[i].dragDropComponent.data = {
        type = i,
        id = balanceSkillInfo[i],
        itemdata = ItemData.new("DragItem", balanceSkillInfo[i])
      }
      self.dragDrop[i]:SetDragEnable(true)
      local itemInfo = Table_Item[balanceSkillInfo[i]]
      IconManager:SetItemIcon(itemInfo.Icon, self.curSkillCell_Icon[i])
      self.curSkillCell_Icon[i].gameObject.transform.localScale = LuaGeometry.GetTempVector3(0.8, 0.8, 0.8)
      self.curSkillCell_Bg[i].color = LuaColor.White()
      self.curSkillCell_Empty[i]:SetActive(false)
    else
      self.dragDrop[i]:SetDragEnable(false)
      self.curSkillCell_Icon[i].spriteName = ""
      self.curSkillCell_Bg[i].color = LuaGeometry.GetTempVector4(0.00392156862745098, 0.00784313725490196, 0.011764705882352941, 1)
      self.curSkillCell_Empty[i]:SetActive(true)
    end
    self.skillCtrl[i]:ResetDatas(skillList[i])
  end
  if resetPos then
    for i = 1, 3 do
      self.balanceModeScrollView[i]:ResetPosition()
    end
  end
end

function PvpTalentContentPage:ClearTalentDatas()
  if not self.talentDatas then
    return
  end
  for k, talent in pairs(self.talentDatas) do
    for i = 1, #talent.skills do
      ReusableTable.DestroyAndClearTable(talent.skills[i])
    end
    ReusableTable.DestroyAndClearArray(talent.skills)
    ReusableTable.DestroyAndClearTable(talent)
  end
  ReusableTable.DestroyAndClearTable(self.talentDatas)
  self.talentDatas = nil
end

function PvpTalentContentPage:UpdateCurrentTalentSkillPoints()
  self.labUsablePoints.text = string.format(ZhString.SkillView_Talent_UsablePoints, self.usablePoints, self.maxPoints)
end

function PvpTalentContentPage:SetEditMode(val)
  if self.isEditMode ~= val then
    self.isEditMode = val
    if val then
      self:Show(self.objRightButtons)
    else
      self:Hide(self.objRightButtons)
    end
  end
end

function PvpTalentContentPage:ResetTalents()
  local talentData = SkillProxy.Instance:GetPvpTalentSkillsData()
  self.usablePoints = self.maxPoints - (talentData and talentData.usedPoints or 0)
  self:UpdateCurrentTalentSkillPoints()
  local updateEnable = self.usablePoints > 0
  local cells = self.listTalents:GetCells()
  if 0 < #cells then
    cells[1]:ResetLayer()
    cells[1]:SetLayerUpdateEnable(updateEnable)
    cells[1]:SetLayerEnable(true)
  end
  for i = 2, #cells do
    cells[i]:ResetLayer()
    cells[i]:SetLayerUpdateEnable(updateEnable)
    cells[i]:SetLayerEnable(cells[i - 1]:GetLayerSimulateLevel() >= self.pwsConfig.LayerNeedPoint)
  end
end

function PvpTalentContentPage:ConfirmEditMode(toDo, owner, param)
  if self.isEditMode then
    MsgManager.ConfirmMsgByID(602, function()
      self:ResetTalents()
      self:SetEditMode(false)
      toDo(owner, param)
    end)
  else
    toDo(owner, param)
  end
end

function PvpTalentContentPage:IsEditMode()
  return self.isEditMode
end

function PvpTalentContentPage:OnSwitch(val)
  self.gameObject:SetActive(val == true)
  self:InitShow()
end

function PvpTalentContentPage:HandleMyDataChange(note)
  local data = note.body
  if not data then
    return
  end
  local skillType = ProtoCommon_pb.EUSERDATATYPE_TALENT_SKILLPOINT
  for i = 1, #data do
    if data[i].type == skillType then
      self.maxPoints = Game.Myself.data.userdata:Get(UDEnum.TALENT_POINT) or 0
      self:UpdateCurrentTalentSkillPoints()
      break
    end
  end
end

function PvpTalentContentPage:OnDestroy()
  self.listTalents:Destroy()
  PvpTalentContentPage.super.OnDestroy(self)
end

function PvpTalentContentPage:HandleBalanceModelSkillDoubleClick(cell)
  local data = cell.data
  local id = cell.id
  xdlog("双击装备", id)
  local type = cell.type
  local isArtifact = cell.isArtifact
  if isArtifact then
    SkillProxy.Instance:CallBalanceModeChooseMess(nil, nil, id)
  elseif type == 1 then
    SkillProxy.Instance:CallBalanceModeChooseMess(id, nil, nil)
  elseif type == 2 then
    SkillProxy.Instance:CallBalanceModeChooseMess(nil, id, nil)
  end
end

function PvpTalentContentPage:HandleBalanceSkillUpdate()
  xdlog("服务器来数据了")
  self:SetBalanceModeSkill()
end

function PvpTalentContentPage:HandleBalanceSkillDragStart(note)
  local cellCtrl = note.body
  local data = cellCtrl and cellCtrl.data
  local type = cellCtrl.type
  if cellCtrl.isArtifact then
    type = 3
  end
  for i = 1, 3 do
    self.curSkillCell_HightLight[i]:SetActive(i == type)
  end
end

function PvpTalentContentPage:HandleBalanceSkillDragEnd(note)
  local cellCtrl = note.body
  for i = 1, 3 do
    self.curSkillCell_HightLight[i]:SetActive(false)
  end
end
