local baseCell = autoImport("BaseCell")
PersonalPictureWallCell = class("PersonalPictureWallCell", baseCell)
PersonalPictureWallCell.PhotoStatus = {
  UploadFailure = 1,
  CanReUploading = 2,
  Uploading = 3,
  DownloadFailure = 4,
  Success = 5,
  Downloading = 6
}

function PersonalPictureWallCell:Init()
  PersonalPictureWallCell.super.Init(self)
  self:initView()
  self:initData()
  self:AddViewEvent()
end

function PersonalPictureWallCell:AddViewEvent()
  local background = self:FindGO("background")
  self:AddClickEvent(background, function(obj)
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
  self:AddCellClickEvent()
end

function PersonalPictureWallCell:initData()
end

function PersonalPictureWallCell:initView()
  self.errorCt = self:FindGO("errorCt")
  self.reUploadContainer = self:FindGO("reUploadContainer")
  self.delBtn = self:FindGO("delBtn")
  self.errorTip = self:FindComponent("errorTip", UILabel)
  self.errorTip.text = ZhString.PersonalPictureCell_PicLost
  self.pictureDesLabel = self:FindComponent("pictureDesLabel", UILabel)
  self.timeLabel = self:FindComponent("timeLabel", UILabel)
  self.texture = self:FindGO("texture"):GetComponent(UITextureEx)
  self.textureCt = self:FindGO("textureCt")
  self.maskContainer = self:FindGO("maskContainer")
  self.stateDes = self:FindComponent("stateDes", UILabel)
  self.tipDesCt = self:FindGO("tipDesCt")
  self.tipDesLabel = self:FindComponent("tipDesLabel", UILabel)
  self.checkBox = self:FindComponent("selectedBg", UIToggle)
  self:AddButtonEvent("checkBox", function()
    self:CheckBoxButtonEvent()
  end)
end

function PersonalPictureWallCell:CheckBoxButtonEvent()
  self:PassEvent(PicutureWallSyncPanel.CellSelectedChange, self)
end

function PersonalPictureWallCell:IsSelected()
  return self.checkBox.value
end

function PersonalPictureWallCell:setMode(mode)
  if not self.data then
    return
  end
  self.mode = mode
  self:RefreshStatus()
end

function PersonalPictureWallCell:RefreshStatus()
  if not self.data then
    return
  end
  if self.status == PersonalPictureWallCell.PhotoStatus.Success then
    self:Hide(self.errorCt)
    self:Hide(self.maskContainer)
  elseif self.status == PersonalPictureWallCell.PhotoStatus.Downloading then
    self:Show(self.maskContainer)
    self.stateDes.text = ZhString.PersonalPictureCell_LoadingText
    self:Hide(self.errorCt)
  elseif self.status == PersonalPictureWallCell.PhotoStatus.CanReUploading then
    self:Show(self.maskContainer)
    self.stateDes.text = ZhString.PersonalPictureCell_LoadingText
    self:Hide(self.errorCt)
  elseif self.status == PersonalPictureWallCell.PhotoStatus.DownloadFailure then
    self:Hide(self.maskContainer)
    self:Show(self.errorCt)
    self:Show(self.errorTip.gameObject)
  end
end

function PersonalPictureWallCell:setDownloadProgress(progress)
  FunctionCloudFile.Me():log("setDownloadProgress:", progress)
  progress = 1 <= progress and 1 or progress
  local value = progress * 100
  value = math.floor(value)
  self.stateDes.text = string.format(ZhString.PersonalPictureCell_Downloading, value)
end

function PersonalPictureWallCell:setDownloadFailure()
  FunctionCloudFile.Me():log("setDownloadFailure:")
  self.status = PersonalPictureWallCell.PhotoStatus.DownloadFailure
  self:RefreshStatus()
end

function PersonalPictureWallCell:SetData(data)
  self.data = data
  if not data then
    self:Hide()
    return
  end
  self:Show()
  local time = data.time or 0
  local timeStr = os.date("%Y.%m.%d", time)
  if time == 0 then
    timeStr = ""
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
      self.status = PersonalPictureWallCell.PhotoStatus.Uploading
    elseif isCanReUpLoading then
      self.status = PersonalPictureWallCell.PhotoStatus.CanReUploading
    else
      self.status = PersonalPictureWallCell.PhotoStatus.UploadFailure
    end
  else
    self.status = PersonalPictureWallCell.PhotoStatus.Downloading
  end
  self:SetDataPassEvent()
  self:RefreshStatus()
end

function PersonalPictureWallCell:SetDataPassEvent()
  self:PassEvent(PersonalPicturePanel.GetPersonPicThumbnail, self)
  self:PassEvent(PicutureWallSyncPanel.CheckCurPicIsShow, self)
end

function PersonalPictureWallCell:setIsShowStart(bRet)
end

local color1 = LuaColor(0.8862745098039215, 0.6901960784313725, 0.3215686274509804, 1)
local color2 = LuaColor.White()

function PersonalPictureWallCell:setShowTipDes(isShow, cur)
  if isShow then
    self:Show(self.tipDesCt)
    if cur then
      self.tipDesLabel.text = ZhString.PersonalPictureCell_PictureShowCur
      self.tipDesLabel.color = color1
    else
      self.tipDesLabel.text = ZhString.PersonalPictureCell_PictureShowOther
      self.tipDesLabel.color = color2
    end
  else
    self:Hide(self.tipDesCt)
  end
end

function PersonalPictureWallCell:setIsSelected(bRet)
  if bRet then
    self.checkBox.value = true
  else
    self.checkBox.value = false
  end
end

function PersonalPictureWallCell:setTexture(texture)
  if texture then
    self:Show(self.textureCt)
    self.texture.mainTexture = texture
    if self.status == PersonalPictureWallCell.PhotoStatus.Downloading or self.status == PersonalPictureWallCell.PhotoStatus.UploadFailure or self.status == PersonalPictureWallCell.PhotoStatus.CanReUploading then
      self.status = PersonalPictureWallCell.PhotoStatus.Success
    end
  else
    self.status = PersonalPictureWallCell.PhotoStatus.DownloadFailure
  end
  self:RefreshStatus()
end

function PersonalPictureWallCell:OnExit()
  self.super.OnExit(self)
end
