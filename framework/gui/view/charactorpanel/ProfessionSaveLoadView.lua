autoImport("ProfessionBaseView")
autoImport("SaveCell")
autoImport("MultiProfessionSaveProxy")
autoImport("PlayerDetailViewMP")
autoImport("SavedSkillPreviewCell")
autoImport("SaveAttrInfoCell")
ProfessionSaveLoadView = class("ProfessionSaveLoadView", ProfessionBaseView)
ProfessionSaveLoadView.EquipBtnClick = "ProfessionSaveLoadView.EquipBtnClick"
ProfessionSaveLoadView.CallClose = "ProfessionSaveLoadView.CallClose"
ProfessionSaveLoadView.CloseEquip = "ProfessionSaveLoadView.CloseEquip"
local tempVector3 = LuaVector3.Zero()
local rid = ResourcePathHelper.UICell("SaveCell")

function ProfessionSaveLoadView:ctor(container, initParama, subViewData)
  initParama = initParama or container
  local new_container = {}
  new_container.gameObject = container.gameObject
  new_container.viewdata = initParama.viewdata
  ProfessionSaveLoadView.super.ctor(self, new_container)
end

function ProfessionSaveLoadView:GetShowHideMode()
  return PanelShowHideMode.MoveOutAndMoveIn
end

function ProfessionSaveLoadView:MediatorReActive()
  return true
end

function ProfessionSaveLoadView:Init()
  self:initView()
end

function ProfessionSaveLoadView:initView()
  ProfessionSaveLoadView.super.initView(self, true)
  local panel = Game.GameObjectUtil:FindCompInParents(self.gameObject, UIPanel)
  local uipanels = Game.GameObjectUtil:GetAllComponentsInChildren(self.gameObject, UIPanel, true)
  for i = 1, #uipanels do
    uipanels[i].depth = uipanels[i].depth + panel.depth
  end
  self:ShowSaveLoadState()
end

function ProfessionSaveLoadView:ShowSaveLoadState()
  self:FindSaveObjects()
  self:AddSaveClickEvent()
  self:SetSaveList()
  self:RefreshChoose()
  if self.gemBtn then
    self.gemBtn:SetActive(FunctionUnLockFunc.Me():CheckCanOpen(6200))
  end
end

