WeddingWallPicManager = class("WeddingWallPicManager")
autoImport("UnionWallPhotoNew")
autoImport("UnionWallPhotoHelper")
autoImport("MarryPhoto")

function WeddingWallPicManager:Launch()
  if self.running then
    return
  end
  self.running = true
  if self.serverDataArray then
    TableUtility.ArrayClear(self.serverDataArray)
  end
  self.serverDataArray = {}
  if self.TextureArray_ServerData then
    TableUtility.ArrayClear(self.TextureArray_ServerData)
  end
  self.TextureArray_ServerData = {}
  if self.toBeDownload then
    TableUtility.ArrayClear(self.toBeDownload)
  end
  self.toBeDownload = {}
  if self.delayDelArray then
    TableUtility.ArrayClear(self.delayDelArray)
  end
  self.delayDelArray = {}
  if self.LRUTextureCache then
    TableUtility.ArrayClear(self.LRUTextureCache)
  end
  self.LRUTextureCache = {}
  self.maxCache = 7
  self.maxThumbnailSize = 15
  self.enableLog = false
  self.isDownloading = false
end

function WeddingWallPicManager:log(...)
  if self.enableLog then
    helplog("WeddingWallPicManager", ...)
  end
end

function WeddingWallPicManager:deleteTextureByPhotoData(photoData)
  for i = 1, #self.TextureArray_ServerData do
    local single = self.TextureArray_ServerData[i]
    if self:checkSamePicture(single.photoData, photoData) then
      table.remove(self.TextureArray_ServerData, i)
      Object.DestroyImmediate(single.texture)
      self:StopDownloadAndClean(photoData)
      break
    end
  end
end

function WeddingWallPicManager:removeDelayArray(frameId)
  for j = 1, #self.delayDelArray do
    local single = self.delayDelArray[j]
    if frameId == single.frameId then
      Game.GameObjectManagers[Game.GameObjectType.ScenePhotoFrame]:SetPhoto(single.frameId, nil)
      self:removeDownloadTexture(single.photoData)
      self:removeBytesBySceneryId(single.photoData)
      table.remove(self.delayDelArray, j)
      break
    end
  end
end

function WeddingWallPicManager:StopDownloadAndClean(photoData)
  if FunctionPhotoStorage.IsActive() then
    local uPhotoType = FunctionPhotoStorage.GetUnionWallType(photoData.source, photoData.isBelongAccPic)
    if uPhotoType then
      FunctionPhotoStorage.Me():RemoveUnionWallPhotoData(uPhotoType, photoData.charid, photoData.sourceid)
    end
    return
  end
  UnionWallPhotoNew.Ins():Clear_Personal(photoData.charid, photoData.sourceid)
end

function WeddingWallPicManager:GetBytes(photoData)
  local bytes = self:GetBytesBySceneryId(photoData, true)
  if bytes then
    return bytes
  end
end

function WeddingWallPicManager:GetBytesBySceneryId(photoData, rePos)
  for i = 1, #self.LRUTextureCache do
    local single = self.LRUTextureCache[i]
    if self:checkSamePicture(single.photoData, photoData) then
      if rePos then
        table.remove(self.LRUTextureCache, i)
        table.insert(self.LRUTextureCache, 1, single)
      end
      return single.bytes
    end
  end
end

function WeddingWallPicManager:removeBytesBySceneryId(photoData)
  for i = 1, #self.LRUTextureCache do
    local single = self.LRUTextureCache[i]
    if self:checkSamePicture(single.photoData, photoData) then
      table.remove(self.LRUTextureCache, i)
      break
    end
  end
end

function WeddingWallPicManager:addOriginBytesBySceneryId(photoData, bytes)
  if not self:GetBytesBySceneryId(photoData) then
    if #self.LRUTextureCache > self.maxCache then
      table.remove(self.LRUTextureCache)
    end
    local data = {}
    data.photoData = photoData
    data.bytes = bytes
    table.insert(self.LRUTextureCache, 1, data)
  else
    self:log("addOriginBytesBySceneryId:exsit ")
  end
