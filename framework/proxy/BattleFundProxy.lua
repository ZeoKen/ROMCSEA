autoImport("BattleFundData")
BattleFundProxy = class("BattleFundProxy", pm.Proxy)
BattleFundProxy.Instance = nil
BattleFundProxy.NAME = "BattleFundProxy"
BattleFundProxy.RedTipID = 10723

function BattleFundProxy:ctor(proxyName, data)
  self.proxyName = proxyName or BattleFundProxy.NAME
  if BattleFundProxy.Instance == nil then
    BattleFundProxy.Instance = self
  end
  if data ~= nil then
    self:setData(data)
  end
  self:Init()
end

function BattleFundProxy:Init()
  if GameConfig.SystemForbid.BattleFund then
    return
  end
end

function BattleFundProxy:IsActive()
  if self.actData then
    return self.actData:IsActive()
  end
  return false
end

function BattleFundProxy:GetActData()
  return self.actData
end

function BattleFundProxy:GetConfig()
  if self.actData then
    return self.actData:GetConfig()
  end
  return nil
end

function BattleFundProxy:RecvBattleFundInfo(serverData)
  if not serverData then
    return
  end
  local info = serverData and serverData.info
  if self.actData and self.actData.actId == info.activityid then
    self.actData:SetData(info)
  else
    self.actData = BattleFundData.new(info)
    if self.actData:IsActive() and not self.actData:HasPurchased() then
      local config = self.actData:GetConfig()
      if config then
        ServiceUserEventProxy.Instance:CallChargeQueryCmd(config.DepositID)
      end
    end
  end
  if self.actData:HasUntakenReward() then
    local lastRedTipTime = PlayerPrefs.GetInt("LastBattleFundRedTip", 0)
    local curTimeStamp = ServerTime.CurServerTime() / 1000
    if not ClientTimeUtil.IsSameDay(lastRedTipTime, curTimeStamp) then
      RedTipProxy.Instance:UpdateRedTip(BattleFundProxy.RedTipID)
      PlayerPrefs.SetInt("LastBattleFundRedTip", curTimeStamp)
    end
  else
    RedTipProxy.Instance:RemoveWholeTip(BattleFundProxy.RedTipID)
  end
end

function BattleFundProxy:TakeReward(day, free)
  local actId = self.actData and self.actData:GetActId()
  if actId then
    ServiceActivityCmdProxy.Instance:CallBattleFundRewardActCmd(actId, day, free)
  end
end

function BattleFundProxy:HasPurchased()
  return self.actData and self.actData:HasPurchased()
end

function BattleFundProxy:CanPurchase()
  return self.actData and self.actData:CanPurchase()
end

function BattleFundProxy:GetLeftBuyTime()
  if not self.actData then
    return 0
  end
  return self.actData:GetLeftBuyTime()
end

function BattleFundProxy:GetRewardDatas()
  return self.actData and self.actData:GetRewardDatas() or {}
end

function BattleFundProxy:RecvQueryChargeCnt(serverData)
  if self.actData then
    self.actData:UpdatePurchaseCnt(serverData)
  end
end

function BattleFundProxy:RecvChargeQueryCmd(serverData)
  if self.actData then
    self.actData:RecvChargeQueryCmd(serverData)
  end
end

function BattleFundProxy:GetTakableRewards()
  if self.actData then
    return self.actData:GetTakableRewards()
  end
  return 0
end
