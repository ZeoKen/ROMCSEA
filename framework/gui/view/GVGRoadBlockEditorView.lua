autoImport("GVGRoadBlockEditorCell")
GVGRoadBlockEditorView = class("GVGRoadBlockEditorView", ContainerView)
GVGRoadBlockEditorView.ViewType = UIViewType.PopUpLayer
local MapTexName = "GVG_map"

function GVGRoadBlockEditorView:Init()
  self:AddListenEvts()
  self:InitData()
  self:FindObjs()
  self:InitView()
end

function GVGRoadBlockEditorView:AddListenEvts()
  self:AddListenEvt(ServiceEvent.GuildCmdGvgRoadblockModifyGuildCmd, self.OnRoadBlockModified)
  self:AddListenEvt(ServiceEvent.GuildCmdGvgRoadblockQueryGuildCmd, self.RefreshView)
end

function GVGRoadBlockEditorView:InitData()
  self.blockStates = {}
end

function GVGRoadBlockEditorView:FindObjs()
  self:AddButtonEvent("CloseButton", function()
    self:CloseSelf()
  end)
  TipsView.Me():TryShowGeneralHelpByHelpId(530, self:FindGO("HelpButton"))
  self.mapTex = self:FindComponent("MapTex", UITexture)
  self.blockIconA1 = self:FindComponent("blockA1", UIMultiSprite)
  self.blockIconA2 = self:FindComponent("blockA2", UIMultiSprite)
  self.blockIconB1 = self:FindComponent("blockB1", UIMultiSprite)
  self.blockIconB2 = self:FindComponent("blockB2", UIMultiSprite)
  self.blockIconB3 = self:FindComponent("blockB3", UIMultiSprite)
  self.blockIconC1 = self:FindComponent("blockC1", UIMultiSprite)
  self.blockIconC2 = self:FindComponent("blockC2", UIMultiSprite)
  local grid = self:FindComponent("BlockGrid", UIGrid)
  self.blockListCtrl = UIGridListCtrl.new(grid, GVGRoadBlockEditorCell, "GVGRoadBlockEditorCell")
  self.blockListCtrl:AddEventListener(MouseEvent.MouseClick, self.HandleBlockSelect, self)
  self.saveBtn = self:FindGO("SaveBtn")
  self:AddClickEvent(self.saveBtn, function()
    self:OnSaveBtnClick()
  end)
  self.saveBtnGrey = self:FindGO("SaveBtnGrey")
end

function GVGRoadBlockEditorView:InitView()
  ServiceGuildCmdProxy.Instance:CallGvgRoadblockQueryGuildCmd()
end

function GVGRoadBlockEditorView:RefreshView()
  self.roadBlock = GvgProxy.Instance:GetMyGuildRoadBlock()
  local datas = ReusableTable.CreateArray()
  local mod = self.roadBlock or 0
  for i = 1, 3 do
    local data = {}
    data.index = i
    data.state = mod // 10 ^ (3 - i)
    mod = mod % 10 ^ (3 - i)
    datas[#datas + 1] = data
    self.blockStates[i] = data.state
  end
  self.blockListCtrl:ResetDatas(datas)
  ReusableTable.DestroyArray(datas)
end

function GVGRoadBlockEditorView:OnEnter()
  PictureManager.Instance:SetRoadBlockTexture(MapTexName, self.mapTex)
end

function GVGRoadBlockEditorView:OnExit()
  PictureManager.Instance:UnloadRoadBlockTexture(MapTexName, self.mapTex)
end

function GVGRoadBlockEditorView:HandleBlockSelect(cell)
  local state = cell.state
  if cell.index == 1 then
    self.blockIconA1.CurrentState = state == 1 and 1 or 0
    self.blockIconA2.CurrentState = state == 2 and 1 or 0
  elseif cell.index == 2 then
    self.blockIconB1.CurrentState = state == 1 and 1 or 0
    self.blockIconB2.CurrentState = state == 2 and 1 or 0
    self.blockIconB3.CurrentState = state == 3 and 1 or 0
  elseif cell.index == 3 then
    self.blockIconC1.CurrentState = state == 1 and 1 or 0
    self.blockIconC2.CurrentState = state == 2 and 1 or 0
  end
  if not self.isDirty then
    self.isDirty = state ~= self.blockStates[cell.index]
  end
  self:SetSaveBtnState(self.isDirty)
end

function GVGRoadBlockEditorView:OnSaveBtnClick()
  if GvgProxy.Instance:IsInRoadBlockActivedTime() then
    MsgManager.ShowMsgByID(2676)
    return
  end
  local roadBlock = 0
  local cells = self.blockListCtrl:GetCells()
  local count = #cells
  for i = 1, count do
    roadBlock = roadBlock + cells[i].state * 10 ^ (count - i)
  end
  self.roadBlock = roadBlock
  ServiceGuildCmdProxy.Instance:CallGvgRoadblockModifyGuildCmd(roadBlock)
end

function GVGRoadBlockEditorView:SetSaveBtnState(state)
  self.saveBtn:SetActive(state)
  self.saveBtnGrey:SetActive(not state)
end

function GVGRoadBlockEditorView:OnRoadBlockModified(note)
  if note.body and note.body.ret then
    MsgManager.ShowMsgByID(34009)
    local cells = self.blockListCtrl:GetCells()
    for i = 1, #cells do
      self.blockStates[cells[i].index] = cells[i].state
    end
    self.isDirty = false
    self:SetSaveBtnState(self.isDirty)
  end
end
