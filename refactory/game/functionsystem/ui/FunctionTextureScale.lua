autoImport("TextureScale2")
FunctionTextureScale = class("FunctionTextureScale")
FunctionTextureScale.ins = nil

function FunctionTextureScale:ctor()
  self.idGenerator = 0
  self.queueWillScale = {}
  self.nextFlag = true
  FunctionTextureScale.ins = self
end

function FunctionTextureScale:Scale(texture2D, coefficient, complete_callback)
  local id = self.idGenerator + 1
  local scaleParams = {
    id = id,
    texture2D = texture2D,
    coefficient = coefficient,
    completeCallback = complete_callback
  }
  table.insert(self.queueWillScale, scaleParams)
  return id
end

function FunctionTextureScale:CancelScale(id)
  for i = 1, #self.queueWillScale do
    local scaleParam = self.queueWillScale[i]
    if scaleParam.id == id then
      self.queueWillScale[i] = nil
      break
    end
  end
end

function FunctionTextureScale:Update()
  if self.nextFlag and #self.queueWillScale > 0 then
    local scaleParam = self.queueWillScale[1]
    self:DoScale(scaleParam.texture2D, scaleParam.coefficient, scaleParam.completeCallback)
    self.nextFlag = false
  end
end

local _goTextureScale, _camera, _uiTexture, _screenShotHelper

function FunctionTextureScale:DoScale(texture2D, coefficient, complete_callback)
  if _goTextureScale == nil then
    _goTextureScale = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UIView("TextureScale"), UIManagerProxy.Instance.UIRoot.transform)
    _screenShotHelper = _goTextureScale:GetComponent(ScreenShotHelper)
    local transCamera = _goTextureScale.transform:Find("Camera")
    _camera = transCamera:GetComponent(Camera)
    _camera.hideFlags = HideFlags.HideAndDontSave
    _camera.enabled = false
    local Panel = _goTextureScale.transform:Find("Panel")
    local transUITexture = Panel:Find("Texture")
    if transUITexture then
      _uiTexture = transUITexture:GetComponent(UITexture)
    else
      helplog("if transUITexture then == nil")
      return
    end
  end
  local texWidth = texture2D.width
  local texHeight = texture2D.height
  local newTexWidth = texWidth * coefficient
  local newTexHeight = texHeight * coefficient
  local ratio = newTexWidth / newTexHeight
  _camera.aspect = ratio
  _uiTexture.mainTexture = texture2D
  local size = UIManagerProxy.Instance:GetUIRootSize()
  _uiTexture.width = size[1]
  _uiTexture.height = size[2]
  PpLua:SetEnable(false)
  _screenShotHelper:Setting(newTexWidth, newTexHeight, TextureFormat.RGB24, 24, ScreenShot.AntiAliasing.None)
  _screenShotHelper:GetScreenShot(function(x)
    _uiTexture.mainTexture = nil
    if complete_callback ~= nil then
      complete_callback(x)
    end
    table.remove(self.queueWillScale, 1)
    self.nextFlag = true
    PpLua:SetEnable(true)
  end, _camera)
end
