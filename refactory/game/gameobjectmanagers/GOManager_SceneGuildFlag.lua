MaxSceneGuildFlag = 8
GOManager_SceneGuildFlag = class("GOManager_SceneGuildFlag")
local tempVector2 = LuaVector2.Zero()
local CheckFlagInvalid = function()
  if GameConfig.SystemForbid.GVG or not FunctionUnLockFunc.checkFuncStateValid(4) then
    return true
  end
  return false
end

function GOManager_SceneGuildFlag:ctor()
  self.objects = {}
  self.renderers = {}
  self.objGuildIDMap = {}
  self.refAtlases = {}
  self.lobbyFlagId = {}
end

function GOManager_SceneGuildFlag:Clear()
  for obj, guildId in pairs(self.objGuildIDMap) do
    GuildPictureManager.Instance():RemoveGuildPicRelative(guildId)
  end
  for _, atlas in pairs(self.refAtlases) do
    atlas:RemoveRef()
  end
  TableUtility.TableClear(self.objects)
  TableUtility.TableClear(self.renderers)
  TableUtility.TableClear(self.objGuildIDMap)
  TableUtility.TableClear(self.refAtlases)
end

local GetStrongHoldId_ = function(obj, flagid)
  local strongHoldId = tonumber(obj:GetProperty(0))
  if nil ~= strongHoldId then
    return strongHoldId
  end
  return flagid
end

function GOManager_SceneGuildFlag:SetIconWithAtlas(strongHoldId, atlas, spriteData, guildId, color)
  if atlas == nil or spriteData == nil then
    return
  end
  local flagObjects = self.objects
  for flagId, obj in pairs(flagObjects) do
    local shID = GetStrongHoldId_(obj, flagId)
    if shID == strongHoldId and obj then
      local offset_x, offset_y, scale_x, scale_y, texture
      atlas:AddRef()
      texture = atlas.texture
      if not texture then
        atlas:RemoveRef()
        return
      end
      offset_x = spriteData.x / texture.width
      offset_y = (texture.height - spriteData.y - spriteData.height) / texture.height
      scale_x = spriteData.width / texture.width
      scale_y = spriteData.height / texture.height
      self:SetFlagIcon(flagId, texture, offset_x, offset_y, scale_x, scale_y, guildId, color)
      self.refAtlases[flagId] = atlas
    end
  end
end

function GOManager_SceneGuildFlag:SetIcon(strongHoldId, icon, offsetX, offsetY, scaleX, scaleY, guildId)
  local flagObjects = self.objects
  for flagId, obj in pairs(flagObjects) do
    local shID = GetStrongHoldId_(obj, flagId)
    if shID == strongHoldId then
      self:SetFlagIcon(flagId, icon, offsetX, offsetY, scaleX, scaleY, guildId)
    end
  end
end

function GOManager_SceneGuildFlag:ResetNewGvgFlag(flagid, portrait, guildid)
  local obj = self.objects[flagid]
  if not obj then
    return
  end
  local flagGo = obj.gameObject
  if flagGo.activeInHierarchy ~= true then
    flagGo:SetActive(true)
  end
  FunctionGuild.Me():SetGuildLandIcon(flagid, portrait, guildid)
end

function GOManager_SceneGuildFlag:HideNewGvgFlag(flagid)
  local obj = self.objects[flagid]
  if not obj then
    return
  end
  local flagGo = obj.gameObject
  if flagGo.activeInHierarchy ~= false then
    flagGo:SetActive(false)
  end
end

