PetFun = {}
PetFun.Max = {
  lv = 1.3,
  flv = 1.7,
  area = 1
}
PetFriendRatio = {
  [1] = {
    0,
    0,
    0,
    0,
    0.01,
    0.01,
    0.01,
    0.015,
    0.015,
    0.03
  },
  [2] = {
    0,
    0,
    0,
    0,
    0.01,
    0.01,
    0.01,
    0.025,
    0.025,
    0.05
  },
  [3] = {
    0,
    0,
    0,
    0,
    0.025,
    0.025,
    0.025,
    0.05,
    0.05,
    0.1
  },
  [4] = {
    0,
    0,
    0,
    0,
    0.05,
    0.05,
    0.05,
    0.1,
    0.1,
    0.2
  },
  [5] = {
    0,
    0,
    0,
    0,
    0.1,
    0.1,
    0.1,
    0.2,
    0.2,
    0.4
  },
  [6] = {
    0,
    0,
    0,
    0,
    0.15,
    0.15,
    0.15,
    0.3,
    0.3,
    0.6
  },
  [7] = {
    0,
    0,
    0,
    0,
    0.2,
    0.2,
    0.2,
    0.4,
    0.4,
    0.8
  }
}
local MIN_SEC = 60
local DAY_SEC = 86400
local GetSkillParam = function(spaceid, skillid)
  local sparam
  if skillid and skillid ~= 0 then
    local skillcfg = Table_Skill[skillid]
    if not skillcfg then
      return nil
    end
    local skill_SkillSpace = skillcfg.Logic_Param.SkillSpace
    if not skill_SkillSpace then
      return nil
    end
    local skill_SkillValue = skillcfg.Logic_Param.SkillValue
    if not skill_SkillValue then
      return nil
    end
    if spaceid == skill_SkillSpace then
      sparam = skill_SkillValue
    else
      sparam = 0
    end
  end
  return sparam
end
local GetFriendlyParam = function(petid, petfriendlv)
  local petcfg = Table_Pet[petid]
  if not petcfg then
    return 0
  end
  local FriendRatio = petcfg.PetFriend
  if not FriendRatio then
    return 0
  elseif FriendRatio == 0 then
    FriendRatio = 1
  elseif 7 < FriendRatio then
    FriendRatio = 7
  end
  if petfriendlv == nil or 10 < petfriendlv then
    return 0
  end
  local flparam = PetFriendRatio[FriendRatio][petfriendlv]
  if flparam == nil then
    flparam = 0
  end
  return flparam
end
local GetLvParam = function(petbaselv, spaceid)
  local spacecfg = Table_Pet_WorkSpace[spaceid]
  if not spacecfg or not spacecfg.Frequency then
    return 0
  end
  petbaselv = petbaselv - spacecfg.Level
  if petbaselv < 0 then
    return 0
  end
  return petbaselv * 5.0E-4
end

function PetFun.getPetAdventureBLvParam(deltalv)
  if 0 <= deltalv and deltalv < 10 then
    return 1, 0.02
  elseif 10 <= deltalv and deltalv < 20 then
    return 1.1, 0.01
  elseif 20 <= deltalv and deltalv < 30 then
    return 1.2, 0.01
  elseif 30 <= deltalv and deltalv < 40 then
    return 1.3, 0.01
  elseif 40 <= deltalv and deltalv < 50 then
    return 1.3, 0
  elseif 50 <= deltalv and deltalv < 60 then
    return 1.3, 0
  elseif 60 <= deltalv and deltalv < 70 then
    return 1.3, 0
  elseif 70 <= deltalv and deltalv < 80 then
    return 1.3, 0
  elseif 80 <= deltalv and deltalv < 90 then
    return 1.3, 0
  elseif 90 <= deltalv and deltalv <= 100 then
    return 1.3, 0
  end
  return 1.3, 0
end

function PetFun.getPetAdventureFLvParam(deltalv)
  if 0 <= deltalv and deltalv < 1 then
    return 1
  elseif 1 <= deltalv and deltalv < 2 then
    return 1
  elseif 2 <= deltalv and deltalv < 3 then
    return 1.1
  elseif 3 <= deltalv and deltalv < 4 then
    return 1.15
  elseif 4 <= deltalv and deltalv < 5 then
    return 1.2
  elseif 5 <= deltalv and deltalv < 6 then
    return 1.35
  elseif 6 <= deltalv and deltalv < 7 then
    return 1.4
  elseif 7 <= deltalv and deltalv < 8 then
    return 1.45
  elseif 8 <= deltalv and deltalv < 9 then
    return 1.5
  elseif 9 <= deltalv and deltalv < 10 then
    return 1.6
  elseif 10 <= deltalv and deltalv < 11 then
    return 1.7
  end
  return 1
