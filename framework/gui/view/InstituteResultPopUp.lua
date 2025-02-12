InstituteResultPopUp = class("InstituteResultPopUp", ContainerView)
InstituteResultPopUp.ViewType = UIViewType.NormalLayer

function InstituteResultPopUp:Init()
  self.resultData = self.viewdata.viewdata.resultData
  if self.resultData then
    self:InitView()
  end
  self:MapEvent()
end

function InstituteResultPopUp:InitView()
  self.rewardInfo = self:FindGO("RewardInfo")
  self.scroeInfo = self:FindGO("ScroeInfo")
  self.getScore = self:FindComponent("GetScore", UILabel)
  self.currentScore = self:FindComponent("CurrentScore", UILabel)
  self.gardenNum = self:FindComponent("Garden", UILabel)
  self.robNum = self:FindComponent("ROB", UILabel)
  self.anim1 = self:FindGO("Anim1")
  self.anim2 = self:FindGO("Anim2")
  self.anim3 = self:FindGO("Anim3")
  local instituteresultGO = self:FindGO("59Instituteresult")
  if instituteresultGO ~= nil then
    instituteresultGO.gameObject:SetActive(false)
  end
  local effectPath = ResourcePathHelper.Effect(ResourcePathHelper.UIEffect("59Instituteresult"))
  local effect = self:LoadPreferb_ByFullPath(effectPath)
  effect.transform.localPosition = LuaGeometry.GetTempVector3(359.3, 106.7, 0)
  self:UpdateInfo()
end

function InstituteResultPopUp:MapEvent()
  self:AddListenEvt(ServiceEvent.PlayerMapChange, self.HandleMapChange)
end

function InstituteResultPopUp:HandleMapChange(note)
  if note.type == LoadSceneEvent.StartLoad then
    self:CloseSelf()
  end
end

function InstituteResultPopUp:UpdateInfo()
  local rdata = self.resultData
  if rdata.getScore > 0 then
    self.rewardInfo:SetActive(true)
    self.gardenNum.text = self.resultData.garden
    self.robNum.text = self.resultData.rob
    local multiple = self.resultData.multiple
    if multiple and multiple ~= 1 then
      self.gardenNum.text = self.resultData.garden .. ZhString.InstituteResultPopUp_Multiple .. multiple
      self.robNum.text = self.resultData.rob .. ZhString.InstituteResultPopUp_Multiple .. multiple
    end
    self.getScore.text = string.format(ZhString.InstituteResultPopUp_RewardScore, rdata.getScore)
    if 0 < rdata.todayScore then
      self.currentScore.text = ZhString.InstituteResultPopUp_DailyScore .. string.format("[FC7508]%s[-]/%s", tostring(rdata.currentScore), tostring(rdata.todayScore))
    else
      self.currentScore.text = ZhString.InstituteResultPopUp_DailyScore .. string.format("[FC7508]%s[-]", tostring(rdata.currentScore))
    end
  else
    self.rewardInfo:SetActive(false)
    self.getScore.text = ZhString.InstituteResultPopUp_FailScore
    self.currentScore.text = ZhString.InstituteResultPopUp_DailyScore .. string.format("%s/%s", tostring(rdata.currentScore), tostring(rdata.todayScore))
  end
end

function InstituteResultPopUp:PlayInstituteAnim()
  self.anim1:SetActive(false)
  self.anim2:SetActive(false)
  self.anim3:SetActive(false)
  if self.lt then
    self.lt:Destroy()
    self.lt = nil
  end
  self.lt = TimeTickManager.Me():CreateOnceDelayTick(1500, function(owner, deltaTime)
    self.anim1:SetActive(true)
    self.lt = TimeTickManager.Me():CreateOnceDelayTick(300, function(owner, deltaTime)
      self.anim2:SetActive(true)
      self.lt = TimeTickManager.Me():CreateOnceDelayTick(300, function(owner, deltaTime)
        self.anim3:SetActive(true)
      end, self)
    end, self)
  end, self)
end

function InstituteResultPopUp:OnEnter()
  InstituteResultPopUp.super.OnEnter(self)
  self:CameraRotateToMe()
  self:PlayInstituteAnim()
end

function InstituteResultPopUp:OnExit()
  if self.lt then
    self.lt:cancel()
    self.lt = nil
  end
  InstituteResultPopUp.super.OnExit(self)
  self:CameraReset()
end
