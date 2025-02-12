FunctionGuild = class("FunctionGuild")
GuildFuncAuthorityMap = {
  UpgradeGuild = 7,
  DisMissGuild = 16,
  CancelDissolution = 16,
  ChangeGuildLine = 17,
  ChangeGuildName = 20,
  ChangeGvgLine = 37
}
autoImport("GuildHeadData")
autoImport("PhotoFileInfo")
local dialogData = {}

function FunctionGuild.Me()
  if nil == FunctionGuild.me then
    FunctionGuild.me = FunctionGuild.new()
  end
  return FunctionGuild.me
end

function FunctionGuild:ctor()
  self.customIconCache = {}
  self.cacheFlag_SetMap = {}
  EventManager.Me():AddEventListener(GuildPictureManager.ThumbnailDownloadCompleteCallback, self.ThumbnailDownloadCompleteCallback, self)
end

function FunctionGuild:ShowGuildDialog(npcInfo, tasks)
  local npcData = npcInfo.data.staticData
  local npcfunction = npcData and npcData.NpcFunction
  for i = 1, #npcfunction do
    local single = npcfunction[i]
    local funcCfg = Table_NpcFunction[single.type]
    if funcCfg then
      if funcCfg.NameEn == "CreateGuild" or funcCfg.NameEn == "ApplyGuild" then
        self:ShowEnterGuildDialog(npcInfo, tasks)
        break
      elseif funcCfg.NameEn == "UpgradeGuild" or funcCfg.NameEn == "DisMissGuild" or funcCfg.NameEn == "CancelDissolution" or funcCfg.NameEn == "ChangeGuildName" or funcCfg.NameEn == "ChangeGuildLine" or funcCfg.NameEn == "GiveUpGuildLand" or funcCfg.NameEn == "ChangeGvgLine" then
        self:ShowUpgradeGuildDialog(npcInfo, tasks)
        break
      end
    end
  end
end

function FunctionGuild:ShowEnterGuildDialog(npcInfo, tasks)
  local dialogData = {viewname = "DialogView"}
  if not GuildProxy.Instance:IHaveGuild() then
    local text, viceText = self:GetFormatEnterGuildText()
    local dDataConfig = {
      id = 0,
      Speaker = npcInfo.data.staticData.id,
      Text = text,
      ViceText = viceText
    }
    helplog(dDataConfig.Text, dDataConfig.ViceText)
    dialogData.defaultDialog = dDataConfig
  else
    local defaultDlg = npcInfo.data.staticData.DefaultDialog
    if defaultDlg then
      dialogData.defaultDialog = defaultDlg
    else
      dialogData.dialoglist = {
        "My lord, you had a guild..."
      }
    end
  end
  dialogData.npcinfo = npcInfo
  dialogData.tasks = tasks
  GameFacade.Instance:sendNotification(UIEvent.ShowUI, dialogData)
end

function FunctionGuild:GetFormatEnterGuildText()
  local text, viceText = ZhString.FunctionGuild_GuildCreateTip, ""
  local needItems = GameConfig.Guild.createitem
  for i = 1, #needItems do
    local needItem = needItems[i]
    if needItem[1] and needItem[2] then
      local sIData = Table_Item[needItem[1]]
      local tempText, hasNum = ""
      if needItem[1] == 100 or needItem[1] == 110 then
        tempText = string.format(ZhString.FunctionGuild_GuildCreateGoldCondition, i, needItem[2], sIData.NameZh)
        hasNum = MyselfProxy.Instance:GetROB()
      elseif needItem[1] == 105 then
        tempText = string.format(ZhString.FunctionGuild_GuildCreateGoldCondition, i, needItem[2], sIData.NameZh)
        hasNum = MyselfProxy.Instance:GetGold()
      else
        tempText = string.format(ZhString.FunctionGuild_GuildCreateItemCondition, i, sIData.NameZh, needItem[2])
        hasNum = BagProxy.Instance:GetItemNumByStaticID(needItem[1])
      end
      if hasNum >= needItem[2] then
        viceText = viceText .. "[00ff00]" .. tempText .. "[-]"
      else
        viceText = viceText .. "[ff0000]" .. tempText .. "[-]"
      end
      if i <= #needItems then
        viceText = viceText .. "\n"
      end
    else
      errorLog("Guild Create Item ErrorConfig")
    end
  end
  return text, viceText
