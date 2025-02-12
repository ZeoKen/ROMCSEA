autoImport("UIAchievementPopupTipView")
UIViewAchievementPopupTip = class("UIViewAchievementPopupTip", SubView)
UIViewAchievementPopupTip.PfbPath = "part/UIViewAchievementPopupTip"
UIViewAchievementPopupTip.Instance = nil

function UIViewAchievementPopupTip:Init()
  UIViewAchievementPopupTip.Instance = self
  self:ListenServer()
end

function UIViewAchievementPopupTip:SetGameObject(game_object)
  self.gameObject = game_object
end

function UIViewAchievementPopupTip:GetGameObjects()
  self.goUIAchievementPopUpTipView = self:FindGO("UIAchievementPopupTipView")
end

function UIViewAchievementPopupTip:GetModelSet()
end

function UIViewAchievementPopupTip:LoadView()
  if self.uiAchievementPopupTipView == nil then
    self.uiAchievementPopupTipView = UIAchievementPopupTipView.new()
    self.uiAchievementPopupTipView:SetGameObject(self.goUIAchievementPopUpTipView)
    self.uiAchievementPopupTipView:GetGameObjects()
    self.uiAchievementPopupTipView:RegisterClickEvent()
    self.uiAchievementPopupTipView:Init()
    self.uiAchievementPopupTipView:SetOnComplete(function()
      self:OnAchievementPopupTipShowComplete()
    end)
  end
end

function UIViewAchievementPopupTip:ListenServer()
  self:AddListenEvt(ServiceEvent.AchieveCmdNewAchieveNtfAchCmd, self.OnReceiveCompleteAchievement_FromServer)
end

function UIViewAchievementPopupTip:ShowAchievementPopupTip(achievement_conf_id)
  if BranchMgr.IsJapan() or BranchMgr.IsSEA() or BranchMgr.IsNA() or BranchMgr.IsEU() then
    OverseaHostHelper:AFAchievementTrack(achievement_conf_id)
  end
  self.queueAchievements = self.queueAchievements or {}
  table.insert(self.queueAchievements, achievement_conf_id)
  if not self.isShowing then
    self:ShowTopAchievementPopupTip()
  end
end

function UIViewAchievementPopupTip:ShowTopAchievementPopupTip()
  if not self.isShowing and not self.pauseShowing and self.queueAchievements and #self.queueAchievements > 0 then
    local headOfQueueAchievements = self:PeekQueueAchievements()
    if headOfQueueAchievements ~= nil then
      self.uiAchievementPopupTipView:Show(headOfQueueAchievements)
      self.isShowing = true
    end
  end
end

function UIViewAchievementPopupTip:StopShowAchievementPopupTip()
  if self.isShowing then
    self.isShowing = false
    self.uiAchievementPopupTipView:StopShow()
    if self.queueAchievements ~= nil then
      TableUtility.ArrayClear(self.queueAchievements)
    end
  end
end

function UIViewAchievementPopupTip:PauseShowAchievementPopupTip()
  if self.isShowing then
    self.isShowing = false
    self.uiAchievementPopupTipView:StopShow()
  end
  self.pauseShowing = true
end

function UIViewAchievementPopupTip:ResumeShowAchievementPopupTip()
  self.pauseShowing = false
  self:ShowTopAchievementPopupTip()
end

function UIViewAchievementPopupTip:UnShowAchievementPopupTip(achievement_conf_id)
end

function UIViewAchievementPopupTip:PeekQueueAchievements()
  if self.queueAchievements ~= nil then
    for k, v in pairs(self.queueAchievements) do
      local achievementConfID = v
      if achievementConfID ~= nil then
        self.queueAchievements[k] = nil
        return achievementConfID
      end
    end
  end
  return nil
end

function UIViewAchievementPopupTip:OnAchievementPopupTipShowComplete()
  local headOfQueueAchievements = self:PeekQueueAchievements()
  if headOfQueueAchievements ~= nil then
    self.uiAchievementPopupTipView:Show(headOfQueueAchievements)
  else
    self.isShowing = false
  end
end

function UIViewAchievementPopupTip:OnReceiveCompleteAchievement_FromServer(message)
  local messageContent = message.body
  local achievementItems = messageContent.items
  if achievementItems ~= nil then
    for i = 1, #achievementItems do
      local achievementItem = achievementItems[i]
      local achievementConfig = Table_Achievement[achievementItem.id]
      local hideTips = achievementConfig and achievementConfig.FinishHideTips
      if not achievementItem.reward_get and hideTips ~= 1 and achievementItem.finishtime ~= nil and achievementItem.finishtime > 0 then
        self:ShowAchievementPopupTip(achievementItem.id)
        local _type = messageContent.type
        if _type ~= nil then
          if self.cachedAchievementData == nil then
            self.cachedAchievementData = {}
          end
          local achievements = self.cachedAchievementData[_type]
          if achievements == nil then
            self.cachedAchievementData[_type] = {
              achievementItem.id
            }
          else
            table.insert(achievements, achievementItem.id)
          end
        end
      end
    end
  end
end

function UIViewAchievementPopupTip:OpenAchievementDetailUI(achievement_conf_id)
  if achievement_conf_id ~= nil and self.cachedAchievementData ~= nil then
    for k, v in pairs(self.cachedAchievementData) do
      local _type = k
      local achievements = v
      if table.ContainsValue(achievements, achievement_conf_id) then
        autoImport("AdventurePanel")
        AdventurePanel.OpenAchievePage(_type, achievement_conf_id)
        return
      end
    end
  end
end
