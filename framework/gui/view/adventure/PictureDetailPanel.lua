PictureDetailPanel = class("PictureDetailPanel", ContainerView)
PictureDetailPanel.ViewType = UIViewType.NormalLayer
autoImport("PictureWallCell")
autoImport("PicutureWallSyncPanel")
local tempVector3 = LuaVector3.Zero()
local tempRot = LuaQuaternion.Identity()
PictureDetailPanel.GetWallPicThumbnail = "PictureDetailPanel_GetWallPicThumbnail"
PictureDetailPanel.CheckIsCurrent = "PictureDetailPanel_CheckIsCurrent"
PictureDetailPanel.NewKeyTag = "PictureDetailPanel_NewKeyTag_%s_%s"
PictureDetailPanel.CheckCurrentShowPhoto = "PictureDetailPanel_CheckCurrentShowPhoto"

function PictureDetailPanel:Init()
  self:AddViewEvts()
  self:initView()
  self:initData()
  self:requestFrameData()
end

function PictureDetailPanel:requestFrameData()
  ServicePhotoCmdProxy.Instance:CallQueryUserPhotoListPhotoCmd()
  ServicePhotoCmdProxy.Instance:CallQueryFramePhotoListPhotoCmd(self.frameId)
end

function PictureDetailPanel:AddViewEvts()
  self:AddListenEvt(PictureWallDataEvent.PhotoCompleteCallback, self.photoCompleteCallback)
  self:AddListenEvt(PictureWallDataEvent.PhotoProgressCallback, self.photoProgressCallback)
  self:AddListenEvt(PictureWallDataEvent.MapEnd, self.MapEnd)
  self:AddListenEvt(ServiceEvent.PhotoCmdQueryFramePhotoListPhotoCmd, self.QueryFramePhotoListPhotoCmd)
  self:AddListenEvt(ServiceEvent.PhotoCmdFrameActionPhotoCmd, self.PhotoCmdFrameActionPhotoCmd)
  self:AddListenEvt(PictureWallDataEvent.ShowRedTip, self.ShowRedTip)
  self:AddListenEvt(ServiceEvent.PhotoCmdUpdateFrameShowPhotoCmd, self.UpdateCurPhoto)
  self:AddListenEvt(PictureWallManager.WallPicThumbnailDownloadProgressCallback, self.WallhumbnailPhDlPgCallback)
  self:AddListenEvt(PictureWallManager.WallPicThumbnailDownloadCompleteCallback, self.WallThumbnailPhDlCpCallback)
  self:AddListenEvt(PictureWallManager.WallPicThumbnailDownloadErrorCallback, self.WallThumbnailPhDlErCallback)
end

function PictureDetailPanel:WallhumbnailPhDlPgCallback(note)
  local data = note.body
  local cell = self:GetItemCellById(data.photoData)
  if cell then
    cell:setDownloadProgress(data.progress)
  end
end

function PictureDetailPanel:WallThumbnailPhDlCpCallback(note)
  local data = note.body
  local cell = self:GetItemCellById(data.photoData)
  if cell then
    self:GetWallPicThumbnail(cell)
  end
end

function PictureDetailPanel:WallThumbnailPhDlErCallback(note)
  local data = note.body
  local cell = self:GetItemCellById(data.photoData)
  if cell then
    cell:setDownloadFailure()
  end
end

function PictureDetailPanel:ShowRedTip(note)
  local size = note.body
  if 0 < size then
    self:Show(self.redTip)
    self:ShowMsgAnim(note.body)
  else
    self:Hide(self.redTip)
  end
end

function PictureDetailPanel:GetUploadSusPicture()
  return 0
end

function PictureDetailPanel:ShowMsgAnim(count)
end

function PictureDetailPanel:PhotoCmdFrameActionPhotoCmd(note)
  self:requestFrameData()
  if not self.currentData then
    local texture = self.photo.mainTexture
    self.photo.mainTexture = nil
    Object.DestroyImmediate(texture)
  end
end

function PictureDetailPanel:UpdateCurPhoto()
end

local originSize = 0

