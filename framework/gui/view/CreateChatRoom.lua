CreateChatRoom = class("CreateChatRoom", ContainerView)
CreateChatRoom.ViewType = UIViewType.PopUpLayer
CreateChatRoom.Icon = "69"

function CreateChatRoom:Init()
  self.uiInputName = self:FindGO("NameInput"):GetComponent(UIInput)
  if FunctionPerformanceSetting.CheckInputForbidden() then
    local boxColider = self.uiInputName.gameObject:GetComponent(BoxCollider)
    boxColider.enabled = false
  end
  UIUtil.LimitInputCharacter(self.uiInputName, GameConfig.System.roomname_max)
  self.uiInputName.value = Game.Myself.data:GetName() .. OverSea.LangManager.Instance():GetLangByKey(ZhString.Chat_zoneName)
  local objMemberCount = self:FindGO("MemberCount")
  self.labMemberCount = self:FindGO("LabMemberCount", objMemberCount):GetComponent(UILabel)
  self.memberCount = GameConfig.ChatRoom.MaxMembersNum
  self.labMemberCount.text = self.memberCount
  self.labMemberCountTips = self:FindComponent("Tip", UILabel, objMemberCount)
  self.labMemberCountTips.text = string.format(ZhString.Chat_MemberCountTip, self.memberCount)
  self.uiInputSecret = self:FindGO("SecretInput"):GetComponent(UIInput)
  UIUtil.LimitInputCharacter(self.uiInputSecret, GameConfig.ChatRoom.PwdSize)
  EventDelegate.Set(self.uiInputSecret.onChange, function()
    self.uiInputSecret.value = self.uiInputSecret.value:gsub("-", "")
  end)
  self.uiInputSecret.value = ""
  self:AddListenEvt(ServiceEvent.ChatRoomEnterChatRoom, self.OnReceiveEnterChatZoom)
end

function CreateChatRoom:OnEnter()
  self:AddSelectEvent(self.uiInputName, function(go, state)
    if state and FunctionUnLockFunc.Me():ForbidInput(FunctionUnLockFunc.ClientInputForbiddenType.ChatRoom) then
      self.uiInputName.isSelected = false
    end
  end)
  self:AddClickEvent(self:FindGO("CancelButton"), function(g)
    self:sendNotification(ChatRoomEvent.CancelCreateChatRoom)
    self:CloseSelf()
  end)
  self:AddClickEvent(self:FindGO("ConfirmButton"), function(g)
    self:OnButtonConfirmClick()
  end)
  self:AddClickEvent(self:FindGO("BtnReduce"), function(g)
    self:OnButtonReduceClick()
  end)
  self:AddClickEvent(self:FindGO("BtnAdd"), function(g)
    self:OnButtonAddClick()
  end)
  self:AddClickEvent(self:FindGO("CloseButton"), function()
    self:sendNotification(ChatRoomEvent.CancelCreateChatRoom)
    self:CloseSelf()
  end)
end

function CreateChatRoom:OnButtonConfirmClick()
  if string.len(self.uiInputName.value) == 0 then
    MsgManager.ShowMsgByID(806)
    return
  end
  if string.len(self.uiInputSecret.value) ~= GameConfig.ChatRoom.PwdSize and string.len(self.uiInputSecret.value) ~= 0 then
    MsgManager.ShowMsgByID(805)
    return
  end
  if ChatZoomProxy.Instance:IsInChatZone() then
    MsgManager.ShowMsgByID(813)
    return
  end
  if FunctionMaskWord.Me():CheckMaskWord(self.uiInputName.value, GameConfig.MaskWord.ChatroomName) then
    MsgManager.ShowMsgByID(2604)
    return
  end
  local _MapManager = Game.MapManager
  if _MapManager:IsInGVGRaid() then
    MsgManager.ShowMsgByID(25311)
    return
  end
  if _MapManager:IsPvPMode_TeamTwelve() then
    MsgManager.ShowMsgByID(25311)
    return
  end
  ServiceChatRoomProxy.Instance:CallCreateChatRoom(self.uiInputName.value, self.memberCount, self.uiInputSecret.value)
end

function CreateChatRoom:OnButtonReduceClick()
  if self.memberCount <= 2 then
    return
  end
  self.memberCount = self.memberCount - 1
  self.labMemberCount.text = tostring(self.memberCount)
end

function CreateChatRoom:OnButtonAddClick()
  if self.memberCount >= GameConfig.ChatRoom.MaxMembersNum then
    return
  end
  self.memberCount = self.memberCount + 1
  self.labMemberCount.text = tostring(self.memberCount)
end

function CreateChatRoom:OnReceiveEnterChatZoom(data)
  if data == nil then
    return
  end
  self:CloseSelf()
  local zoomInfo = data.body.data
  local ownerID = zoomInfo.ownerid
  local isShow = true
  if isShow then
    local str1 = zoomInfo.name
    local str2 = "(" .. #zoomInfo.members .. "/" .. zoomInfo.maxnum .. ")"
    SceneUIManager.Instance:AddRoleTopFuncWords(Game.Myself, CreateChatRoom.Icon, {left = str1, right = str2}, nil, true, 10)
  end
end
