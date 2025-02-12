StarView = class("StarView", ContainerView)
StarView.ViewType = UIViewType.NormalLayer
local TYPE = LoveLetterData.Type
local screenShotWidth = -1
local screenShotHeight = 1080
local textureFormat = TextureFormat.RGB24
local texDepth = 24
local antiAliasing = ScreenShot.AntiAliasing.None
local shotName = "RO_ShareTemp"

function StarView:OnExit()
  PictureManager.Instance:UnLoadStar()
  StarView.super.OnExit(self)
end

function StarView:Init()
  self:FindObj()
  self:AddEvt()
  self:AddViewEvt()
  self:InitShow()
end

function StarView:FindObj()
  self.content = self:FindGO("Content"):GetComponent(UILabel)
  self.from = self:FindGO("From"):GetComponent(UILabel)
  self.star = self:FindGO("Star"):GetComponent(UITexture)
  self.btnRoot = self:FindGO("BtnRoot")
  self.screenShotHelper = self.gameObject:GetComponent(ScreenShotHelper)
  self.share = self:FindGO("Share")
  self.save = self:FindGO("Save")
end

function StarView:AddEvt()
  self:AddClickEvent(self.save, function()
    self:ClickSave()
  end)
  self:AddClickEvent(self.share, function()
    self:ClickShare()
  end)
  local closeButton = self:FindGO("CloseButton")
  self:AddClickEvent(closeButton, function()
    self:CloseView()
  end)
end

function StarView:AddViewEvt()
  self:AddListenEvt(ServiceEvent.ItemSaveLoveLetterCmd, self.CloseView)
  self:AddListenEvt(ShareEvent.ClickPlatform, self.ClickPlatform)
end

function StarView:InitShow()
  self.isQueue = self.viewdata.viewdata == nil
  local isOpen = StarProxy.Instance:CheckShareOpen()
  self.share:SetActive(isOpen)
  self:UpdateView()
end

function StarView:UpdateView()
  local data
  if self.isQueue then
    data = StarProxy.Instance:GetFrontData()
  else
    data = self.viewdata.viewdata
  end
  if data then
    self:SetData(data)
  end
end

function StarView:SetData(data)
  if data then
    self.id = data.id
    local content = ""
    local letter = Table_LoveLetter[data.staticId]
    if letter and letter.Letter then
      content = letter.Letter
    end
    self.content.text = string.format(ZhString.Star_Content, Game.Myself.data:GetName(), content)
    self.from.text = data.name
    PictureManager.Instance:SetStar(data.bg, self.star)
    self.save:SetActive(data.type == TYPE.Star)
    local gmCm = NGUIUtil:GetCameraByLayername("Default")
    local ui = NGUIUtil:GetCameraByLayername("UI")
    self.screenShotHelper:GetScreenShot(function(texture)
      self.texture = texture
    end, gmCm, ui)
  end
end

function StarView:ClickSave()
  if self.id then
    helplog("CallSaveLoveLetterCmd", self.id)
    ServiceItemProxy.Instance:CallSaveLoveLetterCmd(self.id)
  end
end

function StarView:ClickShare()
  if ApplicationInfo.IsRunOnWindowns() then
    MsgManager.ShowMsgByID(43486)
    return
  end
  self:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.GeneralShareView
  })
end

function StarView:ClickPlatform(note)
  local data = note.body
  if data then
    self:SharePicture(data, "", "")
  end
end

function StarView:CloseView()
  if self.isQueue then
    local isNext = StarProxy.Instance:ShowNext()
    if not isNext then
      self:UpdateView()
      return
    end
  end
  self:CloseSelf()
end

function StarView:SharePicture(platform_type, content_title, content_body)
  helplog("StarView SharePicture", platform_type)
  local gmCm = NGUIUtil:GetCameraByLayername("Default")
  local ui = NGUIUtil:GetCameraByLayername("UI")
  self.btnRoot:SetActive(false)
  self.screenShotHelper:Setting(screenShotWidth, screenShotHeight, textureFormat, texDepth, antiAliasing)
  self.screenShotHelper:GetScreenShot(function(texture)
    self.btnRoot:SetActive(true)
    local picName = shotName .. tostring(os.time())
    local path = PathUtil.GetSavePath(PathConfig.TempShare) .. "/" .. picName
    if self.texture ~= nil then
      texture = self.texture
    else
      xdlog("没有获得 texture")
    end
    ScreenShot.SaveJPG(texture, path, 100)
    path = path .. ".jpg"
    helplog("StarView Share path", path)
    if not BranchMgr.IsChina() then
      local overseasManager = OverSeas_TW.OverSeasManager.GetInstance()
      if platform_type ~= "fb" then
        xdlog("startSharePicture", platform_type .. "分享")
        if platform_type == "twitter" then
          content_title = OverseaHostHelper.TWITTER_MSG
        end
        overseasManager:ShareImgWithChannel(path, content_title, OverseaHostHelper.Share_URL, content_body, platform_type, function(msg)
          redlog("msg" .. msg)
          ROFileUtils.FileDelete(path)
          if msg == "1" then
            Debug.Log("success")
          else
            MsgManager.FloatMsgTableParam(nil, ZhString.LineNotInstalled)
          end
        end)
        return
      end
      xdlog("startSharePicture", "fb 分享图片")
      overseasManager:ShareImg(path, content_title, OverseaHostHelper.Share_URL, content_body, function(msg)
        redlog("msg" .. msg)
        ROFileUtils.FileDelete(path)
        if msg == "1" then
          MsgManager.FloatMsgTableParam(nil, ZhString.FaceBookShareSuccess)
        else
          MsgManager.FloatMsgTableParam(nil, ZhString.FaceBookShareFailed)
        end
      end)
      return
    end
    SocialShare.Instance:ShareImage(path, content_title, content_body, platform_type, function(succMsg)
      helplog("StarView Share success")
      ROFileUtils.FileDelete(path)
      if platform_type == E_PlatformType.Sina then
        MsgManager.ShowMsgByIDTable(566)
      end
    end, function(failCode, failMsg)
      helplog("StarView Share failure")
      ROFileUtils.FileDelete(path)
      local errorMessage = failMsg or "error"
      if failCode ~= nil then
        errorMessage = failCode .. ", " .. errorMessage
      end
      MsgManager.ShowMsg("", errorMessage, 0)
    end, function()
      helplog("StarView Share cancel")
      ROFileUtils.FileDelete(path)
    end)
  end, gmCm, ui)
end