end

function FunctionGuild:ShowUpgradeGuildDialog(npcInfo, tasks)
  local npcData = npcInfo.data.staticData
  local npcfunction = npcData and npcData.NpcFunction
  local guildFunc = {}
  for i = 1, #npcfunction do
    local funcType = npcfunction[i].type
    local funcCfg = Table_NpcFunction[funcType]
    if funcCfg == nil then
      helplog("ERROR!!!", funcType)
    end
    local myGuildMemberData = GuildProxy.Instance:GetMyGuildMemberData()
    if funcCfg and myGuildMemberData then
      local canDo = true
      if GuildFuncAuthorityMap[funcCfg.NameEn] then
        canDo = GuildProxy.Instance:CanJobDoAuthority(myGuildMemberData.job, GuildFuncAuthorityMap[funcCfg.NameEn])
      end
      local isDismissing = GuildProxy.Instance:IsDismissing()
      if canDo then
        if funcCfg.NameEn == "DisMissGuild" then
          if not isDismissing then
            table.insert(guildFunc, npcfunction[i])
          end
        elseif funcCfg.NameEn == "CancelDissolution" then
          if isDismissing then
            table.insert(guildFunc, npcfunction[i])
          end
        else
          table.insert(guildFunc, npcfunction[i])
        end
      end
    end
  end
  TableUtility.TableClear(dialogData)
  dialogData.viewname = "DialogView"
  if npcData.DefaultDialog then
    dialogData.dialoglist = {
      npcData.DefaultDialog
    }
  else
    dialogData.dialoglist = {
      "No Default Dialog..."
    }
  end
  dialogData.addconfig = guildFunc
  dialogData.npcinfo = npcInfo
  dialogData.tasks = tasks
  GameFacade.Instance:sendNotification(UIEvent.ShowUI, dialogData)
end

function FunctionGuild:ShowGuildRaidDialog(npcInfo)
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.GuildOpenRaidDialog,
    viewdata = {npcInfo = npcInfo}
  })
end

function FunctionGuild:ShowEnterGuildFubenDialog(npcInfo)
  TableUtility.TableClear(dialogData)
  dialogData.viewname = "DialogView"
  local timetick = 0
  local unlockData = GuildProxy.Instance:GetGuildGateInfoByNpcId(npcInfo.data.id)
  if unlockData then
    timetick = unlockData.opentime
  end
  GameFacade.Instance:sendNotification(UIEvent.ShowUI, dialogData)
end

function FunctionGuild:MakeGuildUpgrade()
  self.optUpgrade = true
  local guildData = GuildProxy.Instance.myGuildData
  if not guildData then
    return
  end
  local upConfig = guildData:GetUpgradeConfig()
  if not upConfig then
    errorLog("Not UpConfig")
    return
  end
  local assetNum = guildData.asset
  if assetNum and assetNum < upConfig.ReviewFund then
    MsgManager.ShowMsgByIDTable(2617)
    return
  end
  local upItemId, upItemNum = upConfig.DeductItem[1], upConfig.DeductItem[2]
  local upItemName = upItemId and Table_Item[upItemId] and Table_Item[upItemId].NameZh
  local itemNum = GuildProxy.Instance:GetGuildPackItemNumByItemid(GuildItemConfig.GuildItemId)
  if upItemNum > itemNum then
    MsgManager.ShowMsgByIDTable(2618, {upItemName})
    return
  end
  ServiceGuildCmdProxy.Instance:CallLevelupGuildCmd()
