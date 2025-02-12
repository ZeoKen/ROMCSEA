RoleUtil = {
  MASK_COLOR_CHANGE_DURATION = 0.2,
  MASK_COLOR_INVALID = Color.clear,
  DRESS_COUNT_PER_FRAME = 3,
  DRESS_FRAME_INTERVAL = 200
}

function RoleUtil.PS_Outline(on, roleAgent, mat, combineWorker)
  if on then
    local roleData = roleAgent.data
    if roleData.outLine then
      if combineWorker.normalShader == mat.shader then
        mat.shader = combineWorker.normalOutlineShader
      elseif combineWorker.normalShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.normalOutlineShaderWithoutToon
      elseif combineWorker.combineShader == mat.shader then
        mat.shader = combineWorker.combineOutlineShader
      elseif combineWorker.combineShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.combineOutlineShaderWithoutToon
      end
    end
  elseif combineWorker.normalOutlineShader == mat.shader then
    mat.shader = combineWorker.normalShader
  elseif combineWorker.normalOutlineShaderWithoutToon == mat.shader then
    mat.shader = combineWorker.normalShaderWithoutToon
  elseif combineWorker.combineOutlineShader == mat.shader then
    mat.shader = combineWorker.combineShader
  elseif combineWorker.combineOutlineShaderWithoutToon == mat.shader then
    mat.shader = combineWorker.combineShaderWithoutToon
  end
end

function RoleUtil.PS_ToonLight(on, roleAgent, mat, combineWorker)
  if on then
    local toonOn = roleAgent.data.toon
    if toonOn then
      local body = roleAgent.role
      if nil ~= body then
        local smrInfo = body.smrInfo
        if nil ~= smrInfo and nil ~= smrInfo.toonLightParams then
          toonOn = smrInfo.toonLightParams.valid
        end
      end
    end
    if toonOn then
      if combineWorker.normalShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.normalShader
      elseif combineWorker.normalOutlineShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.normalOutlineShader
      elseif combineWorker.combineShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.combineShader
      elseif combineWorker.combineOutlineShaderWithoutToon == mat.shader then
        mat.shader = combineWorker.combineOutlineShader
      end
    end
  elseif combineWorker.normalShader == mat.shader then
    mat.shader = combineWorker.normalShaderWithoutToon
  elseif combineWorker.normalOutlineShader == mat.shader then
    mat.shader = combineWorker.normalOutlineShaderWithoutToon
  elseif combineWorker.combineShader == mat.shader then
    mat.shader = combineWorker.combineShaderWithoutToon
  elseif combineWorker.combineOutlineShader == mat.shader then
    mat.shader = combineWorker.combineOutlineShaderWithoutToon
  end
end

function RoleUtil.PerformanceSetting(roleAgent, setting)
  local mat = roleAgent.combineMaterial
  if nil ~= mat then
    local combineWorker = CombineMeshesWorker.localWorker
    if nil ~= combineWorker and nil ~= setting.outLine then
      RoleUtil.PS_Outline(setting.outLine, roleAgent, mat, combineWorker)
    end
  end
end

function RoleUtil.PerformanceOn(roleAgent, setting)
  if setting.outLine then
    return
  end
  local mat = roleAgent.combineMaterial
  if nil ~= mat then
    local combineWorker = CombineMeshesWorker.localWorker
    if nil ~= combineWorker and not setting.outLine then
      RoleUtil.PS_Outline(setting.outLine, roleAgent, mat, combineWorker)
    end
  end
end

function RoleUtil.RoleOutlineOnOff(roleAgent, on)
  local combineWorker = CombineMeshesWorker.localWorker
  if nil ~= combineWorker then
    local mat = roleAgent.combineMaterial
    if nil ~= mat then
      local combineWorker = CombineMeshesWorker.localWorker
      RoleUtil.PS_Outline(on, roleAgent, mat, combineWorker)
    end
  end
end

function RoleUtil.ToonEffectInfoLerp(src, tar, p)
  local info = {}
  info.lights = {}
  if nil ~= tar.lights then
    for i = 1, #tar.lights do
      local light = {}
      local srcLight = src.lights[i]
      local tarLight = tar.lights[i]
      light.color = Color.Lerp(srcLight.color, tarLight.color, p)
      light.exposure = Mathf.Lerp(srcLight.exposure, tarLight.exposure, p)
      info.lights[i] = light
    end
  end
  return info
end

