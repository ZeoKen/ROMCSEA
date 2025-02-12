UIModelZenyShop = class("UIModelZenyShop")
UIModelZenyShop.luckyBagConfType = {Deposit = 0, Shop = 1}

function UIModelZenyShop:Ins()
  if UIModelZenyShop.ins == nil then
    UIModelZenyShop.ins = UIModelZenyShop.new()
  end
  return UIModelZenyShop.ins
end

function UIModelZenyShop:ctor()
  self.luckyBagPurchaseTimes = {}
  self.luckyBagPurchaseLimits = {}
  self:SetLuckyBagPurchaseTimesZero()
  self:SetLuckyBagPurchaseLimitsZero()
  self:SetLuckyBagBatchInfo()
end

function UIModelZenyShop:SetLuckyBagPurchaseTimes(lucky_bag_conf_id, times)
  self.luckyBagPurchaseTimes[lucky_bag_conf_id] = times
end

function UIModelZenyShop:SetLuckyBagPurchaseLimit(lucky_bag_conf_id, limit)
  helplog("SetLuckyBagPurchaseLimit:", lucky_bag_conf_id, limit)
  self.luckyBagPurchaseLimits[lucky_bag_conf_id] = limit
end

function UIModelZenyShop:SetLuckyBagBatchDailyCount(lucky_bag_conf_id, dailycount)
  helplog("SetLuckyBagBatchDailyCount:", lucky_bag_conf_id, dailycount)
  self.luckyBagPurchaseBatchDailyCount[lucky_bag_conf_id] = dailycount
end

function UIModelZenyShop:SetLuckyBagBatchInfo()
  self.luckyBagPurchaseBatchDailyCount = {}
  self.originToBatchProduct = {}
  self.batchToOriginProduct = {}
  for k, v in pairs(Table_Deposit) do
    local productID = k
    local productConf = v
    if productConf.OriginId and Table_Deposit[productConf.OriginId] then
      self.originToBatchProduct[productConf.OriginId] = productID
      self.batchToOriginProduct[productID] = productConf.OriginId
    end
  end
end

function UIModelZenyShop:SetLuckyBagPurchaseTimesZero()
  for k, v in pairs(Table_Deposit) do
    local productID = k
    local productConf = v
    if productConf.LimitType ~= 6 and productConf.Type == 4 and productConf.Switch == 1 and productConf.ActivityCount ~= 1 then
      self.luckyBagPurchaseTimes[productID] = 0
    end
  end
end

function UIModelZenyShop:SetLuckyBagPurchaseLimitsZero()
  for k, v in pairs(Table_Deposit) do
    local productID = k
    local productConf = v
    if productConf.LimitType ~= 6 and productConf.Type == 4 and productConf.Switch == 1 and productConf.ActivityCount ~= 1 then
      self.luckyBagPurchaseLimits[productID] = 0
    end
  end
end

function UIModelZenyShop:AddLuckyBagPurchaseTimes(lucky_bag_conf_id)
  local purchaseTimes = self.luckyBagPurchaseTimes[lucky_bag_conf_id]
  purchaseTimes = purchaseTimes or 0
  purchaseTimes = purchaseTimes + 1
  self.luckyBagPurchaseTimes[lucky_bag_conf_id] = purchaseTimes
end

function UIModelZenyShop:GetLuckyBagPurchaseTimes(lucky_bag_conf_id)
  if self.luckyBagPurchaseTimes ~= nil then
    return self.luckyBagPurchaseTimes[lucky_bag_conf_id]
  end
  return nil
end

function UIModelZenyShop:GetLuckyBagPurchaseLimit(lucky_bag_conf_id)
  if self.luckyBagPurchaseLimits ~= nil then
    return self.luckyBagPurchaseLimits[lucky_bag_conf_id]
  end
  return nil
end

function UIModelZenyShop:GetLuckyBagBatchDailyCount(lucky_bag_conf_id)
  if self.luckyBagPurchaseBatchDailyCount ~= nil then
    return self.luckyBagPurchaseBatchDailyCount[lucky_bag_conf_id]
  end
  return nil
end

UIModelZenyShop.LuckyBagShopType = 913
UIModelZenyShop.LuckyBagShopID = 1

function UIModelZenyShop:GetLuckyBagShopConf()
  return ShopProxy.Instance:GetConfigByTypeId(UIModelZenyShop.LuckyBagShopType, UIModelZenyShop.LuckyBagShopID)
end

function UIModelZenyShop:RequestQueryShopItem(shop_type, shop_id)
  ShopProxy.Instance:CallQueryShopConfig(shop_type, shop_id)
end

UIModelZenyShop.ItemShopType = 650
UIModelZenyShop.ItemShopID = 1

function UIModelZenyShop:GetItemShopConf()
  return ShopProxy.Instance:GetConfigByTypeId(UIModelZenyShop.ItemShopType, UIModelZenyShop.ItemShopID)
end

local allProductActivityParams = {}

function UIModelZenyShop:SafeGetTable(targettable, ziduan1, ziduan2)
  if targettable == nil then
    targettable = {}
  end
  if ziduan1 == nil then
    return targettable
  end
  if ziduan2 == nil then
    return targettable
  end
  if targettable[ziduan1] == nil then
    targettable[ziduan1] = {}
  end
  if targettable[ziduan1][ziduan2] == nil then
    targettable[ziduan1][ziduan2] = {}
  end
  return targettable[ziduan1][ziduan2]
end

