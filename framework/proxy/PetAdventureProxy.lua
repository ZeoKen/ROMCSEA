autoImport("PetAdventureItemData")
PetAdventureProxy = class("PetAdventureProxy", pm.Proxy)
PetAdventureProxy.Instance = nil
PetAdventureProxy.NAME = "PetAdventureProxy"
PetAdventureProxy.QuestPhase = {
  NONE = ScenePet_pb.EPETADVENTURESTATUS_MIN,
  MATCH = ScenePet_pb.EPETADVENTURESTATUS_CANACCEPT,
  UNDERWAY = ScenePet_pb.EPETADVENTURESTATUS_ACCEPT,
  FINISHED = ScenePet_pb.EPETADVENTURESTATUS_COMPLETE,
  SUBMIT = ScenePet_pb.EPETADVENTURESTATUS_SUBMIT,
  Activity = 5
}
PetAdventureProxy.PETPHASE = {
  NONE = 0,
  MATCH = 1,
  UNDERWAY = 2,
  FIGHTING = 3
}

function PetAdventureProxy:ctor(proxyName, data)
  self.proxyName = proxyName or PetAdventureProxy.NAME
  if PetAdventureProxy.Instance == nil then
    PetAdventureProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:ResetData()
end

function PetAdventureProxy:ResetData()
  self.questData = {}
  self.recvQuestComplete = true
  self.chooseQuestData = {}
  self:ResetPetClickIndex()
  self.questTimes = {}
end

function PetAdventureProxy:GetBattlePet(petData)
  self.battlePet = {}
  for i = 1, #petData do
    local itemInfo = petData[i].base
    local item = ItemData.new(itemInfo.guid, itemInfo.id)
    local PetInfo = PetEggInfo.new(item.staticData)
    PetInfo:Server_SetData(petData[i].egg)
    PetInfo.guid = itemInfo.guid
    table.insert(self.battlePet, PetInfo)
  end
end

local CheckInvalid = function(questId)
  if Table_FuncState[131] and not FunctionUnLockFunc.checkFuncStateValid(131) and 0 ~= TableUtility.ArrayFindIndex(Table_FuncState[131].Param, questId) then
    return true
  end
  return false
end

function PetAdventureProxy:SetQuestData(serviceQuestData, times, finished)
  if self.recvQuestComplete then
    self.questData = {}
  end
  self.recvQuestComplete = finished
  for i = 1, #serviceQuestData do
    if not CheckInvalid(serviceQuestData[i].id) then
      local data = PetAdventureItemData.new()
      data:SetData(serviceQuestData[i])
      table.insert(self.questData, data)
    end
  end
  if times then
    if #times <= 0 then
      TableUtility.TableClear(self.questTimes)
    else
      for i = 1, #times do
        self.questTimes[times[i].id] = times[i].times
      end
    end
  else
    TableUtility.TableClear(self.questTimes)
  end
  table.sort(self.questData, function(l, r)
    return self:_sortPetQuest(l, r)
  end)
end

function PetAdventureProxy:_sortPet(l, r)
  if l == nil or r == nil then
    return false
  end
  local leftLocked = self:bPetlocked(l)
  local rightLocked = self:bPetlocked(r)
  local leftLevelLocked = self:bLevelLocked(l)
  local rightLevelLocked = self:bLevelLocked(r)
  local leftFriLocked = self:bFriendlyLocked(l)
  local rightFriLocked = self:bFriendlyLocked(r)
  local leftUnderway = l.phase == PetAdventureProxy.PETPHASE.UNDERWAY
  local rightUnderway = r.phase == PetAdventureProxy.PETPHASE.UNDERWAY
  local leftFighting = l.phase == PetAdventureProxy.PETPHASE.FIGHTING
  local rightFighting = r.phase == PetAdventureProxy.PETPHASE.FIGHTING
  if not leftLocked and not rightLocked then
    return l.petid > r.petid
  end
  if not leftLocked or not rightLocked then
    return not leftLocked
  end
  if leftUnderway or rightUnderway then
    return leftUnderway and not rightUnderway
  end
  if leftFighting or rightFighting then
    return leftFighting and not rightFighting
  end
  if leftFriLocked or rightFriLocked then
    return leftFriLocked and not rightFriLocked
  end
  if leftLevelLocked or rightLevelLocked then
    return leftLevelLocked and not rightLevelLocked
  end
  return l.petid > r.petid
end

function PetAdventureProxy:_sortPetQuest(l, r)
  if l == nil or r == nil then
    return false
  end
  local lState = l.statusSortID
  local rState = r.statusSortID
  local lType = l.staticData.QuestType
  local rType = r.staticData.QuestType
  local lLv = l.staticData.Level
  local rLv = r.staticData.Level
  local lId = l.id
  local rId = r.id
  if lState == rState then
    if lType == rType then
      if lLv == rLv then
        return lId > rId
      else
        return lLv > rLv
      end
    else
      return lType < rType
    end
  else
    return lState > rState
  end
