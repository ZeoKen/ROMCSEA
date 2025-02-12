autoImport("WrapCellHelper")
autoImport("YoyoRoomCombineCell")
autoImport("YoyoRoomToggleCell")
YoyoViewPage = class("YoyoViewPage", SubView)
local yoyoView_Path = ResourcePathHelper.UIView("YoyoViewPage")
local Y_PVP_TYPE
local RaidMap = GameConfig.PVPConfig[1].RaidMap
local MaxPlayerNum = GameConfig.PVPConfig[1].PeopleLimit
YoyoViewPage.timeTick = nil
local intervalTime = GameConfig.PVPConfig[1] and GameConfig.PVPConfig[1].Refresh or 3
local resID = ResourcePathHelper.UICell("YoyoRoomToggleCell")

function YoyoViewPage:Init()
  Y_PVP_TYPE = PvpProxy.Type.Yoyo
  self:FindObjs()
  self:AddUIEvts()
  self:AddViewEvts()
end

function YoyoViewPage:UpdateView()
  self:ClearLeanTick()
  self.roomlist = {}
  self:CallReqRoomList()
end

function YoyoViewPage:ReUniteCellData(datas, perRowNum)
  local newData = {}
  if datas ~= nil and 0 < #datas then
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

function YoyoViewPage:FindObjs()
  self:LoadSubView()
  self.itemRoot = self:FindGO("cutWrap", self.objRoot)
  self.quickJoin = self:FindGO("quickJoin", self.objRoot)
  self.HelpButton = self:FindGO("RuleBtn", self.objRoot)
  self.scrollView = self:FindComponent("RoomRoot", ROUIScrollView, self.objRoot)
  self.refreshTipLab = self:FindComponent("refreshTipLab", UILabel, self.objRoot)
  self.backToTopBtn = self:FindGO("backToTop", self.objRoot)
  self.RoomBtnRoot = self:FindGO("RoomBtnRoot", self.objRoot)
  local ListTable = self.RoomBtnRoot:GetComponent(UIGrid)
  self.gridListCtl = UIGridListCtrl.new(ListTable, YoyoRoomToggleCell, "YoyoRoomToggleCell")
  self.gridListCtl:AddEventListener(MouseEvent.MouseClick, self._freshClickChoose, self)
  local list = {}
  for i = 1, #RaidMap do
    table.insert(list, RaidMap[i][1])
  end
  self.gridListCtl:ResetDatas(list)
  self.chooseMapId = RaidMap[1][1]
  self:_refreshChoose()
end

function YoyoViewPage:_freshClickChoose(cellctl)
  if nil ~= cellctl and cellctl.data ~= self.chooseMapId then
    self.chooseMapId = cellctl.data
    self:ShowUIByPage(self.chooseMapId)
    self:_refreshChoose()
  end
  if self.itemWrapHelper then
    self.itemWrapHelper:ResetPosition()
  end
end

function YoyoViewPage:LoadSubView()
  self.objRoot = self:FindGO("YoyoView")
  local obj = self:LoadPreferb_ByFullPath(yoyoView_Path, self.objRoot, true)
  obj.name = "YoyoViewPage"
end

function YoyoViewPage:AddUIEvts()
  self:AddClickEvent(self.quickJoin, function(go)
    self:CallQuickjoin()
  end)
  self:RegistShowGeneralHelpByHelpID(PanelConfig.YoyoViewPage.id, self.HelpButton)
  
  function self.scrollView.OnPulling(offsetY, triggerY)
    self.refreshTipLab.text = offsetY < triggerY and ZhString.PullRefreshYoyoRoom or ZhString.LoosenRefreshYoyoRoom
  end
  
  function self.scrollView.OnStop()
    self.refreshTipLab.text = ZhString.YoyoRoomRefreshing
    self.refreshLean = TimeTickManager.Me():CreateOnceDelayTick(5000, function(owner, deltaTime)
      self:_handleRefreshRoom()
    end, self)
    self:CallReqRoomList()
  end
end

function YoyoViewPage:AddViewEvts()
  self:AddListenEvt(ServiceEvent.MatchCCmdReqRoomListCCmd, self.RecvRoomList)
  self:AddListenEvt(ServiceEvent.MatchCCmdJoinRoomCCmd, self.RecvJoinRoom)
end

function YoyoViewPage:RecvJoinRoom(note)
  local data = note.body
  if data.type == Y_PVP_TYPE and data.ret then
    self.container:CloseSelf()
  end
end

function YoyoViewPage:OnEnter()
  YoyoViewPage.super.OnEnter(self)
end

function YoyoViewPage:OnExit()
  self:ClearLeanTick()
  YoyoViewPage.super.OnExit(self)
end

