autoImport("WrapScrollViewHelper")
autoImport("ChatRoomCombineCell")
autoImport("ChatNameCell")
PrivateChatView = class("PrivateChatView", SubView)

function PrivateChatView:OnEnter()
  PrivateChatView.super.OnEnter(self)
  self:ResetNewMessage()
  self.ContentTable:SetActive(true)
  ChatRoomProxy.Instance:SetCurrentPrivateChatId(self.curChatId)
  if self.container.viewdata.viewdata and self.container.viewdata.viewdata.key == "PrivateChat" then
    return
  end
  self:SelectChatByIndex(1)
  self:UpdateChat()
end

function PrivateChatView:OnExit()
  ChatRoomProxy.Instance:ResetUnreadCount(self.curChatId)
  ChatRoomProxy.Instance:SetCurrentPrivateChatId(0)
  self.ContentTable:SetActive(false)
  PrivateChatView.super.OnExit(self)
end

function PrivateChatView:Init()
  self:FindObjs()
  self:AddEvts()
  self:AddViewEvts()
  self:InitShow()
end

function PrivateChatView:FindObjs()
  self.PrivateChat = self.container.PrivateChat
  self.ContentScrollView = self:FindGO("ContentScrollView", self.PrivateChat):GetComponent(UIScrollView)
  self.ContentPanel = self.ContentScrollView.gameObject:GetComponent(UIPanel)
  self.ContentTable = self:FindGO("ContentTable", self.PrivateChat)
  self.ContentTitle = self:FindComponent("ContentTitle", UILabel)
  self.CloseBtn = self:FindGO("CloseBtn", self.PrivateChat)
  self.ChatNameScrollView = self:FindComponent("ChatNameScrollView", UIScrollView)
  self.ChatNameContainer = self:FindGO("ChatNameContainer", self.PrivateChat):GetComponent(UIGrid)
  self.NewMessage = self:FindGO("NewMessageBg", self.PrivateChat)
  self.NewMessageLabel = self:FindGO("NewMessageLabel", self.NewMessage):GetComponent(UILabel)
end

function PrivateChatView:AddEvts()
  self:AddClickEvent(self.CloseBtn, function(g)
    self:ClickCloseBtn(g)
  end)
  self:AddClickEvent(self.NewMessage, function(g)
    self:HandleNewMessage()
  end)
  local openFriend = self:FindGO("OpenFriend")
  self:AddClickEvent(openFriend, function()
    self:sendNotification(UIEvent.JumpPanel, {
      view = PanelConfig.FriendMainView
    })
  end)
end

function PrivateChatView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.SessionSocialitySocialDataUpdate, self.HandleSocialDataUpdate)
  self:AddListenEvt(ChatRoomEvent.UpdateSelectChat, self.HandleUpdateSelectChat)
  self:AddListenEvt(ServiceEvent.SessionSocialitySocialUpdate, self.HandleSocialUpdate)
  self:AddListenEvt(ServiceEvent.SessionSocialityQuerySocialData, self.HandleQuerySocial)
  self:AddListenEvt(ChatRoomEvent.AutoSendPrivateEvent, self.HandleSendAutoPrivate)
end

local config = {}

function PrivateChatView:InitShow()
  self:ResetNewMessage()
  self.curChannel = ChatChannelEnum.Private
  self.curChatId = ChatRoomProxy.Instance:GetCurrentPrivateChatId()
  self.itemContent = WrapScrollViewHelper.new(ChatRoomCombineCell, ChatRoomPage.rid, self.ContentScrollView.gameObject, self.ContentTable, 10, function()
    if self.itemContent:GetIsMoveToFirst() then
      self:ResetNewMessage()
    else
      self.isLock = true
    end
  end)
  self.itemContent:AddEventListener(ChatRoomEvent.SelectHead, self.container.HandleClickHead, self)
  self.nameList = UIGridListCtrl.new(self.ChatNameContainer, ChatNameCell, "ChatNameCell")
  self.nameList:AddEventListener(MouseEvent.MouseClick, self.HandleClickName, self)
  self.nameList:SetDisableDragIfFit()
end

