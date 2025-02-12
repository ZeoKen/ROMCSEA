SetViewSwitchRolePage = class("SetViewSwitchRolePage", SubView)
autoImport("SetViewHeadCell")
autoImport("SwitchRolePanel")

function SetViewSwitchRolePage:Init()
  self:initView()
  self:AddViewEvents()
  self:initData()
end

function SetViewSwitchRolePage:initView()
  self.grid = self:FindComponent("roleGrid", UIGrid)
  self.roleGrid = UIGridListCtrl.new(self.grid, SetViewHeadCell, "SetViewHeadCell")
  self.roleGrid:AddEventListener(MouseEvent.MouseClick, self.cellClick, self)
  local otherGO = self:FindGO("OtherRoles")
  self.content = self:FindGO("content", otherGO)
  self.contentGrid = self:FindGO("contentGrid", otherGO)
  self.contentBg = self:FindComponent("contentBg", UISprite, otherGO)
  local switchRoleBtn = self:FindGO("switchRoleBtn")
  local switchRoleBtnLabel = self:FindComponent("switchRoleLabel", UILabel)
  switchRoleBtnLabel.text = ZhString.SetViewSecurityPage_SwitchRoleLabel
  if BranchMgr.IsJapan() then
    switchRoleBtn.gameObject:SetActive(false)
  end
end

function SetViewSwitchRolePage:initData()
  local allRoles = ServiceUserProxy.Instance:GetAllRoleInfos()
  local arrays = {}
  if allRoles and 1 < #allRoles then
    for i = 1, #allRoles do
      local single = allRoles[i]
      local deletetime = single.deletetime
      local leftTime = deletetime ~= 0 and ServerTime.ServerDeltaSecondTime(deletetime * 1000) or 1
      if single.id ~= 0 and single.id ~= Game.Myself.data.id and 0 < leftTime then
        arrays[#arrays + 1] = single
      end
    end
  end
  if #arrays == 0 then
    self.roleGrid:SetEmptyDatas(1)
  else
    self.roleGrid:ResetDatas(arrays)
  end
end

function SetViewSwitchRolePage:AddViewEvents()
  self:AddButtonEvent("switchRoleBtn", function()
    self:Show(self.content)
    self.roleGrid:Layout()
    self:resizeContentBg()
  end)
end

function SetViewSwitchRolePage:resizeContentBg()
  local size = #self.roleGrid:GetCells()
  self.contentBg.width = size * 126
end

function SetViewSwitchRolePage:cellClick(cellCtr)
  if cellCtr.data == nil then
    MsgManager.ShowMsgByID(13012)
  elseif cellCtr.data.deletetime ~= 0 then
    MsgManager.ShowMsgByID(13011)
  else
    MsgManager.ConfirmMsgByID(13010, function()
      PlayerPrefs.SetString(ServiceLoginUserCmdProxy.toswitchroleid, tostring(cellCtr.data.id))
      PlayerPrefs.Save()
      Game.Me():BackToSwitchRole()
    end)
  end
end