function YoyoViewPage:OnDestroy()
  if self.itemWrapHelper then
    self.itemWrapHelper:Destroy()
  end
  YoyoViewPage.super.OnDestroy(self)
end

function YoyoViewPage:ClearLeanTick()
  self:_stopTick()
  self:_removeLeanTween()
end

function YoyoViewPage:CallReqRoomList()
  if nil == self.timeTick then
    ServiceMatchCCmdProxy.Instance:CallReqRoomListCCmd(Y_PVP_TYPE)
    self:_timeCountDown()
  else
    MsgManager.ShowMsgByID(952)
    self:_handleRefreshRoom()
  end
end

function YoyoViewPage:CallQuickjoin()
  ServiceMatchCCmdProxy.Instance:CallJoinRoomCCmd(Y_PVP_TYPE, nil, nil, true)
end

function YoyoViewPage:handleJoinRoom(cellData)
  if nil == cellData or nil == cellData.roomId then
    return
  end
  self:CallJoinRoom(cellData.roomId)
end

function YoyoViewPage:CallJoinRoom(roomId)
  ServiceMatchCCmdProxy.Instance:CallJoinRoomCCmd(Y_PVP_TYPE, roomId)
end

function YoyoViewPage:RecvRoomList(note)
  local data = note.body
  if data then
    local dtype = data.type
    if dtype == Y_PVP_TYPE then
      self:ShowUIByPage(self.chooseMapId)
    end
  end
end

function YoyoViewPage:ShowUIByPage(mapid)
  self.sortedRoomData = self:GetClassifiedRoomData()
  if nil == self.sortedRoomData then
    return
  end
  local singleRoomData = self.sortedRoomData[mapid]
  table.sort(singleRoomData, function(l, r)
    return self:_sortRoomData(l, r)
  end)
  self:ShowSingleRoom(singleRoomData)
end

function YoyoViewPage:_sortRoomData(left, right)
  if left == nil then
    return false
  elseif right == nil then
    return true
  end
  if left.playerNum == MaxPlayerNum then
    return false
  elseif right.playerNum == MaxPlayerNum then
    return true
  elseif left.playerNum == right.playerNum then
    return left.roomId < right.roomId
  else
    return left.playerNum > right.playerNum
  end
end

function YoyoViewPage:ShowSingleRoom(singleRoomData)
  local newData = self:ReUniteCellData(singleRoomData, 1)
  if self.itemWrapHelper == nil then
    local wrapConfig = {
      wrapObj = self.itemRoot,
      pfbNum = 5,
      cellName = "YoyoRoomCombineCell",
      control = YoyoRoomCombineCell,
      dir = 1
    }
    self.itemWrapHelper = WrapCellHelper.new(wrapConfig)
    self.itemWrapHelper:AddEventListener(YoyoJoinRoomEvent.JoinRoom, self.handleJoinRoom, self)
  end
  self.itemWrapHelper:UpdateInfo(newData)
end

function YoyoViewPage:_handleRefreshRoom()
  self:_removeLeanTween()
  self.scrollView:Revert()
end

function YoyoViewPage:_removeLeanTween()
  if self.refreshLean then
    self.refreshLean:Destroy()
    self.refreshLean = nil
  end
end

function YoyoViewPage:_timeCountDown()
  local deltaTime, lastTime = 0
  self.timeTick = TimeTickManager.Me():CreateTick(0, 33, function(self)
    if lastTime then
      deltaTime = deltaTime + (RealTime.time - lastTime)
      if deltaTime > intervalTime then
        self:_stopTick()
      end
    end
    lastTime = RealTime.time
  end, self, 1)
end

function YoyoViewPage:_stopTick()
  TimeTickManager.Me():ClearTick(self, 1)
  self.timeTick = nil
end

function YoyoViewPage:GetClassifiedRoomData()
  local yoyoData = PvpProxy.Instance:GetRoomList(PvpProxy.Type.Yoyo)
  if nil == yoyoData then
    return nil
  end
  local mapTab = {}
  if nil == RaidMap then
    helplog("配置有误，请检查配置——> GameConfig.PVPConfig RaidMap ")
    return
  end
  for i = 1, #RaidMap do
    mapTab[i] = RaidMap[i][1]
  end
  local classifiedRoomData = {}
  for i = 1, #mapTab do
    local configID = mapTab[i]
    local temp = {}
    for _, v in pairs(yoyoData) do
      if v.raidid == configID then
        table.insert(temp, v)
      end
    end
    classifiedRoomData[configID] = temp
  end
  return classifiedRoomData
end

function YoyoViewPage:_refreshChoose()
  if self.gridListCtl then
    local childCells = self.gridListCtl:GetCells()
    for i = 1, #childCells do
      local childCell = childCells[i]
      childCell:ShowChooseImg(self.chooseMapId)
    end
  end
end
