autoImport("CupModeForbiddenPro")
CompetiveModeView = class("CompetiveModeView", SubView)
local CompetiveModeViewPath = ResourcePathHelper.UIView("CompetiveModeView")
local ViewName = "CompetiveModeView"
local TeamPwsViewName = "TeamPwsSubView"
local CupModeViewName = "CupModeView"
local FreeModeViewName = "TeamPwsFreeModeView"
local CustomModeViewName = "PvpCustomModeView"
local TabTextures = GameConfig.CompetiveMode and GameConfig.CompetiveMode.TabTextures or {
  "12pvp_bg_pic4",
  "12pvp_bg_pic5"
}
local TabNames = GameConfig.CompetiveMode and GameConfig.CompetiveMode.TabNames or ZhString.CompetiveModeTabNames
local tickInterval = 5000
local _cellName = "CupModeForbiddenPro"
local _cellSize = 0.4

function CompetiveModeView:OnEnter()
  CompetiveModeView.super.OnEnter(self)
  self:StartTick()
end

function CompetiveModeView:OnExit()
  CompetiveModeView.super.OnExit(self)
  self:StopTick()
end

function CompetiveModeView:OnDestroy()
  local picManager = PictureManager.Instance
  picManager:UnLoadPVP(TabTextures[1], self.teamPwsTex)
  picManager:UnLoadPVP(TabTextures[2], self.cupModeTex)
  picManager:UnLoadPVP(TeamPwsView.TexSeason, self.txt_season)
  self:StopTick()
  CompetiveModeView.super.OnDestroy(self)
end

function CompetiveModeView:Init()
  self:FindObjs()
  self:AddBtnEvts()
  self:AddViewEvts()
  self:InitShow()
end

function CompetiveModeView:LoadSubViews()
  self.rootGO = self:FindGO("TeamPwsView")
  local go = self:LoadPreferb_ByFullPath(CompetiveModeViewPath, self.rootGO, true)
  go.name = ViewName
  self.teamPwsView = self:AddSubView(TeamPwsViewName, TeamPwsView)
  self.cupModeView = self:AddSubView(CupModeViewName, CupModeView)
  self.freeModeView = self:AddSubView(FreeModeViewName, TeamPwsFreeModeView)
  self.customModeView = self:AddSubView(CustomModeViewName, PvpCustomModeView)
end

function CompetiveModeView:FindObjs()
  self:LoadSubViews()
  self.teamPwsTabGO = self:FindGO("TeamPwsTab", self.rootGO)
  self.teamPwsViewGO = self:FindGO(TeamPwsViewName, self.rootGO)
  self.teamPwsTex = self:FindComponent("Tex", UITexture, self.teamPwsTabGO)
  self.teamPwsName = self:FindComponent("Name", UILabel, self.teamPwsTabGO)
  self.teamPwsRuleGO = self:FindGO("RuleBtn", self.teamPwsTabGO)
  self.weekLabel = self:FindComponent("Desc", UILabel, self.teamPwsTabGO)
  self.teamPwsDescBG = self:FindGO("DescBG", self.teamPwsTabGO)
  self.weekLabel.gameObject:SetActive(false)
  self.teamPwsDescBG:SetActive(false)
  self.cupModeTabGO = self:FindGO("CupModeTab", self.rootGO)
  self.cupModeViewGO = self:FindGO(CupModeViewName, self.rootGO)
  self.cupModeTex = self:FindComponent("Tex", UITexture, self.cupModeTabGO)
  self.cupModeName = self:FindComponent("Name", UILabel, self.cupModeTabGO)
  self.cupModeDesc = self:FindComponent("Desc", UILabel, self.cupModeTabGO)
  self:AddClickEvent(self.cupModeDesc.gameObject, function()
    local param = CupMode6v6Proxy.Instance:GetForbiddenProStr()
    if not StringUtil.IsEmpty(param) then
      MsgManager.ConfirmMsgByID(28088, nil, nil, nil, param)
    end
  end)
  self.cupModeRuleGO = self:FindGO("RuleBtn", self.cupModeTabGO)
  self.cupModeDescBG = self:FindGO("DescBG", self.cupModeTabGO)
  self.freeModeTabGO = self:FindGO("FreeModeTab", self.rootGO)
  self.freeModeViewGO = self:FindGO(FreeModeViewName, self.rootGO)
  self.freeModeTex = self:FindComponent("Tex", UITexture, self.freeModeTabGO)
  self.freeModeName = self:FindComponent("Name", UILabel, self.freeModeTabGO)
  self.freeModeRuleGO = self:FindGO("RuleBtn", self.freeModeTabGO)
  self.freeModeDescBG = self:FindGO("DescBG", self.freeModeTabGO)
  self.freeModeDescBG:SetActive(false)
  self.customModeTabGO = self:FindGO("CustomModeTab", self.rootGO)
  self.customModeViewGO = self:FindGO(CustomModeViewName, self.rootGO)
  self.customModeTex = self:FindComponent("Tex", UITexture, self.customModeTabGO)
  self.customModeName = self:FindComponent("Name", UILabel, self.customModeTabGO)
  self.customModeRuleGO = self:FindGO("RuleBtn", self.customModeTabGO)
  self.customModeDescBG = self:FindGO("DescBG", self.customModeTabGO)
  self.customModeDescBG:SetActive(false)
  self.helpBtn = self:FindGO("HelpBtn", self.rootGO)
  self.openLabel = self:FindGO("OpenLabel", self.rootGO):GetComponent(UILabel)
  self.openLabel_Bg = self:FindGO("OpenBg", self.openLabel.gameObject):GetComponent(UISprite)
  self.txt_season = self:FindGO("txt_season", self.openLabel.gameObject):GetComponent(UITexture)
  self.openLabel.gameObject:SetActive(false)
