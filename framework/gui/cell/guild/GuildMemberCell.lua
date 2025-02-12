local BaseCell = autoImport("BaseCell")
GuildMemberCell = class("GuildMemberCell", BaseCell)
local MAXARTIFACT = 6

function GuildMemberCell:Init()
  self.widget = self.gameObject:GetComponent(UIWidget)
  self.name = self:FindComponent("Name", UILabel)
  self.lv = self:FindComponent("Lv", UILabel)
  self.pro = self:FindComponent("Pro", UILabel)
  self.job = self:FindComponent("Job", UILabel)
  self.weekContri = self:FindComponent("WeekContri", UILabel)
  self.contribution = self:FindComponent("Contribution", UILabel)
  self.offlineTime = self:FindComponent("OffTime", UILabel)
  self.sex = self:FindComponent("Sex", UISprite)
  self.currentline = self:FindComponent("CurrentLine", UILabel)
  self.artifactPos = self:FindGO("ArtifactPos")
  self.noArtifact = self:FindComponent("NoArtifact", UILabel)
  self.noArtifact.text = ZhString.GvgLandInfoPopUp_None
  self.Voice = self:FindGO("Voice")
  self.voiceSwitch = self:FindGO("VoiceSwitch")
  self.returnSymbol = self:FindGO("returnSymbol")
  self.gvgState = self:FindComponent("GvgState", UISprite)
  self.Voice.gameObject:SetActive(ApplicationInfo.NeedOpenVoiceRealtime())
  self.VoiceSwitch = self:FindGO("VoiceSwitch")
  self.VoiceSwitchOpen = self:FindGO("Open", self.VoiceSwitch)
  self.Voice_UISpirte = self:FindGO("Voice"):GetComponent(UISprite)
  if self:FindGO("VoiceSwitch") then
    self.VoiceSwitch_UISprite = self:FindGO("VoiceSwitch"):GetComponent(UISprite)
    self.VoiceSwitchOpen_UISprite = self:FindGO("Open", self.VoiceSwitch):GetComponent(UISprite)
    self.VoiceSwitchOpen_UISprite.spriteName = "Voice_btn_circle"
    self:AddClickEvent(self.VoiceSwitch.gameObject, function()
      if GVoiceProxy.Instance:GetCurGuildRealTimeVoiceCount() + 1 > GameConfig.Guild.realtime_voice_limit and self.curVoiceSwitchState == false then
        MsgManager.ShowMsgByID(25860)
      elseif self.curVoiceSwitchState == true then
        helplog("if curVoiceSwitchState == true then")
        ServiceGuildCmdProxy.Instance:CallOpenRealtimeVoiceGuildCmd(self.data.id, false)
      else
        helplog("if curVoiceSwitchState == false then")
        ServiceGuildCmdProxy.Instance:CallOpenRealtimeVoiceGuildCmd(self.data.id, true)
      end
    end)
    self.Voice.gameObject:SetActive(false)
    self.VoiceSwitch.gameObject:SetActive(false)
    self.VoiceSwitchOpen.gameObject:SetActive(false)
  end
  self:AddCellClickEvent()
  self.voiceSwitch:SetActive(self.Voice.activeSelf)
  self.assembleCompleteBtn = self:FindGO("AssembleCompleteBtn")
  local assembleCompleteBtnSp = self.assembleCompleteBtn:GetComponent(UISprite)
  self.assembleCompleteBtnLP = self.assembleCompleteBtn:GetComponent(UILongPress)
  
  function self.assembleCompleteBtnLP.pressEvent(obj, state)
    local tabName = ZhString.GuildAssembleComplete
    TabNameTip.OnLongPress(state, tabName, true, assembleCompleteBtnSp, NGUIUtil.AnchorSide.Top, {150, 40})
  end
  
  self.assembleOtherBtn = self:FindGO("AssembleOtherBtn")
  local assembleOtherBtnSp = self.assembleOtherBtn:GetComponent(UISprite)
  self.assembleOtherBtnLP = self.assembleOtherBtn:GetComponent(UILongPress)
  
  function self.assembleOtherBtnLP.pressEvent(obj, state)
    local tabName = ZhString.GuildAssembleOther
    TabNameTip.OnLongPress(state, tabName, true, assembleOtherBtnSp, NGUIUtil.AnchorSide.Top, {150, 40})
  end
  
  self.mercenaryGO = self:FindGO("MercenryBg")
end

function GuildMemberCell:ShowVoiceSwitch()
  if GameConfig.SystemForbid.OpenVoiceRealtime then
    self.Voice.gameObject:SetActive(false)
    self.VoiceSwitch.gameObject:SetActive(false)
    self.VoiceSwitchOpen.gameObject:SetActive(false)
    return
  end
  if self.Voice then
    self.Voice.gameObject:SetActive(true)
    self.VoiceSwitch.gameObject:SetActive(true)
    self.VoiceSwitchOpen.gameObject:SetActive(true)
  end
  self.VoiceSwitch.gameObject:SetActive(true)
  self.Voice.gameObject:SetActive(true)
  self.VoiceSwitch.gameObject:SetActive(true)
  self.VoiceSwitchOpen.gameObject:SetActive(true)
end

local tempVector3 = LuaVector3.Zero()

