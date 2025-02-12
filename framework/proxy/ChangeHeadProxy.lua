autoImport("ChangeHeadData")
ChangeHeadProxy = class("ChangeHeadProxy", pm.Proxy)
ChangeHeadProxy.Instance = nil
ChangeHeadProxy.NAME = "ChangeHeadProxy"

function ChangeHeadProxy:ctor(proxyName, data)
  self.proxyName = proxyName or ChangeHeadProxy.NAME
  if ChangeHeadProxy.Instance == nil then
    ChangeHeadProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function ChangeHeadProxy:Init()
  self.portraitList = {}
  self.frameList = {}
  self.backgroundList = {}
  self.chatframeList = {}
end

function ChangeHeadProxy:RecvQueryPortraitList(data)
  if data.portrait then
    TableUtility.ArrayClear(self.portraitList)
    local empty = ChangeHeadData.new(0)
    empty:SetType(ChangeHeadData.HeadCellType.Avatar)
    TableUtility.ArrayPushBack(self.portraitList, empty)
    for i = 1, #data.portrait do
      local changeHeadData = ChangeHeadData.new(data.portrait[i])
      changeHeadData:SetType(ChangeHeadData.HeadCellType.Avatar)
      TableUtility.ArrayPushBack(self.portraitList, changeHeadData)
    end
  end
end

function ChangeHeadProxy:RecvNewPortraitFrame(data)
  if data.portrait then
    if #self.portraitList == 0 then
      local empty = ChangeHeadData.new(0)
      empty:SetType(ChangeHeadData.HeadCellType.Avatar)
      TableUtility.ArrayPushBack(self.portraitList, empty)
    end
    for i = 1, #data.portrait do
      local changeHeadData = ChangeHeadData.new(data.portrait[i])
      changeHeadData:SetType(ChangeHeadData.HeadCellType.Avatar)
      TableUtility.ArrayPushBack(self.portraitList, changeHeadData)
    end
  end
end

function ChangeHeadProxy:GetPortraitList()
  return self.portraitList
end

function ChangeHeadProxy:RecvSyncAllPhotoFrame(data)
  self:SyncChangeHeadData(self.frameList, ChangeHeadData.HeadCellType.Portrait, data)
end

function ChangeHeadProxy:RecvSyncAllBackgroundFrame(data)
  self:SyncChangeHeadData(self.backgroundList, ChangeHeadData.HeadCellType.Frame, data)
end

function ChangeHeadProxy:RecvSyncUnlockChatFrame(data)
  self:SyncChangeHeadData(self.chatframeList, ChangeHeadData.HeadCellType.ChatFrame, data)
end

function ChangeHeadProxy:SyncChangeHeadData(list, type, data)
  if data.ids then
    for i = 1, #data.ids do
      local info = data.ids[i]
      local id = info.id
      if info.del then
        list[id] = nil
      else
        local changeHeadData = list[id]
        if not changeHeadData then
          changeHeadData = ChangeHeadData.new(id)
          list[id] = changeHeadData
        end
        changeHeadData:SetType(type)
        changeHeadData:SetEndTime(info.endtime)
      end
    end
  end
end

function ChangeHeadProxy:RecvUnlockPhotoFrame(data)
  if data.del then
    for i = #self.frameList, 1, -1 do
      if data.id == self.frameList[i].id then
        table.remove(self.frameList, i)
      end
    end
  else
    if #self.frameList == 0 then
      local empty = ChangeHeadData.new(0)
      empty:SetType(ChangeHeadData.HeadCellType.Portrait)
      TableUtility.ArrayPushBack(self.frameList, empty)
    end
    local changeHeadData = ChangeHeadData.new(data.id)
    changeHeadData:SetType(ChangeHeadData.HeadCellType.Portrait)
    TableUtility.ArrayPushBack(self.frameList, changeHeadData)
  end
end

function ChangeHeadProxy:RecvUnlockBackgroundFrame(data)
  if data.del then
    for i = #self.backgroundList, 1, -1 do
      if data.id == self.backgroundList[i].id then
        table.remove(self.backgroundList, i)
      end
    end
  else
    if #self.backgroundList == 0 then
      local empty = ChangeHeadData.new(0)
      empty:SetType(ChangeHeadData.HeadCellType.Frame)
      TableUtility.ArrayPushBack(self.backgroundList, empty)
    end
    local changeHeadData = ChangeHeadData.new(data.id)
    changeHeadData:SetType(ChangeHeadData.HeadCellType.Frame)
    TableUtility.ArrayPushBack(self.backgroundList, changeHeadData)
  end
end

function ChangeHeadProxy:GetListDatas(type, map)
  local result = {}
  local empty = ChangeHeadData.new(0)
  empty:SetType(type)
  TableUtility.ArrayPushBack(result, empty)
  for _, data in pairs(map) do
    TableUtility.ArrayPushBack(result, data)
  end
  return result
end

function ChangeHeadProxy:GetFrameList()
  return self:GetListDatas(ChangeHeadData.HeadCellType.Portrait, self.frameList)
end

function ChangeHeadProxy:GetBackgroundList()
  return self:GetListDatas(ChangeHeadData.HeadCellType.Frame, self.backgroundList)
end

function ChangeHeadProxy:GetChatframeList()
  return self:GetListDatas(ChangeHeadData.HeadCellType.ChatFrame, self.chatframeList)
end