function PictureDetailPanel:QueryFramePhotoListPhotoCmd(note)
  local data = note.body
  local list = {}
  if data and data.frameid == self.frameId then
    local photos = data.photos
    for i = 1, #photos do
      local single = photos[i]
      local photoData = PhotoData.new(single)
      list[#list + 1] = photoData
    end
  end
  local curSize = #list
  self:SetData(list)
  local cells = self:GetItemCells()
  if 0 < #list and self.firstActivie then
    self.firstActivie = false
    self.switchCtPlay:Play(true)
  end
  if (0 == originSize or curSize < originSize) and 0 < curSize then
    self:CellClickEvent(cells[1])
  end
  if curSize == 0 then
    self:Hide(self.RemoveCt)
  end
  originSize = curSize
end

function PictureDetailPanel:changePhotoSize()
  local frameData = Table_ScenePhotoFrame[self.frameId]
  local dir = 0
  if frameData then
    dir = frameData.Dir
  end
  if dir == 1 then
    self.photo.width = 400
    self.photo.height = 600
  end
end

function PictureDetailPanel:photoCompleteCallback(note)
  local data = note.body
  Game.PictureWallManager:log("PictureDetailPanel:photoCompleteCallback1", data.photoData.charid, self.currentData.charid, data.byte)
  if self.currentData and Game.PictureWallManager:checkSamePicture(data.photoData, self.currentData) then
    self:completeCallback(data.byte)
  end
end

function PictureDetailPanel:photoProgressCallback(note)
  local data = note.body
  Game.PictureWallManager:log("PictureDetailPanel:photoProgressCallback", data.photoData.charid, self.currentData.charid)
  if self.currentData and Game.PictureWallManager:checkSamePicture(data.photoData, self.currentData) then
    self:progressCallback(data.progress)
  end
end

function PictureDetailPanel:showAnim()
  LuaVector3.Better_Set(tempVector3, 0, 0, 0)
  self.gameObject.transform.localScale = tempVector3
  local sceneryData = self.viewdata.viewdata.serverData
  local trans = self.viewdata.viewdata.trans
  local gm = NGUIUtil:GetCameraByLayername("Default")
  local x, y = LuaGameObject.WorldToViewportPointByTransform(gm, trans.transform, Space.World)
  x = 1280 * (x - 0.5)
  y = 720 * (y - 0.5)
  LuaVector3.Better_Set(tempVector3, x, y, 0)
  local tweenPosition = self.gameObject:GetComponent(TweenPosition)
  local play = self.gameObject:GetComponent(UIPlayTween)
  tweenPosition.from = tempVector3
  self.gameObject.transform.localPosition = tempVector3
  EventDelegate.Set(play.onFinished, function()
    self:showOtherUI()
  end)
  play:Play(true)
end

function PictureDetailPanel:showOtherUI()
  self:Show(self.leftSliderCt)
  self:Show(self.UpdateCt)
  self:Hide(self.scrollView)
  self:Show(self.scrollView)
end

function PictureDetailPanel:MapEnd(note)
  self:CloseSelf()
end

function PictureDetailPanel:OnEnter()
  self:showAnim()
end

function PictureDetailPanel:initData()
  self:initDefaultTextureSize()
  self.serverData = self.viewdata.viewdata.serverData
  self.frameId = self.viewdata.viewdata.frameId
  if self.serverData and self.serverData.photoData then
    local photoData = self.serverData.photoData
    self.anglez = photoData.anglez
    self.isThumbnail = false
  else
    self:changePhotoSize()
  end
  self.currentData = nil
  self.firstActivie = true
end

function PictureDetailPanel:ScrollViewRevert(callback)
  self.revertCallBack = callback
  self.scrollView:Revert()
end

function PictureDetailPanel:initView()
  self.scrollView = self:FindComponent("ItemScrollView", ROUIScrollView)
  
  function self.scrollView.OnStop()
    self:ScrollViewRevert()
  end
  
  self.photo = self:FindGO("photo"):GetComponent(UITexture)
  self.progress = self:FindGO("loadProgress"):GetComponent(UILabel)
  self:Hide(self.progress.gameObject)
  self.leftSlider = self:FindComponent("leftSlider", TweenPosition)
  self.leftSliderCt = self:FindGO("leftSliderCt")
  self.UpdateCt = self:FindGO("UpdateCt")
  self.frameSizeLabel = self:FindComponent("frameSizeLabel", UILabel)
  self.redTip = self:FindGO("redTip")
  self.PhotoCt = self:FindGO("PhotoCt")
  self.RemoveCt = self:FindGO("RemoveCt")
  self:Hide(self.RemoveCt)
  self:Hide(self.redTip)
  self:Hide(self.leftSliderCt)
  self:Hide(self.UpdateCt)
  self.SusMsg = self:FindComponent("SusMsg", UILabel)
  self.tipMsg = self:FindComponent("tipMsg", UILabel)
  self:Hide(self.SusMsg.gameObject)
  self.tipMsg.text = ZhString.DetailPictureShowOther_TipMsg
  self.switchCtPlay = self:FindComponent("switchCt", UIPlayTween)
  local itemContainer = self:FindGO("bag_itemContainer")
  local wrapConfig = {
    wrapObj = itemContainer,
    pfbNum = 6,
    cellName = "PictureWallCell",
    control = PictureWallCell,
    dir = 1
  }
  self.wraplist = WrapCellHelper.new(wrapConfig)
  self.wraplist:AddEventListener(MouseEvent.MouseClick, self.CellClickEvent, self)
  self.wraplist:AddEventListener(PictureDetailPanel.GetWallPicThumbnail, self.GetWallPicThumbnail, self)
  self:AddClickEvent(self.UpdateCt, function()
    local uploads = PhotoDataProxy.Instance:getUploadedPhoto()
    local uploadsSize = PhotoDataProxy.Instance:getUploadedPhotoSize()
    if PhotoDataProxy.Instance:checkPhotoSyncPermission() then
      self:sendNotification(UIEvent.JumpPanel, {
        view = PanelConfig.PicutureWallSyncPanel,
        viewdata = {
          frameId = self.frameId,
          from = PicutureWallSyncPanel.PictureSyncFrom.GuildWall
        }
      })
      self:Hide(self.SusMsg.gameObject)
      self:Hide(self.redTip)
      PhotoDataProxy.Instance:clearToSeeDatas()
    else
      MsgManager.ShowMsgByIDTable(997)
    end
  end)
  self:AddButtonEvent("RemoveCt", function()
    if self.currentData then
      MsgManager.ConfirmMsgByID(25404, function(...)
        local list = {
          {
            source = self.currentData.source,
            sourceid = self.currentData.sourceid,
            charid = self.currentData.serverData.charid,
            accid_svr = self.currentData.serverData.accid_svr
          }
        }
        ServicePhotoCmdProxy.Instance:CallFrameActionPhotoCmd(self.frameId, PhotoCmd_pb.EFRAMEACTION_REMOVE, list)
        self.currentData = nil
      end)
    end
  end)
  self:SetData({})
end

function PictureDetailPanel:CellClickEvent(cellCtl)
  if cellCtl and cellCtl.data then
    helplog("CellClickEvent:", cellCtl.data.charid, Game.Myself.data.id)
    if Game.PictureWallManager:checkSamePicture(cellCtl.data, self.currentData) then
      return
    end
    cellCtl:IsCurrent(true)
    local oldIndex = self:GetIndexByCellData(self.currentData)
    if oldIndex then
      local cells = self:GetItemCells()
      local ctl = cells[oldIndex]
      ctl:IsCurrent(false)
    end
    self.currentData = cellCtl.data
    self.anglez = self.currentData.anglez
    self:getPhoto(self.currentData)
    if self.currentData.isMyself or GuildProxy.Instance:ImGuildChairman() then
      self:IsShowRemoveBtn(true)
    else
      self:IsShowRemoveBtn(false)
    end
  else
    self:Hide(self.RemoveCt)
    self.currentData = nil
  end
end

function PictureDetailPanel:GetWallPicThumbnail(cellCtl)
  if cellCtl and cellCtl.data then
    Game.PictureWallManager:GetPicThumbnailByCell(cellCtl)
  end
end

function PictureDetailPanel:GetIndexByCellData(data)
  if not data then
    return
  end
  local cells = self:GetItemCells()
  for i = 1, #cells do
    local single = cells[i]
    if single.data and Game.PictureWallManager:checkSamePicture(single.data, data) then
      return i
    end
  end
end

function PictureDetailPanel:SetData(datas, noResetPos)
  self.frameSizeLabel.text = string.format(ZhString.PersonalPictureCell_CurFrameShowState, #datas, PhotoDataProxy.Instance:getTotalCountPerFrame())
  self.wraplist:UpdateInfo(datas)
  if 1 < #datas then
    self:Show(self.tipMsg.gameObject)
  else
    self:Hide(self.tipMsg.gameObject)
  end
  local cells = self:GetItemCells()
  if cells and 0 < #cells then
    for i = 1, #cells do
      local single = cells[i]
      if Game.PictureWallManager:checkSamePicture(single.data, self.currentData) then
        single:IsCurrent(true)
      else
        single:IsCurrent(false)
      end
    end
  end
  if not noResetPos then
    self.wraplist:ResetPosition()
  end
  self.scrollView:ResetPosition()
end

function PictureDetailPanel:initDefaultTextureSize()
  self.originWith = self.photo.width
  self.originHeight = self.photo.height
end

function PictureDetailPanel:setTexture(texture)
  local anglez = 0
  if self.anglez >= 45 and self.anglez <= 135 then
    anglez = 90
  elseif self.anglez >= 225 and self.anglez <= 315 then
    anglez = 270
  elseif self.anglez >= 135 and self.anglez <= 225 then
    anglez = 180
  end
  LuaVector3.Better_Set(tempVector3, 0, 0, anglez)
  LuaQuaternion.Better_SetEulerAngles(tempRot, tempVector3)
  self.PhotoCt.transform.localRotation = tempRot
  local orginRatio = self.originWith / self.originHeight
  local textureRatio = 0
  if anglez == 90 or anglez == 270 then
    textureRatio = texture.height / texture.width
  else
    textureRatio = texture.width / texture.height
  end
  local wRatio = math.min(orginRatio, textureRatio) == orginRatio
  local height = self.originHeight
  local width = self.originWith
  if wRatio then
    height = self.originWith / textureRatio
  else
    width = self.originHeight * textureRatio
  end
  if anglez == 90 or anglez == 270 then
    self.photo.width = height
    self.photo.height = width
  else
    self.photo.width = width
    self.photo.height = height
  end
  Object.DestroyImmediate(self.photo.mainTexture)
  self.photo.mainTexture = texture
end

function PictureDetailPanel:getPhoto(photoData)
  if photoData then
    local serverData = Game.PictureWallManager:getServerData(photoData)
    local bytes = Game.PictureWallManager:GetBytes(photoData)
    if bytes then
      self:completeCallbackBytes(bytes)
    else
      local tBytes
      local thumbnail = true
      if photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SCENERY then
        if photoData.isBelongAccPic then
          tBytes = UnionWallPhotoNew.Ins():TryGetThumbnailFromLocal_ScenicSpot_Account(photoData.charid, photoData.sourceid, photoData.time)
        else
          tBytes = UnionWallPhotoNew.Ins():TryGetThumbnailFromLocal_ScenicSpot(photoData.charid, photoData.sourceid, photoData.time)
        end
      elseif photoData.source == ProtoCommon_pb.ESOURCE_PHOTO_SELF then
        tBytes = UnionWallPhotoNew.Ins():TryGetThumbnailFromLocal_Personal(photoData.charid, photoData.sourceid, photoData.time)
      end
      if tBytes then
        self:completeCallback(tBytes, thumbnail)
      elseif serverData and serverData.texture then
        self:completeCallbackThumbnailTexture(serverData.texture)
      end
      Game.PictureWallManager:tryGetOriginImage(photoData)
    end
  end
end

function PictureDetailPanel:completeCallbackBytes(bytes)
  local texture = Texture2D(0, 0, TextureFormat.RGB24, false)
  local bRet = ImageConversion.LoadImage(texture, bytes)
  if bRet then
    self:setTexture(texture)
  else
    Object.DestroyImmediate(texture)
  end
end

function PictureDetailPanel:completeCallbackThumbnailTexture(texture)
  local texture = Texture2D(0, 0, TextureFormat.RGB24, false)
  texture:LoadRawTextureData(texture:GetRawTextureData())
  texture:Apply()
  self:setTexture(texture)
end

function PictureDetailPanel:progressCallback(progress)
  self:Show(self.progress.gameObject)
  progress = 1 <= progress and 1 or progress
  local value = progress * 100
  value = math.floor(value)
  self.progress.text = value .. "%"
end

function PictureDetailPanel:completeCallback(bytes, thumbnail)
  if not thumbnail then
    self:Hide(self.progress.gameObject)
  end
  self.isThumbnail = thumbnail
  if bytes then
    helplog("xxxx333")
    local texture = Texture2D(0, 0, TextureFormat.RGB24, false)
    local bRet = ImageConversion.LoadImage(texture, bytes)
    if bRet then
      helplog("xxxx2222", tostring(thumbnail))
      self:setTexture(texture)
      if not thumbnail then
        Game.PictureWallManager:addOriginBytesBySceneryId(self.currentData, bytes)
      end
    else
      helplog("xxxx1111")
      Object.DestroyImmediate(texture)
    end
  end
end

function PictureDetailPanel:OnExit()
  originSize = 0
  Object.DestroyImmediate(self.photo.mainTexture)
  PhotoDataProxy.Instance:clearToSeeDatas()
  self.wraplist:Destroy()
end

function PictureDetailPanel:GetItemCellById(photoData)
  local cells = self:GetItemCells()
  if cells and 0 < #cells then
    for i = 1, #cells do
      local single = cells[i]
      if single.data and Game.PictureWallManager:checkSamePicture(single.data, photoData) then
        return single
      end
    end
  end
end

function PictureDetailPanel:GetItemCells()
  return self.wraplist:GetCellCtls()
end

function PictureDetailPanel:IsShowRemoveBtn(isShow)
  if PhotoDataProxy.Instance:checkPhotoSyncPermission() then
    if isShow then
      self:Show(self.RemoveCt)
    else
      self:Hide(self.RemoveCt)
    end
  else
    self:Hide(self.RemoveCt)
  end
end
