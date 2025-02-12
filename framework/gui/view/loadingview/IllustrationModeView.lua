IllustrationModeView = class("IllustrationModeView", SubView)

function IllustrationModeView:Init()
  self.gameObject = self:FindGO("IllustrationMode")
  self.pic = self:FindGO("IllustrationPic"):GetComponent(UITexture)
  self.data = self.viewdata.viewdata and self.viewdata.viewdata or 1
  self:AddButtonEvent("IllustrationPic", function()
  end)
  self:AddViewListeners()
  self:LoadPic()
end

function IllustrationModeView:LoadPic()
  PictureManager.Instance:SetIllustration(self.data, self.pic)
  if self.pic.mainTexture == nil then
    error(string.format("Illustration Set Error:%s", self.data))
  end
  local containerWidget = self.gameObject:GetComponent(UIWidget)
  self.pic.width = 1024
  self.pic.height = 1024
  if self.data then
    self:TweenPic(0, 1, 0.8)
  end
end

function IllustrationModeView:TweenPic(from, to, duration)
  self:CancelTweenPic()
  LeanTween.alphaNGUI(self.pic, from, to, duration)
end

function IllustrationModeView:CancelTweenPic()
  LeanTween.cancel(self.pic.gameObject)
end

function IllustrationModeView:OnEnter()
  Game.AssetManager_Role:SetForceLoadAll(true)
  IllustrationModeView.super.OnEnter(self)
end

function IllustrationModeView:OnExit()
  PictureManager.Instance:UnLoadIllustration(self.data, self.pic)
  Game.AssetManager_Role:SetForceLoadAll(false)
end

function IllustrationModeView:AddViewListeners()
end

function IllustrationModeView:ServerReceiveLoadedHandler(note)
end

function IllustrationModeView:ClickTryToEnter()
  if self.serverReceiveLoaded then
    self.container:CloseSelf()
  end
end

function IllustrationModeView:SceneFadeOut(note)
  self:CancelTweenPic()
  self.pic.gameObject:SetActive(false)
  self.container:DoFadeOut(1.5)
end

function IllustrationModeView:SceneFadeInFinish()
  self.container:CloseSelf()
end

function IllustrationModeView:LoadFinish()
  self.container:FireLoadFinishEvent()
  self:TweenPic(1, 0, 0.8)
  self.container:DoFadeIn(2.5)
end

function IllustrationModeView:SceneFadeOutFinish()
end

function IllustrationModeView:StartLoadScene(note)
end

function IllustrationModeView:Update(delta)
end