function GuildMemberCell:SetVoiceSwitchState(b)
  if GameConfig.SystemForbid.OpenVoiceRealtime then
    self.Voice.gameObject:SetActive(false)
    self.VoiceSwitch.gameObject:SetActive(false)
    self.VoiceSwitchOpen.gameObject:SetActive(false)
    return
  end
  if self.VoiceSwitchOpen_UISprite then
    GVoiceProxy.Instance:DebugLog("set VoiceSwitchOpen_UISprite")
    self.VoiceSwitchOpen_UISprite.height = 40
    self.VoiceSwitchOpen_UISprite.width = 40
    if b then
      self.VoiceSwitchOpen_UISprite.spriteName = "Voice_btn_circle"
      tempVector3[1] = -19
      self.VoiceSwitchOpen.gameObject.transform.localPosition = tempVector3
      self.VoiceSwitch_UISprite.spriteName = "Voice_bg_line"
      self.Voice_UISpirte.spriteName = "ui_guild_microphone_JM"
    else
      self.VoiceSwitchOpen_UISprite.spriteName = "Voice_btn_circle"
      tempVector3[1] = 19
      self.VoiceSwitchOpen.gameObject.transform.localPosition = tempVector3
      self.VoiceSwitch_UISprite.spriteName = "Voice_bg_line2"
      self.Voice_UISpirte.spriteName = "ui_team_voice"
    end
    self.curVoiceSwitchState = b
  end
end

function GuildMemberCell:SetData(data)
  self.data = data
  if data then
    self.gameObject:SetActive(true)
    self.artiData = ArtifactProxy.Instance:GetMemberArti(data.id)
    if self.artiData then
      self:Show(self.artifactPos)
      self:Hide(self.noArtifact)
      self:SetMemberArtifact(self.artiData)
    else
      self:Hide(self.artifactPos)
      self:Show(self.noArtifact)
    end
    self.name.text = data.name
    self.name.text = AppendSpace2Str(data.name)
    self.lv.text = data.baselevel
    self.pro.text = ProfessionProxy.GetProfessionNameFromSocialData(data)
    self.job.text = data:GetJobName()
    self.contribution.text = string.format(ZhString.GuildMemberCell_Contri, data.totalcontribution or 0)
    self.weekContri.text = string.format(ZhString.GuildMemberCell_WeekContri, data.weekcontribution or 0)
    self.sex.spriteName = data:IsBoy() and "friend_icon_man" or "friend_icon_woman"
    self.widget.alpha = data:IsOffline() and 0.7 or 1
    self:UpdateTimeSymbol()
    if GVoiceProxy.Instance:IsThisCharIdRealtimeVoiceAvailable(data.id) then
      self:SetVoiceSwitchState(true)
      self.Voice.gameObject:SetActive(true)
      self.Voice.gameObject:SetActive(ApplicationInfo.NeedOpenVoiceRealtime())
    else
      self:SetVoiceSwitchState(false)
    end
    if not data:IsOffline() then
      if data.userreturnendtime and 0 < data.userreturnendtime then
        self.returnSymbol:SetActive(true)
        if self.offlineTime.gameObject.activeSelf then
          self.returnSymbol.transform.localPosition = LuaGeometry.GetTempVector3(415, -14, 0)
        else
          self.returnSymbol.transform.localPosition = LuaGeometry.GetTempVector3(470, -14, 0)
        end
      else
        self.returnSymbol:SetActive(false)
      end
    else
      self.returnSymbol:SetActive(false)
    end
    local isAssembleComplete = data:IsAssembleComplete()
    local isAssembleInMyGuild = data:IsAssembleInMyGuild()
    self.assembleCompleteBtn:SetActive(isAssembleComplete and isAssembleInMyGuild)
    self.assembleOtherBtn:SetActive(isAssembleComplete and not isAssembleInMyGuild)
    if self.gvgState then
      if data.ingvgfire == 1 then
        self.gvgState.gameObject:SetActive(true)
        IconManager:SetUIIcon("Guild_icon_ghz", self.gvgState)
      elseif data.ingvgsuper == 1 then
        self.gvgState.gameObject:SetActive(true)
        IconManager:SetUIIcon("Guild_icon_dfs", self.gvgState)
      else
        self.gvgState.gameObject:SetActive(false)
      end
    end
    self.mercenaryGO:SetActive(data:IsMercenaryOfOtherGuild() and not data:IsMercenary() or false)
  else
    self.gameObject:SetActive(false)
  end
  self.voiceSwitch:SetActive(self.Voice.activeSelf)
end

local baseDepth = 9

function GuildMemberCell:SetMemberArtifact(artiData)
  if not self.artifacts then
    self.artifacts = {}
    for i = 1, MAXARTIFACT do
      self.artifacts[i] = self:FindComponent("arti" .. i, UISprite)
    end
  end
  for i = 1, MAXARTIFACT do
    if self.artifacts[i] and i <= #artiData then
      self:Show(self.artifacts[i].gameObject)
      if artiData[i] and artiData[i].itemID then
        local icon = artiData[i].itemStaticData and artiData[i].itemStaticData.Icon or ""
        IconManager:SetItemIcon(icon, self.artifacts[i])
      end
    else
      self:Hide(self.artifacts[i].gameObject)
    end
  end
end

function GuildMemberCell:UpdateTimeSymbol()
  local data = self.data
  self.offlineTime.text = ClientTimeUtil.GetFormatOfflineTimeStr(data.offlinetime)
  if not data:IsOffline() and data.zoneid ~= ChangeZoneProxy.Instance:GetSimpleZoneId(MyselfProxy.Instance:GetZoneId()) then
    self.currentline.gameObject:SetActive(true)
    self.offlineTime.gameObject:SetActive(false)
    self.currentline.text = ChangeZoneProxy.Instance:ZoneNumToString(data.zoneid)
  else
    self.offlineTime.gameObject:SetActive(true)
    self.currentline.gameObject:SetActive(false)
  end
end
