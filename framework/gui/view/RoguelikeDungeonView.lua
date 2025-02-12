autoImport("GemContainerView")
RoguelikeDungeonView = class("RoguelikeDungeonView", GemContainerView)
RoguelikeDungeonView.ViewType = UIViewType.PopUpLayer
RoguelikeDungeonView.TogglePageNameMap = {
  LoadTab = "RoguelikeDungeonLoadPage"
}

function RoguelikeDungeonView:AddEvents()
  self:AddListenEvt(ServiceEvent.PlayerMapChange, self.CloseSelf)
  self:AddListenEvt(ServiceEvent.RoguelikeCmdRoguelikeWeekReward, self.CloseSelf)
  self:AddListenEvt(ServiceEvent.SessionTeamEnterTeam, self.OnEnterTeam)
end

function RoguelikeDungeonView:OnEnterTeam()
  local pageClass = self.viewMap[self.activePageName or ""]
  if pageClass and pageClass.OnEnterTeam then
    pageClass:OnEnterTeam()
  end
end

function RoguelikeDungeonView:GetDefaultPageName()
  return self.TogglePageNameMap.LoadTab
end
