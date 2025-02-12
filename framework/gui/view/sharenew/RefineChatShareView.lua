RefineChatShareView = class("RefineChatShareView", BaseView)
autoImport("PhotographResultPanel")
RefineChatShareView.ViewType = UIViewType.ShareLayer
RefineChatShareView.ShareType = {
  NormalShare = 1,
  SkadaShare = 2,
  RaidResultShare = 3
}

function RefineChatShareView:Init()
  self:initView()
  self:initData()
end

function RefineChatShareView:initView()
  self.objHolder = self:FindGO("objHolder")
  self.itemName = self:FindComponent("itemName", UILabel)
  self.Title = self:FindComponent("Title", UILabel)
  self.Container = self:FindGO("Container")
  self.objBgCt = self:FindGO("objBgCt")
  self.refineBg = self:FindGO("refineBg", self.objBgCt)
  self.closeBtn = self:FindGO("CloseButton")
  self.screenShotHelper = self.gameObject:GetComponent(ScreenShotHelper)
  self.ShareDescription = self:FindComponent("ShareDescription", UILabel)
  local myName = self:FindGO("myName"):GetComponent(UILabel)
  myName.text = self.viewdata.viewdata.name
  local serverName = self:FindGO("ServerName"):GetComponent(UILabel)
  local curServer = FunctionLogin.Me():getCurServerData()
  local serverID = curServer and curServer.name or 1
  serverName.text = serverID
  if BranchMgr.IsJapan() then
    myName.gameObject:SetActive(false)
    serverName.gameObject:SetActive(false)
    local bg_name = self:FindGO("bg_name")
    if bg_name then
      bg_name:SetActive(false)
    end
  end
  local title = self:FindGO("Title")
  if title then
    local lbl = title:GetComponent(UILabel)
    lbl.text = GameConfig.Share.Sharetitle[ESHAREMSGTYPE.ESHARE_REFINE]
  end
  local rologo = self:FindGO("Logo")
  local texName = GameConfig.Share.Logo
  local logoTex = rologo:GetComponent(UITexture)
  PictureManager.Instance:SetPlayerRefluxTexture(texName, logoTex)
  self:AddButtonEvent("BgClick", function(go)
    self:CloseSelf()
  end)
  self:GetGameObjects()
  self:RegisterButtonClickEvent()
end

function RefineChatShareView:ShareToGlobalChannel()
end

function RefineChatShareView:FormatBufferStr(bufferId)
  local str = ItemUtil.getBufferDescById(bufferId)
  local result = ""
  local bufferStrs = string.split(str, "\n")
  for m = 1, #bufferStrs do
    local buffData = Table_Buffer[bufferId]
    local buffStr = ""
    if buffData then
      buffStr = string.format("{bufficon=%s} ", buffData.BuffIcon)
    end
    result = result .. buffStr .. bufferStrs[m] .. "\n"
  end
  if result ~= "" then
    result = string.sub(result, 1, -2)
  end
  return result
end

function RefineChatShareView:setItemProperty(data)
  local label = ""
  if data.itemData.cardInfo then
    local bufferIds = data.itemData.cardInfo.BuffEffect.buff
    for i = 1, #bufferIds do
      local str = ItemUtil.getBufferDescById(bufferIds[i])
      local bufferStrs = string.split(str, "\n")
      for j = 1, #bufferStrs do
        local cardTip = bufferStrs[j]
        label = label .. cardTip .. "\n"
      end
    end
    label = string.sub(label, 1, -2)
    self.ShareDescription.alignment = 0
  elseif data.effectFromType == FloatAwardView.EffectFromType.RefineType then
    label = self:GetRefineInfo(data.itemData.equipInfo)
    self.ShareDescription.alignment = 0
  elseif data.showType == FloatAwardView.ShowType.ItemType then
    label = ZhString.ItemTip_Desc .. tostring(data.itemData.staticData.Desc)
    self.ShareDescription.alignment = 1
  elseif data.itemData.equipInfo then
    local equipInfo = data.itemData.equipInfo
    local uniqueEffect = equipInfo:GetUniqueEffect()
    if uniqueEffect and 0 < #uniqueEffect then
      local special = {}
      special.label = {}
      for i = 1, #uniqueEffect do
        local id = uniqueEffect[i].id
        label = label .. self:FormatBufferStr(id) .. "\n"
      end
      label = string.sub(label, 1, -2)
    end
    self.ShareDescription.alignment = 0
  end
  if label ~= "" then
    self.ShareDescription.text = label
  else
    self.ShareDescription.text = ""
  end
end