function GOManager_SceneGuildFlag:SetFlagIcon(flagID, icon, offsetX, offsetY, scaleX, scaleY, guildId, color)
  local obj = self.objects[flagID]
  if nil == obj then
    return
  end
  local renderer = self.renderers[flagID]
  local renderer2 = obj:GetComponentProperty(1)
  if nil == renderer then
    if nil == icon then
      return
    end
    renderer = obj:GetComponentProperty(0)
    self.renderers[flagID] = renderer
  elseif nil == icon then
    renderer.material = nil
    renderer.materials = _EmptyTable
    if renderer2 then
      renderer2.material = nil
      renderer2.materials = _EmptyTable
    end
    if self.refAtlases[flagID] then
      self.refAtlases[flagID]:RemoveRef()
      self.refAtlases[flagID] = nil
    end
    self.renderers[flagID] = nil
    if self.objGuildIDMap[obj] then
      GuildPictureManager.Instance():RemoveGuildPicRelative(self.objGuildIDMap[obj])
      self.objGuildIDMap[obj] = nil
    end
    return
  end
  if Slua.IsNull(renderer) then
    return
  end
  renderer.material = Game.Prefab_SceneGuildIcon.sharedMaterial
  if color then
    local _, c = ColorUtil.TryParseHexString(color)
    if _ then
      renderer.material.color = c
    end
  end
  renderer.material.mainTexture = icon
  if renderer2 then
    renderer2.material = Game.Prefab_SceneGuildIcon.sharedMaterial
    renderer2.material.mainTexture = icon
  end
  if self.refAtlases[flagID] then
    self.refAtlases[flagID]:RemoveRef()
    self.refAtlases[flagID] = nil
  end
  local lastCustomIconGuildID = self.objGuildIDMap[obj]
  self.objGuildIDMap[obj] = guildId
  if lastCustomIconGuildID ~= guildId then
    if lastCustomIconGuildID then
      GuildPictureManager.Instance():RemoveGuildPicRelative(lastCustomIconGuildID)
    end
    if guildId then
      GuildPictureManager.Instance():AddGuildPicRelative(guildId)
    end
  end
  if nil ~= offsetX and nil ~= offsetY then
    LuaVector2.Better_Set(tempVector2, offsetX, offsetY)
    renderer.material.mainTextureOffset = tempVector2
    if renderer2 then
      renderer2.material.mainTextureOffset = tempVector2
    end
  end
  if nil ~= scaleX and nil ~= scaleY then
    LuaVector2.Better_Set(tempVector2, scaleX, scaleY)
    renderer.material.mainTextureScale = tempVector2
    if renderer2 then
      renderer2.material.mainTextureScale = tempVector2
    end
  end
end

function GOManager_SceneGuildFlag:SetFlag(obj, ID)
  self.objects[ID] = obj
  if nil ~= obj then
    local renderer = obj:GetComponentProperty(0)
    renderer.material = nil
    renderer.materials = _EmptyTable
    local renderer2 = obj:GetComponentProperty(1)
    if renderer2 then
      renderer2.material = nil
      renderer2.materials = _EmptyTable
    end
    if self.refAtlases[ID] then
      self.refAtlases[ID]:RemoveRef()
      self.refAtlases[ID] = nil
    end
    if self.objGuildIDMap[obj] then
      GuildPictureManager.Instance():RemoveGuildPicRelative(self.objGuildIDMap[obj])
      self.objGuildIDMap[obj] = nil
    end
  else
    self.renderers[ID] = nil
  end
  if nil ~= obj then
    if ID > MaxSceneGuildFlag then
      GvgProxy.Instance:TryResetLobbyFlag()
      return
    end
    local strongHoldId = tonumber(obj:GetProperty(0))
    if strongHoldId and Table_Guild_StrongHold[strongHoldId] then
      FunctionGuild.Me():SetStrongHoldFlag(ID, strongHoldId)
    end
  end
end

function GOManager_SceneGuildFlag:OnClick(obj)
  if not FunctionUnLockFunc.checkFuncStateValid(4) then
    MsgManager.ShowMsgByID(40003)
    return
  end
  if Game.MapManager:IsInGVGRaid() then
    return
  end
  local strongHoldId = GetStrongHoldId_(obj, obj.ID)
  FunctionVisitNpc.AccessGuildFlag(strongHoldId, obj.transform)
end

function GOManager_SceneGuildFlag:ClearFlag(obj)
  local objID = obj.ID
  local testObj = self.objects[objID]
  if nil ~= testObj and testObj == obj then
    self:SetFlag(nil, objID)
    return true
  end
  return false
end

function GOManager_SceneGuildFlag:RegisterGameObject(obj)
  if CheckFlagInvalid() then
    GameObject.Destroy(obj.gameObject)
    return true
  end
  local objID = obj.ID
  Debug_AssertFormat(0 < objID, "RegisterSceneGuildFlag({0}) invalid id: {1}", obj, objID)
  if nil ~= self.objects[objID] then
    local lobbyId = objID + 1
    self.lobbyFlagId[#self.lobbyFlagId + 1] = lobbyId
    self:SetFlag(obj, lobbyId)
  else
    if objID > MaxSceneGuildFlag then
      self.lobbyFlagId[#self.lobbyFlagId + 1] = objID
    end
    self:SetFlag(obj, objID)
  end
  return true
end

function GOManager_SceneGuildFlag:GetLobbyFlagId()
  return self.lobbyFlagId
end

function GOManager_SceneGuildFlag:UnregisterGameObject(obj)
  if CheckFlagInvalid() then
    return true
  end
  if self.objGuildIDMap[obj] then
    GuildPictureManager.Instance():RemoveGuildPicRelative(self.objGuildIDMap[obj])
    self.objGuildIDMap[obj] = nil
  end
  if not self:ClearFlag(obj) then
    Debug_AssertFormat(false, "UnregisterSceneGuildFlag({0}) failed: {1}", obj, obj.ID)
    return false
  end
  return true
end