function UIModelZenyShop:SetActivityParams_Discount(p_conf_id, activity_params)
  if activity_params ~= nil then
    local pConfID = activity_params[1]
    if not table.ContainsKey(allProductActivityParams, pConfID) then
      allProductActivityParams[pConfID] = {}
    end
    if not table.ContainsKey(allProductActivityParams[pConfID], 1) then
      allProductActivityParams[pConfID][1] = {}
    end
    local discountTimes = activity_params[2]
    local newPConfID = activity_params[3]
    local startTime = activity_params[4]
    local endTime = activity_params[5]
    local activityID = activity_params[6]
    allProductActivityParams[pConfID][1][1] = discountTimes
    allProductActivityParams[pConfID][1][2] = newPConfID
    allProductActivityParams[pConfID][1][4] = startTime
    allProductActivityParams[pConfID][1][5] = endTime
    allProductActivityParams[pConfID][1][6] = activityID
  else
    self:SafeGetTable(allProductActivityParams, p_conf_id, 1)
  end
end

function UIModelZenyShop:SetActivityParams_GainMore(p_conf_id, activity_params)
  if activity_params ~= nil then
    local pConfID = activity_params[1]
    if not table.ContainsKey(allProductActivityParams, pConfID) then
      allProductActivityParams[pConfID] = {}
    end
    if not table.ContainsKey(allProductActivityParams[pConfID], 2) then
      allProductActivityParams[pConfID][2] = {}
    end
    local gainMoreTimes = activity_params[2]
    local multipleNumber = activity_params[3]
    local startTime = activity_params[4]
    local endTime = activity_params[5]
    local activityID = activity_params[6]
    allProductActivityParams[pConfID][2][1] = gainMoreTimes
    allProductActivityParams[pConfID][2][2] = multipleNumber
    allProductActivityParams[pConfID][2][4] = startTime
    allProductActivityParams[pConfID][2][5] = endTime
    allProductActivityParams[pConfID][2][6] = activityID
  else
    self:SafeGetTable(allProductActivityParams, p_conf_id, 2)
  end
end

function UIModelZenyShop:SetActivityParams_MoreTimes(p_conf_id, activity_params)
  if activity_params ~= nil then
    local pConfID = activity_params[1]
    if not table.ContainsKey(allProductActivityParams, pConfID) then
      allProductActivityParams[pConfID] = {}
    end
    if not table.ContainsKey(allProductActivityParams[pConfID], 3) then
      allProductActivityParams[pConfID][3] = {}
    end
    local moreTimesTimes = activity_params[2]
    local startTime = activity_params[3]
    local endTime = activity_params[4]
    local activityID = activity_params[5]
    allProductActivityParams[pConfID][3][1] = moreTimesTimes
    allProductActivityParams[pConfID][3][2] = startTime
    allProductActivityParams[pConfID][3][3] = endTime
    allProductActivityParams[pConfID][3][4] = activityID
  else
    self:SafeGetTable(allProductActivityParams, p_conf_id, 3)
  end
end

function UIModelZenyShop:SetActivityUsedTimes(activity_id, used_times)
  for _, v in pairs(allProductActivityParams) do
    local activityParams = v
    if activityParams[1] ~= nil and activityParams[1][6] == activity_id then
      activityParams[1][3] = used_times
      break
    end
    if activityParams[2] ~= nil and activityParams[2][6] == activity_id then
      activityParams[2][3] = used_times
      break
    end
    if activityParams[3] ~= nil and activityParams[3][4] == activity_id then
      activityParams[3][5] = used_times
    end
  end
end

function UIModelZenyShop:GetProductActivity(p_conf_id)
  return allProductActivityParams[p_conf_id]
end

function UIModelZenyShop:GetProductActivity_Discount(activity_p_conf_id)
  for k, v in pairs(allProductActivityParams) do
    local activity = v
    local discountActivity = activity[1]
    if discountActivity ~= nil then
      local activityPConfID = discountActivity[2]
      if activityPConfID == activity_p_conf_id then
        return discountActivity
      end
    end
  end
  return nil
end

function UIModelZenyShop:SetEPVIPCards(ep_vip_cards)
  self.epVIPCards = ep_vip_cards
end

function UIModelZenyShop:GetEPVIPCards()
  return self.epVIPCards
end

function UIModelZenyShop:SetFPRFlag(tab_fpr_flag_product)
  if self.fprFlagProduct == nil then
    self.fprFlagProduct = {}
  end
  TableUtility.TableClear(self.fprFlagProduct)
  for i = 1, #tab_fpr_flag_product do
    self.fprFlagProduct[tab_fpr_flag_product[i]] = 0
  end
end

function UIModelZenyShop:RemoveFPRFlag(product_conf_id)
  if self.fprFlagProduct ~= nil then
    self.fprFlagProduct[product_conf_id] = nil
  end
end

function UIModelZenyShop:IsFPR(product_conf_id)
  if self.fprFlagProduct2 and self.fprFlagProduct2[product_conf_id] then
    Debug.LogWarning("客户端购买成功，不再是首充")
    return false
  end
  if self.fprFlagProduct == nil then
    return false
  else
    return self.fprFlagProduct[product_conf_id] ~= nil
  end
end

function UIModelZenyShop:SetFPRFlag2(productID)
  Debug.LogWarning("客户端充值成功: " .. productID)
  if self.fprFlagProduct2 == nil then
    self.fprFlagProduct2 = {}
  end
  TableUtility.TableClear(self.fprFlagProduct2)
  self.fprFlagProduct2[productID] = 0
end

UIModelZenyShop.DailyOneZenyGoodsID = 201300

function UIModelZenyShop:UpdateOneZenyGoodsBuyInfo()
end