function ProfessionSaveLoadView:FindSaveObjects()
  self.whitebgSP = self:FindGO("whitebgSP")
  self.equipBtn = self:FindGO("EquipBtn", self.whitebgSP)
  self.astroBtn = self:FindGO("AstroBtn", self.whitebgSP)
  self.skillBtn = self:FindGO("SkillBtn", self.whitebgSP)
  self.gemBtn = self:FindGO("GemBtn", self.whitebgSP)
  self.EquipBtn_UISprite = self:FindGO("Sprite", self.equipBtn):GetComponent(UISprite)
  self.AstroBtn_UISprite = self:FindGO("Sprite", self.astroBtn):GetComponent(UISprite)
  self.SkillBtn_UISprite = self:FindGO("Sprite", self.skillBtn):GetComponent(UISprite)
  self.GemBtn_UISprite = self:FindGO("Sprite", self.gemBtn):GetComponent(UISprite)
  IconManager:SetUIIcon("equip_Details", self.EquipBtn_UISprite)
  IconManager:SetItemIcon("item_5501", self.AstroBtn_UISprite)
  IconManager:SetItemIcon("item_5670", self.GemBtn_UISprite)
  local propDes = self:FindComponent("propDes", UILabel)
  local str = ZhString.MultiProfession_Info
  propDes.text = str
  self.propGridView = self:FindComponent("propGrid", UIGrid)
  self.propGrid = UIGridListCtrl.new(self.propGridView, SaveAttrInfoCell, "SaveAttrInfoCell")
  self.propSecGridView = self:FindComponent("propSecGrid", UIGrid)
  self.propSecGrid = UIGridListCtrl.new(self.propSecGridView, SaveAttrInfoCell, "SaveAttrInfoCell")
  self.skillColumns = self:FindGO("SkillColumns")
  self.nextBtn = self:FindGO("NextBtn")
  self.nextBtnSp = self:FindComponent("NextBtn", UISprite)
  self.nilTip = self:FindGO("NilTip")
  self.manualGrid = self:FindGO("ManualGrid", self.skillColumns):GetComponent(UIGrid)
  self.manualCtl = UIGridListCtrl.new(self.manualGrid, SavedSkillPreviewCell, "SavedSkillPreviewCell")
  self.autoGrid = self:FindGO("AutoGrid", self.skillColumns):GetComponent(UIGrid)
  self.autoCtl = UIGridListCtrl.new(self.autoGrid, SavedSkillPreviewCell, "SavedSkillPreviewCell")
  self.whitebgSaveLoad = self:FindGO("whitebgSaveLoad")
  self.LoadBtn = self:FindGO("LoadBtn", self.whitebgSaveLoad)
  self.SaveBtn = self:FindGO("SaveBtn", self.whitebgSaveLoad)
  self.DeleteBtn = self:FindGO("DeleteBtn", self.whitebgSaveLoad)
  self.saveScrollView = self:FindGO("ScrollView", self.whitebgSaveLoad):GetComponent(UIScrollView)
  self.saveGrid = self:FindGO("SaveGrid", self.saveScrollView.gameObject):GetComponent(UIGrid)
  self.saveCtl = UIGridListCtrl.new(self.saveGrid, SaveCell, "SaveCell")
  self.saveCtl:AddEventListener(MouseEvent.MouseClick, self.ClickItem, self)
  self.saveCtl:AddEventListener(MouseEvent.DoubleClick, self.DoubleClickItem, self)
  self.propertyCt = self:FindGO("propertyCt")
  self.Profession = self:FindGO("Profession")
  self.roleName = self:FindGO("Name", self.whitebgSaveLoad):GetComponent(UILabel)
  self.jobLv = self:FindGO("jobLv", self.whitebgSaveLoad):GetComponent(UILabel)
  self.astroPoint = self:FindGO("astroPoint", self.whitebgSaveLoad):GetComponent(UILabel)
  self.skillPoint = self:FindGO("skillPoint", self.whitebgSaveLoad):GetComponent(UILabel)
  self.playerDetailViewMP = self:AddSubView("PlayerDetailViewMP", PlayerDetailViewMP)
  self.detaiview = self:FindGO("PlayerDetailViewMP")
  self.detaiview.transform.localPosition = LuaGeometry.GetTempVector3(290, 0, 0)
  self:AddEventListener(ProfessionSaveLoadView.EquipBtnClick, self.playerDetailViewMP.OnClickBtn, self.playerDetailViewMP)
  self:AddEventListener(ProfessionSaveLoadView.CloseEquip, self.playerDetailViewMP.CloseUI, self.playerDetailViewMP)
  self.selectedID = MultiProfessionSaveProxy.Instance:GetDefaultRecord()
  local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
  ServiceNUserProxy.Instance:CallQueryProfessionDataDetailUserCmd(SaveInfoEnum.Record)
  MsgManager.FloatMsg("", ZhString.MultiProfession_WaitRecordInfo)
  self.nextToggle = true
end

