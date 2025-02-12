local _GrayTogLabColor = Color(0.6627450980392157, 0.6509803921568628, 0.6509803921568628, 1)
autoImport("GvgQuestTableCell")
autoImport("GvgGroupQuestTableCell")
autoImport("GvgScoreFixedCell")
autoImport("GvgScoreCell")
GvgQuestScoreTip = class("GvgQuestScoreTip", BaseTip)

function GvgQuestScoreTip:Init()
  GvgQuestScoreTip.super.Init(self)
  self.closecomp = self.gameObject:GetComponent(CloseWhenClickOtherPlace)
  
  function self.closecomp.callBack(go)
    self:CloseSelf()
  end
  
  self:AddButtonEvent("CloseButton", function()
    self:CloseSelf()
  end)
  TipsView.Me():TryShowGeneralHelpByHelpId(525, self:FindGO("HelpButton"))
  self:FindQuestObj()
  self:FindScoreObj()
  self:FindTogs()
  EventManager.Me():AddEventListener(ServiceEvent.GuildCmdGvgScoreInfoUpdateGuildCmd, self._UpdateServerScore, self)
end

function GvgQuestScoreTip:FindQuestObj()
  self.questRoot = self:FindGO("QuestRoot")
  self.empty = self:FindGO("empty", self.questRoot)
  local emptyLabel = self:FindComponent("emptyLabel", UILabel, self.empty)
  emptyLabel.text = ZhString.MainViewGvgPage_GvgQuestTip_Empty
  local questRootTableObj = self:FindGO("QuestRootTable", self.questRoot)
  self.questSeparator = self:FindGO("Separator", self.questRootTableObj)
  self.group = self:FindGO("Group", self.questRootTableObj)
  local groupTitle = self:FindGO("Title", self.group):GetComponent(UILabel)
  groupTitle.text = ZhString.MainViewGvgPage_GvgQuestTip_Group
  local groupGrid = self:FindGO("QuestTable", self.group):GetComponent(UITable)
  self.groupQuestList = UIGridListCtrl.new(groupGrid, GvgGroupQuestTableCell, "GvgQuestTableCell")
  self.personal = self:FindGO("Personal", self.questRootTableObj)
  local personalTitle = self:FindGO("Title", self.personal):GetComponent(UILabel)
  personalTitle.text = ZhString.MainViewGvgPage_GvgQuestTip_Personal
  self.personalRate = self:FindGO("Rate", self.personal):GetComponent(UILabel)
  local citytype = GvgProxy.Instance.cityType
  local config = GameConfig.GVGConfig.citytype_data[citytype]
  if config then
    local rate = config.user_task_rate - 1
    if 0 < rate then
      self.personalRate.text = string.format(ZhString.MainViewGvgPage_GvgQuestTip_PersonalRate, rate * 100)
    else
      self.personalRate.gameObject:SetActive(false)
    end
  else
    self.personalRate.gameObject:SetActive(false)
  end
  local personalGrid = self:FindGO("QuestTable", self.personal):GetComponent(UITable)
  self.personalQuestList = UIGridListCtrl.new(personalGrid, GvgQuestTableCell, "GvgQuestTableCell")
end

function GvgQuestScoreTip:FindScoreObj()
  self.scoreRoot = self:FindGO("ScoreRoot")
  local scoreRootTableObj = self:FindGO("ScoreRootTable", self.scoreRoot)
  self.scoreMid = self:FindGO("Mid", scoreRootTableObj)
  local scoreMidTitle = self:FindComponent("Title", UILabel, self.scoreMid)
  scoreMidTitle.text = ZhString.MainViewGvgPage_GvgQuestTip_ScoreMid
  local scoreMidTable = self:FindComponent("ScoreMidTable", UITable, self.scoreMid)
  self.scoreMidList = UIGridListCtrl.new(scoreMidTable, GvgScoreCell, "GvgScoreCell")
  self.scoreAfter = self:FindGO("After", scoreRootTableObj)
  local scoreAfterTitle = self:FindComponent("Title", UILabel, self.scoreAfter)
  scoreAfterTitle.text = ZhString.MainViewGvgPage_GvgQuestTip_ScoreAfter
  local scoreAfterTable = self:FindComponent("ScoreAfterTable", UITable, self.scoreAfter)
  self.scoreAfterList = UIGridListCtrl.new(scoreAfterTable, GvgScoreFixedCell, "GvgScoreCell")
