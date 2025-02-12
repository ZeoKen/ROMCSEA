autoImport("LeisureModelView")
autoImport("WarbandModelView")
autoImport("CupModeForbiddenPro")
MultiPvpView = class("MultiPvpView", SubView)
local TEXTURE = {
  "12pvp_bg_pic2",
  "12pvp_bg_pic5",
  "12pvp_bg"
}
local tick_interval = 5000
local _cellName = "CupModeForbiddenPro"
local _cellSize = 0.4

function MultiPvpView:Init()
  self.coreTabMap = ReusableTable.CreateTable()
  self:FindObjs()
  self:InitShow()
  self:AddEvts()
  self:ForbidWarband()
end

function MultiPvpView:AddEvts()
  self:AddListenEvt(PVPEvent.TwelveChamption_ScheduleChanged, self.RefreshScheduleStatus)
  self:AddListenEvt(ServiceEvent.MatchCCmdQueryTwelveSeasonInfoMatchCCmd, self.RefreshScheduleStatus)
  self:AddListenEvt(ServiceEvent.MatchCCmdQueryTwelveSeasonFinishMatchCCmd, self.clearTimeTick)
  self:AddListenEvt(PVPEvent.TwelveChamption_Fighting, self.UpdateFightingTime)
end

function MultiPvpView:ForbidWarband()
  local warbandOpen = GameConfig.SystemForbid.WarbandForbid == nil
  self.warbandModelBtn:SetActive(warbandOpen)
  self.MultiPvpGrid:Reposition()
end

local ShowHelpDesc = function(id)
  local desc = Table_Help[id] and Table_Help[id].Desc or ZhString.Help_RuleDes
  TipsView.Me():ShowGeneralHelp(desc)
end

function MultiPvpView:FindObjs()
  self.gameObject = self:FindGO("MultiPvpView")
  self.leisureModelBtn = self:FindGO("LeisureModelBtn")
  self.leisureModelObj = self:FindGO("LeisureModelView")
  self.leisureTex = self:FindComponent("LeisureTex", UITexture)
  self.battleName = self:FindComponent("Name", UILabel, self.leisureModelBtn)
  self.battleName.text = ZhString.TwelvePVP_RelaxTabName
  self.twelvePVP_RuleBtn = self:FindGO("RuleBtn", self.leisureModelBtn)
  self:AddClickEvent(self.twelvePVP_RuleBtn, function(g)
    ShowHelpDesc(PanelConfig.LeisureModelView.id)
  end)
  self.MultiPvpGrid = self:FindComponent("MultiPvpGrid", UIGrid)
  self.warbandModelBtn = self:FindGO("WarbandModelBtn")
  self.warbandModelObj = self:FindGO("WarbandModelView")
  self.warbandTex = self:FindComponent("WarbandTex", UITexture)
  self.warbandDesc = self:FindComponent("WarTabDesc", UILabel)
  self:AddClickEvent(self.warbandDesc.gameObject, function()
    local param = WarbandProxy.Instance:GetForbiddenProStr()
    if not StringUtil.IsEmpty(param) then
      MsgManager.ConfirmMsgByID(28088, nil, nil, nil, param)
    end
  end)
  self.cupModeDescBG = self:FindGO("DescBG", self.warbandModelBtn)
  self.warbandRuleBtn = self:FindGO("RuleBtn", self.warbandModelBtn)
  self:AddClickEvent(self.warbandRuleBtn, function(g)
    ShowHelpDesc(PanelConfig.WarbandModelView.id)
  end)
  self.freeModeBtn = self:FindGO("FreeModeBtn")
  self.freeModeObj = self:FindGO("FreeModeView")
  self.warbandTabName = self:FindComponent("Name", UILabel, self.warbandModelBtn)
  self.warbandTabName.text = ZhString.Warband_TabName
  self.warbandCommingSoonBtn = self:FindGO("WarbandCommingSoonBtn", self.gameObject)
  self.commingSoonTex = self:FindComponent("CommingSoonTex", UITexture, self.warbandCommingSoonBtn)
  self.commingSoonLab = self:FindComponent("CommingSoonLab", UILabel, self.warbandCommingSoonBtn)
  self.commingSoonLab.text = ZhString.TwelvePVP_ComingSoon
  self.warbandCommingSoonBtn:SetActive(false)
  self.customModeBtn = self:FindGO("CustomModeBtn")
  self.customModeObj = self:FindGO("MultiPvpCustomModeView")
  self.helpBtn = self:FindGO("HelpBtn", self.gameObject)
  self:AddClickEvent(self.helpBtn, function()
    if self.leisureModelObj.activeSelf then
      ShowHelpDesc(PanelConfig.LeisureModelView.id)
    elseif self.warbandModelObj.activeSelf then
      ShowHelpDesc(PanelConfig.WarbandModelView.id)
    elseif self.freeModeObj.activeSelf then
      ShowHelpDesc(929)
    elseif self.customModeObj.activeSelf then
      ShowHelpDesc(PanelConfig.LeisureModelView.id)
    end
  end)
  self.openLabel = self:FindGO("OpenLabel", self.gameObject):GetComponent(UILabel)
  self.openLabel_Bg = self:FindGO("OpenBg", self.openLabel.gameObject):GetComponent(UISprite)
  self.txt_season = self:FindGO("txt_season", self.openLabel.gameObject):GetComponent(UITexture)
  self.openLabel.gameObject:SetActive(false)
