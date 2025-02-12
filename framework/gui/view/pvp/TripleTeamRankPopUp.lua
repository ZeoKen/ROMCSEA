autoImport("TeamPwsRankPopUp")
autoImport("TripleTeamRankCell")
TripleTeamRankPopUp = class("TripleTeamRankPopUp", TeamPwsRankPopUp)
TripleTeamRankPopUp.ViewType = UIViewType.PopUpLayer

function TripleTeamRankPopUp:FindObjs()
  TripleTeamRankPopUp.super.FindObjs(self)
  self.scoreLimitLabel = self:FindComponent("ScoreLimit", UILabel)
  self.bestRankLabel = self:FindComponent("BestRank", UILabel)
end

function TripleTeamRankPopUp:InitView()
  self.listRanks = WrapListCtrl.new(self:FindGO("rankContainer"), TripleTeamRankCell, "TripleTeamRankCell", WrapListCtrl_Dir.Vertical)
  self.listRanks:AddEventListener(MouseEvent.MouseClick, self.ClickCellHead, self)
end

function TripleTeamRankPopUp:AddListenEvts()
  self:AddListenEvt(ServiceEvent.MatchCCmdQueryTriplePwsRankMatchCCmd, self.HandleQueryTriplePwsRankMatchCCmd)
end

function TripleTeamRankPopUp:HandleQueryTriplePwsRankMatchCCmd(note)
  local data = note and note.body
  if data and data.isfinish then
    self:RefreshRankData()
    self:UpdateData()
  end
end

function TripleTeamRankPopUp:QueryRankData()
  PvpProxy.Instance:QueryTriplePwsRankData()
end

function TripleTeamRankPopUp:RefreshRankData(searchInput)
  if not StringUtil.IsEmpty(searchInput) then
    self.data = PvpProxy.Instance:GetTriplePwsRankSearchResult(searchInput)
  else
    self.data = PvpProxy.Instance:GetTriplePwsRankData()
  end
end

function TripleTeamRankPopUp:UpdateData(isLayout)
  TripleTeamRankPopUp.super.UpdateData(self, isLayout)
  local scoreLimit = PvpProxy.Instance:GetTriplePwsScoreLimit()
  self.scoreLimitLabel.text = string.format(ZhString.Triple_RankScoreLimit, scoreLimit)
  local bestRank = PvpProxy.Instance:GetTriplePwsBestRank() or 0
  bestRank = 0 < bestRank and bestRank or ZhString.ItemTip_None
  self.bestRankLabel.text = string.format(ZhString.Triple_BestRank, bestRank)
end

function TripleTeamRankPopUp:OnExit()
  TeamPwsRankPopUp.super.OnExit(self)
end
