local BaseCell = autoImport("BaseCell")
GuildActivityCell = class("GuildActivityCell", BaseCell)
GuildActivityCellEvent = {
  TraceRoad = "GuildActivityCellEvent_TraceRoad",
  ClickHelp = "GuildActivityCellEvent_ClickHelp"
}
local GUILD_CHALLENGE_REWARD = SceneTip_pb.EREDSYS_GUILD_CHALLENGE_REWARD or 42
local assembleProgressFoe = "guild_bg_jindutiao"
local tempArgs = {}

function GuildActivityCell:Init()
  self.name = self:FindComponent("Name", UILabel)
  self.desc = self:FindComponent("Tip", UILabel)
  self.headIcon = self:FindComponent("HeadIcon", UISprite)
  self.multiplySymbol = self:FindGO("MultiplySymbol")
  self.multiplySymbol_label = self:FindComponent("Label", UILabel, self.multiplySymbol.gameObject)
  self.multiplySymbol_reward = self:FindComponent("Tip", UILabel, self.multiplySymbol)
  if BranchMgr.IsSEA() or BranchMgr.IsNA() or BranchMgr.IsEU() then
    if AppBundleConfig.GetSDKLang() ~= "cn" then
      self.multiplySymbol_reward.text = ZhString.OverSea_Reward
    else
      self.multiplySymbol_reward.text = ZhString.Cn_Reward
    end
  else
    self.multiplySymbol_reward.text = ZhString.Cn_Reward
  end
  self.transButton = self:FindGO("TransButton")
  self.transButton_label = self:FindComponent("Label", UILabel, self.transButton)
  self:AddClickEvent(self.transButton, function(go)
    if self.delayGildTimer then
      MsgManager.FloatMsg(nil, ZhString.TouchSoFast)
      return
    elseif BranchMgr.IsSEA() then
      self.delayGildTimer = TimeTickManager.Me():CreateOnceDelayTick(10000, function(owner, deltaTime)
        self.delayGildTimer = nil
      end, self)
    end
    self:DoTrace()
  end)
  self.helpButton = self:FindGO("DescButton")
  self:AddClickEvent(self.helpButton, function(go)
    self:PassEvent(GuildActivityCellEvent.ClickHelp, self.data)
  end)
  self.assembleButton = self:FindGO("AssembleButton")
  self.assembleGreyBtn = self:FindGO("AssembleButtonGrey")
  self:AddClickEvent(self.assembleButton, function()
    self:OnAssembleBtnClick()
  end)
  self:AddClickEvent(self.assembleGreyBtn, function()
    self:OnAssembleGreyBtnClick()
  end)
  self.foe = self:FindComponent("foe", UITexture)
  self.assembleProgressBar = self:FindComponent("AssembleProgress", UIProgressBar)
  self.assembleDesc = self:FindComponent("AssembleTip", UILabel)
  self.remainTimeLabel = self:FindComponent("RemainTime", UILabel)
end

function GuildActivityCell:DoTrace()
  if Game.Myself:IsDead() then
    MsgManager.ShowMsgByIDTable(2500)
  elseif self.data then
    local assembleId = self.data.AssembleId
    if assembleId then
      local state = GuildProxy.Instance:GetGuildAssembleState()
      if state == ActivityCmd_pb.EGUILDASSEMBLE_STATUS_PROCESS then
        self:GotoNpc()
      elseif state == ActivityCmd_pb.EGUILDASSEMBLE_STATUS_COMPLETE then
        self:JumpPanel()
      end
    elseif self.data.PanelId then
      self:JumpPanel()
    else
      self:GotoNpc()
    end
  end
end

function GuildActivityCell:JumpPanel()
  if self.data.PanelId then
    self:sendNotification(UIEvent.JumpPanel, {
      view = self.data.PanelId,
      viewdata = self.data
    })
  end
end

function GuildActivityCell:GotoNpc()
  local currentRaidID = SceneProxy.Instance:GetCurRaidID()
  local raidData = currentRaidID and Table_MapRaid[currentRaidID]
  if raidData and raidData.Type == 10 then
    TableUtility.TableClear(tempArgs)
    tempArgs.npcUID = self.data.UniqueID
    local cmd = MissionCommandFactory.CreateCommand(tempArgs, MissionCommandVisitNpc)
    if cmd then
      Game.Myself:Client_SetMissionCommand(cmd)
    end
    self:PassEvent(GuildActivityCellEvent.TraceRoad)
  else
    ServiceGuildCmdProxy.Instance:CallEnterTerritoryGuildCmd()
  end
end