end

function MultiPvpView:_loadForbiddenProPfb()
  local cellpfb = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UICell(_cellName))
  if nil == cellpfb then
    redlog("can not find cellpfb", _cellName)
    return
  end
  cellpfb.transform:SetParent(self.warbandModelBtn.transform, false)
  cellpfb.transform.localScale = LuaGeometry.GetTempVector3(_cellSize, _cellSize, _cellSize)
  return cellpfb
end

function MultiPvpView:InitTex()
  PictureManager.Instance:SetPVP(TEXTURE[1], self.leisureTex)
  PictureManager.Instance:SetPVP(TEXTURE[2], self.warbandTex)
  PictureManager.Instance:SetPVP(TEXTURE[3], self.commingSoonTex)
end

function MultiPvpView:InitShow()
  self.leisureModelView = self:AddSubView("LeisureModelView", LeisureModelView)
  self.warbandModelView = self:AddSubView("WarbandModelView", WarbandModelView)
  self.freeModeView = self:AddSubView("MultiPvpFreeModeView", MultiPvpFreeModeView)
  self.customModeView = self:AddSubView("MultiPvpCustomModeView", MultiPvpCustomModeView)
  self:AddTabChangeEvent(self.leisureModelBtn, self.leisureModelObj, self.leisureModelView)
  self:AddTabChangeEvent(self.warbandModelBtn, self.warbandModelObj, self.warbandModelView)
  self:AddTabChangeEvent(self.freeModeBtn, self.freeModeObj, self.freeModeView)
  self:AddTabChangeEvent(self.customModeBtn, self.customModeObj, self.customModeView)
  if self.viewdata.view and self.viewdata.view.tab then
    self:TabChangeHandlerWithPanelID(self.viewdata.view.tab)
  else
    self:TabChangeHandler(self.leisureModelBtn.name)
  end
  self:UpdateTabDesc()
end

function MultiPvpView:AddTabChangeEvent(toggleObj, targetObj, script)
  local key = toggleObj.name
  if not self.coreTabMap[key] then
    local table = ReusableTable.CreateTable()
    table.obj = targetObj
    table.script = script
    table.tabGO = toggleObj
    self.coreTabMap[key] = table
    self:AddClickEvent(toggleObj, function(go)
      self:TabChangeHandler(go.name)
    end)
  end
end

function MultiPvpView:TabChangeHandlerWithPanelID(tabID)
  if tabID == PanelConfig.LeisureModelView.tab then
    self:TabChangeHandler(self.leisureModelBtn.name)
  elseif tabID == PanelConfig.WarbandModelView.tab then
    self:TabChangeHandler(self.warbandModelBtn.name)
  else
    self:TabChangeHandler(self.leisureModelBtn.name)
  end
end

