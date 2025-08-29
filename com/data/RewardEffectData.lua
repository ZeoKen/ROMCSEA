RewardEffectData = class("RewardEffectData")

function RewardEffectData:ctor(data)
  self.id = data.id
  self.endtime = data.endtime
  self.isused = data.isused
  local config = Table_UserEffectInfo[data.id]
  self.tabType = config and config.Type
  self.itemID = config.Item
end