end

function PetAdventureProxy:GetQuestData()
  return self.questData
end

function PetAdventureProxy:HandleQuestResultData(item, time)
  UIMultiModelUtil.Instance:RemoveModels()
  if time then
    self.questTimes[time.id] = time.times
  end
  local data = PetAdventureItemData.new()
  data:SetData(item)
  for i = 1, #self.questData do
    if self.questData[i].id == data.id then
      if data.status == PetAdventureProxy.QuestPhase.SUBMIT then
        table.remove(self.questData, i)
        break
      elseif data.status == PetAdventureProxy.QuestPhase.UNDERWAY then
        self.questData[i] = data
        break
      end
    end
  end
  table.sort(self.questData, function(l, r)
    return self:_sortPetQuest(l, r)
  end)
end

function PetAdventureProxy:GetLeftAdventureTime(id)
  local total = Table_Pet_Adventure[id] and Table_Pet_Adventure[id].DailyAdventureCount
  if total then
    local times = self.questTimes[id]
    return times and total - times or total
  end
end

function PetAdventureProxy:SetIllustratedRewardNameData(data)
  self.IllustratedRewardNameData = data
end

function PetAdventureProxy:GetTimes(id)
  return self.questTimes[id]
end

function PetAdventureProxy:GetIllustratedRewardNameData()
  if self.IllustratedRewardNameData then
    return self.IllustratedRewardNameData
  else
    return nil
  end
end

function PetAdventureProxy:HandleFinished()
  UIMultiModelUtil.Instance:RemoveModels()
  for i = 1, #self.questData do
    if self.questData[i].id == self.chooseQuestData.id then
      self.questData[i].status = PetAdventureProxy.QuestPhase.FINISHED
      return self.questData[i]
    end
  end
end

function PetAdventureProxy:SetChooseQuestData(data)
  self.chooseQuestData = data
end

function PetAdventureProxy:GetChooseQuestData()
  return self.chooseQuestData
end

function PetAdventureProxy:ResetPetClickIndex()
  self.clickPetIndex = nil
end

function PetAdventureProxy:bPetlocked(petData)
  local bLevelLocked = self:bLevelLocked(petData)
  local bFriendlyLocked = self:bFriendlyLocked(petData)
  local petState = petData.phase
  local lock = bLevelLocked or bFriendlyLocked or petState == PetAdventureProxy.PETPHASE.UNDERWAY or petState == PetAdventureProxy.PETPHASE.FIGHTING
  return lock
end

function PetAdventureProxy:bLevelLocked(petData)
  local staticLv = self.chooseQuestData.staticData.Level
  local petLv = petData.lv
  return staticLv > petLv
end

function PetAdventureProxy:bFriendlyLocked(petData)
  return petData.friendlv < GameConfig.PetAdventureMinLimit.limit_friendly_lv
end

function PetAdventureProxy:GetOwnPetsData()
  local allPets = {}
  if self.battlePet then
    for i = 1, #self.battlePet do
      self.battlePet[i].phase = PetAdventureProxy.PETPHASE.FIGHTING
      table.insert(allPets, self.battlePet[i])
    end
  end
  local bagPet = BagProxy.Instance:GetMyPetEggs()
  if bagPet then
    for i = 1, #bagPet do
      local pet = bagPet[i].petEggInfo
      pet.phase = PetAdventureProxy.PETPHASE.MATCH
      pet.guid = bagPet[i].id
      table.insert(allPets, pet)
    end
  end
  for i = 1, #self.questData do
    local data = self.questData[i]
    if data and data.status == PetAdventureProxy.QuestPhase.UNDERWAY or data.status == PetAdventureProxy.QuestPhase.FINISHED then
      local petEggs = data.petEggs
      if petEggs then
        for j = 1, #petEggs do
          if petEggs[j] and 0 ~= petEggs[j] then
            petEggs[j].phase = PetAdventureProxy.PETPHASE.UNDERWAY
            table.insert(allPets, petEggs[j])
          end
        end
      end
    end
  end
  table.sort(allPets, function(l, r)
    return self:_sortPet(l, r)
  end)
  return allPets
end

function PetAdventureProxy:SetMatchPetData(petInfo)
  local clickIndex = self.clickPetIndex
  for i = 1, #self.matchPetData do
    if 0 ~= self.matchPetData[i] and self.matchPetData[i].guid == petInfo.guid then
      self.matchPetData[i] = 0
      self:ResetPetClickIndex()
      return i
    end
  end
  if 0 == self.matchPetData[clickIndex] then
    self.matchPetData[clickIndex] = petInfo
    self:ResetPetClickIndex()
    return clickIndex
  end
  for i = 1, #self.matchPetData do
    if 0 == self.matchPetData[i] then
      self.matchPetData[i] = petInfo
      self:ResetPetClickIndex()
      return i
    end
  end