end

local isMax

function PetFun.calcPetAdventureLvEff(blvdelta, maxpet, petlv)
  local blv, blvparam = PetFun.getPetAdventureBLvParam(blvdelta)
  if maxpet == 0 then
    maxpet = 1
  end
  isMax = blv >= PetFun.Max.lv
  return (blv + petlv % 10 * blvparam) * 0.5 / maxpet, isMax
end

function PetFun.calcPetAdventureFlyEff(flvdelta, maxpet)
  local flv = PetFun.getPetAdventureFLvParam(flvdelta)
  if maxpet == 0 then
    maxpet = 1
  end
  isMax = flv >= PetFun.Max.flv
  return flv * 0.5 / maxpet, isMax
end

function PetFun.calcPetAdventureAreaEff(blvdelta, maxpet, flvdelta, param, petlv)
  local lveff = PetFun.calcPetAdventureLvEff(blvdelta, maxpet, petlv)
  local flyeff = PetFun.calcPetAdventureFlyEff(flvdelta, maxpet)
  isMax = 1 <= param
  return (lveff + flyeff) * (param - 1), isMax
end

function PetFun.getPetAdventureBaseExpParam(adventurelv, petblv)
  local param = {
    [11] = 1,
    [12] = 1.1,
    [13] = 1.3,
    [14] = 1.6,
    [15] = 1.9,
    [16] = 2.2,
    [17] = 2.5,
    [18] = 2.8,
    [19] = 3.1,
    [20] = 3.4,
    [21] = 1,
    [22] = 1.1,
    [23] = 1.2,
    [24] = 1.3,
    [25] = 1.4,
    [26] = 1.5,
    [27] = 1.6,
    [28] = 1.7,
    [29] = 1.8,
    [30] = 1.9,
    [31] = 1,
    [32] = 1.07,
    [33] = 1.15,
    [34] = 1.24,
    [35] = 1.34,
    [36] = 1.45,
    [37] = 1.57,
    [38] = 1.71,
    [39] = 1.85,
    [40] = 2.01,
    [41] = 1,
    [42] = 1.1,
    [43] = 1.23,
    [44] = 1.37,
    [45] = 1.4,
    [46] = 1.5,
    [47] = 1.6,
    [48] = 1.25,
    [49] = 1.3,
    [50] = 1.35,
    [51] = 1,
    [52] = 1.63,
    [53] = 1.67,
    [54] = 1.02,
    [55] = 1.43,
    [56] = 1.47,
    [57] = 1.52,
    [58] = 1.56,
    [59] = 1.61,
    [60] = 1.58,
    [61] = 1,
    [62] = 1.03,
    [63] = 1.05,
    [64] = 1.04,
    [65] = 1.06,
    [66] = 1.09,
    [67] = 1.07,
    [68] = 1.1,
    [69] = 1.12,
    [70] = 1.13,
    [71] = 1,
    [72] = 0.94,
    [73] = 0.92,
    [74] = 0.95,
    [75] = 0.97,
    [76] = 0.99,
    [77] = 1.01,
    [78] = 1.03,
    [79] = 1.05,
    [80] = 1.07,
    [81] = 1,
    [82] = 0.94,
    [83] = 0.96,
    [84] = 0.99,
    [85] = 1.01,
    [86] = 1.03,
    [87] = 1.06,
    [88] = 1.08,
    [89] = 1.1,
    [90] = 1.17,
    [91] = 1,
    [92] = 1.03,
    [93] = 1.05,
    [94] = 1.08,
    [95] = 1.11,
    [96] = 1.14,
    [97] = 1.06,
    [98] = 1.08,
    [99] = 1.1
  }
  if 11 <= adventurelv and adventurelv <= 20 then
    if param[petblv] == nil then
      return param[20]
    end
    return param[petblv]
  elseif 21 <= adventurelv and adventurelv <= 29 then
    if param[petblv] == nil then
      return param[29]
    end
    return param[petblv]
  elseif 30 <= adventurelv and adventurelv <= 39 then
    if param[petblv] == nil then
      return param[39]
    end
    return param[petblv]
  elseif 40 <= adventurelv and adventurelv <= 49 then
    if param[petblv] == nil then
      return param[49]
    end
    return param[petblv]
  elseif 50 <= adventurelv and adventurelv <= 59 then
    if param[petblv] == nil then
      return param[59]
    end
    return param[petblv]
  elseif 60 <= adventurelv and adventurelv <= 69 then
    if param[petblv] == nil then
      return param[69]
    end
    return param[petblv]
  elseif 70 <= adventurelv and adventurelv <= 79 then
    if param[petblv] == nil then
      return param[79]
    end
    return param[petblv]
  elseif 80 <= adventurelv and adventurelv <= 89 then
    if param[petblv] == nil then
      return param[89]
    end
    return param[petblv]
  elseif 90 <= adventurelv and adventurelv <= 99 then
    if param[petblv] == nil then
      return param[99]
    end
    return param[petblv]
  end
  return 0
