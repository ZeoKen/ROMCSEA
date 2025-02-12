EquipUtil = {}
local ZENY = GameConfig.MoneyId.Zeny
local _Prefix = "Material_"
local InsertOrAddNum = function(array, item, idKey, numKey)
  if type(array) ~= "table" or type(item) ~= "table" then
    return
  end
  idKey = idKey or "id"
  numKey = numKey or "num"
  for _, i in pairs(array) do
    if i[idKey] == item[idKey] then
      i[numKey] = i[numKey] + item[numKey]
      return
    end
  end
  local copy = {}
  TableUtility.TableShallowCopy(copy, item)
  TableUtility.ArrayPushBack(array, copy)
end

function EquipUtil.CalcEquipUpgradeCost(id, count)
  local num = count or 0
  local upgradeData = Table_EquipUpgrade[id]
  if not upgradeData and num ~= 0 then
    redlog("Func CalcEquipUpgradeCost()--> Table_EquipUpgrade staticData is nil ,error EquipID: ", id)
    return
  end
  local result = {}
  local selfcost = {id = id, num = 1}
  InsertOrAddNum(result, selfcost)
  local costZeny = 0
  local cost, tempId
  local costTab = {}
  for i = 1, count do
    cost = upgradeData[_Prefix .. i]
    if cost then
      for i = 1, #cost do
        tempId = cost[i].id
        if tempId ~= ZENY then
          InsertOrAddNum(result, cost[i])
        else
          costZeny = costZeny + cost[i].num
        end
      end
    end
  end
  redlog("EquipUtil.CalcEquipUpgradeCost result: ", result, costZeny)
  return result, costZeny
end

function EquipUtil.GetRecoverCost(itemData, card_rv, upgrade_rv, strength_rv, enchant_rv, strength_rv2, ignoreVIP, quench_rv)
  if itemData == nil then
    return 0
  end
  local recoverConfig = GameConfig.EquipRecover
  local resultCost = 0
  local _card_needRv, _upgrade_needRv, _strength_needRv, _enchant_needRv, _strength2_needRv, _quench_needRv
  if card_rv and (not NewRechargeProxy.Ins:AmIMonthlyVIP() or ignoreVIP) then
    local equipCards = itemData.equipedCardInfo
    if equipCards and 0 < #equipCards then
      local maxIndex = #recoverConfig.Card
      for k, v in pairs(equipCards) do
        local q = v.cardInfo.Quality
        q = math.clamp(q, 1, maxIndex)
        resultCost = resultCost + recoverConfig.Card[q]
        _card_needRv = true
      end
    end
  end
  if upgrade_rv then
    local equiplv = itemData.equipInfo.equiplv
    if 0 < equiplv then
      equiplv = math.clamp(equiplv, 1, #recoverConfig.Upgrade)
      resultCost = resultCost + recoverConfig.Upgrade[equiplv]
      _upgrade_needRv = true
    end
  end
  local strength_addCost = false
  if strength_rv and 0 < itemData.equipInfo.strengthlv then
    strength_addCost = true
    resultCost = resultCost + recoverConfig.Strength
    _strength_needRv = true
  end
  if strength_rv2 and strength_addCost == false and 0 < itemData.equipInfo.strengthlv2 then
    resultCost = resultCost + recoverConfig.Strength
    _strength2_needRv = true
  end
  if enchant_rv and itemData.enchantInfo and itemData.enchantInfo:HasAttri() then
    resultCost = resultCost + recoverConfig.Enchant
    _enchant_needRv = true
  end
  if quench_rv and itemData:HasQuench() then
    resultCost = resultCost + recoverConfig.Quench
    _quench_needRv = true
  end
  return resultCost, _card_needRv, _upgrade_needRv, _strength_needRv, _strength2_needRv, _enchant_needRv, _quench_needRv
end