end

function WeddingWallPicManager:removeDownloadTexture(photoData)
  for j = 1, #self.toBeDownload do
    local data = self.toBeDownload[j]
    if self:checkSamePicture(photoData, data) then
      table.remove(self.toBeDownload, j)
      break
    end
  end
end

function WeddingWallPicManager:checkSamePicture(exsitData, serverData)
  if exsitData and serverData then
    if exsitData.charid == serverData.charid and exsitData.sourceid == serverData.sourceid and exsitData.source == serverData.source and exsitData.time == serverData.time then
      return true
    end
  else
    self:log("checkSamePicture data is nil!!!!!!!!")
  end
end

function WeddingWallPicManager:getServerData(photoData)
  local list = {}
  for i = 1, #self.serverDataArray do
    local single = self.serverDataArray[i]
    if self:checkSamePicture(single.photoData, photoData) then
      list[#list + 1] = single
    end
  end
  return list
end

function WeddingWallPicManager:getTextureByPhotoData(photoData, rePos)
  for i = 1, #self.TextureArray_ServerData do
    local single = self.TextureArray_ServerData[i]
    if self:checkSamePicture(single.photoData, photoData) then
      if rePos then
        table.remove(self.TextureArray_ServerData, i)
        table.insert(self.TextureArray_ServerData, 1, single)
      end
      return single.texture
    end
  end
end

function WeddingWallPicManager:getServerDataByFrameId(frameId)
  for i = 1, #self.serverDataArray do
    local single = self.serverDataArray[i]
    if single.frameId == frameId then
      return single
    end
  end
end

function WeddingWallPicManager:removeServerDataByFrame(frameId)
  for i = 1, #self.serverDataArray do
    local single = self.serverDataArray[i]
    if single.frameId == frameId then
      table.remove(self.serverDataArray, i)
      Game.GameObjectManagers[Game.GameObjectType.WeddingPhotoFrame]:SetPhoto(frameId, nil)
      break
    end
  end
end

function WeddingWallPicManager:UpdateFramePictureInfos(list)
  for i = 1, #list do
    self:UpdateFramePictureInfo(list[i])
  end
  self:startTryGenThumbnail()
end

function WeddingWallPicManager:UpdateFramePictureInfo(serverData)
  local frameId = tonumber(serverData.frameid)
  local charid = serverData.charid
  local photoData = serverData.photo
  self:log("AddPictureInfo", frameId, photoData.sourceid, photoData.source, photoData.time, photoData.anglez)
  if frameId == 0 then
    return
  end
  local exsitData = self:getServerDataByFrameId(frameId)
  if exsitData then
    if self:checkSamePicture(photoData, exsitData.photoData) then
      self:trySetThumbnailTexture(exsitData.photoData)
      return
    else
      Game.GameObjectManagers[Game.GameObjectType.WeddingPhotoFrame]:SetPhoto(frameId, nil)
      if exsitData.photoData.charid == photoData.charid and exsitData.photoData.sourceid == photoData.sourceid and exsitData.photoData.source == photoData.source and exsitData.photoData.time ~= photoData.time then
        self:deleteTextureByPhotoData(exsitData.photoData)
        self:removeDownloadTexture(exsitData.photoData)
        self:removeBytesBySceneryId(exsitData.photoData)
      end
      exsitData.photoData = PhotoData.new(photoData)
    end
    self:trySetThumbnailTexture(exsitData.photoData)
  else
    local localPhotoData = PhotoData.new(photoData)
    local data = {photoData = localPhotoData, frameId = frameId}
    self.serverDataArray[#self.serverDataArray + 1] = data
    self:trySetThumbnailTexture(localPhotoData)
  end
end

function WeddingWallPicManager:GetPicThumbnailByCell(cell)
  local data = cell.data
  local index = data.index
  local time = data.time
  local texture = self:getTextureByPhotoData(data, true)
  if texture then
    cell:setTexture(texture)
  else
    local hasIn = self:HasInToBeDownload(data)
    if not hasIn then
      self.toBeDownload[#self.toBeDownload + 1] = data
      if #self.toBeDownload > 0 then
        self:startTryGenThumbnail()
      end
    end
  end
end

function WeddingWallPicManager:HasInToBeDownload(photoData)
  for i = 1, #self.toBeDownload do
    local single = self.toBeDownload[i]
    if self:checkSamePicture(single, photoData) then
      return true
    end
  end
end

function WeddingWallPicManager:trySetThumbnailTexture(photoData)
  local texture = self:getTextureByPhotoData(photoData, true)
  if texture then
    self:trySetScenePhoto(photoData, texture)
  else
    local exsit = false
    for i = 1, #self.toBeDownload do
      local single = self.toBeDownload[i]
      if self:checkSamePicture(photoData, single) then
        exsit = true
        break
      end
    end
    if not exsit then
      self.toBeDownload[#self.toBeDownload + 1] = photoData
    end
  end
end

function WeddingWallPicManager:addTextureByPhotoData(photoData, texture)
  if not self:getTextureByPhotoData(photoData) then
    if #self.TextureArray_ServerData > self.maxThumbnailSize then
      local textureData = table.remove(self.TextureArray_ServerData)
      Object.DestroyImmediate(textureData.texture)
    end
    local data = {}
    data.photoData = photoData
    data.texture = texture
    table.insert(self.TextureArray_ServerData, 1, data)
  else
    self:log("addTextureByPhotoData:exsit ")
    Object.DestroyImmediate(texture)
  end
end

function WeddingWallPicManager:startTryGenThumbnail()
  if FunctionPhotoStorage.IsActive() then
    local singleLoadData
    for i = 1, #self.toBeDownload do
      singleLoadData = self.toBeDownload[i]
      if singleLoadData then
        self:tryGenThumbnail(singleLoadData)
      end
    end
    TableUtility.TableClear(self.toBeDownload)
    return
  end
  if #self.toBeDownload > 0 and not self.isDownloading then
    local loadData = self.toBeDownload[1]
    self:tryGenThumbnail(loadData)
  end
end

function WeddingWallPicManager:tryGenThumbnail(photoData)
  self:log("tryGenThumbnail", photoData.charid, photoData.sourceid, photoData.time)
  self.isDownloading = true
  if FunctionPhotoStorage.IsActive() then
    local uPhotoType = FunctionPhotoStorage.GetUnionWallType(photoData.source, photoData.isBelongAccPic)
    if uPhotoType then
      FunctionPhotoStorage.Me():GetUnionWallPhoto(uPhotoType, photoData.charid, photoData.sourceid, photoData.time, true, function(progress)
        self:thumbnailProgressCallback(photoData, progress)
      end, function(bytes, errorMessage)
        if bytes then
          self:thumbnailCompleteCallback(photoData, bytes)
        else
          self:thumbnailErrorCallback(photoData, errorMessage)
        end
      end)
    else
      self:log("unknown source")
    end
    return
  end
  if photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SELF then
    UnionWallPhotoHelper.Ins():GetThumbnail_Personal(photoData.charid, photoData.sourceid, photoData.time, function(progress)
      self:thumbnailProgressCallback(photoData, progress)
    end, function(bytes)
      self:thumbnailCompleteCallback(photoData, bytes)
    end, function(errorMessage)
      self:thumbnailErrorCallback(photoData, errorMessage)
    end)
  elseif photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SCENERY then
    if photoData.isBelongAccPic then
      UnionWallPhotoHelper.Ins():GetOriginImage_ScenicSpot_Account(photoData.charid, photoData.sourceid, photoData.time, function(progress)
        self:thumbnailProgressCallback(photoData, progress)
      end, function(bytes)
        self:thumbnailCompleteCallback(photoData, bytes)
      end, function(errorMessage)
        self:thumbnailErrorCallback(photoData, errorMessage)
      end)
    else
      UnionWallPhotoHelper.Ins():GetThumbnail_ScenicSpot(photoData.charid, photoData.sourceid, photoData.time, function(progress)
        self:thumbnailProgressCallback(photoData, progress)
      end, function(bytes)
        self:thumbnailCompleteCallback(photoData, bytes)
      end, function(errorMessage)
        self:thumbnailErrorCallback(photoData, errorMessage)
      end)
    end
  else
    self:log("unknown source")
  end
end

function WeddingWallPicManager:thumbnailProgressCallback(photoData, progress)
  self:log("thumbnailProgressCallback", charId, sceneryId, progress)
  self:WallPicThumbnailDownloadProgressCallback1(photoData, progress)
end

function WeddingWallPicManager:thumbnailErrorCallback(photoData, errorMessage)
  self.isDownloading = false
  self:removeDownloadTexture(photoData)
  self:log("thumbnailErrorCallback", photoData.charid, errorMessage)
  local serverDatas = self:getServerData(photoData)
  for i = 1, #serverDatas do
    local single = serverDatas[i]
    self:removeDelayArray(single.frameId)
  end
  self:WallPicThumbnailDownloadErrorCallback1(photoData, errorMessage)
  self:startTryGenThumbnail()
end

function WeddingWallPicManager:thumbnailCompleteCallback(photoData, bytes)
  self:log("thumbnailCompleteCallback:", charId, sceneryId)
  self.isDownloading = false
  local serverDatas = self:getServerData(photoData)
  for i = 1, #serverDatas do
    local single = serverDatas[i]
    self:removeDelayArray(single.frameId)
  end
  local texture = Texture2D(200, 100, TextureFormat.RGB24, false)
  local bRet = ImageConversion.LoadImage(texture, bytes)
  if bRet then
    self:trySetScenePhoto(photoData, texture)
    self:addTextureByPhotoData(photoData, texture)
    self:WallPicThumbnailDownloadCompleteCallback1(photoData, bytes)
    self:removeDownloadTexture(photoData)
    self:startTryGenThumbnail()
  else
    self:thumbnailErrorCallback(photoData, "load LoadImage error!")
    Object.DestroyImmediate(texture)
  end
end

function WeddingWallPicManager:trySetScenePhoto(photoData, texture)
  local serverDatas = self:getServerData(photoData)
  for i = 1, #serverDatas do
    local single = serverDatas[i]
    self:log("GameObjectManagers:trySetScenePhoto sus", single.frameId, tostring(texture))
    Game.GameObjectManagers[Game.GameObjectType.WeddingPhotoFrame]:SetPhoto(single.frameId, texture, texture.width, texture.height, photoData.anglez)
  end
end

function WeddingWallPicManager:tryGetOriginImage(photoData)
  self:log("tryGetOriginImage", photoData.charid, photoData.sourceid, tostring(photoData.source))
  self:log("tryGetOriginImage", tostring(photoData.isBelongAccPic))
  if FunctionPhotoStorage.IsActive() then
    local uPhotoType = FunctionPhotoStorage.GetUnionWallType(photoData.source, photoData.isBelongAccPic)
    if uPhotoType then
      FunctionPhotoStorage.Me():GetUnionWallPhoto(uPhotoType, photoData.charid, photoData.sourceid, photoData.time, false, function(progress)
        self:originProgressCallback(photoData, progress)
      end, function(bytes, errorMessage)
        if bytes then
          self:originCompleteCallback(photoData, bytes)
        else
          self:originErrorCallback(photoData, errorMessage)
        end
      end)
    else
      self:log("tryGetOriginImage unknown source")
    end
    return
  end
  if photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SELF then
    UnionWallPhotoHelper.Ins():GetOriginImage_Personal(photoData.charid, photoData.sourceid, photoData.time, function(progress)
      self:originProgressCallback(photoData, progress)
    end, function(bytes)
      self:originCompleteCallback(photoData, bytes)
    end, function(errorMessage)
      self:originErrorCallback(photoData, errorMessage)
    end)
  elseif photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SCENERY then
    if photoData.isBelongAccPic then
      UnionWallPhotoHelper.Ins():GetOriginImage_ScenicSpot_Account(photoData.charid, photoData.sourceid, photoData.time, function(progress)
        self:originProgressCallback(photoData, progress)
      end, function(bytes)
        self:originCompleteCallback(photoData, bytes)
      end, function(errorMessage)
        self:originErrorCallback(photoData, errorMessage)
      end)
    else
      UnionWallPhotoHelper.Ins():GetOriginImage_ScenicSpot(photoData.charid, photoData.sourceid, photoData.time, function(progress)
        self:originProgressCallback(photoData, progress)
      end, function(bytes)
        self:originCompleteCallback(photoData, bytes)
      end, function(errorMessage)
        self:originErrorCallback(photoData, errorMessage)
      end)
    end
  else
    self:log("tryGetOriginImage unknown source")
  end
end

WeddingWallPicManager.WallPicOriginDownloadProgressCallback = "WeddingWallPicManager_WallPicOriginDownloadProgressCallback"
WeddingWallPicManager.WallPicOriginDownloadCompleteCallback = "WeddingWallPicManager_WallPicOriginDownloadCompleteCallback"
WeddingWallPicManager.WallPicOriginDownloadErrorCallback = "WeddingWallPicManager_WallPicOriginDownloadErrorCallback"

function WeddingWallPicManager:originProgressCallback(photoData, progress)
  self:log("originProgressCallback", photoData.charid, photoData.sourceid, progress)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WallPicOriginDownloadProgressCallback, {photoData = photoData, progress = progress})
end

function WeddingWallPicManager:originCompleteCallback(photoData, bytes)
  self:log("originCompleteCallback", photoData.charid, photoData.sourceid, tostring(bytes))
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WallPicOriginDownloadCompleteCallback, {photoData = photoData, byte = bytes})
end

function WeddingWallPicManager:originErrorCallback(photoData, errorMessage)
  self:log("originErrorCallback", photoData.charid, photoData.sourceid, errorMessage)
end

WeddingWallPicManager.WallPicThumbnailDownloadProgressCallback = "WeddingWallPicManager_WallPicThumbnailDownloadProgressCallback"
WeddingWallPicManager.WallPicThumbnailDownloadCompleteCallback = "WeddingWallPicManager_WallPicThumbnailDownloadCompleteCallback"
WeddingWallPicManager.WallPicThumbnailDownloadErrorCallback = "WeddingWallPicManager_WallPicThumbnailDownloadErrorCallback"

function WeddingWallPicManager:WallPicThumbnailDownloadProgressCallback1(photoData, progress)
  self:log("WallPicThumbnailDownloadProgressCallback", index, time, progress)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WallPicThumbnailDownloadProgressCallback, {photoData = photoData, progress = progress})
end

function WeddingWallPicManager:WallPicThumbnailDownloadCompleteCallback1(photoData, bytes)
  self:log("WallPicThumbnailDownloadCompleteCallback", index, time, tostring(bytes))
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WallPicThumbnailDownloadCompleteCallback, {photoData = photoData, byte = bytes})
end

