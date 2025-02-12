autoImport("GuildFindPage")
GuildFindView = class("GuildFindView", ContainerView)
GuildFindView.ViewType = UIViewType.NormalLayer

function GuildFindView:Init()
  local findBord = self:FindGO("FindBord")
  if not self.guildFindPage then
    self.guildFindPage = self:AddSubView("GuildFindPage", GuildFindPage, findBord)
  end
end

function GuildFindView:OnEnter()
  GuildFindView.super.OnEnter(self)
end

function GuildFindView:OnExit()
  GuildFindView.super.OnExit(self)
end