function ProfessionSaveLoadView:AddSaveClickEvent()
  self:AddClickEvent(self.equipBtn, function(go)
    local data = MultiProfessionSaveProxy.Instance:GetUsersaveData(self.selectedID)
    self:PassEvent(ProfessionSaveLoadView.EquipBtnClick, data)
  end)
  self:AddClickEvent(self.astroBtn, function(go)
    if not MyselfProxy.Instance:IsUnlockAstrolabe() then
      MsgManager.ShowMsgByID(25432)
      return
    end
    local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
    if savedata == nil then
      return
    end
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.AstrolabeView,
      viewdata = {
        storageId = self.selectedID
      }
    })
  end)
  self:AddClickEvent(self.skillBtn, function(go)
    local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
    if savedata == nil then
      return
    end
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.CharactorProfessSkill,
      viewdata = {
        saveId = self.selectedID,
        saveType = SaveInfoEnum.Record,
        allowedSkillTip = {
          SkillTip.FuncTipType.SubSkillsReadOnly,
          SkillTip.FuncTipType.ItemCost
        }
      }
    })
  end)
  self:AddClickEvent(self.gemBtn, function(go)
    local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
    if savedata == nil then
      return
    end
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.GemEmbedPreview,
      viewdata = {
        saveId = self.selectedID,
        saveType = SaveInfoEnum.Record
      }
    })
  end)
  self:AddClickEvent(self.nextBtn, function(go)
    local userData = MultiProfessionSaveProxy.Instance:GetUserDataByID(self.selectedID)
    if not userData then
      return
    end
    if not self.nextToggle then
      self:ShowSkills()
      self.nextBtnSp.flip = 0
    else
      self:ShowAttribute()
      self.nextBtnSp.flip = 1
    end
    self.nextToggle = not self.nextToggle
  end)
  local myselfData = Game.Myself.data
  self:AddClickEvent(self.LoadBtn, function(go)
    if self.call_lock then
      return
    end
    if myselfData:IsTransformed() then
      MsgManager.ShowMsgByID(27009)
      return
    end
    if myselfData:IsInMagicMachine() then
      MsgManager.ShowMsgByID(27008)
      return
    end
    if myselfData:IsOnWolf() then
      MsgManager.ShowMsgByID(27007)
      return
    end
    if myselfData:GetBuffListByType("Transform") ~= nil then
      MsgManager.ShowMsgByID(27009)
      return
    end
    if Game.Myself:IsInBooth() then
      MsgManager.ShowMsgByID(25708)
      return
    end
    self:LockCall()
    local callRecord = function()
      ServiceNUserProxy.Instance:CallLoadRecordUserCmd(self.selectedID)
    end
    local totalContri, totalGold = MultiProfessionSaveProxy.Instance:GetContribute(self.selectedID), MultiProfessionSaveProxy.Instance:GetGoldMedal(self.selectedID)
    AstrolabeProxy.ConfirmAstrolMaterialOnChange(totalContri, totalGold, function()
      if GemProxy.CheckIsGemDataDifferentFrom(MultiProfessionSaveProxy.Instance:GetGemData(self.selectedID)) then
        MsgManager.ConfirmMsgByID(36011, callRecord)
      else
        callRecord()
      end
    end)
  end)
  self:AddClickEvent(self.SaveBtn, function(go)
    if self.call_lock then
      return
    end
    if not ProfessionProxy.CanChangeProfession4NewPVPRule(25389) then
      return
    end
    self:LockCall()
    local str = string.format(ZhString.MultiProfession_SaveName, self.selectedID)
    ServiceNUserProxy:CallSaveRecordUserCmd(self.selectedID, str)
    redlog("CallSaveRecordUserCmd", self.selectedID)
  end)
  self:AddClickEvent(self.DeleteBtn, function(go)
    if self.call_lock then
      return
    end
    self:LockCall()
    MsgManager.ConfirmMsgByID(25430, function()
      ServiceNUserProxy.Instance:CallDeleteRecordUserCmd(self.selectedID)
    end)
    self:PassEvent(ProfessionSaveLoadView.CloseEquip)
  end)
  self:AddListenEvt(ServiceEvent.NUserUpdateRecordInfoUserCmd, self.HandleRecvUpdateRecordInfoUserCmd)
  self:AddListenEvt(SaveCell.StatusChange, self.SetSaveList)
end

function ProfessionSaveLoadView:LockCall()
  if self.call_lock then
    return
  end
  self.call_lock = true
  if self.lock_lt == nil then
    self.lock_lt = TimeTickManager.Me():CreateOnceDelayTick(500, function(owner, deltaTime)
      self.lock_lt = nil
      self.call_lock = false
    end, self)
  end
end

function ProfessionSaveLoadView:CancelLockCall()
  if not self.call_lock then
    return
  end
  self.call_lock = false
  if self.lock_lt then
    self.lock_lt:Destroy()
    self.lock_lt = nil
  end
end