function WeddingWallPicManager:WallPicThumbnailDownloadErrorCallback1(photoData, errorMessage)
  self:log("WallPicThumbnailDownloadErrorCallback", index, time, errorMessage)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WallPicThumbnailDownloadErrorCallback, {photoData = photoData, errorMessage = errorMessage})
end

function WeddingWallPicManager:ShowDetailPicure(frameId, frameObj)
  local serverData = self:getServerDataByFrameId(frameId)
  local viewData = {
    view = PanelConfig.WeddingWallPictureDetail,
    viewdata = {
      serverData = serverData,
      frameId = frameId,
      trans = frameObj.transform
    }
  }
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, viewData)
end

function WeddingWallPicManager:ClickFrame(frameId, frameObj)
  self:log("ClickFrame:", frameId)
  self:ShowDetailPicure(frameId, frameObj)
end

function WeddingWallPicManager:Shutdown()
  GameFacade.Instance:sendNotification(PictureWallDataEvent.MapEnd)
  if not self.running then
    return
  end
  self.running = false
  self:_DestroyDatas()
end

function WeddingWallPicManager:_DestroyDatas()
  for i = 1, #self.TextureArray_ServerData do
    local single = self.TextureArray_ServerData[i]
    if single and single.texture then
      Object.DestroyImmediate(single.texture)
    end
  end
  for i = 1, #self.serverDataArray do
    local single = self.serverDataArray[i]
    Game.GameObjectManagers[Game.GameObjectType.WeddingPhotoFrame]:SetPhoto(single.frameId, nil)
  end
  TableUtility.ArrayClear(self.TextureArray_ServerData)
  TableUtility.ArrayClear(self.serverDataArray)
  TableUtility.ArrayClear(self.delayDelArray)
  TableUtility.ArrayClear(self.toBeDownload)
  TableUtility.ArrayClear(self.LRUTextureCache)
  PhotoDataProxy.Instance:clearToSeeDatas()
  PhotoDataProxy.Instance:clearSelectedData()
  PhotoDataProxy.Instance:clearRemoveData()
  PhotoDataProxy.Instance:clearUpPhotos()
  PhotoDataProxy.Instance:clearCurFrameList()
