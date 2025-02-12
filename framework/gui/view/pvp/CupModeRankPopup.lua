autoImport("CupModeRankCell")
CupModeRankPopup = class("CupModeRankPopup", ContainerView)
CupModeRankPopup.ViewType = UIViewType.PopUpLayer

function CupModeRankPopup:Init()
  self:InitUI()
end

function CupModeRankPopup:InitUI()
  self.title = self:FindComponent("Title", UILabel)
  self.title.text = ZhString.Warband_RankTitle
  self.emptyTip = self:FindComponent("Empty", UILabel)
  self.emptyTip.text = ZhString.Warband_NoRank
  local container = self:FindGO("Wrap")
  local config = {
    wrapObj = container,
    pfbNum = 6,
    cellName = "WarbandSeasonRankCell",
    control = CupModeRankCell
  }
  self.rankList = WrapCellHelper.new(config)
  self:UpdateList()
end

local result = {}

function CupModeRankPopup:UpdateList()
  local proxy = CupMode6v6Proxy.Instance
  local result = proxy:GetSessionRank()
  self.rankList:ResetDatas(result)
  self.emptyTip.gameObject:SetActive(#result == 0)
end