function PrivateChatView:ClickCloseBtn()
  local curNameIndex = self:GetCurChatIdNameIndex()
  local index = curNameIndex - 1
  if index < 1 then
    index = 1
  end
  ChatRoomProxy.Instance:RemovePrivateChat(curNameIndex)
  self:SelectChatByIndex(index)
  if self.isLock then
    self:ResetNewMessage()
  end
  self:ResetChat()
  self.container:ResetKeyword()
end

function PrivateChatView:HandleNewMessage()
  self:ResetNewMessage()
  self:ResetPositionInfo()
end

function PrivateChatView:ResetNewMessage()
  self.isLock = false
  self.unRead = 0
  if self.NewMessage.activeSelf then
    self.NewMessage:SetActive(false)
  end
end

function PrivateChatView:SelectChatByIndex(index)
  local datas = self:GetPrivateChatList()
  if #datas == 0 then
    self:SetCurChatId(0)
    self.ContentTitle.gameObject:SetActive(false)
    return
  end
  self:SelectChatByData(datas[index])
end

function PrivateChatView:SelectChatByData(data)
  if data.id and data.name then
    self:SetCurChatId(data.id)
    ChatRoomProxy.Instance:LoadLocalDataById(self.curChatId)
    self:UpdateTitle(data.name)
  end
end

function PrivateChatView:UpdateChat()
  self:UpdateChatContent()
  self:UpdateChatName()
end

function PrivateChatView:ResetChat()
  self:ResetPositionInfo()
  self:UpdateChatName()
end