function RoleUtil.GetToonEffectInfo(role)
  local mat = role.combineMaterial
  if nil == mat then
    return nil
  end
  local info = {}
  info.lights = {}
  for i = 1, 3 do
    local light = {}
    light.color = CombineMeshesWorker.GetToonLightColor(mat, i)
    light.exposure = CombineMeshesWorker.GetToonLightExposure(mat, i)
    info.lights[i] = light
  end
  return info
end

function RoleUtil.SetToonEffectInfo(role, info)
  local mat = role.combineMaterial
  if nil == mat then
    return
  end
  if nil ~= info.lights then
    for i = 1, #info.lights do
      local light = info.lights[i]
      CombineMeshesWorker.SetToonLightColor(mat, light.color, i)
      CombineMeshesWorker.SetToonLightExposure(mat, light.exposure, i)
    end
  end
end

function RoleUtil.GetAvatarWeaponID(avatar)
  local weaponID = avatar.rightWeapon.ID
  if 0 == weaponID then
    weaponID = avatar.leftWeapon.ID
  end
  return weaponID
end

function RoleUtil.GetRoleWeaponID(role)
  local avatar = role.data.avatar
  if nil == avatar then
    return 0
  end
  return RoleUtil.GetAvatarWeaponID(avatar)
end

function RoleUtil.SetRoleActionSuffix(role, avatar)
  local weaponID = RoleUtil.GetAvatarWeaponID(avatar)
  if 0 == weaponID then
    role.actionSuffix = nil
  else
    role.actionSuffix = Table_Equip[weaponID].Type
  end
end

function RoleUtil.SetHair(roleAgent, hairID, hairColorIndex, immediately)
  local roleData = {hair = hairID, haircolor = hairColorIndex}
  RoleUtil.UpdateRoleAvatar(nil, roleData, roleAgent, nil, immediately)
end

function RoleUtil.SetHairColor(roleAgent, hairColorIndex)
  local hair = roleAgent.data.avatar.hair
  hair.maskColor = RoleUtil.GetRolePartyColor(hair.ID, hairColorIndex, Table_HairStyle)
  roleAgent.data.avatar.hair = hair
  roleAgent:SetPartMaskColor(Config.RolePoint.CONNECT_HAIR, hair.maskColor)
end

function RoleUtil.SetAccessories(roleAgent, accessoriesID, immediately)
  local roleData = {accessory = accessoriesID}
  RoleUtil.UpdateRoleAvatar(nil, roleData, roleAgent, nil, immediately)
end

function RoleUtil.GetNPCHairDefaultColor(npcID)
  local info = Table_Npc[npcID] or Table_Monster[npcID]
  if nil == info then
    return 0
  end
  if info.HeadDefaultColor and 0 ~= info.HeadDefaultColor then
    return info.HeadDefaultColor
  end
  local hairInfo = Table_HairStyle[info.Hair]
  if nil == hairInfo then
    return 0
  end
  return hairInfo.DefaultColor
end

function RoleUtil.GetNPCBodyDefaultColor(npcID)
  local info = Table_Npc[npcID] or Table_Monster[npcID]
  if nil == info then
    return 0
  end
  if 0 ~= info.BodyDefaultColor then
    return info.BodyDefaultColor
  end
  local bodyInfo = Table_Body[info.Body]
  if nil == bodyInfo then
    return 0
  end
  return bodyInfo.DefaultColor
end

function RoleUtil.OnTimer(deltaTime)
  if nil == RoleUtil.queue or RoleUtil.queue:Empty() then
    TimeTickManager.Me():ClearTick(RoleUtil)
    RoleUtil.timer = nil
    return
  end
  local count = 0
  repeat
    local func = RoleUtil.queue:Pop()
    if func() then
      count = count + 1
    end
    if RoleUtil.queue:Empty() then
      TimeTickManager.Me():ClearTick(RoleUtil)
      RoleUtil.timer = nil
      return
    end
  until count >= RoleUtil.DRESS_COUNT_PER_FRAME
end

function RoleUtil.RoleDress(newAvatar, roleAgent, localScale, immediately)
  if nil == roleAgent or immediately then
    return RoleUtil.DoRoleDress(newAvatar, roleAgent, localScale)
  end
  if nil == RoleUtil.timer then
    roleAgent = RoleUtil.DoRoleDress(newAvatar, roleAgent, localScale)
    RoleUtil.timer = TimeTickManager.Me():CreateTick(0, RoleUtil.DRESS_FRAME_INTERVAL, RoleUtil.OnTimer, RoleUtil)
  else
    if nil == RoleUtil.queue then
      RoleUtil.queue = LuaQueue.new()
    end
    RoleUtil.queue:Push(function()
      if nil ~= roleAgent and Game.GameObjectUtil:ObjectIsNULL(roleAgent) then
        return false
      end
      RoleUtil.DoRoleDress(newAvatar, roleAgent, localScale)
      if roleAgent.sitdownOnStart then
        roleAgent:Sitdown()
      end
      return true
    end)
  end
  return roleAgent