function RefineChatShareView:GetRefineInfo(equipInfo)
  local refineEffect, refineTxt = equipInfo.equipData.RefineEffect, ""
  for propKey, v in pairs(refineEffect) do
    if not StringUtil.IsEmpty(refineTxt) then
      refineTxt = refineTxt .. "; "
    end
    local proName, proV = GameConfig.EquipEffect[propKey], v * equipInfo.refinelv
    local pro = RolePropsContainer.config[propKey]
    if pro and pro.isPercent then
      refineTxt = refineTxt .. EquipProps.MakeStr(proName, " +", string.format("%s%%", proV * 100), vstrColorStr)
    else
      refineTxt = refineTxt .. EquipProps.MakeStr(proName, " +", proV, vstrColorStr)
    end
  end
  return refineTxt
end

function RefineChatShareView:OnEnter()
  self:SetData(self.viewdata.viewdata.data)
  local parent = self.Container.transform
  local effectPath = ResourcePathHelper.EffectCommon("RefineChatShareView")
  self.focusEffect = Game.AssetManager_UI:CreateAsset(effectPath, parent)
end

function RefineChatShareView:SetData(data)
  if data.shareType then
    self.shareType = data.shareType
  else
    self.shareType = RefineChatShareView.ShareType.NormalShare
  end
  self.data = data
  if self.shareType == RefineChatShareView.ShareType.NormalShare then
    self:Show(self.Container)
    self.itemName.text = data.itemData.staticData.NameZh
    if data.effectFromType == FloatAwardView.EffectFromType.RefineType then
      self.Title.text = "+" .. data.itemData.equipInfo.refinelv .. " " .. ZhString.ShareAwardView_RefineSus
      data.showType = FloatAwardView.ShowType.ItemType
      self:Show(self.objBgCt)
      self:Show(self.refineBg)
    elseif data.showType == FloatAwardView.ShowType.CardType then
      self.Title.text = ZhString.ShareAwardView_GetCard
      self:Show(self.objBgCt)
    else
      self.Title.text = ZhString.ShareAwardView_GetItem
      data.showType = FloatAwardView.ShowType.ItemType
      self:Show(self.objBgCt)
      self:Show(self.refineBg)
    end
    data.itemData:SetItemNum(1)
    local obj = data:getModelObj(self.objHolder)
    if data.showType == FloatAwardView.ShowType.CardType and obj then
      obj.transform.localPosition = LuaGeometry.Const_V3_zero
      obj.transform.localScale = LuaGeometry.GetTempVector3(0.8, 0.8, 0.8)
    elseif data.effectFromType == FloatAwardView.EffectFromType.RefineType and obj then
      obj.transform.localPosition = LuaGeometry.Const_V3_zero
    elseif data.showType ~= FloatAwardView.ShowType.ItemType or obj then
    end
    self:setItemProperty(data)
  end
end

function RefineChatShareView:GetGameObjects()
end

function RefineChatShareView:RegisterButtonClickEvent()
end

function RefineChatShareView:changeUIState(isStart)
  if isStart then
    self:Hide(self.goUIViewSocialShare)
    self:Hide(self.closeBtn)
  else
    self:Show(self.goUIViewSocialShare)
    self:Show(self.closeBtn)
  end
end

function RefineChatShareView:initData()
  self.screenShotWidth = -1
  self.screenShotHeight = 1080
  self.textureFormat = TextureFormat.RGB24
  self.texDepth = 24
  self.antiAliasing = ScreenShot.AntiAliasing.None
end

function RefineChatShareView:OnExit()
  if self.shareType ~= RefineChatShareView.ShareType.SkadaShare and self.shareType ~= RefineChatShareView.ShareType.RaidResultShare and self.data then
    self.data:Exit()
  end
end

local screenShotWidth = -1
local screenShotHeight = 1080
local textureFormat = TextureFormat.RGB24
local texDepth = 24
local antiAliasing = ScreenShot.AntiAliasing.None
local shotName = "RO_ShareTemp"

function RefineChatShareView:SharePicture(platform_type, content_title, content_body)
  helplog("RefineChatShareView SharePicture", platform_type)
  local weekReward = MyselfProxy.Instance:GetAccVarValueByType(Var_pb.EACCVARTYPE_SHARE_WEEK_REWARD) or 0
  if weekReward == 0 then
    ServiceChatCmdProxy.Instance:CallShareSuccessNofityCmd()
  end
  local gmCm = NGUIUtil:GetCameraByLayername("Default")
  local ui = NGUIUtil:GetCameraByLayername("UI")
  self.CloseButton = self:FindGO("CloseButton")
  self.CloseButton:SetActive(false)
  self.SharePanel = self:FindGO("SharePanel")
  if self.SharePanel then
    self.SharePanel:SetActive(false)
  end
  self.screenShotHelper:Setting(screenShotWidth, screenShotHeight, textureFormat, texDepth, antiAliasing)
  self.screenShotHelper:GetScreenShot(function(texture)
    self.CloseButton:SetActive(true)
    if self.SharePanel then
      self.SharePanel:SetActive(true)
    end
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
