autoImport("RaidStatisticsView")
StarArkStatisticsView = class("StarArkStatisticsView", RaidStatisticsView)
StarArkStatisticsView.ViewType = UIViewType.CheckLayer

function StarArkStatisticsView:AddListenEvts()
  self:AddListenEvt(ServiceEvent.FuBenCmdQueryElementRaidStat, self.HandleRecvQueryElementRaidStat)
  self:AddListenEvt(PVEEvent.ComodoRaid_Shutdown, self.CloseSelf)
end

function StarArkStatisticsView:InitView()
  StarArkStatisticsView.super.InitView(self)
  self.raidMapTog.gameObject:SetActive(false)
end

function StarArkStatisticsView:OnEnter()
  RaidStatisticsView.super.OnEnter(self)
  ServiceFuBenCmdProxy.Instance:CallQueryElementRaidStat(nil, nil, nil, PveRaidType.StarArk)
end

function StarArkStatisticsView:GetRecordFilter()
  local filter = GroupRaidProxy.Instance:GetStarArkRecordFilter()
  if not self.recordDataL then
    self.recordDataL = 1
  end
  if not self.recordDataR then
    self.recordDataR = 1
  end
  return filter
end

function StarArkStatisticsView:InitFilter(filter, filterConfig, currentFilter, extraCofig)
  filterConfig = filterConfig or _EmptyTable
  filter:Clear()
  if extraCofig then
    for i = 1, #filterConfig do
      local filterData = extraCofig[filterConfig[i]]
      filter:AddItem(filterData, filterConfig[i])
    end
    if 0 < #filterConfig then
      local range, filterData
      if extraCofig then
        range = filterConfig[1]
        filterData = extraCofig[range]
      else
        range = filterConfig[0]
        filterData = filterConfig[range]
      end
      filter.value = filterData
      currentFilter = filter.data
      self.filterData = range
    end
  else
    for i = 0, #filterConfig do
      if filterConfig[i] then
        filter:AddItem(filterConfig[i], i)
      end
    end
    filter.value = filterConfig[currentFilter] or ""
  end
end

function StarArkStatisticsView:HandleRecvQueryElementRaidStat()
  self.isinit = false
  RaidStatisticsView.HandleRecvQueryInfo(self)
end

function StarArkStatisticsView:UpdatePlayerList(gridctl, filtervalue, recordtime)
  local datas = GroupRaidProxy.Instance:GetElementDataByIndex(recordtime, filtervalue)
  local weights = GroupRaidProxy.Instance:GetElementWeightMapByTime(recordtime)
  if datas then
    self:SortByFilter(filtervalue, datas)
    for i = 1, #datas do
      datas[i]:SetPercentage(weights, filtervalue)
    end
    gridctl:ResetDatas(datas)
  end
end
