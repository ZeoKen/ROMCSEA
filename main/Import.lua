autoImportPathMap = {}
mConfig_Special = {
  "StageBagItemIndex",
  "EquipFun",
  "GameConfig",
  "MapTeleport",
  "CommonFun",
  "TransferTeleport"
}

function reAutoImport(moduleName)
  ClearTableFromG(moduleName)
  return autoImport(moduleName)
end

function ClearTableFromG(moduleName)
  local fullPath = autoImportPathMap[moduleName]
  if fullPath then
    _G[fullPath] = nil
    package.loaded[fullPath] = nil
  end
  autoImportPathMap[moduleName] = nil
  _G[moduleName] = nil
end

function autoImport(moduleName)
  local fullPath = autoImportPathMap[moduleName]
  if fullPath == nil then
    local moduleNameNovice
    if ISNoviceServerType and moduleName ~= "Table_NoviceServer" and not BranchMgr.IsNO() and not BranchMgr.IsNOTW() then
      local p = moduleName:match("^Table_([%w_]+)$")
      local s = moduleName:match("^Scene_([%w_]+)$")
      if p then
        moduleNameNovice = "Table_" .. p .. "_NoviceServer"
      elseif s then
        moduleNameNovice = "Scene_" .. s .. "_NoviceServer"
      elseif TableUtil.ArrayIndexOf(mConfig_Special, moduleName) ~= 0 then
        moduleNameNovice = moduleName .. "_NoviceServer"
      end
    end
    if moduleNameNovice then
      fullPath = MyLuaSrv.GetFullPath(moduleNameNovice)
      if fullPath == moduleNameNovice then
        fullPath = nil
      end
    end
    if nil == fullPath then
      fullPath = MyLuaSrv.GetFullPath(moduleName)
    end
    autoImportPathMap[moduleName] = fullPath
  end
  if nil ~= _G[fullPath] then
    return _G[fullPath]
  end
  if nil ~= package.loaded[fullPath] then
    return package.loaded[fullPath]
  end
  if fullPath ~= nil then
    return require(fullPath)
  end
  return nil
end

function getFullPath(moduleName)
  local fullPath = autoImportPathMap[moduleName]
  if fullPath == nil then
    fullPath = MyLuaSrv.GetFullPath(moduleName)
    autoImportPathMap[moduleName] = fullPath
  end
  return fullPath
end