end

WeddingWallPicManager.WeddingPicDownloadProgressCallback = "WeddingWallPicManager_WeddingPicDownloadProgressCallback"
WeddingWallPicManager.WeddingPicDownloadCompleteCallback = "WeddingWallPicManager_WeddingPicDownloadCompleteCallback"
WeddingWallPicManager.WeddingPicDownloadErrorCallback = "WeddingWallPicManager_WeddingPicDownloadErrorCallback"
WeddingWallPicManager.WeddingPicUploadProgressCallback = "WeddingWallPicManager_WeddingPicUploadProgressCallback"
WeddingWallPicManager.WeddingPicUploadCompleteCallback = "WeddingWallPicManager_WeddingPicUploadCompleteCallback"
WeddingWallPicManager.WeddingPicUploadErrorCallback = "WeddingWallPicManager_WeddingPicUploadErrorCallback"

function WeddingWallPicManager:GetWeddingPicture(index, time)
  local weddingInfo = WeddingProxy.Instance:GetWeddingInfo()
  if FunctionPhotoStorage.IsActive() then
    FunctionPhotoStorage.Me():GetWeddingPhoto(index, time, false, function(progress)
      self:WeddingPicDownloadProgressCallback1(weddingInfo.id, index, time, progress)
    end, function(bytes, errorMessage)
      if bytes then
        self:WeddingPicDownloadCompleteCallback1(weddingInfo.id, index, time, bytes)
      else
        self:WeddingPicDownloadErrorCallback1(index, time, errorMessage)
      end
    end)
    return
  end
  self:log("GetWeddingPicture", weddingInfo.id, tostring(index), tostring(time))
  MarryPhoto.Ins():GetOriginImage(weddingInfo.id, 0, time, function(progress)
    self:WeddingPicDownloadProgressCallback1(weddingInfo.id, index, time, progress)
  end, function(bytes)
    self:WeddingPicDownloadCompleteCallback1(weddingInfo.id, index, time, bytes)
  end, function(errorMessage)
    self:WeddingPicDownloadErrorCallback1(index, time, errorMessage)
  end)
