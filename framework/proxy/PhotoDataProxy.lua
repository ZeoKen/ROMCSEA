PhotoDataProxy = class("PhotoDataProxy", pm.Proxy)
PhotoDataProxy.Instance = nil
PhotoDataProxy.NAME = "PhotoDataProxy"
autoImport("PhotoData")
local tempArray = {}
PhotoDataProxy.PhotoType = {
  PersonalPhotoType = 1,
  SceneryPhotoType = 2,
  PostcardType = 3
}

function PhotoDataProxy:ctor(proxyName, data)
  self.proxyName = proxyName or PhotoDataProxy.NAME
  if PhotoDataProxy.Instance == nil then
    PhotoDataProxy.Instance = self
  end
  self.pictureAblumSize = 0
  self.totoalUpSize = -1
  self.totalCountPerFrame = GameConfig.Wedding.MaxFramePhotoCount or 30
  self.photos = {}
  self.upPhotos = {}
  self.currentFrameList = {}
  self.selectedData = {}
  self.removeDatas = {}
  self.tobeSeeList = {}
end

function PhotoDataProxy:removeToSeeDatas(data)
  for i = 1, #self.tobeSeeList do
    local single = self.tobeSeeList[i]
    if single.sourceid == data.sourceid and single.source == data.source then
      table.remove(self.tobeSeeList, i)
      break
    end
  end
end

