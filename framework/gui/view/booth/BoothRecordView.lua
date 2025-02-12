autoImport("BoothRecordCell")
BoothRecordView = class("BoothRecordView", SubView)

function BoothRecordView:Init()
  self:FindObjs()
  self:AddEvts()
  self:AddViewEvts()
  self:InitShow()
end

function BoothRecordView:FindObjs()
  self.objRoot = self:FindGO("RecordRoot", self.container.recordRoot)
  self.contentContainer = self:FindGO("RecordsContainer", self.objRoot)
  self.empty = self:FindGO("RecordEmpty", self.objRoot)
  self.tips = self:FindGO("Tips", self.objRoot):GetComponent(UILabel)
  self.loadingRoot = self:FindGO("LoadingRoot", self.objRoot)
end

function BoothRecordView:AddEvts()
  self:AddClickEvent(self:FindGO("QuickTakeBtn", self.objRoot), function()
    self:ClickQuickTake()
  end)
  self.scrollRecord = self:FindGO("RecordsScrollView", self.objRoot):GetComponent(UIScrollView)
  NGUIUtil.HelpChangePageByDrag(self.scrollRecord, function()
    self:DragUp()
  end, function()
    self:DragDown()
  end, 50)
end

function BoothRecordView:AddViewEvts()
  self:AddListenEvt(ServiceEvent.RecordTradeMyTradeLogRecordTradeCmd, self.RecvMyTradeLog)
  self:AddListenEvt(ServiceEvent.RecordTradeListNtfRecordTrade, self.RecvListNtf)
  self:AddListenEvt(ServiceEvent.RecordTradeTakeLogCmd, self.RecvTakeLog)
  self:AddListenEvt(ServiceEvent.RecordTradeTakeAllLogCmd, self.RecvTakeAllLog)
  self:AddListenEvt(ServiceEvent.RecordTradeAddNewLog, self.RecvLog)
  self:AddListenEvt(ServiceEvent.RecordTradeQucikTakeLogTradeCmd, self.RecvQucikTakeLogTrade)
  self:AddListenEvt(ServiceEvent.RecordTradeUpdateOrderTradeCmd, self.RecvUpdateOrderTrade)
end

function BoothRecordView:InitShow()
  local day = 86400
  self.tips.text = string.format(ZhString.Booth_ExchangeRecordMaxLog, math.floor(GameConfig.Exchange.LogTime / day), math.floor(GameConfig.Exchange.ReceiveTime / day))
  self.empty:SetActive(false)
  self.loadingRoot:SetActive(false)
  local wrapConfig = {
    wrapObj = self.contentContainer,
    pfbNum = 9,
    cellName = "BoothRecordCell",
    control = BoothRecordCell,
    dir = 1
  }
  self.wrapHelper = WrapCellHelper.new(wrapConfig)
  self:UpdateRecord()
  self:ResetPage()
  self:CallRecordList(self.currentPage)
end

function BoothRecordView:UpdateRecord()
  local data = BoothProxy.Instance:GetBoothSellRecordList()
  self.wrapHelper:UpdateInfo(data)
  self.wrapHelper:ResetPosition()
  self.empty:SetActive(#data < 1)
end

function BoothRecordView:ResetPage()
  self.currentPage = 1
  self.totalPage = 1
end

function BoothRecordView:RecvMyTradeLog(note)
  if not note.body or note.body.trade_type ~= BoothProxy.TradeType.Booth then
    return
  end
  self:RecvLog(note)
  self.wrapHelper:ResetPosition()
end

function BoothRecordView:RecvLog(note)
  local data = note.body
  local tradeType = not data.trade_type and data.log and data.log.trade_type
  if data and tradeType == BoothProxy.TradeType.Booth then
    self:UpdateRecord()
    self.totalPage = data.total_page_count and math.max(data.total_page_count, 1) or 1
    if data.index then
      self.currentPage = math.clamp(data.index + 1, 1, self.totalPage)
    end
  end
end

function BoothRecordView:RecvListNtf(note)
  local data = note.body
  if not data or data.trade_type ~= BoothProxy.TradeType.Booth then
    return
  end
  if data.type == RecordTrade_pb.ELIST_NTF_MY_LOG then
    self:CallRecordList(self.currentPage)
  end
end

function BoothRecordView:RecvTakeLog(note)
  local data = note.body
  if data.success and (not data.log or data.log.trade_type == BoothProxy.TradeType.Booth) then
    self:UpdateRecord()
  end
end

function BoothRecordView:RecvTakeAllLog(note)
  local data = note.body
  if data ~= nil then
    local dirty = false
    local _TradeType = BoothProxy.TradeType.Booth
    for i = 1, #data.infos do
      if data.infos[i].tradetype == _TradeType then
        dirty = true
        break
      end
    end
    if dirty then
      self:UpdateRecord()
    end
  end
end

function BoothRecordView:RecvUpdateOrderTrade(note)
  local data = note.body
  if data and data.charid == self.container.playerID and data.type == BoothProxy.TradeType.Booth then
    self:CallRecordList(self.currentPage)
  end
end

function BoothRecordView:RecvQucikTakeLogTrade(note)
  if not note.body then
    return
  end
  TimeTickManager.Me():ClearTick(self)
  self.loadingRoot:SetActive(false)
end

function BoothRecordView:DragUp()
  local page = self.currentPage - 1
  if 1 <= page then
    self.currentPage = page
    self:CallRecordList(self.currentPage)
  end
end

function BoothRecordView:DragDown()
  self:CallRecordList(self.currentPage + 1)
end

function BoothRecordView:ClickQuickTake()
  local sellReceiveCount = BoothProxy.Instance:GetBoothSellRecordReceiveCount()
  if 0 < sellReceiveCount then
    TimeTickManager.Me():ClearTick(self)
    TimeTickManager.Me():CreateOnceDelayTick(15000, function(owner, deltaTime)
      if self.loadingRoot.gameObject then
        self.loadingRoot:SetActive(false)
      end
    end, self)
    self.loadingRoot:SetActive(true)
    ServiceRecordTradeProxy.Instance:CallQucikTakeLogTradeCmd(BoothProxy.TradeType.Booth)
  end
end

function BoothRecordView:CallRecordList(index)
  if index and 0 < index and index <= self.totalPage then
    ServiceRecordTradeProxy.Instance:CallMyTradeLogRecordTradeCmd(Game.Myself.data.id, index - 1, nil, nil, BoothProxy.TradeType.Booth)
  end
end

function BoothRecordView:OnExit()
  TimeTickManager.Me():ClearTick(self)
  BoothRecordView.super.OnExit(self)
end

function BoothRecordView:OnDestroy()
  self.wrapHelper:Destroy()
  self.scrollRecord.onDragStarted = nil
  self.scrollRecord.onDragFinished = nil
  self.scrollRecord.onStoppedMoving = nil
  BoothRecordView.super.OnDestroy(self)
end