function GuildActivityCell:SetData(data)
  self.data = data
  if data then
    self.gameObject:SetActive(true)
    self.name.text = data.Name
    IconManager:SetUIIcon(data.Icon, self.headIcon)
    self.headIcon:MakePixelPerfect()
    local timeStr = ""
    if data.AssembleId then
      local curAssembleNum = GuildProxy.Instance:GetGuildAssembleCompleteNum()
      self.desc.text = ""
      self.assembleDesc.text = string.format(data.Content, curAssembleNum)
      local endTime = ClientTimeUtil.GetOSDateTime(data.FinishTime)
      local serverTime = ServerTime.CurServerTime() / 1000
      local remainTime = endTime - serverTime
      remainTime = math.max(remainTime, 0)
      local day, hour, min = ClientTimeUtil.FormatTimeBySec(remainTime)
      if day <= 0 then
        if hour <= 0 then
          min = math.max(min, 1)
          timeStr = timeStr .. string.format(ZhString.NoviceBattlePassRemainTimeMin, min)
        else
          timeStr = timeStr .. string.format(ZhString.RemainTimeHour, hour)
        end
      else
        timeStr = timeStr .. string.format(ZhString.RemainTimeDay, day)
      end
      self.assembleProgressBar.gameObject:SetActive(true)
      PictureManager.Instance:SetGuildBuilding(assembleProgressFoe, self.foe)
      if GameConfig.Assemble then
        local config = GameConfig.Assemble[data.AssembleId]
        if config then
          local reward = config.Reward
          local maxAssembleNum = reward[#reward].Amount
          self.assembleProgressBar.value = curAssembleNum / maxAssembleNum
        end
      end
      local assembleState = GuildProxy.Instance:GetGuildAssembleState()
      local isCurChar = GuildProxy.Instance:IsCurrentCharacterAssembled()
      local isCompleteCurGuild = GuildProxy.Instance:IsAssembledInCurGuild()
      self.assembleButton:SetActive(assembleState == ActivityCmd_pb.EGUILDASSEMBLE_STATUS_NONE)
      if assembleState == ActivityCmd_pb.EGUILDASSEMBLE_STATUS_PROCESS then
        self.assembleGreyBtn:SetActive(not isCurChar)
        self.transButton:SetActive(isCurChar)
        self.transButton_label.text = ZhString.GuildActivityCell_Go
      elseif assembleState == ActivityCmd_pb.EGUILDASSEMBLE_STATUS_COMPLETE then
        self.assembleGreyBtn:SetActive(not isCurChar or not isCompleteCurGuild)
        self.transButton:SetActive(isCurChar and isCompleteCurGuild)
        self.transButton_label.text = ZhString.GuildActivityCell_Show
      else
        self.assembleGreyBtn:SetActive(false)
        self.transButton:SetActive(false)
      end
    else
      self.desc.text = data.Content
      self.assembleDesc.text = ""
      self.assembleProgressBar.gameObject:SetActive(false)
      self.assembleButton:SetActive(false)
      self.assembleGreyBtn:SetActive(false)
      self.transButton:SetActive(true)
      if data.PanelId then
        self.transButton_label.text = ZhString.GuildActivityCell_Show
      elseif data.UniqueID then
        self.transButton_label.text = ZhString.GuildActivityCell_Go
      end
    end
    self.remainTimeLabel.text = timeStr
    if data.id == 7 then
      local rewardInfo = ActivityEventProxy.Instance:GetRewardByType(AERewardType.GuildDonate)
      local discount = rewardInfo and rewardInfo:GetMultiple() or 1
      if discount <= 1 then
        self.multiplySymbol:SetActive(false)
      else
        self.multiplySymbol:SetActive(true)
        self.multiplySymbol_label.text = "*" .. math.floor(discount)
      end
    else
      self.multiplySymbol:SetActive(false)
    end
    self.helpButton:SetActive(0 < #data.HelpID)
    self:RegistRedTip()
  else
    self.gameObject:SetActive(false)
  end
end

function GuildActivityCell:RegistRedTip()
  self:UnRegisteRedTip()
  if self.data == nil then
    return
  end
  if self.data.PanelId and self.data.PanelId == PanelConfig.GuildChallengeTaskPopUp.id then
    self.red_registe = true
    RedTipProxy.Instance:RegisterUI(GUILD_CHALLENGE_REWARD, self.transButton, 10, {-7, -7})
  end
  if self.data.AssembleId then
    RedTipProxy.Instance:RegisterUI(SceneTip_pb.EREDSYS_GUILD_ASSEMBLY_AWARD, self.transButton, 10, {6, -2}, NGUIUtil.AnchorSide.TopLeft)
  end
end

function GuildActivityCell:UnRegisteRedTip()
  if self.red_registe then
    RedTipProxy.Instance:UnRegisterUI(GUILD_CHALLENGE_REWARD, self.transButton)
  end
  self.red_registe = false
  if self.data.AssembleId then
    RedTipProxy.Instance:UnRegisterUI(SceneTip_pb.EREDSYS_GUILD_ASSEMBLY_AWARD, self.transButton)
  end
end

function GuildActivityCell:OnRemove()
  self:UnRegisteRedTip()
  if self.delayGildTimer then
    self.delayGildTimer:Destroy()
    self.delayGildTimer = nil
  end
  PictureManager.Instance:UnloadGuildBuilding(assembleProgressFoe, self.foe)
end

function GuildActivityCell:OnAssembleBtnClick()
  MsgManager.ConfirmMsgByID(43133, function()
    ServiceActivityCmdProxy.Instance:CallGuildAssembleAcceptCmd()
  end)
end

function GuildActivityCell:OnAssembleGreyBtnClick()
  local isCurChar = GuildProxy.Instance:IsCurrentCharacterAssembled()
  local isCurGuild = GuildProxy.Instance:IsAssembledInCurGuild()
  if not isCurChar then
    MsgManager.ShowMsgByID(43134)
  elseif not isCurGuild then
    MsgManager.ShowMsgByID(43135)
  end
end

function GuildActivityCell:OnGuildAssembleAccept()
  MsgManager.ConfirmMsgByID(43119, function()
    self:DoTrace()
  end)
end