end

function FunctionGuild:UpgradeGuild()
  if self.optUpgrade then
    self.optUpgrade = false
    self:PlayUpgradeEffect()
  end
end

function FunctionGuild:PlayUpgradeEffect()
  FloatingPanel.Instance:FloatingMidEffectByFullPath(ResourcePathHelper.UIEffect(EffectMap.UI.GuildUpgrade))
  ServiceGuildCmdProxy.Instance:CallLevelupEffectGuildCmd()
end

function FunctionGuild:ResetGuildItemQueryState()
  self.item_Queryed = false
end

function FunctionGuild:QueryGuildItemList()
  if self.item_Queryed == true then
    return
  end
  self.item_Queryed = true
  local guildData = GuildProxy.Instance.myGuildData
  if guildData then
    GuildProxy.Instance:ClearGuildPackItems()
    ServiceGuildCmdProxy.Instance:CallQueryPackGuildCmd()
  end
end

function FunctionGuild:ResetGuildEventQueryState()
  self.event_Queryed = false
end

function FunctionGuild:QueryGuildEventList()
  if self.event_Queryed == true then
    return
  end
  self.event_Queryed = true
  local guildData = GuildProxy.Instance.myGuildData
  if guildData then
    GuildProxy.Instance:ClearGuildEventList()
    ServiceGuildCmdProxy.Instance:CallQueryEventListGuildCmd()
  end
end

function FunctionGuild:MyGuildJobChange(old, new)
  helplog("MyGuildJobChange", old, new)
end

function FunctionGuild:SetStrongHoldFlag(flagID, id)
  local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
  if flagManager == nil then
    return
  end
  local strongHoldStaticData = Table_Guild_StrongHold[id]
  if not strongHoldStaticData then
    return
  end
  local icon = strongHoldStaticData.Icon or "GuilIcon_115"
  local iconColor = strongHoldStaticData.IconColor
  local atlas, spriteData
  local guildAtlas = IconManager:GetAtlasByType(UIAtlasConfig.IconAtlas.uiicon)
  for i = 1, #guildAtlas do
    spriteData = guildAtlas[i]:GetSprite(icon)
    if spriteData ~= nil then
      atlas = guildAtlas[i]
      break
    end
  end
  if not atlas or not spriteData then
    return
  end
  flagManager:SetIconWithAtlas(id, atlas, spriteData, nil, iconColor)
end

function FunctionGuild:SetGuildLandIcon(flagID, portrait, guildId)
  redlog("FunctionGuild:SetGuildLandIcon", flagID, portrait, guildId)
  local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
  if flagManager == nil then
    return
  end
  if portrait == nil then
    flagManager:SetIcon(flagID, nil, nil, nil, nil, nil, guildId)
    return
  end
  local guildHeadData = GuildHeadData.new()
  guildHeadData:SetBy_InfoId(portrait)
  guildHeadData:SetGuildId(guildId)
  local offset_x, offset_y, scale_x, scale_y, texture
  if guildHeadData.type == GuildHeadData_Type.Config then
    local guildIcon = guildHeadData and guildHeadData.staticData.Icon or nil
    if guildIcon == nil then
      flagManager:SetIcon(flagID, nil, nil, nil, nil, nil, guildId)
      return
    end
    local atlas, spriteData
    local guildAtlas = IconManager:GetAtlasByType(UIAtlasConfig.IconAtlas.guild)
    for i = 1, #guildAtlas do
      spriteData = guildAtlas[i]:GetSprite(guildIcon)
      if spriteData ~= nil then
        atlas = guildAtlas[i]
        break
      end
    end
    flagManager:SetIconWithAtlas(flagID, atlas, spriteData, guildId)
  elseif guildHeadData.type == GuildHeadData_Type.Custom then
    texture = GuildPictureManager.Instance():GetThumbnailTexture(guildHeadData.guildid, UnionLogo.CallerIndex.UnionFlag, guildHeadData.index, guildHeadData.time)
    if texture == nil then
      flagManager:SetIcon(flagID, nil, nil, nil, nil, nil, guildId)
      self.cacheFlag_SetMap[guildHeadData.guildid] = flagID
      local adata = {
        callIndex = UnionLogo.CallerIndex.UnionFlag,
        guild = guildHeadData.guildid,
        index = guildHeadData.index,
        time = guildHeadData.time,
        picType = guildHeadData.pic_type
      }
      GuildPictureManager.Instance():AddMyThumbnailInfos({adata})
      return
    else
      offset_x = 0
      offset_y = 0
      scale_x = 1
      scale_y = 1
    end
    if texture ~= nil then
      flagManager:SetIcon(flagID, texture, offset_x, offset_y, scale_x, scale_y, guildId)
    end
  end
