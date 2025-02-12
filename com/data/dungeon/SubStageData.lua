SubStageData = class("SubStageData")
SubStageData.LockState = 1
SubStageData.ChallengeState = 2
SubStageData.PassState = 3
SubStageData.NormalType = 0
SubStageData.EliteType = 1

function SubStageData:ctor(id, mainStage)
  self.id = id
  self.mainStage = mainStage
  self.state = SubStageData.LockState
  self.staticData = Table_Stage[id]
  self.star = 0
  self.type = 0
  self.finish = false
  self.challengeTime = 0
end

function SubStageData:SetStar(star)
  if star > self.star then
    local newAdd = star - self.star
    self.star = star
    return newAdd
  end
  return 0
end

function SubStageData:SetState(state)
  if self.state ~= SubStageData.PassState then
    self.state = state
  end
end

function SubStageData:DebugLog(needPrint)
  return "str"
end