end

function PetFun.calcPetAdventureBaseExp(adventureexp, roleexp, adventurelv, petblv, maxpet)
  if maxpet == 0 then
    maxpet = 1
  end
  return adventureexp * PetFun.getPetAdventureBaseExpParam(adventurelv, petblv) + roleexp / maxpet
end

function PetFun.calcPetWorkMaxReward(start_time, end_time, max_reward)
  local max_continue_day = GameConfig.PetWorkSpace.pet_work_continue_day
  local curDay = os.date("*t", end_time)
  if nil == start_time or 0 == start_time then
    return max_reward
  end
  local startDate = os.date("*t", start_time)
  local startRefreshTime = os.time({
    year = startDate.year,
    month = startDate.month,
    day = startDate.day,
    hour = 5
  })
  local curRefreshTime = os.time({
    year = curDay.year,
    month = curDay.month,
    day = curDay.day,
    hour = 5
  })
  local multiple = (curRefreshTime - startRefreshTime) / DAY_SEC
  multiple = start_time < startRefreshTime and multiple + 1 or multiple
  multiple = end_time > curRefreshTime and multiple + 1 or multiple
  multiple = math.min(max_continue_day, multiple)
  return math.floor(multiple) * max_reward
end

function PetFun.calcPetWorkRewardCount(starttime, endtime, frequency, maxreward, lastcount)
  if frequency == 0 then
    return 0
  end
  local n = 0
  local result = 0
  local date = os.date("*t", starttime)
  local dayfive = os.time({
    year = date.year,
    month = date.month,
    day = date.day,
    hour = 5
  })
  local daynextfive = dayfive + DAY_SEC
  local endt = 0
  if starttime < dayfive then
    if endtime <= dayfive then
      endt = endtime
    else
      endt = dayfive
    end
    local r = (endt - starttime) / 60 / frequency
    local curmax = maxreward
    if lastcount <= maxreward then
      curmax = maxreward - lastcount
    end
    if r > curmax then
      result = result + curmax
    else
      result = result + r
    end
  else
    if endtime <= daynextfive then
      endt = endtime
    else
      endt = daynextfive
    end
    local r = (endt - starttime) / 60 / frequency
    local curmax = maxreward
    if lastcount <= maxreward then
      curmax = maxreward - lastcount
    end
    if r > curmax then
      result = result + curmax
    else
      result = result + r
    end
    n = 1
  end
  while true do
    local day = starttime + n * DAY_SEC
    local date = os.date("*t", day)
    local dayfive = os.time({
      year = date.year,
      month = date.month,
      day = date.day,
      hour = 5
    })
    local daynextfive = dayfive + DAY_SEC
    if endtime <= dayfive then
      break
    end
    if endtime > daynextfive then
      local r = (daynextfive - dayfive) / 60 / frequency
      if maxreward < r then
        result = result + maxreward
      else
        result = result + r
      end
    else
      local r = (endtime - dayfive) / 60 / frequency
      if maxreward < r then
        result = result + maxreward
      else
        result = result + r
      end
    end
    n = n + 1
  end
  return result
end