function ProfessionSaveLoadView:HandleRecvUpdateRecordInfoUserCmd(note)
  redlog("HandleRecvUpdateRecordInfoUserCmd")
  self:CancelLockCall()
  self:SetSaveList()
end

function ProfessionSaveLoadView:ShowSkills()
  self.skillColumns:SetActive(true)
  self.propSecGridView.gameObject:SetActive(false)
end

function ProfessionSaveLoadView:SetSaveList()
  local trimmedData = {}
  _slotdatas = MultiProfessionSaveProxy.Instance.slotDatas
  for i = 1, #_slotdatas do
    table.insert(trimmedData, _slotdatas[i])
    if _slotdatas[i].status == 0 and _slotdatas[i].type == SceneUser2_pb.ESLOT_BUY then
      break
    end
  end
  self.saveCtl:ResetDatas(trimmedData)
  self.selectedID = MultiProfessionSaveProxy.Instance:GetDefaultRecord()
  self:RefreshChoose()
  self:SetPreview(self.selectedID)
end

function ProfessionSaveLoadView:showInfo(saveID)
  local classID = MultiProfessionSaveProxy.Instance:GetProfession(saveID)
  if Table_Class[classID] then
    self.currentPfn = Table_Class[classID]
  else
    self.currentPfn = nil
  end
  self:ResetDataBySave(saveID)
end

function ProfessionSaveLoadView:ResetDataBySave(saveID)
  if self.currentPfn == nil or self.currentPfn.id == 1 then
    self.propertyCt.gameObject:SetActive(false)
    self.Profession.gameObject:SetActive(false)
    return
  end
  if self.currentPfn ~= nil then
    self.Profession.gameObject:SetActive(true)
    self.propertyCt.gameObject:SetActive(true)
    local userData = MultiProfessionSaveProxy.Instance:GetUserDataByID(self.selectedID)
    local sex = userData and userData:Get(UDEnum.SEX)
    self.professionName.text = ProfessionProxy.GetProfessionName(self.currentPfn.id, sex)
    self.professionNameEn.text = ProfessionProxy.GetProfessionNameEn(self.currentPfn.id, sex)
    self.professionBg.color = ColorUtil[string.format("CareerFlag%d", self.currentPfn.Type)]
    self.profBg.color = ColorUtil[string.format("CareerFlag%d", self.currentPfn.Type)]
    IconManager:SetProfessionIcon(self.currentPfn.icon, self.professionIcon)
    local lv = MultiProfessionSaveProxy.Instance:GetJobLevel(saveID)
    local usedAstro = #MultiProfessionSaveProxy.Instance:GetActiveStars(saveID)
    local totalAstro = AstrolabeProxy.Instance:GetTotalPointCount()
    local classID = MultiProfessionSaveProxy.Instance:GetProfession(saveID)
    lv = ProfessionProxy.Instance:GetThisJobLevelForClient(classID, lv)
    self.jobLv.text = string.format(ZhString.MultiProfession_Joblv, lv)
    self.astroPoint.text = string.format(ZhString.MultiProfession_Astro, usedAstro, totalAstro)
    local unusedSkill = MultiProfessionSaveProxy.Instance:GetUsedPoints(saveID)
    local totalSkill = Game.Myself.data.userdata:Get(UDEnum.SKILL_POINT) + (SkillProxy.Instance:GetUsedPoints() or 0)
    self.skillPoint.text = string.format(ZhString.MultiProfession_Skill, unusedSkill, totalSkill)
    local id = self.currentPfn.id
    local num = id - math.floor(id / 10) * 10
    local joblv = num * 40 + 10
    if 3 <= num then
      joblv = joblv + 30
    end
    local props = MultiProfessionSaveProxy.Instance:GetProps(self.selectedID)
    local showDatas = {}
    for i = 1, #GameConfig.SavePreviewAttrMain do
      local single = GameConfig.SavePreviewAttrMain[i]
      local test = props:GetPropByName(single)
      for k, v in pairs(props.mProps) do
        local data = {}
        if k == single then
          data.name = test.propVO.displayName
          data.value = v.value
          table.insert(showDatas, data)
        end
      end
    end
    if FunctionUnLockFunc.Me():CheckCanOpen(6200) then
      local skillGemCountDesc, attrGemCountDesc = MultiProfessionSaveProxy.Instance:GetGemCountDesc(self.selectedID)
      table.insert(showDatas, {
        name = ZhString.Gem_SkillGemCountLabel,
        value = skillGemCountDesc
      })
      table.insert(showDatas, {
        name = ZhString.Gem_AttributeGemCountLabel,
        value = attrGemCountDesc
      })
    end
    self.propGrid:ResetDatas(showDatas)
    self.propGridView:Reposition()
  end
  self:SetModel()
