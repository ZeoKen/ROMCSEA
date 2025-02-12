FunctionPreload = class("FunctionPreload")

function FunctionPreload.Me()
  if nil == FunctionPreload.me then
    FunctionPreload.me = FunctionPreload.new()
  end
  return FunctionPreload.me
end

function FunctionPreload:ctor()
  self:Reset()
  self.npcPreloads = ReusableTable.CreateTable()
  self.partKeyLimit = {}
  local partIndex = Asset_Role.PartIndex
  self.partKeyLimit[partIndex.Body] = Game.GOLuaPoolManager.role_part_bodyPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Hair] = Game.GOLuaPoolManager.role_part_hairPool:GetKeyLimit()
  self.partKeyLimit[partIndex.LeftWeapon] = Game.GOLuaPoolManager.role_part_weaponPool:GetKeyLimit()
  self.partKeyLimit[partIndex.RightWeapon] = Game.GOLuaPoolManager.role_part_weaponPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Head] = Game.GOLuaPoolManager.role_part_headPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Wing] = Game.GOLuaPoolManager.role_part_wingPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Face] = Game.GOLuaPoolManager.role_part_facePool:GetKeyLimit()
  self.partKeyLimit[partIndex.Tail] = Game.GOLuaPoolManager.role_part_tailPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Eye] = Game.GOLuaPoolManager.role_part_eyePool:GetKeyLimit()
  self.partKeyLimit[partIndex.Mount] = Game.GOLuaPoolManager.role_part_mountPool:GetKeyLimit()
  self.partKeyLimit[partIndex.Mouth] = Game.GOLuaPoolManager.role_part_mouthPool:GetKeyLimit()
  self.preloadKeyCountRecord = {}
  for k, v in pairs(partIndex) do
    self.preloadKeyCountRecord[v] = 0
  end
  self:InitFrequency_UI()
end

function FunctionPreload:Reset()
  if self.launched and self.professPreloader then
    GameObject.Destroy(self.professPreloader)
  end
end

function FunctionPreload:ResetCountRecord()
  for k, v in pairs(self.preloadKeyCountRecord) do
    self.preloadKeyCountRecord[k] = 0
  end
end

