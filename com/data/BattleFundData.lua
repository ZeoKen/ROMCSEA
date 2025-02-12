BattleFundData = class("BattleFundData")
local RewardState = {
  UnTaken = 1,
  CannotTake = 2,
  Taken = 3
}
BattleFundData.RewardState = RewardState

function BattleFundData:ctor(serverData)
  self:SetData(serverData)
end

function BattleFundData:SetData(serverData)
  if not serverData or not GameConfig.BattleFund then
    return
  end
  self.actId = serverData.activityid
  self.startTime = serverData.starttime or 0
  self.buyTime = serverData.buytime or 0
  self.loginDay = serverData.loginday or 0
  self.rewardDays = serverData.rewarddays
  self.freeRewardDays = serverData.freerewarddays
  local config = GameConfig.BattleFund[self.actId]
  if not config then
    return
  end
  if not self.rewardDatas then
    self.rewardDatas = {}
    for i, v in pairs(config.Reward) do
      table.insert(self.rewardDatas, {
        day = i,
        itemId = v[1][1],
        itemNum = v[1][2],
        free = false
      })
    end
    if config.FreeReward and next(config.FreeReward) then
      table.insert(self.rewardDatas, {free = true})
    end
  end
  if self.rewardDatas then
    for _, v in ipairs(self.rewardDatas) do
      if v.free == true then
        local nextState = RewardState.Taken
        local nextFreeDay = v.day
        for day, freeReward in pairs(config.FreeReward) do
          if table.ContainsValue(self.freeRewardDays, day) then
            if not nextFreeDay or day > nextFreeDay then
              nextFreeDay = day
              nextState = RewardState.Taken
            end
          elseif not nextFreeDay or nextState == RewardState.Taken or day < nextFreeDay then
            nextFreeDay = day
            if day <= self.loginDay then
              nextState = RewardState.UnTaken
            else
              nextState = RewardState.CannotTake
            end
          end
        end
        if nextFreeDay then
          v.day = nextFreeDay
          v.state = nextState
          local freeConfig = config.FreeReward[nextFreeDay]
          v.itemId = freeConfig[1][1]
          v.itemNum = freeConfig[1][2]
        end
      elseif table.ContainsValue(self.rewardDays, v.day) then
        v.state = RewardState.Taken
      elseif self.loginDay >= v.day then
        v.state = RewardState.UnTaken
      else
        v.state = RewardState.CannotTake
      end
    end
  end
  self:SortRewardDatas()
end

function BattleFundData:GetTakableRewards()
  local config = GameConfig.BattleFund[self.actId]
  if not config then
    return 0
  end
  local total = 0
  for day, reward in pairs(config.Reward) do
    if day <= self.loginDay and (not self.rewardDays or not table.ContainsValue(self.rewardDays, day)) then
      total = total + reward[1][2]
    end
  end
  return total
end

function BattleFundData:SortRewardDatas()
  if not self.rewardDatas then
    return
  end
  table.sort(self.rewardDatas, function(a, b)
    if a.free then
      return a.state ~= RewardState.Taken
    elseif b.free then
      return b.state == RewardState.Taken
    elseif a.state ~= b.state then
      return a.state < b.state
    else
      return a.day < b.day
    end
  end)
end

function BattleFundData:GetRewardDatas()
  return self.rewardDatas
end

function BattleFundData:HasUntakenReward()
  if not self.rewardDatas then
    return false
  end
  for _, v in ipairs(self.rewardDatas) do
    if v.state == RewardState.UnTaken then
      return true
    end
  end
  return false
end

function BattleFundData:GetActId()
  return self.actId
end

function BattleFundData:GetConfig()
  if GameConfig.BattleFund and self.actId then
    return GameConfig.BattleFund[self.actId]
  end
  return nil
end

function BattleFundData:IsActive()
  local config = self:GetConfig()
  if not config then
    return false
  end
  if not self.startTime or self.startTime <= 0 then
    return false
  end
  if not self.rewardDatas or self.rewardDays and #self.rewardDays >= #self.rewardDatas then
    return false
  end
  if (not self.buyTime or self.buyTime == 0) and ServerTime.CurServerTime() / 1000 > self.startTime + config.BuyLimitTime then
    return false
  end
  return true
end

function BattleFundData:CanPurchase()
  if self.canPurchase == false or self.purchaseCnt and self.purchaseCnt > 0 then
    return false
  end
  return true
end

function BattleFundData:UpdatePurchaseCnt(serverData)
  if not serverData or not serverData.info then
    return
  end
  local config = self:GetConfig()
  if not config then
    return
  end
  local depositId = config.DepositID
  for _, v in ipairs(serverData.info) do
    if v.dataid == depositId then
      self.purchaseCnt = v.count
      self.purchaseLimit = v.limit
      break
    end
  end
end

function BattleFundData:RecvChargeQueryCmd(serverData)
  if not serverData then
    return
  end
  local config = self:GetConfig()
  if not config then
    return
  end
  local depositId = config.DepositID
  if depositId == serverData.data_id then
    self.purchaseCnt = serverData.charged_count or 0
    self.canPurchase = serverData.ret
  end
end

function BattleFundData:HasPurchased()
  return self.buyTime and self.buyTime > 0 and true or false
end

function BattleFundData:GetLeftBuyTime()
  local config = self:GetConfig()
  if not config then
    return 0
  end
  return self.startTime + config.BuyLimitTime - ServerTime.CurServerTime() / 1000
end