function PrivateChatView:UpdateChatContent()
  local datas = ChatRoomProxy.Instance:GetPrivateMessagesByGuid(self.curChatId)
  self.itemContent:UpdateInfo(datas, self.isLock)
  self.container:ShowEmptyTip(#datas == 0, ChatRoomEnum.PRIVATECHAT)
end

function PrivateChatView:ResetPositionInfo()
  local datas = ChatRoomProxy.Instance:GetPrivateMessagesByGuid(self.curChatId)
  if datas then
    self.itemContent:ResetPosition(datas)
    self.container:ShowEmptyTip(#datas == 0, ChatRoomEnum.PRIVATECHAT)
  end
end

function PrivateChatView:UpdateChatName()
  ChatRoomProxy.Instance:ResetUnreadCount(self.curChatId)
  local datas = self:GetPrivateChatList()
  for i = 1, #datas do
    if i == 1 then
      datas[i].isFirst = true
    else
      datas[i].isFirst = false
    end
    if datas[i].id == self.curChatId then
      datas[i].isChoose = true
    else
      datas[i].isChoose = false
    end
  end
  self.nameList:ResetDatas(datas)
end

function PrivateChatView:UpdateTitle(name)
  self.ContentTitle.gameObject:SetActive(true)
  self.ContentTitle.text = string.format(ZhString.Chat_privateTitle, name)
end

function PrivateChatView:HandleClickName(cellctr)
  if cellctr.data then
    ChatRoomProxy.Instance:ResetUnreadCount(self.curChatId)
    self:SelectChatByData(cellctr.data)
    if self.isLock then
      self:ResetNewMessage()
    end
    self.container:ResetKeyword()
    self:ResetChat()
    self:ClearRedTip()
  end
end

function PrivateChatView:HandleChatRetUserCmd(note)
  local data = note.body
  if data:GetChannel() ~= self.curChannel then
    return
  end
  if self.isLock then
    self.unRead = self.unRead + 1
  end
  if self.curChatId == 0 then
    self:SelectChatByIndex(1)
  end
  self:UpdateChat()
  if self.unRead > 0 then
    self:ShowNewMessage()
  else
    self.NewMessage:SetActive(false)
  end
end

function PrivateChatView:HandleUpdateSelectChat(note)
  if note.body then
    ChatRoomProxy.Instance:ResetUnreadCount(self.curChatId)
    self:ResetNewMessage()
    self:ResetPositionInfo()
    ChatRoomProxy.Instance:LoadDataByPlayerTip(note.body)
    self:SelectChatByData(note.body)
    self.container:SwitchValue(ChatRoomEnum.PRIVATECHAT)
    self:ClearRedTip()
  end
end

function PrivateChatView:HandleQuerySocial(note)
  if self.curChatId == 0 then
    self:SelectChatByIndex(1)
  end
  self:UpdateChat()
  local data = Game.SocialManager:Find(self.curChatId)
  if data then
    self:UpdateTitle(data.name)
  end
end

function PrivateChatView:HandleSocialUpdate(data)
  if data.body.dels and #data.body.dels > 0 then
    for i = 1, #data.body.dels do
      if data.body.dels[i] == self.curChatId then
        local curNameIndex = self:GetCurChatIdNameIndex()
        local index = curNameIndex - 1
        if index < 1 then
          index = 1
        end
        self:SelectChatByIndex(index)
        if self.isLock then
          self:ResetNewMessage()
        end
      end
    end
  end
  self:UpdateChat()
end

function PrivateChatView:HandleSocialDataUpdate(note)
  local data = note.body
  if data and data.guid == self.curChatId then
    if not self.isLock then
      self:ResetPositionInfo()
    else
      self:UpdateChatContent()
    end
  end
  self:UpdateChatName()
end

function PrivateChatView:HandleSendAutoPrivate(note)
  local data = note.body
  local id = data and data.id
  self.container:SwitchValue(ChatRoomEnum.PRIVATECHAT)
  local cells = self.nameList:GetCells()
  for i = 1, #cells do
    local cell = cells[i]
    if cell.data.id == id then
      self:HandleClickName(cell)
    end
  end
  local type = data and data.type
  local str = data and data.str
  if type == "lovechallenge" then
    local loveconfession = data and data.loveconfession or 1
    self:SendLovechallenge(str, loveconfession)
  else
    self:SendMessage(str)
  end
end

function PrivateChatView:SendMessage(content, voice, voicetime, photo, expression)
  if ChatRoomProxy.Instance:CanPrivateTalk() then
    ChatRoomProxy.Instance.curChatId = self.curChatId
    ServiceChatCmdProxy.Instance:CallChatCmd(self.curChannel, content, self.curChatId, voice, voicetime, nil, nil, photo, expression)
  else
    MsgManager.ShowMsgByIDTable(41)
  end
end

function PrivateChatView:SendAutoSysMessage(content, voice, voicetime, photo, expression, loveconfession)
  ChatRoomProxy.Instance.curChatId = self.curChatId
  ServiceChatCmdProxy.Instance:CallChatCmd(self.curChannel, content, self.curChatId, voice, voicetime, nil, nil, photo, expression, loveconfession)
end

function PrivateChatView:SendLovechallenge(content, loveconfession)
  xdlog("发送爱情挑战私聊", content)
  self:SendAutoSysMessage(content, nil, nil, nil, nil, loveconfession)
end

function PrivateChatView:GetCurChatIdNameIndex()
  local curNameIndex = 0
  for i = 1, #self.nameList:GetCells() do
    local cell = self.nameList:GetCells()[i]
    if cell.data and cell.data.id == self.curChatId then
      curNameIndex = i
    end
  end
  return curNameIndex
end

function PrivateChatView:GetPrivateChatList()
  return ChatRoomProxy.Instance:GetPrivateChatList(true)
end

function PrivateChatView:ShowNewMessage()
  if not self.NewMessage.activeSelf then
    self.NewMessage:SetActive(true)
  end
  self.NewMessageLabel.text = tostring(self.unRead) .. ZhString.Chat_newMessage
end

function PrivateChatView:HandleKeywordEffect(note)
  local datas = note.body
  if self.container.CurrentState ~= ChatRoomEnum.PRIVATECHAT then
    return
  end
  if datas.message:GetChannel() ~= self.curChannel then
    return
  end
  if datas.message:GetChatId() then
    if datas.message:GetChatId() ~= self.curChatId then
      return
    end
  elseif datas.message:GetId() ~= self.curChatId then
    return
  end
  self.container:AddKeywordEffect(datas.data)
end

function PrivateChatView:ResetTalk()
  self.container:SetVisible(true)
  ChatRoomProxy.Instance:SetCurrentChatChannel(self.curChannel)
end

function PrivateChatView:ClearRedTip()
  ChatRoomProxy.Instance:ClearRedTip()
end

function PrivateChatView:SetCurChatId(id)
  self.curChatId = id
  ChatRoomProxy.Instance:SetCurrentPrivateChatId(id)
end