end

function CompetiveModeView:_loadForbiddenProPfb()
  local cellpfb = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UICell(_cellName))
  if nil == cellpfb then
    redlog("can not find cellpfb", _cellName)
    return
  end
  cellpfb.transform:SetParent(self.cupModeTabGO.transform, false)
  cellpfb.transform.localScale = LuaGeometry.GetTempVector3(_cellSize, _cellSize, _cellSize)
  return cellpfb
end

function CompetiveModeView:InitShow()
  local picManager = PictureManager.Instance
  picManager:SetPVP(TabTextures[1], self.teamPwsTex)
  picManager:SetPVP(TabTextures[2], self.cupModeTex)
  picManager:SetPVP(TeamPwsView.TexSeason, self.txt_season)
  if TabNames then
    self.teamPwsName.text = TabNames[1]
    self.cupModeName.text = TabNames[2]
    self.freeModeName.text = TabNames[3]
    self.customModeName.text = TabNames[4]
  end
  self:TabChangeHandler(self.teamPwsTabGO.name)
end

local ShowHelpDesc = function(id)
  local desc = Table_Help[id] and Table_Help[id].Desc or ZhString.Help_RuleDes
  TipsView.Me():ShowGeneralHelp(desc)
end

function CompetiveModeView:AddBtnEvts()
  self:AddTabChangeEvent(self.teamPwsTabGO, self.teamPwsViewGO, self.teamPwsView)
  self:AddTabChangeEvent(self.cupModeTabGO, self.cupModeViewGO, self.cupModeView)
  self:AddTabChangeEvent(self.freeModeTabGO, self.freeModeViewGO, self.freeModeView)
  self:AddTabChangeEvent(self.customModeTabGO, self.customModeViewGO, self.customModeView)
  if self.teamPwsRuleGO then
    self:AddClickEvent(self.teamPwsRuleGO, function(go)
      ShowHelpDesc(PanelConfig.TeamPwsView.id)
    end)
  end
  if self.cupModeRuleGO then
    self:AddClickEvent(self.cupModeRuleGO, function(go)
      ShowHelpDesc(PanelConfig.CupModeView.id)
    end)
  end
  self:AddClickEvent(self.helpBtn, function()
    if self.teamPwsView.objRoot.activeSelf then
      ShowHelpDesc(PanelConfig.TeamPwsView.id)
    elseif self.cupModeView.rootGO.activeSelf then
      ShowHelpDesc(PanelConfig.CupModeView.id)
    elseif self.freeModeView.objRoot.activeSelf then
      ShowHelpDesc(PanelConfig.FreeBattleView.id)
    end
  end)
end