end

function GvgQuestScoreTip:FindTogs()
  self.toggleRoot = self:FindGO("ToggleRoot")
  self.questTogLab = self:FindComponent("QuestTog", UILabel, self.toggleRoot)
  self.scoreTogLab = self:FindComponent("ScoreTog", UILabel, self.toggleRoot)
  self:AddClickEvent(self.questTogLab.gameObject, function()
    self.questTogLab.color = ColorUtil.NGUIWhite
    self.scoreTogLab.color = _GrayTogLabColor
    self:Show(self.questRoot)
    self:Hide(self.scoreRoot)
  end)
  self:AddClickEvent(self.scoreTogLab.gameObject, function()
    self.scoreTogLab.color = ColorUtil.NGUIWhite
    self.questTogLab.color = _GrayTogLabColor
    self:Show(self.scoreRoot)
    self:Hide(self.questRoot)
  end)
end

function GvgQuestScoreTip:UpdateByGVGSeasonState()
  if self.seasonStateSet then
    return
  end
  self.seasonStateSet = true
  self:Show(self.questRoot)
  self:Hide(self.scoreRoot)
end

function GvgQuestScoreTip:SetPos(pos)
  if self.gameObject then
    local p = self.gameObject.transform.position
    pos.z = p.z
    self.gameObject.transform.position = pos
  else
    self.pos = pos
  end
end

function GvgQuestScoreTip:SetData()
  self:UpdateQuest()
  self:UpdateScore()
  self:UpdateByGVGSeasonState()
end

function GvgQuestScoreTip:UpdateQuest()
  local isEmpty = true
  local needSeparator = false
  local groupList = {}
  local groupTaskID = GvgProxy.Instance:GetGroupTaskID()
  if groupTaskID ~= nil then
    isEmpty = false
    self:Show(self.group)
    groupList[#groupList + 1] = {
      taskid = groupTaskID,
      progress = GvgProxy.Instance:GetGroupTaskProgress()
    }
  else
    self:Hide(self.group)
  end
  self.groupQuestList:ResetDatas(groupList)
  local personalList = {}
  local infoDatas = GvgProxy.Instance.questInfoData
  for i = 1, #GvgProxy.GvgQuestListp do
    local single = GvgProxy.GvgQuestListp[i]
    personalList[#personalList + 1] = {
      key = single,
      value = infoDatas[single] or 0
    }
  end
  if 0 < #personalList then
    isEmpty = false
    self:Show(self.personal)
  else
    self:Hide(self.personal)
  end
  self.personalQuestList:ResetDatas(personalList)
  self.empty:SetActive(isEmpty)
  self.questSeparator:SetActive(needSeparator)
end

function GvgQuestScoreTip:UpdateScore()
  self:_UpdateServerScore()
  self:_UpdateFixedScore()
end

function GvgQuestScoreTip:_UpdateServerScore()
  local data = GvgProxy.Instance:IsLeisureSeason() and GvgProxy.Instance:GetLeisureBattleInfo() or GvgProxy.Instance:GetBattleInfo()
  self.scoreMidList:ResetDatas(data)
end

function GvgQuestScoreTip:_UpdateFixedScore()
  local data = GvgProxy.Instance:IsLeisureSeason() and GvgProxy.Instance:GetLeisureBattleEndInfo() or GvgProxy.Instance:GetBattleEndInfo()
  self.scoreAfterList:ResetDatas(data)
end

function GvgQuestScoreTip:AddIgnoreBounds(obj)
  if self.gameObject and self.closecomp then
    self.closecomp:AddTarget(obj.transform)
  end
end

function GvgQuestScoreTip:OnExit()
  EventManager.Me():RemoveEventListener(ServiceEvent.GuildCmdGvgScoreInfoUpdateGuildCmd, self._UpdateServerScore, self)
  self.scoreMidList:RemoveAll()
  return GvgQuestScoreTip.super.OnExit(self)
end

function GvgQuestScoreTip:CloseSelf()
  if self.callback then
    self.callback(self.callbackParam)
  end
  TipsView.Me():HideCurrent()
end

function GvgQuestScoreTip:DestroySelf()
  self.scoreMidList:RemoveAll()
  if not Slua.IsNull(self.gameObject) then
    GameObject.Destroy(self.gameObject)
  end
end