end

function RoleUtil.HandleAvatar(newAvatar, roleAgent)
  local invalidHairIDs
  local ignoreHair = false
  local ignoreFace = false
  local accessories = newAvatar.accessories
  local headData = Table_Equip[accessories.ID]
  if nil ~= headData then
    invalidHairIDs = headData.HairID
    local display = headData.display and headData.display[1]
    if nil ~= display then
      if 1 == display then
        ignoreHair = true
        ignoreFace = true
      elseif 2 == display then
        ignoreHair = true
      end
    end
  end
  if ignoreHair then
    newAvatar.hair = RoleAvatar.Part(0)
  else
    local hair = newAvatar.hair
    local hairID = hair.ID
    if Gender.NONE ~= newAvatar.gender and nil ~= invalidHairIDs and 0 < #invalidHairIDs then
      for i = 1, #invalidHairIDs do
        if invalidHairIDs[i] == hairID then
          if Gender.MALE == newAvatar.gender then
            hair.ID = 998
            break
          end
          if Gender.FEMALE == newAvatar.gender then
            hair.ID = 999
          end
          break
        end
      end
    end
    newAvatar.hair = hair
  end
  if ignoreFace then
    newAvatar.face = RoleAvatar.Part(0)
  end
end

function RoleUtil.DoRoleDress(newAvatar, roleAgent, localScale)
  local bodyMaskColorList, hairMaskColorList
  local forceDress = false
  if nil == newAvatar then
    newAvatar = roleAgent.data.avatar
    forceDress = true
  end
  RoleUtil.HandleAvatar(newAvatar, roleAgent)
  if nil ~= roleAgent and roleAgent.delayDress then
    roleAgent:DelayDress(newAvatar)
    return roleAgent
  end
  if LuaUtils.ColorEquals(RoleUtil.MASK_COLOR_INVALID, newAvatar.body.maskColor) then
    bodyMaskColorList = ColorUtil.ToColorList(RoleUtil.GetRolePartColorTable(newAvatar.body.ID, Table_Body))
  end
  if LuaUtils.ColorEquals(RoleUtil.MASK_COLOR_INVALID, newAvatar.hair.maskColor) then
    hairMaskColorList = ColorUtil.ToColorList(RoleUtil.GetRolePartColorTable(newAvatar.hair.ID, Table_HairStyle))
  end
  local headData = Table_Equip[newAvatar.accessories.ID]
  local display = headData and headData.display and headData.display[1]
  if nil ~= headData and nil ~= display and 0 < display then
    newAvatar.hair = RoleAvatar.Part(0)
  end
  if nil == roleAgent then
    roleAgent = newAvatar:CreateRole(function(newRoleAgent)
      RoleUtil.SetRoleActionSuffix(newRoleAgent, newAvatar)
    end)
  else
    local moving = roleAgent.moving
    RoleUtil.SetRoleActionSuffix(roleAgent, newAvatar)
    newAvatar:RoleDress(roleAgent, forceDress)
    if moving then
      roleAgent:PlayActionWalk()
    end
  end
  if nil ~= roleAgent then
    roleAgent:SetBodyMaskColorList(bodyMaskColorList, RoleUtil.MASK_COLOR_CHANGE_DURATION)
    roleAgent:SetPartMaskColorList(SkillConfig.ROLE_CP_HAIR, hairMaskColorList, RoleUtil.MASK_COLOR_CHANGE_DURATION)
    if nil ~= localScale then
      roleAgent.localScale = localScale
    end
    local performanceSetting = FunctionPerformanceSetting.Me():GetSetting()
    RoleUtil.PerformanceOn(roleAgent, performanceSetting)
  end
  local creature = roleAgent.data.custom
  if nil ~= creature then
    creature:OnDressed()
  end
  return roleAgent
end

