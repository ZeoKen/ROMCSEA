autoImport("ChangeHeadCombineCell")
autoImport("TeamMemberPreviewCell")
ChangeHeadView = class("ChangeHeadView", ContainerView)
ChangeHeadView.ViewType = UIViewType.PopUpLayer
local HeadCellType = ChangeHeadData.HeadCellType
local pos = LuaVector3.Zero()

function ChangeHeadView:OnExit()
  if self.choosePortrait then
    ServiceNUserProxy.Instance:CallUsePortrait(self.choosePortrait)
  end
  if self.choosePortraitFrame then
    ServiceUserShowProxy.Instance:CallSelectPhotoFrame(self.choosePortraitFrame)
  end
  if self.chooseBackground then
    ServiceUserShowProxy.Instance:CallSelectBackgroundFrame(self.chooseBackground)
  end
  if self.chooseChatframe then
    xdlog("申请换气泡", self.chooseChatframe)
    ServiceUserShowProxy.Instance:CallSelectChatFrame(self.chooseChatframe)
  end
  RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_MONSTER_IMG)
  ChangeHeadView.super.OnExit(self)
end

function ChangeHeadView:Init()
  self:AddEvts()
  self:AddViewEvts()
  self:InitView()
end

function ChangeHeadView:AddEvts()
  local revertBtn = self:FindGO("RevertBtn")
  self:AddClickEvent(revertBtn, function()
    self:Revert()
  end)
  self.avatarTab = self:FindGO("AvatarTab"):GetComponent(UIToggle)
  self.portraitTab = self:FindGO("PortraitTab"):GetComponent(UIToggle)
  self.frameTab = self:FindGO("FrameTab"):GetComponent(UIToggle)
  self.chatframeTab = self:FindGO("ChatFrameTab"):GetComponent(UIToggle)
  EventDelegate.Set(self.avatarTab.onChange, function()
    self.headCellObj:SetActive(self.avatarTab.value)
    self.BackgroundContainer:SetActive(not self.avatarTab.value)
    self.chatframeContainer:SetActive(not self.avatarTab.value)
    if self.avatarTab.value then
      self:ClearView()
      self:SetUpAvatarList()
      self:SwitchBG(1)
    end
  end)
  EventDelegate.Set(self.portraitTab.onChange, function()
    self.headCellObj:SetActive(self.portraitTab.value)
    self.BackgroundContainer:SetActive(not self.portraitTab.value)
    self.chatframeContainer:SetActive(not self.portraitTab.value)
    if self.portraitTab.value then
      if self.firstSeePortraitFrame then
        self.firstSeePF = false
      end
      self:SwitchBG(1)
      self:ClearView()
      self:SetUpFrameList()
      self:SetPortraitPreview()
      self.choosePortraitFrame = Game.Myself.data.userdata:Get(UDEnum.PORTRAIT_FRAME) or 0
      self:SetChooseCell(true, self.choosePortraitFrame)
      self:SetChooseData(true, self.choosePortraitFrame)
    end
  end)
  EventDelegate.Set(self.frameTab.onChange, function()
    self.BackgroundContainer:SetActive(self.frameTab.value)
    self.headCellObj:SetActive(not self.frameTab.value)
    self.chatframeContainer:SetActive(not self.frameTab.value)
    if self.frameTab.value then
      if self.firstSeeBackground then
        self.firstSeePF = false
      end
      self:SwitchBG(2)
      self:ClearView()
      self:SetUpBackgroundList()
      self:SetFramePreview()
      self.chooseBackground = Game.Myself.data.userdata:Get(UDEnum.BACKGROUND) or 0
      self:SetChooseCell(true, self.chooseBackground)
      self:SetChooseData(true, self.chooseBackground)
    end
  end)
  EventDelegate.Set(self.chatframeTab.onChange, function()
    self.BackgroundContainer:SetActive(self.frameTab.value)
    self.headCellObj:SetActive(self.avatarTab.value or self.portraitTab.value)
    self.chatframeContainer:SetActive(self.chatframeTab.value)
    if self.chatframeTab.value then
      self:SwitchBG(1)
      self:ClearView()
      self:SetUpChatframeList()
      self.chooseChatframe = Game.Myself.data.userdata:Get(UDEnum.CHAT_FRAME) or 0
      xdlog("chatframe值", self.chooseChatframe)
      self:SetChooseCell(true, self.chooseChatframe)
      self:SetChatFramePreviewPart(self.chooseChatframe)
    end
  end)
  self.avatarTab.value = true
  self:RegisterRedTipCheck(SceneTip_pb.EREDSYS_MONSTER_IMG, self.avatarTab, nil, {-15, -15})
  self:RegisterRedTipCheck(SceneTip_pb.EREDSYS_PORTRAIT_FRAME, self.portraitTab, nil, {-15, -15})
  self:RegisterRedTipCheck(SceneTip_pb.EREDSYS_BACKGROUND_FRAME, self.frameTab, nil, {-15, -15})
  self.emptyTip = self:FindGO("Empty"):GetComponent(UILabel)
  self.emptyTip.text = ZhString.ChangeHeadView_EmptyTip