end

function WeddingWallPicManager:UploadWeddingPicture(texture, index, time, from)
  local weddingInfo = WeddingProxy.Instance:GetWeddingInfo()
  if FunctionPhotoStorage.IsActive() then
    FunctionPhotoStorage.Me():SaveWeddingPhoto(texture, index, time, from, function(progress)
      self:WeddingPicUploadProgressCallback1(weddingInfo.id, index, time, progress)
    end, function(bytes, errorMessage)
      if bytes then
        self:WeddingPicUploadCompleteCallback1(weddingInfo.id, index, time, bytes)
      else
        self:WeddingPicUploadErrorCallback1(index, time, errorMessage)
      end
    end)
    return
  end
  local bytes = ImageConversion.EncodeToJPG(texture)
  self:log("UploadWeddingPicture", index, time, from)
  local md5 = MyMD5.HashBytes(bytes)
  GamePhoto.SetPhotoFileMD5_Marry(0, md5)
  local pbMd5 = PhotoCmd_pb.PhotoMd5()
  pbMd5.md5 = md5
  pbMd5.sourceid = index
  pbMd5.time = time
  pbMd5.source = ProtoCommon_pb.ESOURCE_WEDDING_PHOTO
  ServicePhotoCmdProxy.Instance:CallAddMd5PhotoCmd(pbMd5)
  local ctData = PhotoDataProxy.Instance:getCurCertificateData()
  self:log("UploadWeddingPicture weddingInfo:", weddingInfo.id, tostring(bytes))
  MarryPhoto.Ins():SaveAndUpload(weddingInfo.id, 0, bytes, time, function(progress)
    self:log("UploadWeddingPicture progress:", progress)
    self:WeddingPicUploadProgressCallback1(index, time, progress)
  end, function(bytes)
    self:log("UploadWeddingPicture sus:")
    if from == PicutureWallSyncPanel.PictureSyncFrom.WeddingCertificate then
      ServiceNUserProxy.Instance:CallUploadWeddingPhotoUserCmd(ctData.id, index, time)
    else
      ServiceWeddingCCmdProxy.Instance:CallUploadWeddingPhotoCCmd(index, time)
    end
    self:WeddingPicUploadCompleteCallback1(index, time)
    ServicePhotoCmdProxy.Instance:CallRemoveMd5PhotoCmd(pbMd5)
  end, function(errorMessage)
    self:log("UploadWeddingPicture error:", errorMessage)
    self:WeddingPicUploadErrorCallback1(index, time, errorMessage)
  end)