function FunctionPreload:_PreloadMakeRole(info, element, manager)
  local id = info[element]
  if id then
    self.makeRoles[#self.makeRoles + 1] = id
    self:_PreloadNpc(id, manager, 1)
  end
end

function FunctionPreload:PreloadMakeRole()
  local manager = Game.AssetManager_Role
  manager:SetForceLoadAll(true)
  self.makeRoles = {}
  local roleInfo
  for i = 1, #CharacterSelectList do
    roleInfo = CharacterSelectList[i]
    self:_PreloadMakeRole(roleInfo, "maleID", manager)
    self:_PreloadMakeRole(roleInfo, "femaleID", manager)
    self:_PreloadMakeRole(roleInfo, "petID", manager)
  end
end

function FunctionPreload:PreloadNewMakeRole()
  local manager = Game.AssetManager_Role
  manager:SetForceLoadAll(true)
  self.makeRoles = {}
  local roleInfo
  for i = 1, #Table_CreateCharactor do
    roleInfo = Table_CreateCharactor[i]
    self:_PreloadMakeRole(roleInfo, "maleID", manager)
    self:_PreloadMakeRole(roleInfo, "femaleID", manager)
  end
end

function FunctionPreload:ClearMakeRole()
  local manager = Game.AssetManager_Role
  manager:SetForceLoadAll(false)
  if self.makeRoles then
    for i = 1, #self.makeRoles do
      self:_ClearPreloadNpc(self.makeRoles[i], manager)
    end
  end
end

function FunctionPreload:PreloadJobs()
  if not self.preloadJobs then
    self.preloadJobs = true
    local professBodyIDs = {
      1,
      2,
      3,
      4,
      5,
      6,
      11,
      12,
      13,
      14,
      19,
      20,
      21,
      22,
      27,
      28,
      29,
      30,
      35,
      36,
      37,
      38
    }
    local manager = Game.AssetManager_Role
    for i = 1, #professBodyIDs do
      manager:PreloadPart(1, professBodyIDs[i], 10)
    end
  end
end

function FunctionPreload:SceneNpcs(pos, range)
  local npcList = Game.MapManager:GetNPCPointArray()
  local manager = Game.AssetManager_Role
  local npcInfo, npcID, distance, needPreLoad
  local newPreloads = ReusableTable.CreateTable()
  local bothHave = ReusableTable.CreateTable()
  local squareRange = range * range
  local distanceFunc = VectorUtility.DistanceXZ_Square
  if npcList then
    for i = 1, #npcList do
      npcInfo = npcList[i]
      npcID = npcInfo.ID
      needPreLoad = false
      if newPreloads[npcID] == nil and bothHave[npcID] == nil then
        if pos then
          distance = distanceFunc(pos, npcInfo.position)
          if squareRange >= distance then
            needPreLoad = true
          end
        else
          needPreLoad = true
        end
        if needPreLoad then
          if self.npcPreloads[npcID] then
            bothHave[npcID] = npcID
            self.npcPreloads[npcID] = nil
          else
            newPreloads[npcID] = npcID
          end
        end
      end
    end
  end
  self:ResetCountRecord()
  for k, v in pairs(newPreloads) do
    self:_PreloadNpc(v, manager)
  end
  for k, v in pairs(bothHave) do
    newPreloads[k] = v
  end
  self:_SetCurrentNpcPreload(newPreloads)
  ReusableTable.DestroyAndClearTable(bothHave)
end

local PreLoadOrClear = function(data, manager, func, args, keyCountTable, keyLimit)
  local indexMap = Asset_Role.PartIndex
  local count
  for k, v in pairs(indexMap) do
    if data[k] then
      if keyCountTable then
        count = keyCountTable[v]
        count = count + 1
        if v == indexMap.LeftWeapon or v == indexMap.RightWeapon then
          keyCountTable[indexMap.LeftWeapon] = count
          keyCountTable[indexMap.RightWeapon] = count
        else
          keyCountTable[v] = count
        end
        if count <= keyLimit[v] then
          func(manager, v, data[k], args)
        else
        end
      else
        func(manager, v, data[k], args)
      end
    end
  end
end

function FunctionPreload:_ManagerNpcPartsHandle(npcID, manager, func, args, checkKey)
  local npcData = Table_Npc[npcID]
  local indexMap = Asset_Role.PartIndex
  if npcData then
    if checkKey then
      PreLoadOrClear(npcData, manager, func, args, self.preloadKeyCountRecord, self.partKeyLimit)
    else
      PreLoadOrClear(npcData, manager, func, args)
    end
  else
    npcData = Table_Monster[npcID]
    if npcData then
      if checkKey then
        PreLoadOrClear(npcData, manager, func, args, self.preloadKeyCountRecord, self.partKeyLimit)
      else
        PreLoadOrClear(npcData, manager, func, args)
      end
    end
  end
end

function FunctionPreload:_ClearPreloadNpc(npcID, manager)
end

function FunctionPreload:_PreloadNpc(npcID, manager, count)
  count = count or 1
  self:_ManagerNpcPartsHandle(npcID, manager, manager.PreloadPart, count, true)
end

function FunctionPreload:_SetCurrentNpcPreload(maps)
  if self.npcPreloads and self.npcPreloads ~= maps then
    ReusableTable.DestroyAndClearTable(self.npcPreloads)
  end
  self.npcPreloads = maps
end

local PRELOADMAXCOUNT = 5

function FunctionPreload:GetFrequencyFilePath()
  return ApplicationHelper.persistentDataPath .. "/" .. "LoadFrequency.txt"
end

function FunctionPreload:InitFrequency_UI()
  if BackwardCompatibilityUtil.CompatibilityMode_V29 then
    return
  end
  local t1 = os.clock()
  local filePath = self:GetFrequencyFilePath()
  local wfile = io.open(filePath, "r")
  if wfile == nil then
    return
  end
  local fileStr = wfile:read("a")
  wfile:close()
  local t = loadstring(fileStr)
  if type(t) == "function" then
    t()
  end
end

function FunctionPreload:RecordFrequency_UI(b)
  self.recordFrequency_UI = b
end

function FunctionPreload:SaveLoadFrequency_UI()
  if BackwardCompatibilityUtil.CompatibilityMode_V29 then
    return
  end
  if not self.recordFrequency_UI then
    return
  end
  if Frequency_UI == nil then
    return
  end
  local t1 = os.clock()
  local filePath = self:GetFrequencyFilePath()
  local wfile = io.open(filePath, "w+")
  if wfile == nil then
    redlog(string.format("not find file:%s", filePath))
  end
  wfile:write("Frequency_UI = \n" .. Serialize(Frequency_UI))
  wfile:close()
end

function FunctionPreload:AddLoadFrequency_UI(uiname, count)
  if BackwardCompatibilityUtil.CompatibilityMode_V29 then
    return
  end
  if PreloadUI_Static and PreloadUI_Static[uiname] then
    return
  end
  if not self.recordFrequency_UI then
    return
  end
  if Frequency_UI == nil then
    Frequency_UI = {}
  end
  local ac = Frequency_UI[uiname]
  if ac == nil then
    Frequency_UI[uiname] = count
  else
    Frequency_UI[uiname] = count + ac
  end
end

local UIAssetPreloaded = function(asset, path, custom)
  if not Slua.IsNull(asset) then
    Game.GOLuaPoolManager:AddToUIPool(path, oassetbj)
  end
end
local UI_STYPE = "UI"

function FunctionPreload:PreLoadUI()
  if BackwardCompatibilityUtil.CompatibilityMode_V29 then
    return
  end
  local t1 = os.clock()
  local viewPathHelp = ResourcePathHelper.UIView
  local assetManager = Game.AssetManager_UI.assetManager
  for viewname, v in pairs(PreloadUI_Static) do
    local viewPath = viewPathHelp(viewname)
    assetManager:LimitLoadAsset(UI_STYPE, viewPath, GameObject, UIAssetPreloaded, self)
  end
  if Frequency_UI then
    local insertSort = TableUtility.InsertSort
    local insertSortFunc = function(l, r)
      return Frequency_UI[l] < Frequency_UI[r]
    end
    local dynamicConfig = {}
    for viewname, _ in pairs(Frequency_UI) do
      insertSort(dynamicConfig, viewname, insertSortFunc)
    end
    local limitCount = math.min(PRELOADMAXCOUNT, #dynamicConfig)
    for i = 1, limitCount do
      assetManager:LimitLoadAsset(UI_STYPE, viewPathHelp(dynamicConfig[i]), GameObject, UIAssetPreloaded, self)
    end
  end
end

function FunctionPreload:PreloadPackageView()
  if self.packageInited then
    return
  end
  self.packageInited = true
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.Bag,
    viewdata = {isPreload = true}
  })
  GameFacade.Instance:sendNotification(UIEvent.CloseUI, {
    className = "PackageView",
    needRollBack = false
  })
end