end

function PetAdventureProxy:bConditionLimit()
  local condit = self.chooseQuestData.staticData.Condition
end

function PetAdventureProxy:SetPetsData(petNum, petsData)
  UIMultiModelUtil.Instance:RemoveModels()
  self.matchPetData = {}
  if petsData and 0 < #petsData then
    for i = 1, #petsData do
      if "table" == type(petsData[i]) and 0 ~= petsData[i] then
        self.matchPetData[#self.matchPetData + 1] = petsData[i]
      end
    end
  else
    for i = 1, petNum do
      self.matchPetData[i] = 0
    end
  end
end

function PetAdventureProxy:bOverFlowPet(data)
  for i = 1, #self.matchPetData do
    local pet = self.matchPetData[i]
    if pet == 0 or pet.guid == data then
      return false
    end
  end
  return true
end

function PetAdventureProxy:GetMatchPetData()
  return self.matchPetData
end

function PetAdventureProxy:GetMatchNum()
  local num = 0
  for i = 1, #self.matchPetData do
    if self.matchPetData[i] and self.matchPetData[i] ~= 0 then
      num = num + 1
    end
  end
  return num
end

local maxFlagArray = {}

function PetAdventureProxy:GetFightEfficiency()
  if 0 == self:GetMatchNum() then
    return 0
  end
  local result = 0
  self.tipData = {}
  local matchPetData = self.matchPetData
  local chooseQuestData = self.chooseQuestData
  local lvLimit = chooseQuestData.staticData.Level
  local area = chooseQuestData.staticData.BigArea
  for i = 1, #matchPetData do
    if matchPetData[i] and 0 ~= matchPetData[i] and matchPetData[i].petid then
      local petLv = matchPetData[i].lv
      local blvdelta = petLv - lvLimit
      local flvdelta = matchPetData[i].friendlv
      local petId = matchPetData[i].petid
      local param = Table_Pet[petId] and Table_Pet[petId].Area[area]
      local petNum = chooseQuestData.staticData.PetNum
      local petEffData = {}
      local PetFunLv, PetFLv, areaEff
      PetFunLv, maxFlagArray[7] = PetFun.calcPetAdventureLvEff(blvdelta, petNum, petLv)
      PetFLv, maxFlagArray[8] = PetFun.calcPetAdventureFlyEff(flvdelta, petNum)
      areaEff, maxFlagArray[9] = PetFun.calcPetAdventureAreaEff(blvdelta, petNum, flvdelta, param, petLv)
      petEffData.name = Table_Monster[petId] and Table_Monster[petId].NameZh
      petEffData.lv = PetFunLv
      petEffData.flv = PetFLv
      petEffData.area = param
      self.tipData[#self.tipData + 1] = petEffData
      result = result + PetFunLv + PetFLv + areaEff
    end
  end
  local roleEff = {}
  local myselfData = Game.Myself.data
  roleEff.refineEff, maxFlagArray[1] = CommonFun.calcPetAdventure_RefineEfficiency(myselfData)
  roleEff.enchantEff, maxFlagArray[2] = CommonFun.calcPetAdventure_EnchantEfficiency(myselfData)
  roleEff.AstrolabeEff, maxFlagArray[3] = CommonFun.calcPetAdventure_XingpanEfficiency(myselfData)
  roleEff.adventureTitleEff, maxFlagArray[4] = CommonFun.calcPetAdventure_AdventureTitleEfficiency(myselfData)
  roleEff.cardEff, maxFlagArray[5] = CommonFun.calcPetAdventure_AdventureSavedCardEfficiency(myselfData)
  roleEff.headwearEff, maxFlagArray[6] = CommonFun.calcPetAdventure_AdventureSavedHeadWearEfficiency(myselfData)
  result = result + roleEff.refineEff + roleEff.enchantEff + roleEff.adventureTitleEff + roleEff.AstrolabeEff + roleEff.headwearEff + roleEff.cardEff
  self.tipData.role = roleEff
  self.tipData.maxEffConfig = maxFlagArray
  return result
end

local areaFilter = {}

function PetAdventureProxy:GetAreaFilter(filterData)
  TableUtility.ArrayClear(areaFilter)
  for k, v in pairs(filterData) do
    table.insert(areaFilter, k)
  end
  table.sort(areaFilter, function(l, r)
    return l < r
  end)
  return areaFilter
end

function PetAdventureProxy:GetQuestProcess()
  local result = 0
  for i = 1, #self.questData do
    local data = self.questData[i]
    if data and data.status == PetAdventureProxy.QuestPhase.UNDERWAY or data.status == PetAdventureProxy.QuestPhase.FINISHED then
      result = result + 1
    end
  end
  return result
end