function PhotoDataProxy:addToSeeDatas(data)
  for i = 1, #self.tobeSeeList do
    local single = self.tobeSeeList[i]
    if single.sourceid == data.sourceid and single.source == data.source then
      return
    end
  end
  self.tobeSeeList[#self.tobeSeeList + 1] = data
end

function PhotoDataProxy:clearUpPhotos(...)
  TableUtility.ArrayClear(self.upPhotos)
end

function PhotoDataProxy:clearCurFrameList(...)
  TableUtility.ArrayClear(self.currentFrameList)
end

function PhotoDataProxy:clearToSeeDatas(...)
  TableUtility.ArrayClear(self.tobeSeeList)
end

function PhotoDataProxy:clearSelectedData(...)
  TableUtility.ArrayClear(self.selectedData)
end

function PhotoDataProxy:clearRemoveData(...)
  TableUtility.ArrayClear(self.removeDatas)
end

function PhotoDataProxy:GetSelectedDataByPhotoData(data)
  for i = 1, #self.selectedData do
    local single = self.selectedData[i]
    if single.source == data.source and single.sourceid == data.sourceid then
      return single, i
    end
  end
end

function PhotoDataProxy:GetRemovedDataByPhotoData(data)
  for i = 1, #self.removeDatas do
    local single = self.removeDatas[i].photoData
    if single.source == data.source and single.sourceid == data.sourceid then
      return single, i
    end
  end
end

function PhotoDataProxy:StartSyncPictureWallFrame(frameId)
  for i = 1, #self.removeDatas do
    local single = self.removeDatas[i]
    local photoData = single.photoData
    ServicePhotoCmdProxy.Instance:CallFrameActionPhotoCmd(single.frameid, PhotoCmd_pb.EFRAMEACTION_REMOVE, {
      {
        source = photoData.source,
        sourceid = photoData.sourceid
      }
    })
  end
  local list = {}
  for i = 1, #self.selectedData do
    local single = self.selectedData[i]
    list[#list + 1] = {
      source = single.source,
      sourceid = single.sourceid
    }
  end
  ServicePhotoCmdProxy.Instance:CallFrameActionPhotoCmd(frameId, PhotoCmd_pb.EFRAMEACTION_UPLOAD, list)
end

function PhotoDataProxy:RemovePhotoData(cell)
  local data, index = self:GetSelectedDataByPhotoData(cell.data)
  local uploadData = self:checkPhotoFrame(cell.data)
  if uploadData then
    self.removeDatas[#self.removeDatas + 1] = uploadData
    cell:setIsSelected(false)
  else
    helplog("remove error no this data")
  end
  if data then
    cell:setIsSelected(false)
    table.remove(self.selectedData, index)
  end
end

function PhotoDataProxy:getCurUpSize()
  local count = #self.selectedData - #self.removeDatas + #self.upPhotos
  return count
end

function PhotoDataProxy:AddPhotoData(cell)
  local data, index = self:GetSelectedDataByPhotoData(cell.data)
  local uploads = self:getUploadedPhoto()
  local count = self:getCurUpSize()
  if count >= self.totoalUpSize then
    MsgManager.ShowMsgByIDTable(999)
  else
    local uploadData = self:checkPhotoFrame(cell.data)
    if uploadData then
      for i = 1, #self.removeDatas do
        local single = self.removeDatas[i].photoData
        if single.source == cell.data.source and single.sourceid == cell.data.sourceid then
          cell:setIsSelected(true)
          table.remove(self.removeDatas, i)
          return
        end
      end
    end
    if not data then
      cell:setIsSelected(true)
      self.selectedData[#self.selectedData + 1] = cell.data
    else
      helplog("add exsit photo data")
    end
  end
end

function PhotoDataProxy:DetailPicUnSelected(PhotoData)
  local data, index = self:GetSelectedDataByPhotoData(PhotoData)
  local uploadData = self:checkPhotoFrame(PhotoData)
  if uploadData then
    self.removeDatas[#self.removeDatas + 1] = uploadData
    return true
  else
    helplog("remove error no this data")
  end
  if data then
    table.remove(self.selectedData, index)
    return true
  end
end

function PhotoDataProxy:DetailPicSelected(PhotoData)
  local data, index = self:GetSelectedDataByPhotoData(PhotoData)
  local uploads = self:getUploadedPhoto()
  local count = self:getCurUpSize()
  if count >= self.totoalUpSize then
    MsgManager.ShowMsgByIDTable(999)
    return false
  else
    local uploadData = self:checkPhotoFrame(PhotoData)
    if uploadData then
      for i = 1, #self.removeDatas do
        local single = self.removeDatas[i].photoData
        if single.source == PhotoData.source and single.sourceid == PhotoData.sourceid then
          table.remove(self.removeDatas, i)
          return true
        end
      end
    end
    if not data then
      self.selectedData[#self.selectedData + 1] = PhotoData
      return true
    else
      helplog("add exsit photo data")
    end
  end
end

function PhotoDataProxy:getPictureAblumSize()
  return self.pictureAblumSize
end

function PhotoDataProxy:isPhotoAlbumFull()
  return #self.photos == self.pictureAblumSize
end

function PhotoDataProxy:isPhotoAlbumOutofbounds()
  return #self.photos > self.pictureAblumSize
end

function PhotoDataProxy:getEmptyCellIndex()
  for i = 1, self.pictureAblumSize do
    local exsit = false
    for j = 1, #self.photos do
      local index = self.photos[j].index
      if index == i then
        exsit = true
        break
      end
    end
    if not exsit then
      return i
    end
  end
end

function PhotoDataProxy:RecvPhotoQueryListCmd(data)
  TableUtility.ArrayClear(self.photos)
  self.pictureAblumSize = data.size and data.size or 0
  if data.photos and #data.photos > 0 then
    for i = 1, #data.photos do
      local single = data.photos[i]
      local data = PhotoData.new(single, PhotoDataProxy.PhotoType.PersonalPhotoType)
      self.photos[#self.photos + 1] = data
    end
  end
end

function PhotoDataProxy:RecvPhotoOptCmd(data)
end

function PhotoDataProxy:RecvPhotoUpdateNtf(data)
  local opttype = data.opttype
  if opttype == PhotoCmd_pb.EPHOTOOPTTYPE_REMOVE then
    local index = data.photo.index
    for i = 1, #self.photos do
      if index == self.photos[i].index then
        table.remove(self.photos, i)
        PersonalPictureManager.Instance():removeAndClearPhotoDataWhenDel(index, data.photo.time)
        break
      end
    end
  else
    local index = data.photo.index
    local update = false
    local oldPhotoData
    for i = 1, #self.photos do
      if index == self.photos[i].index and data.photo.time ~= self.photos[i].time then
        PersonalPictureManager.Instance():removePhotoDataWhenDel(index, self.photos[i].time)
        table.remove(self.photos, i)
        break
      end
      if index == self.photos[i].index and data.photo.time == self.photos[i].time then
        update = true
        oldPhotoData = self.photos[i]
        break
      end
    end
    if not update then
      local tbData = PhotoData.new(data.photo, PhotoDataProxy.PhotoType.PersonalPhotoType)
      self.photos[#self.photos + 1] = tbData
    else
      oldPhotoData:updatePersonalPhoto(data.photo)
    end
  end
end

function PhotoDataProxy:getAllPhotoes()
  return self.photos
end

function PhotoDataProxy:getPhotoDataByIndex(index)
  for i = 1, #self.photos do
    if index == self.photos[i].index then
      return self.photos[i]
    end
  end
end

function PhotoDataProxy:checkPhotoFrame(photoData, frameId)
  local lRet
  for i = 1, #self.upPhotos do
    local tbData = self.upPhotos[i].photoData
    if photoData.sourceid == tbData.sourceid and photoData.source == tbData.source and photoData.charid == tbData.charid then
      lRet = lRet or {}
      lRet[#lRet + 1] = self.upPhotos[i]
    end
  end
  for i = 1, #self.currentFrameList do
    local tbData = self.currentFrameList[i].photoData
    if photoData.sourceid == tbData.sourceid and photoData.source == tbData.source and photoData.charid == tbData.charid and (frameId and frameId == self.currentFrameList[i].frameid or not frameId) then
      lRet = lRet or {}
      lRet[#lRet + 1] = self.currentFrameList[i]
    end
  end
  return lRet
end

function PhotoDataProxy:getUploadedSizeByAlbum(type)
  local count = 0
  for i = 1, #self.upPhotos do
    local single = self.upPhotos[i]
    if single.photoData.source == type then
      count = count + 1
    end
  end
  return count
end

function PhotoDataProxy:getUploadedPhoto()
  return self.upPhotos
end

function PhotoDataProxy:getTotalCountPerFrame()
  return self.totalCountPerFrame
end

function PhotoDataProxy:getUploadedPhotoSize()
  return self.totoalUpSize
end

function PhotoDataProxy:RecvQueryUserPhotoListPhotoCmd(data)
  TableUtility.ArrayClear(self.upPhotos)
  local frames = data.frames
  self.totoalUpSize = data.maxphoto or 0
  self.totalCountPerFrame = data.maxframe or 0
  if frames then
    for i = 1, #frames do
      local single = frames[i]
      for j = 1, #single.photo do
        local sphData = single.photo[j]
        local photoData = PhotoData.new(sphData)
        local tbData = {
          frameid = single.frameid,
          photoData = photoData
        }
        self.upPhotos[#self.upPhotos + 1] = tbData
      end
    end
  end
end

function PhotoDataProxy:RecvFrameActionPhotoCmd(data, isWedding)
  local frameid = data.frameid
  local action = data.action
  local photos = data.photos
  local uploadPhotos = self.upPhotos
  if isWedding then
    uploadPhotos = self.currentFrameList
  end
  if photos and 0 < #photos then
    if action == PhotoCmd_pb.EFRAMEACTION_REMOVE then
      for i = 1, #photos do
        local singleServer = photos[i]
        for j = 1, #uploadPhotos do
          local single = uploadPhotos[j].photoData
          if single.sourceid == singleServer.sourceid and single.source == singleServer.source then
            table.remove(uploadPhotos, j)
            self:removeToSeeDatas(single)
            break
          end
        end
      end
    elseif action == PhotoCmd_pb.EFRAMEACTION_UPLOAD then
      for i = 1, #photos do
        local find = false
        local singleServer = photos[i]
        for j = 1, #uploadPhotos do
          local single = uploadPhotos[j].photoData
          if single.sourceid == singleServer.sourceid and single.source == singleServer.source then
            uploadPhotos[j].frameid = frameid
            self:addToSeeDatas(single)
            find = true
            local key = string.format(PictureDetailPanel.NewKeyTag, singleServer.source, singleServer.sourceid)
            FunctionPlayerPrefs.Me():SetBool(key, true)
            break
          end
        end
        if not find then
          local photoData = PhotoData.new(singleServer)
          local tbData = {frameid = frameid, photoData = photoData}
          self:addToSeeDatas(photoData)
          uploadPhotos[#uploadPhotos + 1] = tbData
          local key = string.format(PictureDetailPanel.NewKeyTag, singleServer.source, singleServer.sourceid)
          FunctionPlayerPrefs.Me():SetBool(key, true)
        end
      end
    end
    GameFacade.Instance:sendNotification(PictureWallDataEvent.ShowRedTip, #self.tobeSeeList)
  end
end

function PhotoDataProxy:checkPhotoSyncPermission()
  return GuildProxy.Instance:CanIDoAuthority(GuildAuthorityMap.EditPicture)
end

function PhotoDataProxy:currentFramePhotoList(data)
  self:clearCurFrameList()
  local photos = data.photos
  local frameid = data.frameid
  for i = 1, #photos do
    local single = photos[i]
    local photoData = PhotoData.new(single)
    local tbData = {frameid = frameid, photoData = photoData}
    self.currentFrameList[#self.currentFrameList + 1] = tbData
  end
end

function PhotoDataProxy:setCurCertificateData(data)
  self.marriageData = data
end

function PhotoDataProxy:getCurCertificateData()
  return self.marriageData
end

function PhotoDataProxy:checkWeddingWallSyncPermission()
  local isNew = WeddingProxy.Instance:IsInWedding(Game.Myself.data.id)
  if isNew then
    return WeddingProxy.Instance:IsSelfInWeddingTime()
  end
end

function PhotoDataProxy:CheckoutPhotoIsUploaded(index)
  if self.photos then
    local count = #self.photos
    for i = 1, count do
      if self.photos[i].index == index then
        return self.photos[i].isupload
      end
    end
    LogUtility.Error(string.format("[%s] CheckoutPhotoIsUploaded() Error : index = %s is not exist in self.photos.values!", self.__cname, tostring(index)))
  else
    LogUtility.Error(string.format("[%s] CheckoutPhotoIsUploaded() Error : self.photos == nil!", self.__cname))
  end
  return true
end