end

function FunctionGuild:ThumbnailDownloadCompleteCallback(cdata)
  local guildid = cdata.guild
  if guildid == nil then
    return
  end
  if self.cacheFlag_SetMap[guildid] == nil then
    return
  end
  local flagManager = Game.GameObjectManagers[Game.GameObjectType.SceneGuildFlag]
  if flagManager == nil then
    return
  end
  local texture = GuildPictureManager.Instance():GetThumbnailTexture(guildid, UnionLogo.CallerIndex.UnionFlag, cdata.index, cdata.time)
  if texture ~= nil then
    local flagID = self.cacheFlag_SetMap[guildid]
    self.cacheFlag_SetMap[guildid] = nil
    flagManager:SetIcon(flagID, texture, 0, 0, 1, 1, guildid)
  end
end

local testAssetPath = "GUI/pic/UI/Dojo_Icon_05"

function FunctionGuild:ClearCustomPicCache(guildid)
  local cache = self.customIconCache[guildid]
  if cache ~= nil then
    for k, v in pairs(cache) do
      if not Slua.IsNull(v) then
        if self.doTest then
          Game.AssetManager_UI:UnLoadAsset(testAssetPath)
        else
          Object.Destroy(v)
        end
      end
      cache[k] = nil
    end
  end
  self.customIconCache[guildid] = nil
end

function FunctionGuild:SetCustomPicCache(guildid, pos, tex)
  local cache = self.customIconCache[guildid]
  if cache == nil then
    cache = {}
    self.customIconCache[guildid] = cache
  end
  local oldPic = cache[pos]
  if oldPic ~= nil and oldPic ~= tex then
    if self.doTest then
      Game.AssetManager_UI:UnLoadAsset(testAssetPath)
    else
      Object.Destroy(oldPic)
    end
  end
  cache[pos] = tex
end

function FunctionGuild:GetCustomPicCache(guildid, pos)
  local cache = self.customIconCache[guildid]
  if cache == nil then
    return nil
  end
  return cache[pos]
end

function FunctionGuild:SaveAndUploadCustomGuildIcon(index, doTest)
  local maxCount = GameConfig.Guild.icon_uplimit or 32
  if index > maxCount then
    MsgManager.ShowMsgByIDTable(2648)
    return
  end
  self.doTest = doTest
  local myGuildData = GuildProxy.Instance.myGuildData
  if myGuildData == nil then
    return
  end
  local timestamp = math.floor(ServerTime.CurServerTime() / 1000)
  if self.doTest then
    Game.AssetManager_UI:LoadAsset(testAssetPath, Texture, function(p, tex)
      tex.name = timestamp
      self:SetCustomPicCache(myGuildData.id, index, tex)
      local bytes = ImageConversion.EncodeToPNG(tex)
      self:UploadCustomGuildIcon(myGuildData.id, index, timestamp, bytes)
    end)
  elseif ApplicationInfo.IsRunOnWindowns() then
    function ImageCropImpl.chooseDone(tex)
      tex.name = timestamp
      
      self:SetCustomPicCache(myGuildData.id, index, tex)
      local bytes = ImageConversion.EncodeToPNG(tex)
      self:UploadCustomGuildIcon(myGuildData.id, index, timestamp, bytes)
    end
    
    ImageCropImpl.ChooseStart(128, 128)
  else
    ImageCropImpl.ChooseStart(128, 128)
    
    function ImageCropImpl.chooseDone(tex)
      tex.name = timestamp
      self:SetCustomPicCache(myGuildData.id, index, tex)
      local bytes = ImageConversion.EncodeToPNG(tex)
      self:UploadCustomGuildIcon(myGuildData.id, index, timestamp, bytes)
    end
  end