end

function ChangeHeadView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.NUserNewPortraitFrame, self.UpdatePortraitList)
end

function ChangeHeadView:InitView()
  self.headCellObj = self:FindGO("HeadContainer")
  self.headCellObj = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UICell("PlayerHeadCell"), self.headCellObj)
  self.headCellObj.transform.localPosition = LuaGeometry.Const_V3_zero
  self.mainHeadCell = PlayerFaceCell.new(self.headCellObj)
  self.mainHeadCell:HideHpMp()
  self.originalHeadData = HeadImageData.new()
  self.originalHeadData:TransByMyself()
  local userData = Game.Myself.data.userdata
  self.myPortraitFrame = userData:Get(UDEnum.PORTRAIT_FRAME) or 0
  self.myBackground = userData:Get(UDEnum.BACKGROUND) or 0
  self.mainHeadCell:SetData(self.originalHeadData)
  self.avatarTab.value = true
  local contentContainer = self:FindGO("ContentContainer")
  local wrapConfig = {
    wrapObj = contentContainer,
    pfbNum = 6,
    cellName = "ChangeHeadCombineCell",
    control = ChangeHeadCombineCell,
    dir = 1
  }
  self.itemWrapHelper = WrapCellHelper.new(wrapConfig)
  self.itemWrapHelper:AddEventListener(ChangeHeadEvent.Select, self.HandleClickItem, self)
  self:UpdatePortraitList()
  if self.originalHeadData.iconData.type == HeadImageIconType.Simple then
    self.choosePortrait = Game.Myself.data.userdata:Get(UDEnum.PORTRAIT)
    self:SetChooseCell(true, self.choosePortrait)
    self:SetChooseData(true, self.choosePortrait)
  end
  self.BackgroundContainer = self:FindGO("BackgroundContainer")
  self.backgroundPreviewCell = TeamMemberPreviewCell.new(self.BackgroundContainer)
  self.title = self:FindGO("Title"):GetComponent(UILabel)
  self.emptyTip.gameObject:SetActive(false)
  self.myChatframe = userData:Get(UDEnum.CHAT_FRAME) or 0
  self.chatframeContainer = self:FindGO("ChatframeContainer")
  local myselfChat = self:FindGO("MyselfChat")
  self.myselfChatBG = myselfChat:GetComponent(UISprite)
  self.myselfChatContent = self:FindGO("chatContent", myselfChat):GetComponent(UILabel)
  for i = 1, 4 do
    self["myselfBgDecorate" .. i] = self:FindGO("bgDecorate" .. i, myselfChat)
    if self["myselfBgDecorate" .. i] then
      self["myselfBgDecorate" .. i .. "_Icon"] = self["myselfBgDecorate" .. i]:GetComponent(UISprite)
    end
  end
  local someoneChat = self:FindGO("SomeoneChat")
  self.someoneChatBG = someoneChat:GetComponent(UISprite)
  self.someoneChatContent = self:FindGO("chatContent", someoneChat):GetComponent(UILabel)
  for i = 1, 4 do
    self["someoneBgDecorate" .. i] = self:FindGO("bgDecorate" .. i, someoneChat)
    if self["someoneBgDecorate" .. i] then
      self["someoneBgDecorate" .. i .. "_Icon"] = self["someoneBgDecorate" .. i]:GetComponent(UISprite)
    end
  end
  self.bgType1 = self:FindGO("BgType1")
  self.bgType2 = self:FindGO("BgType2")
  self.contentWidth = 180
end

function ChangeHeadView:Revert()
  self:SetChooseData(false, self.choosePortrait)
  self:SetChooseCell(false, self.choosePortrait)
  self:RevertMyselfHead()
  self.choosePortrait = 0