function CompetiveModeView:AddViewEvts()
  self:AddListenEvt(CupModeEvent.ScheduleChanged_6v6, self.RefreshScheduleStatus)
  self:AddListenEvt(CupModeEvent.SeasonInfo_6v6, self.RefreshScheduleStatus)
  self:AddListenEvt(CupModeEvent.SeasonFinish_6v6, self.OnSeasonFinish)
  self:AddListenEvt(ServiceEvent.MatchCCmdQueryTeamPwsTeamInfoMatchCCmd, self.HandleQueryTeamPwsTeamInfo)
end

function CompetiveModeView:OnSeasonFinish()
  self:StopTick()
end

function CompetiveModeView:UpdateView()
  self:UpdateCurrentTabView()
  self:RestartTick()
  self:UpdateTabDesc()
end

function CompetiveModeView:StartTick()
  if not self.timeTicker then
    self.tickId = self.tickId or 101
    self.timeTicker = TimeTickManager.Me():CreateTick(0, tickInterval, self.Tick, self, self.tickId)
  end
end

function CompetiveModeView:StopTick()
  if self.timeTicker then
    self.timeTicker:Destroy()
    self.timeTicker = nil
    self.tickId = self.tickId + 1
  end
end

function CompetiveModeView:RestartTick()
  self:StopTick()
  self:StartTick()
end

function CompetiveModeView:Tick()
  local proxy = CupMode6v6Proxy.Instance
  proxy:TryUpdateScheduleStatus()
end

function CompetiveModeView:RefreshScheduleStatus()
  self:UpdateTabDesc()
end

function CompetiveModeView:UpdateTabDesc()
  local curServerTime = ServerTime.CurServerTime() / 1000
  local proxy = CupMode6v6Proxy.Instance
  self.cupModeDescBG:SetActive(false)
  local cupModeStr
  if proxy:IsSeasonNoOpen() or proxy:IsSeasonEnd() then
  elseif curServerTime < proxy.warbandStartTime then
    cupModeStr = CupModeProxy.CupModeStartTimeLeft(proxy.warbandStartTime)
  elseif proxy:IsInSignupTime() then
    cupModeStr = ZhString.Warband_Tab_TimeSignup
  else
    cupModeStr = ZhString.Warband_Tab_TimeToday
  end
  self.cupModeStr = cupModeStr
end

function CompetiveModeView:HandleQueryTeamPwsTeamInfo(note)
  local serverData = note.body
  local _, pwsConfig = next(GameConfig.PvpTeamRaid)
  local nextOpenTime = serverData.opentime
  local curTime = ServerTime.CurServerTime() / 1000
  self.weekLabel.gameObject:SetActive(false)
  if not nextOpenTime then
    return
  end
  if nextOpenTime < curTime then
    return
  end
  local weekCount = math.ceil(serverData.count / (pwsConfig.EventCountPerWeek or 1))
  local strWeek
  if 10 < weekCount then
    local first, second = math.modf(weekCount / 10)
    if 0 < second then
      strWeek = string.format("%s%s", ZhString.ChinaNumber[10], ZhString.ChinaNumber[math.floor(second * 10 + 0.5)])
    else
      strWeek = ZhString.ChinaNumber[10]
    end
    if 1 < first then
      strWeek = string.format("%s%s", ZhString.ChinaNumber[math.clamp(first, 1, 9)], strWeek)
    end
  else
    strWeek = 0 < weekCount and ZhString.ChinaNumber[weekCount] or weekCount
  end
  self.teamPwsStr = strWeek
  local season = serverData.season or 1
  PictureManager.Instance:SetPVP("pvp_icon_season_" .. season, self.txt_season)
end

function CompetiveModeView:UpdateOpenLabel()
  local str = ""
  if self.teamPwsStr and self.teamPwsStr ~= "" then
    str = str .. self.teamPwsStr
  end
  if self.cupModeStr and self.cupModeStr ~= "" then
    if str ~= "" then
      str = str .. "\n"
    end
    str = str .. self.cupModeStr
  end
  if str ~= "" then
    self.openLabel.gameObject:SetActive(true)
    self.openLabel.text = str
  else
    self.openLabel.gameObject:SetActive(false)
  end
  local printY = self.openLabel.printedSize.y
  self.openLabel_Bg.height = printY + 10
end

function CompetiveModeView:TabChangeHandler(key)
  CompetiveModeView.super.TabChangeHandler(self, key)
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