end

function FunctionGuild:UploadCustomGuildIcon(guildid, index, timestamp, bytes)
  if self.upload then
    MsgManager.ShowMsgByIDTable(997)
    return
  end
  self.upload = true
  if FunctionPhotoStorage.IsActive() then
    FunctionPhotoStorage.Me():SaveGuildIcon(bytes, guildid, index, timestamp, PhotoFileInfo.PictureFormat.PNG, nil, function(success, msg)
      self.upload = false
    end)
    return
  end
  local md5 = MyMD5.HashBytes(bytes)
  GamePhoto.SetPhotoFileMD5_UnionLogo(index, md5)
  ServicePhotoCmdProxy.Instance:CallAddMd5PhotoCmd(md5)
  local success_callback = function()
    self.upload = false
    ServiceGuildCmdProxy.Instance:CallGuildIconAddGuildCmd(index, nil, timestamp, false, PhotoFileInfo.PictureFormat.PNG)
    ServicePhotoCmdProxy.Instance:CallRemoveMd5PhotoCmd(md5)
  end
  local error_callback = function(msg)
    MsgManager.ShowMsgByIDTable(995)
    self.upload = false
    error(msg)
  end
  helplog("FunctionGuild UploadCustomGuildIcon ~~~~~~~~~~~~~~~")
  UnionLogo.Ins():SetUnionID(guildid)
  UnionLogo.Ins():SaveAndUpload(index, bytes, timestamp, PhotoFileInfo.PictureFormat.PNG, progress_callback, success_callback, error_callback)
end

function FunctionGuild:GetGuildStrongHoldPosition(id)
  local configData = Table_Guild_StrongHold[id]
  if configData == nil then
    return
  end
  local mapId = configData.MapId
  if mapId == nil then
    return
  end
  local mapName = Table_Map[mapId] and Table_Map[mapId].NameEn
  if mapName == nil then
    return
  end
  local fName = "Scene_" .. mapName
  local sceneInfo = autoImport(fName)
  ClearTableFromG(fName)
  local guildFlags = sceneInfo.GuildFlags
  if guildFlags == nil then
    return
  end
  for k, v in pairs(guildFlags) do
    if v.strongHoldId == id then
      return mapId, v.position
    end
  end
end

function FunctionGuild:GetGuildStrongHoldMetalIdPos(raid_id, point_id)
  if not raid_id or not point_id then
    return
  end
  self.raidMetalMap = self.raidMetalMap or {}
  local raidMetalMap = self.raidMetalMap[raid_id]
  if not raidMetalMap then
    raidMetalMap = {}
    local fName = "Scene_Guild_battle_prt"
    local sceneInfo = autoImport(fName)
    ClearTableFromG(fName)
    local metal_npc_array = sceneInfo.Raids[raid_id].npcs
    for i = 1, #metal_npc_array do
      if 1 <= metal_npc_array[i].uniqueID and metal_npc_array[i].uniqueID <= 8 then
        raidMetalMap[uniqueID] = metal_npc_array[i]
      end
    end
    self.raidMetalMap[raid_id] = raidMetalMap
  end
  return self.raidMetalMap[raid_id][point_id].ID, self.raidMetalMap[raid_id][point_id].position
end
