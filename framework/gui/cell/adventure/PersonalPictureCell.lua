local baseCell = autoImport("BaseCell")
PersonalPictureCell = class("PersonalPictureCell", baseCell)
PersonalPictureCell.PhotoStatus = {
  UploadFailure = 1,
  CanReUploading = 2,
  Uploading = 3,
  DownloadFailure = 4,
  Success = 5,
  Downloading = 6
}

function PersonalPictureCell:Init()
  PersonalPictureCell.super.Init(self)
  self:initView()
  self:initData()
  self:AddViewEvent()
end

function PersonalPictureCell:AddViewEvent()
  local background = self:FindGO("background")
  self:AddClickEvent(background, function(obj)
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
  self:AddCellClickEvent()
end

function PersonalPictureCell:initData()
end

function PersonalPictureCell:initView()
  self.errorCt = self:FindGO("errorCt")
  self.reUploadContainer = self:FindGO("reUploadContainer")
  self.delBtn = self:FindGO("delBtn")
  self:AddClickEvent(self.delBtn, function()
    FunctionCloudFile.Me():log("delBtn")
    self:PassEvent(PersonalPicturePanel.DelPersonPicThumbnail, self)
  end)
  self:AddClickEvent(self.reUploadContainer, function()
    FunctionCloudFile.Me():log("reUploadContainer")
    self.status = PersonalPictureCell.PhotoStatus.Uploading
    self:PassEvent(PersonalPicturePanel.ReUploadingPersonPicThumbnail, self)
    self:RefreshStatus()
  end)
  self.errorTip = self:FindComponent("errorTip", UILabel)
  self.errorTip.text = ZhString.PersonalPictureCell_PicLost
  self.pictureDesLabel = self:FindComponent("pictureDesLabel", UILabel)
  self.timeLabel = self:FindComponent("timeLabel", UILabel)
  self.texture = self:FindGO("texture"):GetComponent(UITextureEx)
  self.textureCt = self:FindGO("textureCt")
  self.replaceSp = self:FindGO("replaceSp")
  self:AddClickEvent(self.replaceSp, function()
    self:PassEvent(PersonalPicturePanel.ReplacePersonPicThumbnail, self)
  end)
  self.maskContainer = self:FindGO("maskContainer")
  self.maskSlider = self:FindGO("maskSlider"):GetComponent(UISlider)
  self.stateDes = self:FindComponent("stateDes", UILabel)
  self.cancelBtn = self:FindGO("cancelBtn")
  self:AddClickEvent(self.cancelBtn, function()
    FunctionCloudFile.Me():log("cancelBtn")
    self:PassEvent(PersonalPicturePanel.CancelPersonPicThumbnail, self)
  end)
  self.pickMark = self:FindGO("pickMark")
  local long = self.gameObject:GetComponent(UILongPress)
  if long then
    function long.pressEvent(obj, isPress)
      if self.mode == PersonalPicturePanel.ShowMode.PickMode then
        self:PassEvent(PersonalPicturePanel.ShowPictureDetail, self)
      end
    end
  end
end

function PersonalPictureCell:setMode(mode)
  if not self.data then
    return
  end
  self.mode = mode
  self:RefreshStatus()
end

function PersonalPictureCell:setIsPick(isPick)
  if isPick then
    self:Show(self.pickMark)
  else
    self:Hide(self.pickMark)
  end
end

function PersonalPictureCell:RefreshStatus()
  if not self.data then
    return
  end
  if self.mode == PersonalPicturePanel.ShowMode.NormalMode then
    self:Hide(self.replaceSp)
    self:Hide(self.delBtn)
    if self.status == PersonalPictureCell.PhotoStatus.Uploading then
      self:Show(self.cancelBtn)
    else
      self:Hide(self.cancelBtn)
    end
  elseif self.mode == PersonalPicturePanel.ShowMode.EditorMode then
    self:Hide(self.replaceSp)
    self:Show(self.delBtn)
    self:Hide(self.cancelBtn)
  elseif self.mode == PersonalPicturePanel.ShowMode.PickMode then
    self:Hide(self.replaceSp)
    self:Hide(self.delBtn)
    self:Hide(self.cancelBtn)
  else
    self:Show(self.replaceSp)
    self:Hide(self.delBtn)
    self:Hide(self.cancelBtn)
  end
  if self.status == PersonalPictureCell.PhotoStatus.Success then
    self:Hide(self.errorCt)
    self:Hide(self.maskContainer)
  elseif self.status == PersonalPictureCell.PhotoStatus.CanReUploading then
    self:Hide(self.maskContainer)
    self:Show(self.errorCt)
    self:Hide(self.errorTip.gameObject)
    self:Show(self.reUploadContainer)
  elseif self.status == PersonalPictureCell.PhotoStatus.UploadFailure then
    self:Hide(self.maskContainer)
    self:Show(self.errorCt)
    self:Show(self.errorTip.gameObject)
    self:Hide(self.reUploadContainer)
  elseif self.status == PersonalPictureCell.PhotoStatus.Uploading then
    self.stateDes.text = ZhString.PersonalPictureCell_LoadingText
    self:Show(self.maskContainer)
    self:Hide(self.errorCt)
  elseif self.status == PersonalPictureCell.PhotoStatus.Downloading then
    self:Show(self.maskContainer)
    self.stateDes.text = ZhString.PersonalPictureCell_LoadingText
    self:Hide(self.errorCt)
  elseif self.status == PersonalPictureCell.PhotoStatus.DownloadFailure then
    self:Hide(self.maskContainer)
    self:Show(self.errorCt)
    self:Show(self.errorTip.gameObject)
    self:Hide(self.reUploadContainer)
  end
end

function PersonalPictureCell:setDownloadProgress(progress)
  FunctionCloudFile.Me():log("setDownloadProgress:", progress)
  progress = 1 <= progress and 1 or progress
  local value = progress * 100
  value = math.floor(value)
  self.stateDes.text = string.format(ZhString.PersonalPictureCell_Downloading, value)
end

function PersonalPictureCell:setDownloadFailure()
  FunctionCloudFile.Me():log("setDownloadFailure:")
  local isCanReUpLoading = self.data and PersonalPictureManager.Instance():isCanReUpLoading(self.data.index, self.data.time)
  self.status = isCanReUpLoading and PersonalPictureCell.PhotoStatus.CanReUploading or PersonalPictureCell.PhotoStatus.DownloadFailure
  self:RefreshStatus()
end

function PersonalPictureCell:setUploadFailure()
  FunctionCloudFile.Me():log("setUploadFailure:")
  self.status = PersonalPictureCell.PhotoStatus.CanReUploading
  self:RefreshStatus()
end

function PersonalPictureCell:setUploadSuccess()
  self.status = PersonalPictureCell.PhotoStatus.Success
  self:RefreshStatus()
end

function PersonalPictureCell:setUploadProgress(progress)
  FunctionCloudFile.Me():log("setUploadProgress:", progress)
  progress = 1 <= progress and 1 or progress
  local value = progress * 100
  value = math.floor(value)
  self.stateDes.text = string.format(ZhString.PersonalPictureCell_Uploading, value)
end

function PersonalPictureCell:SetData(data)
  self.data = data
  if not data then
    self:Hide()
    return
  end
  self:Show()
  local time = data.time or 0
  local timeStr = os.date("%Y.%m.%d", time)
  if time == 0 then
    timeStr = ZhString.PersonalPictureCell_PictureDesNotime
  end
  local name = ""
  if data.type == PhotoDataProxy.PhotoType.SceneryPhotoType then
    name = Table_Viewspot[data.index] and Table_Viewspot[data.index].SpotName or data.mapid
  else
    name = Table_Map[data.mapid] and Table_Map[data.mapid].NameZh or data.mapid
  end
  self.pictureDesLabel.text = name
  self.timeLabel.text = timeStr
  self:Hide(self.textureCt)
  if data.type == PhotoDataProxy.PhotoType.PersonalPhotoType and PersonalPictureManager.Instance():isUpLoadFailure(data.index) then
    local isUpLoading = PersonalPictureManager.Instance():isUpLoading(data.index)
    local isCanReUpLoading = PersonalPictureManager.Instance():isCanReUpLoading(data.index, data.time)
    if isUpLoading then
      self:PassEvent(PersonalPicturePanel.GetPersonPicThumbnail, self)
      self.status = PersonalPictureCell.PhotoStatus.Uploading
    elseif isCanReUpLoading then
      self:PassEvent(PersonalPicturePanel.GetPersonPicThumbnail, self)
      self.status = PersonalPictureCell.PhotoStatus.CanReUploading
    else
      self.status = PersonalPictureCell.PhotoStatus.UploadFailure
    end
  else
    self.status = PersonalPictureCell.PhotoStatus.Downloading
    self:PassEvent(PersonalPicturePanel.GetPersonPicThumbnail, self)
  end
  self:RefreshStatus()
end

function PersonalPictureCell:setTexture(texture)
  if texture then
    self:Show(self.textureCt)
    self.texture.mainTexture = texture
    if self.status == PersonalPictureCell.PhotoStatus.Downloading then
      self.status = PersonalPictureCell.PhotoStatus.Success
    end
  else
    self.status = PersonalPictureCell.PhotoStatus.DownloadFailure
  end
  self:RefreshStatus()
end

function PersonalPictureCell:OnExit()
  self:ClearTempTexture()
  self.super.OnExit(self)
end

function PersonalPictureCell:ClearTempTexture()
  if self.tempTexture then
    Object.DestroyImmediate(self.tempTexture)
    self.tempTexture = nil
  end
end

function PersonalPictureCell:SetTextureBytes(bytes)
  self:ClearTempTexture()
  local texture = Texture2D(2, 2, TextureFormat.RGB24, false)
  if ImageConversion.LoadImage(texture, bytes) then
    self.tempTexture = texture
    self:setTexture(self.tempTexture)
  else
    Object.DestroyImmediate(texture)
  end
end

function PersonalPictureCell:OnCellDestroy()
  self:ClearTempTexture()
end
