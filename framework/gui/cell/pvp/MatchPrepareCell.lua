autoImport("PlayerFaceCell")
MatchPrepareCell = class("MatchPrepareCell", BaseCell)
MatchPrepareCell.EmptyCell = "EmptyCell"
MatchPrepareCell.DefaultCell = "DefaultCell"

function MatchPrepareCell:Init()
  self:FindAndCreateObjs()
end

function MatchPrepareCell:FindAndCreateObjs()
  self.objCheckMark = self:FindGO("CheckMark")
  self.cancelImg = self:FindGO("CancelFlag")
  self.objDefaultHead = self:FindGO("DefaultHead")
  self.headContainer = self:FindGO("HeadContainer")
  self.headIconCell = HeadIconCell.new()
  self.headIconCell:CreateSelf(self.headContainer)
  self.headIconCell:SetMinDepth(30)
end

function MatchPrepareCell:SetData(data)
  self.charID = data.charID
  self.gameObject:SetActive(data.charID ~= MatchPrepareCell.EmptyCell)
  if data.charID == MatchPrepareCell.EmptyCell then
    return
  end
  if data.charID == MatchPrepareCell.DefaultCell then
    self.objDefaultHead:SetActive(true)
    self.headContainer:SetActive(false)
    return
  end
  if type(data.isReady) == "boolean" then
    self.objCheckMark:SetActive(data.isReady)
  elseif type(data.isReady) == "number" then
    self.objCheckMark:SetActive(data.isReady == MatchPreparePopUp.PwsInviteMatchStatus.READY)
    self.cancelImg:SetActive(data.isReady == MatchPreparePopUp.PwsInviteMatchStatus.CANCEL)
  end
  local headData
  if self.charID then
    if self.charID == Game.Myself.data.id then
      headData = HeadImageData.new()
      headData:TransformByCreature(Game.Myself)
    elseif TeamProxy.Instance:IHaveTeam() then
      local memberlst = TeamProxy.Instance.myTeam:GetMembersListExceptMe()
      for i = 1, #memberlst do
        if memberlst[i].id == self.charID then
          headData = HeadImageData.new()
          headData:TransByTeamMemberData(memberlst[i])
          break
        end
      end
    end
  end
  local iconData = headData and headData.iconData
  if iconData then
    if iconData.type == HeadImageIconType.Avatar then
      self.headIconCell:SetData(iconData)
    elseif iconData.type == HeadImageIconType.Simple then
      self.headIconCell:SetSimpleIcon(iconData.icon, iconData.frameType)
      self.headIconCell:SetPortraitFrame(iconData.portraitframe)
    end
  end
  self.headContainer:SetActive(iconData ~= nil)
  self.objDefaultHead:SetActive(not iconData)
end

function MatchPrepareCell:Prepared()
  self.objCheckMark:SetActive(true)
  self.cancelImg:SetActive(false)
end

function MatchPrepareCell:Canceled()
  self.cancelImg:SetActive(true)
  self.objCheckMark:SetActive(false)
end

function MatchPrepareCell:OnCellDestroy()
  self.headIconCell:OnRemove()
end
