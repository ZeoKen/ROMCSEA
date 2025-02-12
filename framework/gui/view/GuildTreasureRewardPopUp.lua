autoImport("HeadImageData")
autoImport("PlayerFaceCell")
GuildTreasureRewardPopUp = class("GuildTreasureRewardPopUp", ContainerView)
GuildTreasureRewardPopUp.ViewType = UIViewType.Lv4PopUpLayer
autoImport("GuildTreasureRewardCell")
local uniqueID = 111

function GuildTreasureRewardPopUp:Init()
  self:InitView()
end

local tempArgs = {}

function GuildTreasureRewardPopUp:InitView()
  self.titleLab = self:FindComponent("Title", UILabel)
  self.percentLab = self:FindComponent("Percent", UILabel)
  self.myRewardStatus = self:FindComponent("MyReward", UILabel)
  self.myRewardStatus.text = ZhString.GuildTreasure_RewardGet
  self.goBtn = self:FindComponent("GoBtn", UILabel)
  self.goBtn.text = ZhString.GuildTreasure_GoBtn
  self.wrap = self:FindGO("Wrap")
  local wrapConfig = {
    wrapObj = self.wrap,
    pfbNum = 9,
    cellName = "GuildTreasureRewardCell",
    control = GuildTreasureRewardCell
  }
  self.wraplist = WrapCellHelper.new(wrapConfig)
  self.emptyTip = self:FindComponent("EmptyTip", UILabel)
  self.emptyTip.text = ZhString.GuildTreasure_EmptyTip
  self.headCell = self:FindGO("PlayerHeadCell")
  self.headCell = PlayerFaceCell.new(self.headCell)
  self.headCell:HideHpMp()
  self.closecomp = self.gameObject:GetComponent(CloseWhenClickOtherPlace)
  
  function self.closecomp.callBack(go)
    self:CloseSelf()
  end
  
  self:AddEvent()
  self:UpdateUI()
end

function GuildTreasureRewardPopUp:AddEvent()
  self:AddClickEvent(self.goBtn.gameObject, function(go)
    if Game.Myself:IsDead() then
      MsgManager.ShowMsgByIDTable(2500)
    else
      FuncShortCutFunc.Me():CallByID(1000)
      self:CloseSelf()
    end
  end)
end

local pb = GuildCmd_pb

function GuildTreasureRewardPopUp:UpdateUI()
  local result = GuildTreasureProxy.Instance:GetTreasureResult()
  local ownerID = result.onwerID
  local guildMember = result:GetMemberData()
  self.percentLab.text = result:GetPrecent()
  self.titleLab.text = string.format(ZhString.GuildTreasure_RewardTitle, result:GetOwnerName())
  if result.state then
    if result.state == pb.ETREASURESTATE_UNGETED then
      self:Hide(self.myRewardStatus)
      self:Show(self.goBtn)
    elseif result.state == pb.ETREASURESTATE_GETED then
      self:Show(self.myRewardStatus)
      self:Hide(self.goBtn)
    elseif result.state == pb.ETREASURESTATE_UNENABLE then
      self:Hide(self.myRewardStatus)
      self:Hide(self.goBtn)
    end
  end
  result = result:GetResultItems()
  if result and 0 < #result then
    self.wrap:SetActive(true)
    self.wraplist:UpdateInfo(result)
    self.emptyTip.gameObject:SetActive(#result == 0)
  else
    self.wrap:SetActive(false)
    self.emptyTip.gameObject:SetActive(true)
  end
  if guildMember then
    local headData = HeadImageData.new()
    if ownerID == Game.Myself.data.id then
      headData:TransByMyself()
    else
      headData:TransByGuildMemberData(guildMember)
    end
    self.headCell:SetData(headData)
  end
end
