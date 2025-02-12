TeamPwsCreateRoomPopup = class("TeamPwsCreateRoomPopup", BaseView)
TeamPwsCreateRoomPopup.ViewType = UIViewType.PopUpLayer

function TeamPwsCreateRoomPopup:Init()
  self.roomNameLabel = self:FindComponent("RoomNameLabel", UILabel)
  self.roomNameLabel.text = string.format(ZhString.TeamPws_RoomName, Game.Myself.data.name)
  self.raidOptionGO = self:FindGO("RaidTabs")
  self.raidOptionPopup = PopupGridList.new(self.raidOptionGO, function(self, data)
    self.selectedRaidData = data
  end, self, self.roomNameLabel.depth + 2)
  local pvp_type = self.viewdata.viewdata and self.viewdata.viewdata.type or PvpProxy.Type.FreeBattle
  local raidModes = PvpCustomRoomProxy.Instance:GetRaidConfigs(pvp_type)
  self.raidOptionPopup:SetData(raidModes)
  self.selectedRaidData = raidModes[1]
  self.contentTable = self:FindComponent("ContentTable", UITable)
  self.passwordGO = self:FindGO("RoomPasswd")
  self.passwordInputGO = self:FindGO("PasswdInput", self.passwordGO)
  self.passwordInputCollider = self.passwordInputGO:GetComponent("BoxCollider")
  self.passwordInput = self.passwordInputGO:GetComponent(UIInput)
  if self.passwordInput then
    UIUtil.LimitInputCharacter(self.passwordInput, GameConfig.ChatRoom.PwdSize)
    EventDelegate.Set(self.passwordInput.onChange, function()
      self.passwordInput.value = self.passwordInput.value:gsub("-", "")
      self.passwordInput.characterLimit = GameConfig.ChatRoom.PwdSize
    end)
    self.passwordInput.value = ""
  end
  self.freeFireToggleGO = self:FindGO("NoticeToggle")
  self.freeFireContainerWidget = self:FindComponent("Container", UIWidget, self.freeFireToggleGO)
  self.freeFireToggle = self.freeFireToggleGO:GetComponent(UIToggle)
  self.freeFireToggleCollider = self.freeFireToggleGO:GetComponent(BoxCollider)
  self.confirmButtonGO = self:FindGO("ConfirmBtn")
  self:AddClickEvent(self.confirmButtonGO, function()
    self:OnConfirmClicked()
  end)
  self.comfirmLabel = self:FindComponent("Label", UILabel, self.confirmButtonGO)
  self.closeButtonGO = self:FindGO("CloseButton")
  self:AddClickEvent(self.closeButtonGO, function()
    self:OnCloseClicked()
  end)
  self.helpButtonGO = self:FindGO("RuleBtn")
  self:AddClickEvent(self.helpButtonGO, function()
    self:OnHelpClicked()
  end)
  self.freeFireTipBtn = self:FindGO("Icon")
  if self.freeFireTipBtn then
    self:RegistShowGeneralHelpByHelpID(32599, self.freeFireTipBtn)
  end
  self:LoadRoomData()
end

function TeamPwsCreateRoomPopup:SetMode(mode)
  local isInBattle = PvpCustomRoomProxy.Instance:IsInBattle()
  local isPreview = mode == PvpCustomRoomProxy.CreateRoomMode.EnterPreview or mode == PvpCustomRoomProxy.CreateRoomMode.InRoomPreview or isInBattle
  self.passwordGO:SetActive(not isPreview)
  self.contentTable:Reposition()
  self.passwordInputCollider.enabled = not isPreview
  self.freeFireToggleCollider.enabled = not isPreview
  self.freeFireContainerWidget.alpha = isPreview and 0.2 or 1.0
  if mode == PvpCustomRoomProxy.CreateRoomMode.EnterPreview then
    self.confirmButtonGO:SetActive(false)
  else
    self.confirmButtonGO:SetActive(true)
    if mode == PvpCustomRoomProxy.CreateRoomMode.InRoomPreview or isInBattle then
      self.comfirmLabel.text = ZhString.PvpCustomRoom_Confirm
    end
  end
end

function TeamPwsCreateRoomPopup:LoadRoomData()
  local viewdata = self.viewdata and self.viewdata.viewdata
  local roomData = viewdata and viewdata.roomdata
  self.comfirmLabel.text = not roomData and ZhString.PvpCustomRoom_Create or ZhString.PvpCustomRoom_Modify
  if roomData then
    self.freeFireToggle.value = roomData:IsFreeFire()
    local proxy = PvpCustomRoomProxy.Instance
    local raidConfig = proxy:GetRaidConfigByRaidId(roomData.raidid)
    if raidConfig then
      self.raidOptionPopup:SetValue(raidConfig.name)
    end
    if roomData.password then
      self.passwordInput.value = roomData.password
    end
  end
  local mode = viewdata and viewdata.mode
  self:SetMode(mode)
end

function TeamPwsCreateRoomPopup:OnCloseClicked(go)
  if self.viewdata.viewdata and self.viewdata.viewdata.roomdata then
    local roomData = PvpCustomRoomProxy.Instance:GetCurrentRoomData()
    if roomData then
      local config = PvpCustomRoomProxy.GetRoomPopup(roomData.pvptype)
      if config then
        GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {view = config})
      end
    end
  end
  self:CloseSelf()
end

function TeamPwsCreateRoomPopup:OnHelpClicked(go)
  MsgManager.ShowMsgByID(473)
end

function TeamPwsCreateRoomPopup:OnConfirmClicked(go)
  local isInBattle = PvpCustomRoomProxy.Instance:IsInBattle()
  local viewdata = self.viewdata and self.viewdata.viewdata
  local mode = viewdata and viewdata.mode
  if mode == PvpCustomRoomProxy.CreateRoomMode.InRoomPreview or isInBattle then
    self:OnCloseClicked()
    return
  end
  if not self.selectedRaidData then
    return
  end
  if string.len(self.passwordInput.value) ~= GameConfig.ChatRoom.PwdSize and string.len(self.passwordInput.value) ~= 0 then
    MsgManager.ShowMsgByID(805)
    return
  end
  local eType = self.selectedRaidData.etype
  local raidId = self.selectedRaidData.raidid
  local roomName = Game.Myself.data.name
  local password = self.passwordInput.value
  local freeFire = self.freeFireToggle.value
  if PvpCustomRoomProxy.Instance:SendCreateRoomReq(eType, raidId, freeFire, password) then
    self:CloseSelf()
  end
end