end

function ChangeHeadView:HandleClickItem(cellctl)
  if cellctl.data then
    if cellctl.type == HeadCellType.Avatar then
      self:SetAvatorPreview(cellctl)
    elseif cellctl.type == HeadCellType.Portrait then
      self:SetPortraitPreview(cellctl)
    elseif cellctl.type == HeadCellType.Frame then
      self:SetFramePreview(cellctl)
    elseif cellctl.type == HeadCellType.ChatFrame then
      self:SetChatframePreview(cellctl)
    end
  end
end

function ChangeHeadView:SetAvatorPreview(cellctl)
  local id = cellctl.data.id
  if self.choosePortrait and self.choosePortrait == id then
    return
  end
  self:LockCall()
  local staticData = Table_HeadImage[id]
  if staticData and staticData.Picture then
    self.mainHeadCell.headIconCell:SetSimpleIcon(staticData.Picture, staticData.frameType)
    self:SetChooseData(false, self.choosePortrait)
    self:SetChooseCell(false, self.choosePortrait)
    self.choosePortrait = id
    self:SetChooseData(true, self.choosePortrait)
    cellctl:SetChoose(true)
  elseif id == 0 then
    self:Revert()
  else
    errorLog(string.format("id : %s is not found in Table_HeadImage", tostring(id)))
  end
end

function ChangeHeadView:SetPortraitPreview(cellctl)
  local id = cellctl and cellctl.data and cellctl.data.id or self.myPortraitFrame
  if self.choosePortraitFrame and self.choosePortraitFrame == id then
    return
  end
  self:LockCall()
  if cellctl then
    self:SetChooseData(false, self.choosePortraitFrame)
    self:SetChooseCell(false, self.choosePortraitFrame)
    self.choosePortraitFrame = id
    self:SetChooseData(true, self.choosePortraitFrame)
    cellctl:SetChoose(true)
  end
  RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_PORTRAIT_FRAME, id)
  self.mainHeadCell.headIconCell:ResetPortraitFrame()
  self.mainHeadCell.headIconCell:SetPortraitFrame(id)
end

function ChangeHeadView:SetFramePreview(cellctl)
  local id = cellctl and cellctl.data and cellctl.data.id or self.myBackground
  self:LockCall()
  if cellctl then
    self:SetChooseData(false, self.chooseBackground)
    self:SetChooseCell(false, self.chooseBackground)
    self.chooseBackground = id
    self:SetChooseData(true, self.chooseBackground)
    cellctl:SetChoose(true)
  end
  RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_BACKGROUND_FRAME, id)
  self.backgroundPreviewCell:ResetPortraitFrame()
  self.backgroundPreviewCell:SetData(id)
end

function ChangeHeadView:SetChatframePreview(cellctl)
  local id = cellctl and cellctl.data and cellctl.data.id or self.myChatframe
  if self.chooseChatframe and self.chooseChatframe == id then
    return
  end
  self:LockCall()
  if cellctl then
    self:SetChooseData(false, self.chooseChatframe)
    self:SetChooseCell(false, self.chooseChatframe)
    self.chooseChatframe = id
    cellctl:SetChoose(true)
  end
  self:SetChatFramePreviewPart(id)
end