function PetFun.calcPlayTimeRewardCount(spaceid, petid, petbaselv, petfriendlv, skillid)
  local spacecfg = Table_Pet_WorkSpace[spaceid]
  if not spacecfg then
    return 0
  end
  local playTimeRewardRatio = spacecfg.PlayTimeRewardRatio
  if not (playTimeRewardRatio and next(playTimeRewardRatio)) or #playTimeRewardRatio ~= 2 then
    return 0
  end
  local ratio = playTimeRewardRatio[2]
  local sparam = GetSkillParam(spaceid, skillid)
  local flparam = GetFriendlyParam(petid, petfriendlv)
  local lvparam = GetLvParam(petbaselv, spaceid)
  local totalRatio
  if nil == sparam then
    totalRatio = 0
  else
    totalRatio = sparam + flparam + lvparam
  end
  return math.floor(ratio * (1 + totalRatio))
end

function PetFun.calcPetWorkFrequency(petid, petbaselv, petfriendlv, spaceid, skillid)
  local spacecfg = Table_Pet_WorkSpace[spaceid]
  if spacecfg == nil or spacecfg.Frequency == nil then
    return 0
  end
  local sparam = 0
  if skillid ~= 0 then
    local skillcfg = Table_Skill[skillid]
    if skillcfg == nil then
      return 0
    end
    local skill_SkillSpace = skillcfg.Logic_Param.SkillSpace
    if skill_SkillSpace == nil then
      return 0
    end
    local skill_SkillValue = skillcfg.Logic_Param.SkillValue
    if skill_SkillValue == nil then
      return 0
    end
    if spaceid == skill_SkillSpace then
      sparam = skill_SkillValue
    end
  end
  local petcfg = Table_Pet[petid]
  if petcfg == nil then
    return 0
  end
  local FriendRatio = petcfg.PetFriend
  if FriendRatio == nil then
    return 0
  elseif FriendRatio == 0 then
    FriendRatio = 1
  elseif 7 < FriendRatio then
    FriendRatio = 7
  end
  if petfriendlv == nil or 10 < petfriendlv then
    return 0
  end
  local flparam = PetFriendRatio[FriendRatio][petfriendlv]
  if flparam == nil then
    flparam = 0
  end
  petbaselv = petbaselv - spacecfg.Level
  if petbaselv < 0 then
    return 0
  end
  local lvparam = petbaselv * 5.0E-4
  local result = spacecfg.Frequency / (1 + sparam + flparam + lvparam)
  return result
end

function PetFun.calcDuringTime(startTime, curTime, frequency, rewardcount, daymaxreward, lastcount)
  if startTime == 0 or curTime == 0 or frequency == 0 or rewardcount == 0 or daymaxreward == 0 then
    return 0
  end
  local date = os.date("*t", startTime)
  local dayfive = os.time({
    year = date.year,
    month = date.month,
    day = date.day,
    hour = 5
  })
  local daynextfive = dayfive + DAY_SEC
  local result = 0
  local reward_endtime = 0
  local day_max_time = frequency * MIN_SEC * daymaxreward
  if day_max_time >= DAY_SEC then
    reward_endtime = startTime + rewardcount * frequency * MIN_SEC
  elseif curTime < daynextfive then
    reward_endtime = startTime + rewardcount * frequency * MIN_SEC
  else
    local date = os.date("*t", curTime)
    local day_cur_five = os.time({
      year = date.year,
      month = date.month,
      day = date.day,
      hour = 5
    })
    if curTime >= day_cur_five then
      local cur_reward_count = PetFun.calcPetWorkRewardCount(startTime, day_cur_five, frequency, daymaxreward, lastcount)
      if rewardcount >= cur_reward_count then
        reward_endtime = day_cur_five + (rewardcount - cur_reward_count) * frequency * MIN_SEC
      end
    else
      local cur_reward_count = PetFun.calcPetWorkRewardCount(startTime, day_cur_five - DAY_SEC, frequency, daymaxreward, lastcount)
      if rewardcount >= cur_reward_count then
        reward_endtime = day_cur_five + (rewardcount - cur_reward_count) * frequency * MIN_SEC
      end
    end
  end
  if curTime >= reward_endtime then
    result = curTime - reward_endtime
  end
  if result > frequency * MIN_SEC then
    result = 0
  end
  return result
end

function test()
  local starttime = 1524717820
  local endtime = 1524720978
  local frequency = 21
  local daymaxreward = 95
  local lastcount = 24
  local count = PetFun.calcPetWorkRewardCount(starttime, endtime, frequency, daymaxreward, lastcount)
  count = math.floor(count)
  PetFun.calcDuringTime(starttime, endtime, frequency, count, daymaxreward, lastcount)
end