end

function WeddingWallPicManager:WeddingPicUploadProgressCallback1(index, time, progress)
  self:log("WeddingPicUploadProgressCallback1", index, time, progress)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicUploadProgressCallback, {
    index = index,
    time = time,
    progress = progress
  })
end

function WeddingWallPicManager:WeddingPicUploadCompleteCallback1(index, time)
  self:log("WeddingPicUploadCompleteCallback1", index, time)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicUploadCompleteCallback, {index = index, time = time})
end

function WeddingWallPicManager:WeddingPicUploadErrorCallback1(index, time, errorMessage)
  self:log("WeddingPicUploadErrorCallback1", index, time, errorMessage)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicUploadErrorCallback, {index = index, time = time})
end

function WeddingWallPicManager:WeddingPicDownloadProgressCallback1(id, index, time, progress)
  self:log("WeddingPicDownloadProgressCallback1", index, time, progress)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicDownloadProgressCallback, {
    id = id,
    index = index,
    time = time,
    progress = progress
  })
end

function WeddingWallPicManager:WeddingPicDownloadCompleteCallback1(id, index, time, bytes)
  self:log("WeddingPicDownloadCompleteCallback1", index, time, tostring(bytes))
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicDownloadCompleteCallback, {
    id = id,
    index = index,
    time = time,
    byte = bytes
  })
end

function WeddingWallPicManager:WeddingPicDownloadErrorCallback1(index, time, errorMessage)
  self:log("WeddingPicDownloadErrorCallback1", index, time, errorMessage)
  GameFacade.Instance:sendNotification(WeddingWallPicManager.WeddingPicDownloadErrorCallback, {
    index = index,
    time = time,
    errorMessage = errorMessage
  })
end