end

function ProfessionSaveLoadView:SetModel()
  local userData = MultiProfessionSaveProxy.Instance:GetUserDataByID(self.selectedID)
  local parts = Asset_Role.CreatePartArray()
  local _partIndex = Asset_Role.PartIndex
  local _partIndexEX = Asset_Role.PartIndexEx
  if userData then
    local hair = userData:Get(UDEnum.HAIR)
    parts[_partIndex.Body] = userData:Get(UDEnum.BODY) or 0
    parts[_partIndex.Hair] = hair or 0
    parts[_partIndex.Eye] = userData:Get(UDEnum.EYE) or 0
    parts[_partIndex.LeftWeapon] = 0
    parts[_partIndex.RightWeapon] = 0
    parts[_partIndex.Head] = userData:Get(UDEnum.HEAD) or 0
    parts[_partIndex.Wing] = userData:Get(UDEnum.BACK) or 0
    parts[_partIndex.Face] = userData:Get(UDEnum.FACE) or 0
    parts[_partIndex.Tail] = userData:Get(UDEnum.TAIL) or 0
    parts[_partIndex.Mount] = 0
    parts[_partIndex.Mouth] = userData:Get(UDEnum.MOUTH) or 0
    parts[_partIndexEX.Gender] = userData:Get(UDEnum.SEX) or 0
    parts[_partIndexEX.HairColorIndex] = userData:Get(UDEnum.HAIRCOLOR) or 0
    parts[_partIndexEX.BodyColorIndex] = userData:Get(UDEnum.CLOTHCOLOR) or 0
  end
  self.model = UIModelUtil.Instance:SetRoleModelTexture(self.PlayerModel, parts)
  self.model:RegisterWeakObserver(self)
  if self.model then
    LuaVector3.Better_Set(tempVector3, -0.6, 0.08, 0)
    self.model:SetPosition(tempVector3)
    LuaVector3.Better_Set(tempVector3, -0.67, 13.62, 0)
    self.model:SetEulerAngleY(tempVector3)
  end
  Asset_Role.DestroyPartArray(parts)
end

function ProfessionSaveLoadView:ObserverDestroyed(obj)
  if obj == self.model then
    self.model = nil
  end
end

function ProfessionSaveLoadView:ClickItem(cell)
  if cell ~= nil and cell.id ~= self.selectedID then
    if cell.data.status == 0 then
      if cell.data.type == SceneUser2_pb.ESLOT_MONTH_CARD then
        return
      else
        if BranchMgr.IsJapan() then
          OverseaHostHelper:SavePlotConfirm(cell.data)
        else
          GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
            view = PanelConfig.PurchaseSaveSlotPopUp,
            viewdata = cell.data
          })
        end
        return
      end
    end
    self.selectedID = cell.id
    self:SetPreview(self.selectedID)
    self:RefreshChoose()
  end
end

function ProfessionSaveLoadView:SetPreview(saveID)
  self.nextToggle = true
  self.nextBtnSp.flip = 0
  local savedata = MultiProfessionSaveProxy.Instance.recordDatas[saveID]
  local curSlotStatus = MultiProfessionSaveProxy.Instance:GetCurrentSlotStatus(self.selectedID)
  if savedata == nil then
    self:ClearPreview()
    self.model = nil
    if curSlotStatus == 1 then
      self.SaveBtn.gameObject:SetActive(true)
    end
  else
    self:showInfo(saveID)
    self.nilTip.gameObject:SetActive(false)
    self:SetPreviewColumns(savedata)
    self.roleName.text = savedata.rolename
    self.DeleteBtn.gameObject:SetActive(true)
    self.SaveBtn.gameObject:SetActive(false)
    self.LoadBtn.gameObject:SetActive(true)
  end
