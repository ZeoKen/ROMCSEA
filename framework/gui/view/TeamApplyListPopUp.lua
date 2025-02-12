TeamApplyListPopUp = class("TeamApplyListPopUp", ContainerView)
TeamApplyListPopUp.ViewType = UIViewType.PopUpLayer
autoImport("TeamApplyCell")
local teamProxy

function TeamApplyListPopUp:Init()
  teamProxy = TeamProxy.Instance
  self:InitUI()
  self:AddViewEvts()
end

function TeamApplyListPopUp.ServerProxy()
  return ServiceSessionTeamProxy.Instance
end

function TeamApplyListPopUp:OnEnter()
  TeamApplyListPopUp.super.OnEnter(self)
  RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_TEAMAPPLY)
  RedTipProxy.Instance:RemoveWholeTip(SceneTip_pb.EREDSYS_TEAMAPPLY)
end

function TeamApplyListPopUp:OnExit()
  TeamApplyListPopUp.super.OnExit(self)
end

function TeamApplyListPopUp:InitUI()
  local page = self:FindGO("TeamApplyListContent")
  local grid = self:FindComponent("ApplyGrid", UIGrid, page)
  self.applyInfoCtl = UIGridListCtrl.new(grid, TeamApplyCell, "TeamApplyCell")
  self.applyInfoCtl:SetDisableDragIfFit()
  local clearButton = self:FindGO("ClearApplyButton")
  self:AddClickEvent(clearButton, function(go)
    self.ServerProxy():CallClearApplyList()
  end)
  local closeButton = self:FindGO("CloseButton")
  self:AddClickEvent(closeButton, function(go)
    self:CloseSelf()
  end)
  self.noneTip = self:FindGO("NoneTip")
  self:UpdateApplyList()
end

function TeamApplyListPopUp:UpdateApplyList()
  local applylst
  if teamProxy:IHaveTeam() then
    applylst = teamProxy.myTeam:GetApplyList()
  else
    applylst = {}
  end
  self.applyInfoCtl:ResetDatas(applylst)
  self.noneTip:SetActive(#applylst == 0)
end

function TeamApplyListPopUp:AddViewEvts()
  self:AddListenEvt(ServiceEvent.SessionTeamEnterTeam, self.UpdateApplyList)
  self:AddListenEvt(ServiceEvent.SessionTeamClearApplyList, self.UpdateApplyList)
  self:AddListenEvt(ServiceEvent.SessionTeamTeamApplyUpdate, self.UpdateApplyList)
  self:AddListenEvt(ServiceEvent.SessionTeamTeamMemberApply, self.UpdateApplyList)
  self:AddListenEvt(ServiceEvent.SessionTeamTeamGroupApplyUpdate, self.UpdateApplyList)
end