local WarbandStartTimeLeft = function(t)
  local day, hour, min = ClientTimeUtil.GetFormatRefreshTimeStr(t)
  if 0 < day then
    return string.format(ZhString.Warband_Tab_DayTimeLeft, day)
  elseif 0 < hour then
    return string.format(ZhString.Warband_Tab_HourTimeLeft, hour)
  elseif 0 < min then
    return string.format(ZhString.Warband_Tab_MinTimeLeft, min)
  else
    return ZhString.Warband_Tab_SecTimeLeft
  end
end

function MultiPvpView:RefreshScheduleStatus(note)
  local serverData = note and note.body
  self:UpdateTabDesc()
  self.warbandModelView:UpdateScheduleStatus()
  local curSeason = serverData and serverData.season or 1
  if curSeason then
    PictureManager.Instance:SetPVP("pvp_icon_season_" .. curSeason, self.txt_season)
  end
end

function MultiPvpView:UpdateTabDesc()
  local multiCupModeStr
  local curServerTime = ServerTime.CurServerTime() / 1000
  if WarbandProxy.Instance:IsSeasonNoOpen() or WarbandProxy.Instance:IsSeasonEnd() then
    multiCupModeStr = ""
  elseif curServerTime < WarbandProxy.Instance.warbandStartTime then
    multiCupModeStr = WarbandStartTimeLeft(WarbandProxy.Instance.warbandStartTime)
  elseif WarbandProxy.Instance:IsInSignupTime() then
    multiCupModeStr = ZhString.Warband_Tab_TimeSignup
  else
    multiCupModeStr = ZhString.Warband_Tab_TimeToday
  end
  self.multiCupModeStr = multiCupModeStr
end

function MultiPvpView:TabChangeHandler(key)
  if self.currentKey ~= key then
    if self.currentKey then
      self.coreTabMap[self.currentKey].obj:SetActive(false)
    end
    self.coreTabMap[key].obj:SetActive(true)
    self.coreTabMap[key].script:UpdateView()
    self.currentKey = key
  end
  for k, v in pairs(self.coreTabMap) do
    if v.tabGO then
      local bg = self:FindComponent("Bg", UISprite, v.tabGO)
      local name = self:FindComponent("Name", UILabel, v.tabGO)
      if k == key then
        bg.spriteName = "sports_btn_liang"
        name.color = LuaGeometry.GetTempVector4(0.34901960784313724, 0.21176470588235294, 0.07450980392156863, 1)
      else
        bg.spriteName = "sports_btn_an"
        name.color = LuaColor.White()
      end
    end
  end
  self.helpBtn:SetActive(not self.customModeView.objRoot.activeSelf)
end

function MultiPvpView:UpdateView()
  self.coreTabMap[self.currentKey].script:UpdateView()
  self:clearTimeTick()
  self.timeTick = TimeTickManager.Me():CreateTick(0, tick_interval, self._tick, self)
end

function MultiPvpView:OnExit()
  self:clearTimeTick()
  MultiPvpView.super.OnExit(self)
end

function MultiPvpView:OnDestroy()
  for k, v in pairs(self.coreTabMap) do
    ReusableTable.DestroyAndClearTable(v)
  end
  ReusableTable.DestroyAndClearTable(self.coreTabMap)
  self:clearTimeTick()
  MultiPvpView.super.OnDestroy(self)
end

function MultiPvpView:clearTimeTick()
  if self.timeTick then
    self.timeTick:Destroy()
    self.timeTick = nil
  end
end

function MultiPvpView:_tick()
  WarbandProxy.Instance:TryUpdateScheduleStatus()
end

function MultiPvpView:UpdateFightingTime()
  if self.warbandModelView then
    self.warbandModelView:UpdateFightingTime()
  end
end

function MultiPvpView:UpdateOpenLabel()
  local str = ""
  if self.multiCupModeStr and self.multiCupModeStr ~= "" then
    str = str .. self.multiCupModeStr
  end
  if str ~= "" then
    self.openLabel.gameObject:SetActive(true)
    self.openLabel.text = str
    local printY = self.openLabel.printedSize.y
    self.openLabel_Bg.height = printY + 10
  else
    self.openLabel.gameObject:SetActive(false)
  end
end