end

function ProfessionSaveLoadView:ClearPreview()
  self.roleName.text = ""
  self.jobLv.text = ""
  self.astroPoint.text = ""
  self.skillPoint.text = ""
  self.nilTip.gameObject:SetActive(true)
  self.skillColumns.gameObject:SetActive(false)
  self.DeleteBtn.gameObject:SetActive(false)
  self.SaveBtn.gameObject:SetActive(false)
  self.LoadBtn.gameObject:SetActive(false)
  self:SetModel()
  self.propertyCt.gameObject:SetActive(false)
  self.Profession.gameObject:SetActive(false)
  self.propSecGridView.gameObject:SetActive(false)
end

function ProfessionSaveLoadView:SetPreviewColumns(savedata)
  self.skillColumns.gameObject:SetActive(true)
  self.propSecGridView.gameObject:SetActive(false)
  self.shortcutSwitchIndex = 1
  self.shortcutSwitchID = ShortCutProxy.ShortCutEnum.ID1
  self:InitSwitchShortCut()
  self:SwitchShortCutTo(ShortCutProxy.SwitchList[self.shortcutSwitchIndex])
  self:RefreshShortCuts()
  local skills2 = savedata:GetEquipedAutoSkills()
  if skills2 then
    self.autoCtl:ResetDatas(skills2)
  end
end

function ProfessionSaveLoadView:RefreshChoose()
  if self.saveCtl then
    local childCells = self.saveCtl:GetCells()
    for i = 1, #childCells do
      local childCell = childCells[i]
      childCell:ShowChoose(self.selectedID)
    end
  end
end

function ProfessionSaveLoadView:DoubleClickItem(cell)
  if cell ~= nil and cell.data.status == 1 and cell.data.recordTime ~= 0 then
    GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.ChangeSaveNamePopUp,
      viewdata = cell
    })
  else
    return
  end
end

function ProfessionSaveLoadView:InitSwitchShortCut()
  if not self.skillShortCutSwitchIcon then
    self.skillShortCutSwitchIcon = self:FindChild("SwitchIcon"):GetComponent(UIMultiSprite)
  end
  if not self.skillShortCutSwtichBtn then
    self.skillShortCutSwtichBtn = self:FindChild("SkillShortCutSwitch")
  end
  self:AddClickEvent(self.skillShortCutSwtichBtn, function()
    self:TryGetNextSwitchID()
    self:SwitchShortCutTo(self.shortcutSwitchID)
  end)
end

function ProfessionSaveLoadView:TryGetNextSwitchID()
  self.shortcutSwitchIndex = self.shortcutSwitchIndex + 1
  if self.shortcutSwitchIndex > #ShortCutProxy.SwitchList then
    self.shortcutSwitchIndex = 1
  end
  local id = ShortCutProxy.SwitchList[self.shortcutSwitchIndex]
  local funcEnable = ShortCutProxy.Instance:ShortCutListIsEnable(id)
  if funcEnable then
    self.shortcutSwitchID = id
  else
    self:TryGetNextSwitchID()
  end
end

function ProfessionSaveLoadView:SwitchShortCutTo(id)
  if not self.skillShortCutSwitchIcon then
    self.skillShortCutSwitchIcon = self:FindChild("SwitchIcon"):GetComponent(UIMultiSprite)
  end
  if not self.skillShortCutSwtichBtn then
    self.skillShortCutSwtichBtn = self:FindChild("SkillShortCutSwitch")
  end
  if id ~= nil then
    self.shortcutSwitchID = id
    if self.shortcutSwitchID == ShortCutProxy.ShortCutEnum.ID1 then
      self.skillShortCutSwitchIcon.CurrentState = 0
      self.skillShortCutSwitchIcon.width = 35
      self.skillShortCutSwitchIcon.height = 35
    elseif self.shortcutSwitchID == ShortCutProxy.ShortCutEnum.ID2 then
      self.skillShortCutSwitchIcon.CurrentState = 1
      self.skillShortCutSwitchIcon.width = 35
      self.skillShortCutSwitchIcon.height = 35
    elseif self.shortcutSwitchID == ShortCutProxy.ShortCutEnum.ID3 then
      self.skillShortCutSwitchIcon.CurrentState = 2
      self.skillShortCutSwitchIcon.width = 35
      self.skillShortCutSwitchIcon.height = 35
    elseif self.shortcutSwitchID == ShortCutProxy.ShortCutEnum.ID4 then
      self.skillShortCutSwitchIcon.CurrentState = 3
      self.skillShortCutSwitchIcon.width = 35
      self.skillShortCutSwitchIcon.height = 35
    end
    self:RefreshShortCuts()
  end