function RoleUtil.DataToAvartar(roleAvatar, roleData)
  local newAvatar = roleAvatar and roleAvatar:CloneSelf() or RoleAvatar()
  if nil ~= roleData.wing then
    newAvatar.wing = RoleAvatar.Part(roleData.wing)
  end
  if nil ~= roleData.sex then
    if 1 == roleData.sex then
      newAvatar.gender = Gender.MALE
    elseif 2 == roleData.sex then
      newAvatar.gender = Gender.FEMALE
    else
      newAvatar.gender = Gender.NONE
    end
  end
  if nil ~= roleData.body then
    local color = RoleUtil.GetRolePartyColor(roleData.body, roleData.bodycolor, Table_Body)
    if nil == color then
      color = RoleUtil.MASK_COLOR_INVALID
    end
    local originOffset = Vector3(0, roleData.floatHeight or 0, 0)
    newAvatar.body = RoleAvatar.Part(color, roleData.body, 1, originOffset)
  end
  if nil ~= roleData.rightWeapon then
    newAvatar.rightWeapon = RoleAvatar.Part(roleData.rightWeapon)
  end
  if nil ~= roleData.leftWeapon then
    newAvatar.leftWeapon = RoleAvatar.Part(roleData.leftWeapon)
  end
  if nil ~= roleData.accessory then
    newAvatar.accessories = RoleAvatar.Part(roleData.accessory)
  end
  if nil ~= roleData.hair then
    local hairID = roleData.hair
    local color = RoleUtil.GetRolePartyColor(hairID, roleData.haircolor, Table_HairStyle)
    if nil == color then
      color = RoleUtil.MASK_COLOR_INVALID
    end
    newAvatar.hair = RoleAvatar.Part(color, hairID)
  end
  if nil ~= roleData.face then
    newAvatar.face = RoleAvatar.Part(roleData.face)
  end
  if nil ~= roleData.tail then
    newAvatar.tail = RoleAvatar.Part(roleData.tail)
  end
  if nil ~= roleData.mount then
    newAvatar.mount = RoleAvatar.Part(roleData.mount)
  end
  return newAvatar
end

function RoleUtil.UpdateRoleAvatar(roleAvatar, roleData, roleAgent, localScale, immediately)
  local newAvatar = RoleUtil.DataToAvartar(roleAvatar or roleAgent and roleAgent.data.avatar, roleData)
  return RoleUtil.RoleDress(newAvatar, roleAgent, localScale, immediately)
end

function RoleUtil.GetRolePartyColor(partId, colorId, table)
  if table ~= nil and colorId ~= nil and table[partId] ~= nil then
    return table[partId].PaintColor_Parsed[colorId]
  end
  return Color.white
end

function RoleUtil.GetRolePartColorTable(partId, table)
  if table ~= nil and table[partId] ~= nil then
    return table[partId].PaintColor_Parsed
  end
  return nil
end

function RoleUtil.SetTransform(roleAgent, config)
  if roleAgent == nil then
    return
  end
  if config.localPosition ~= nil then
    roleAgent.transform.localPosition = config.localPosition
  end
  if config.localScale ~= nil then
    roleAgent.localScale = config.localScale
  end
  if config.rotation ~= nil then
    roleAgent.rotation = Quaternion.Euler(config.rotation)
  else
    roleAgent.rotation = Quaternion.Euler(0, 180, 0)
  end
  if config.size ~= nil then
    roleAgent.data.boundSize = config.size
  end
end

function RoleUtil.PlayAction(roleAgent, action, callback)
  if FunctionSystem.InterruptRole(roleAgent) then
    roleAgent:PlayAction(action, 1, true)
  end
  local animater = roleAgent.animatorHelper
  local tempFunc
  
  function tempFunc(state, oldcount, newcount)
    if state:IsName(action) and roleAgent.idle then
      roleAgent:Wait()
    end
    if type(callback) == "function" then
      callback()
    end
    animater.loopCountChangedListener = {"-=", tempFunc}
  end
  
  animater.loopCountChangedListener = {"+=", tempFunc}
end

function RoleUtil.PlayNpcAction(roleAgent, action, callback)
  roleAgent:PlayAction(action, 1, true)
  local animater = roleAgent.animatorHelper
  local tempFunc
  
  function tempFunc(state, oldcount, newcount)
    if state:IsName(action) and roleAgent.idle then
      roleAgent:Wait()
    end
    if type(callback) == "function" then
      callback()
    end
    animater.loopCountChangedListener = {"-=", tempFunc}
  end
  
  animater.loopCountChangedListener = {"+=", tempFunc}
end

local IsNull = Slua.IsNull

function RoleUtil.UpdateEPNodesDisplay(RolePartObj, display)
  if IsNull(RolePartObj) then
    return
  end
  local _LODLevel = PerformanceManager.LODLevel
  return Game.PerformanceManager:GetLODEffect(RolePartObj.gameObject, display and _LODLevel.High or _LODLevel.Mid)
end