function ChangeHeadView:UpdatePortraitList()
  local data = ChangeHeadProxy.Instance:GetPortraitList()
  self.emptyTip.gameObject:SetActive(not data or #data == 0)
  local newData = self:ReUniteCellData(data, 5)
  self.itemWrapHelper:UpdateInfo(newData, true)
end

function ChangeHeadView:RevertMyselfHead()
  local myself = Game.Myself
  if myself then
    if myself.data:IsTransformed() then
      local monsterId = myself.data.props:GetPropByName("TransformID"):GetValue()
      local monsterIcon = monsterId and Table_Monster[monsterId].Icon
      if monsterIcon then
        self.mainHeadCell.headIconCell:SetSimpleIcon(monsterIcon)
      end
    else
      local userData = myself.data.userdata
      if userData then
        local data = self.originalHeadData.iconData
        data.hairID = userData:Get(UDEnum.HAIR) or nil
        data.bodyID = userData:Get(UDEnum.BODY) or nil
        data.gender = userData:Get(UDEnum.SEX) or nil
        data.haircolor = userData:Get(UDEnum.HAIRCOLOR) or nil
        data.headID = userData:Get(UDEnum.HEAD) or nil
        data.faceID = userData:Get(UDEnum.FACE) or nil
        data.mouthID = userData:Get(UDEnum.MOUTH) or nil
        data.eyeID = userData:Get(UDEnum.EYE) or nil
        self.mainHeadCell.headIconCell:SetData(data)
      end
    end
  end
end

function ChangeHeadView:SetChooseData(isChoose, choosedata)
  local data = ChangeHeadProxy.Instance:GetPortraitList()
  for i = 1, #data do
    if data[i].id == choosedata then
      data[i]:SetChoose(isChoose)
      break
    end
  end
end

function ChangeHeadView:SetChooseCell(isChoose, chooseid)
  local cells = self.itemWrapHelper:GetCellCtls()
  for i = 1, #cells do
    local cell = cells[i]
    for j = 1, #cell.childrenObjs do
      local child = cell.childrenObjs[j]
      if child.data and child.data.id == chooseid then
        child:SetChoose(isChoose)
        break
      end
    end
  end
end

function ChangeHeadView:ReUniteCellData(datas, perRowNum)
  local newData = {}
  if datas ~= nil and 0 < #datas then
    local default = table.remove(datas, 1)
    local sortFunc = function(a, b)
      local type = a.type
      local ERedSys
      if type == ChangeHeadData.HeadCellType.Avatar then
        ERedSys = SceneTip_pb.EREDSYS_MONSTER_IMG
      elseif type == ChangeHeadData.HeadCellType.Portrait then
        ERedSys = SceneTip_pb.EREDSYS_PORTRAIT_FRAME
      elseif type == ChangeHeadData.HeadCellType.Frame then
        ERedSys = SceneTip_pb.EREDSYS_BACKGROUND_FRAME
      end
      local isNew_a = false
      local isNew_b = false
      if ERedSys then
        isNew_a = RedTipProxy.Instance:IsNew(ERedSys, a.id)
        isNew_b = RedTipProxy.Instance:IsNew(ERedSys, b.id)
      end
      if isNew_a == isNew_b then
        return a.id < b.id
      else
        return isNew_a
      end
    end
    table.sort(datas, sortFunc)
    table.insert(datas, 1, default)
    for i = 1, #datas do
      local i1 = math.floor((i - 1) / perRowNum) + 1
      local i2 = math.floor((i - 1) % perRowNum) + 1
      newData[i1] = newData[i1] or {}
      if datas[i] == nil then
        newData[i1][i2] = nil
      else
        newData[i1][i2] = datas[i]
      end
    end
  end
  return newData
end

function ChangeHeadView:ClearView()
  self:CancelLockCall()
  self.itemWrapHelper:UpdateInfo({})
end

function ChangeHeadView:SetUpAvatarList()
  self.title.text = ZhString.ChangeHeadView_ChangeAvator
  self:UpdatePortraitList()
end

function ChangeHeadView:SetUpFrameList()
  self.title.text = ZhString.ChangeHeadView_ChangePortraitFrame
  local data = ChangeHeadProxy.Instance:GetFrameList()
  self.emptyTip.gameObject:SetActive(not data or #data == 0)
  local newData = self:ReUniteCellData(data, 5)
  self.itemWrapHelper:UpdateInfo(newData, true)
end

function ChangeHeadView:SetUpBackgroundList()
  self.title.text = ZhString.ChangeHeadView_ChangeBackground
  local data = ChangeHeadProxy.Instance:GetBackgroundList()
  self.emptyTip.gameObject:SetActive(not data or #data == 0)
  local newData = self:ReUniteCellData(data, 5)
  self.itemWrapHelper:UpdateInfo(newData, true)
end

function ChangeHeadView:SetUpChatframeList()
  self.title.text = ZhString.ChangeHeadView_ChangeChatframe
  local data = ChangeHeadProxy.Instance:GetChatframeList()
  self.emptyTip.gameObject:SetActive(not data or #data == 0)
  local newData = self:ReUniteCellData(data, 5)
  self.itemWrapHelper:UpdateInfo(newData, true)
end

function ChangeHeadView:SwitchBG(type)
  if type == 1 then
    self.bgType1:SetActive(true)
    self.bgType2:SetActive(false)
  else
    self.bgType1:SetActive(false)
    self.bgType2:SetActive(true)
  end
end

function ChangeHeadView:SetChatFramePreviewPart(id)
  if not Table_UserChatFrame then
    return
  end
  local config = Table_UserChatFrame[id]
  if not config then
    xdlog("default")
    self.myselfChatBG.spriteName = "new-chatroom_bg_2"
    for i = 1, 4 do
      self["myselfBgDecorate" .. i .. "_Icon"].gameObject:SetActive(false)
    end
    self.myselfChatBG.flip = 0
    self.someoneChatBG.spriteName = "chatroom_bg_1"
    for i = 1, 4 do
      self["someoneBgDecorate" .. i .. "_Icon"].gameObject:SetActive(false)
    end
    self.myselfChatContent.color = LuaColor.black
    self.someoneChatContent.color = LuaColor.black
  else
    self.myselfChatBG.spriteName = config.BubbleName
    self.myselfChatBG.flip = 1
    local decorateNameRoot = config.IconName
    for i = 1, 4 do
      self["myselfBgDecorate" .. i .. "_Icon"].gameObject:SetActive(true)
      self["myselfBgDecorate" .. i .. "_Icon"].spriteName = decorateNameRoot .. "_" .. i
      self["myselfBgDecorate" .. i .. "_Icon"]:MakePixelPerfect()
    end
    self.someoneChatBG.spriteName = config.BubbleName
    for i = 1, 4 do
      self["someoneBgDecorate" .. i .. "_Icon"].gameObject:SetActive(true)
      self["someoneBgDecorate" .. i .. "_Icon"].spriteName = decorateNameRoot .. "_" .. i
      self["someoneBgDecorate" .. i .. "_Icon"]:MakePixelPerfect()
    end
    if config.TextColor and config.TextColor ~= "" then
      local _, color = ColorUtil.TryParseHtmlString(config.TextColor)
      self.myselfChatContent.color = color
      self.someoneChatContent.color = color
    else
      self.myselfChatContent.color = LuaColor.black
      self.someoneChatContent.color = LuaColor.black
    end
  end
  local size
  UIUtil.FitLabelHeight(self.myselfChatContent, self.contentWidth)
  size = self.myselfChatContent.localSize
  local sizeY = size.y
  if 50 < sizeY then
    pos[2] = 26
  else
    pos[2] = 0
  end
  self.myselfChatBG.height = sizeY + 22
  self.myselfChatBG.width = size.x + 47
  if self.myselfChatBG.width < 127 then
    self.myselfChatBG.width = 127
  end
  LuaVector3.Better_Set(pos, -self.myselfChatBG.width - 27, -15, 0)
  self.myselfBgDecorate1_Icon.transform.localPosition = pos
  LuaVector3.Better_Set(pos, -self.myselfChatBG.width - 25, -self.myselfChatBG.height - 14, 0)
  self.myselfBgDecorate2_Icon.transform.localPosition = pos
  LuaVector3.Better_Set(pos, 23, -self.myselfChatBG.height - 10, 0)
  self.myselfBgDecorate3_Icon.transform.localPosition = pos
  UIUtil.FitLabelHeight(self.someoneChatContent, self.contentWidth)
  size = self.someoneChatContent.printedSize
  sizeY = size.y
  if 50 < sizeY then
    pos[2] = 26
  else
    pos[2] = 0
  end
  self.someoneChatBG.height = sizeY + 22
  self.someoneChatBG.width = size.x + 49
  if self.someoneChatBG.width < 127 then
    self.someoneChatBG.width = 127
  end
  LuaVector3.Better_Set(pos, self.someoneChatBG.width + 27, -15, 0)
  self.someoneBgDecorate1_Icon.transform.localPosition = pos
  LuaVector3.Better_Set(pos, self.someoneChatBG.width + 25, -self.someoneChatBG.height - 14, 0)
  self.someoneBgDecorate2_Icon.transform.localPosition = pos
  LuaVector3.Better_Set(pos, -23, -self.someoneChatBG.height - 10, 0)
  self.someoneBgDecorate3_Icon.transform.localPosition = pos
end

function ChangeHeadView:LockCall()
  if self.call_lock then
    return
  end
  self.call_lock = true
  if not self.lock_lt then
    self.lock_lt = TimeTickManager.Me():CreateOnceDelayTick(1000, function(owner, deltaTime)
      self.lock_lt = nil
      self.call_lock = false
    end, self)
  end
end

function ChangeHeadView:CancelLockCall()
  if not self.call_lock then
    return
  end
  self.call_lock = false
  if self.lock_lt then
    self.lock_lt:Destroy()
    self.lock_lt = nil
  end
end