end

function ProfessionSaveLoadView:RefreshShortCuts()
  self:HandleShortCutSwitchActive()
  local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
  local skillDatas = savedata:GetSkillData()
  local equipskills = skillDatas:GetCurrentEquipedSkillData(true, self.shortcutSwitchID)
  self.manualCtl:ResetDatas(equipskills)
end

function ProfessionSaveLoadView:HandleShortCutSwitchActive(note)
  local savedata = MultiProfessionSaveProxy.Instance.recordDatas[self.selectedID]
  local skillData = savedata:GetSkillData()
  local funcEnable = false
  local ID1 = ShortCutProxy.ShortCutEnum.ID1
  for k, v in pairs(ShortCutProxy.ShortCutEnum) do
    if v ~= ID1 then
      if savedata ~= nil then
        funcEnable = skillData:ShortCutListIsEnable(v)
      end
      if funcEnable then
        break
      end
    end
  end
  if funcEnable then
    self:SetActive(self.skillShortCutSwtichBtn, true)
    LuaVector3.Better_Set(tempVector3, -121, -141, 0)
    self.skillShortCutSwtichBtn.transform.localPosition = tempVector3
    LuaVector3.Better_Set(tempVector3, -71, -141, 0)
    self.manualGrid.gameObject.transform.localPosition = tempVector3
  else
    self:SetActive(self.skillShortCutSwtichBtn, false)
    LuaVector3.Better_Set(tempVector3, -121, -141, 0)
    self.manualGrid.gameObject.transform.localPosition = tempVector3
    if self.shortcutSwitchID ~= ShortCutProxy.ShortCutEnum.ID1 then
      self:SwitchShortCutTo(ShortCutProxy.ShortCutEnum.ID1)
    end
  end
end

function ProfessionSaveLoadView:ShowAttribute()
  self.skillColumns:SetActive(false)
  self.propSecGridView.gameObject:SetActive(true)
  local props = MultiProfessionSaveProxy.Instance:GetProps(self.selectedID)
  if not props then
    return
  end
  local showDatas = {}
  for i = 1, #GameConfig.SavePreviewAttrSec do
    local single = GameConfig.SavePreviewAttrSec[i]
    local test = props:GetPropByName(single)
    local atkper = 1
    local matkper = 1
    for k, v in pairs(props.mProps) do
      if k == "AtkPer" then
        atkper = (v.value + 1000) / 1000
      elseif k == "MAtkPer" then
        matkper = (v.value + 1000) / 1000
      end
    end
    for k, v in pairs(props) do
      local data = {}
      if k == single then
        data.name = string.format("[383838]%s:[-]", test.propVO.displayName)
        data.prop = test
        if k == "AtkSpd" then
          data.value = string.format("%s%%", v.value / 10)
        elseif k == "Atk" then
          data.value = math.floor(v.value * atkper)
        elseif k == "MAtk" then
          data.value = math.floor(v.value * matkper)
        else
          data.value = v.value
        end
        table.insert(showDatas, data)
      end
    end
  end
  self.propSecGrid:ResetDatas(showDatas)
  self.propSecGridView:Reposition()
end

function ProfessionSaveLoadView.CallLoadRecord(selectedID)
  return ServiceNUserProxy.Instance:CallLoadRecordUserCmd(selectedID)
end
