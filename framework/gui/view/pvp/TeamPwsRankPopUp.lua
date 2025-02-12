autoImport("TeamPwsRankCell")
TeamPwsRankPopUp = class("TeamPwsRankPopUp", BaseView)
TeamPwsRankPopUp.ViewType = UIViewType.PopUpLayer

function TeamPwsRankPopUp:Init()
  self:FindObjs()
  self:InitView()
  self:AddButtonEvt()
  self:AddListenEvts()
  self.playerTipOffset = {-70, 14}
  self.playerTipInitData = {}
  self.playerTipFunc = {
    "SendMessage",
    "AddFriend",
    "ShowDetail"
  }
  self.playerTipFunc_Friend = {
    "SendMessage",
    "ShowDetail"
  }
end

function TeamPwsRankPopUp:FindObjs()
  self.objLoading = self:FindGO("LoadingRoot")
  self.objEmptyList = self:FindGO("EmptyList")
  self.inputSearch = self:FindComponent("InputSearch", UIInput)
  self.labRank = self:FindComponent("labRank", UILabel)
  self.labName = self:FindComponent("labName", UILabel)
  self.labGrade = self:FindComponent("labGrade", UILabel)
  self.labScore = self:FindComponent("labScore", UILabel)
end

function TeamPwsRankPopUp:InitView()
  self.listRanks = WrapListCtrl.new(self:FindGO("rankContainer"), TeamPwsRankCell, "TeamPwsRankCell", WrapListCtrl_Dir.Vertical)
  self.listRanks:AddEventListener(MouseEvent.MouseClick, self.ClickCellHead, self)
end

function TeamPwsRankPopUp:AddButtonEvt()
  self:AddButtonEvent("SearchButton", function()
    self:ClickButtonSearch()
  end)
  self:AddButtonEvent("Mask", function()
    self:CloseSelf()
  end)
end

function TeamPwsRankPopUp:AddListenEvts()
  self:AddListenEvt(ServiceEvent.MatchCCmdQueryTeamPwsRankMatchCCmd, self.HandleQueryTeamPwsRankMatchCCmd)
end

function TeamPwsRankPopUp:HandleQueryTeamPwsRankMatchCCmd(note)
  self:RefreshRankData()
  self:UpdateData()
end

function TeamPwsRankPopUp:RefreshRankData(searchInput)
  if searchInput and 0 < #searchInput then
    self.data = PvpProxy.Instance:GetTeamPwsRankSearchResult(searchInput)
  else
    self.data = PvpProxy.Instance:GetTeamPwsRankData()
  end
end

function TeamPwsRankPopUp:UpdateData(isLayout)
  self.objLoading:SetActive(false)
  if not self.data then
    return
  end
  if isLayout == nil then
    isLayout = true
  end
  self.objEmptyList:SetActive(#self.data < 1)
  self.listRanks:ResetDatas(self.data, isLayout)
end

function TeamPwsRankPopUp:QueryRankData()
  ServiceMatchCCmdProxy.Instance:CallQueryTeamPwsRankMatchCCmd()
end

function TeamPwsRankPopUp:ClickButtonSearch()
  if self.objLoading.activeSelf then
    return
  end
  self:RefreshRankData(self.inputSearch.value)
  self:UpdateData()
end

function TeamPwsRankPopUp:ClickCellHead(cellCtl)
  local cellData = cellCtl.data
  if cellCtl == self.curCell or cellData.charID == Game.Myself.data.id then
    FunctionPlayerTip.Me():CloseTip()
    self.curCell = nil
    return
  end
  self.curCell = cellCtl
  local playerTip = FunctionPlayerTip.Me():GetPlayerTip(cellCtl.headIcon.frameSp, NGUIUtil.AnchorSide.TopRight, self.playerTipOffset)
  local player = PlayerTipData.new()
  player:SetByTeamPwsRankData(cellData)
  self.playerTipInitData.playerData = player
  self.playerTipInitData.funckeys = FriendProxy.Instance:IsFriend(cellData.charID) and self.playerTipFunc_Friend or self.playerTipFunc
  playerTip:SetData(self.playerTipInitData)
  playerTip:AddIgnoreBound(cellCtl.headIcon.gameObject)
  
  function playerTip.clickcallback(funcData)
    if funcData.key == "SendMessage" then
      self:CloseSelf()
    end
  end
  
  function playerTip.closecallback()
    self.curCell = nil
  end
end

function TeamPwsRankPopUp:OnEnter()
  TeamPwsRankPopUp.super.OnEnter(self)
  self.objLoading:SetActive(true)
  self.objEmptyList:SetActive(false)
  self:RefreshRankData()
  if self.data then
    self:UpdateData()
  else
    self:QueryRankData()
  end
end

function TeamPwsRankPopUp:OnExit()
  PvpProxy.Instance:TeamPwsRankDataUseOver()
  TeamPwsRankPopUp.super.OnExit(self)
end

function TeamPwsRankPopUp:OnDestroy()
  self.listRanks:Destroy()
  TeamPwsRankPopUp.super.OnDestroy(self)
end
