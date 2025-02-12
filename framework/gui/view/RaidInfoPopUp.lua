RaidInfoPopUp = class("RaidInfoPopUp", BaseView)
RaidInfoPopUp.ViewType = UIViewType.PopUpLayer

function RaidInfoPopUp:Init()
  self:FindObjs()
  self.raidid = self.viewdata.viewdata.raidid
  self.raidData = Table_MapRaid[self.raidid]
  self:UpdateInfoBord()
end

function RaidInfoPopUp:FindObjs()
  self.tiplabel1 = self:FindGO("TipLabel1"):GetComponent(UILabel)
  self.tiplabel2 = self:FindGO("TipLabel2"):GetComponent(UILabel)
  self.tiplabel3 = self:FindGO("TipLabel3"):GetComponent(UILabel)
  self.noTeam = self:FindGO("NoTeamTip")
  self.searchBtn = self:FindGO("SearchButton")
  self:AddClickEvent(self.searchBtn, function(go)
    self:SearchEvt()
  end)
  self.searchLabel = self:FindGO("Label", self.searchBtn):GetComponent(UILabel)
end

function RaidInfoPopUp:UpdateInfoBord()
  if self.raidData then
    self.tiplabel1.text = self.raidData.Desc
    self.tiplabel2.text = self.raidData.Text
  end
  if TeamProxy.Instance:IHaveTeam() then
    self.noTeam:SetActive(false)
    local isLeader = TeamProxy.Instance:CheckImTheLeader()
    self.tiplabel3.gameObject:SetActive(not isLeader)
    if isLeader then
    else
      self.tiplabel3.text = self:GetTeamEnterInfo()
    end
  else
    self.noTeam:SetActive(true)
    self.tiplabel3.gameObject:SetActive(false)
  end
end

function RaidInfoPopUp:GetTeamEnterInfo()
  local enterMember = 0
  if TeamProxy.Instance:IHaveTeam() then
    for k, v in pairs(TeamProxy.Instance.myTeam.members) do
      if v.mapid == self.raidid then
        enterMember = enterMember + 1
      end
    end
  end
  return ""
end

function RaidInfoPopUp:SearchEvt()
  if TeamProxy.Instance.myTeam and TeamProxy.Instance:CheckImTheLeader() then
    self:CallTeamSummon()
  end
  self:CloseSelf()
end

function RaidInfoPopUp:CallTeamSummon()
  ServiceSessionTeamAutoProxy:CallTeamSummon(self.raidid)
end
