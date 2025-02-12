autoImport("UIAutoScrollCtrl")
local _chooseColorFormat = "[c][1F74BF]%s[-][/c]"
local _unChooseColorFormat = "[c][383838]%s[-][/c]"
local baseCell = autoImport("BaseCell")
PveTypeGridCell = class("PveTypeGridCell", baseCell)

function PveTypeGridCell:Init()
  PveTypeGridCell.super.Init(self)
  self:FindObj()
end

function PveTypeGridCell:FindObj()
  self.scroll = self:FindComponent("LabelPanel", UIScrollView)
  self.label = self:FindComponent("Label", UILabel, self.scroll.gameObject)
  self.labelCtrl = UIAutoScrollCtrl.new(self.scroll, self.label, 2, 40)
  self.dragScrollView = self.label.gameObject:GetComponent(UIDragScrollView)
  self.sp = self:FindComponent("Sprite", UISprite)
  self.redTipGO = self:FindGO("RedTip")
  if not self.redTipGO then
    self.redTipGO = Game.AssetManager_UI:CreateAsset(RedTip.resID, self.gameObject)
    if self.redTipGO then
      LuaGameObject.SetLocalPositionGO(self.redTipGO, 148, 0, 0)
      LuaGameObject.SetLocalScaleGO(self.redTipGO, 1, 1, 1)
    end
  end
  self:AddClickEvent(self.label.gameObject, function()
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
end

function PveTypeGridCell:TrySeenRedTip()
  if RedTipProxy.Instance:IsNew(SceneTip_pb.EREDSYS_PVERAID_ENTRANCE, self.data.staticEntranceData.groupid) then
    RedTipProxy.Instance:SeenNew(SceneTip_pb.EREDSYS_PVERAID_ENTRANCE, self.data.staticEntranceData.groupid)
  end
end

function PveTypeGridCell:SetDragScrollView(sv)
  self.dragScrollView.scrollView = sv
end

function PveTypeGridCell:StopAutoScollView()
  if self.labelCtrl then
    self.labelCtrl:Stop(true)
  end
end

function PveTypeGridCell:StartAutoScrollView()
  if self.labelCtrl then
    self.labelCtrl:Start(true, true)
  end
end

function PveTypeGridCell:SetData(data)
  self.data = data
  if not data or not data.staticEntranceData then
    self:Hide(self.label)
    return
  end
  self:Show(self.label)
  self.text = string.format(ZhString.Pve_GridCellText, data.staticEntranceData.lv, data.staticEntranceData.name)
  self:UpdateChoose()
  self:UpdateRedTip()
end

function PveTypeGridCell:SetChoosen(id)
  self.chooseId = id
  self:UpdateChoose()
end

function PveTypeGridCell:UpdateChoose()
  local textFormat
  if self.data and self.chooseId and self.data.id == self.chooseId then
    textFormat = _chooseColorFormat
    self.label.text = string.format(textFormat, self.text)
    ColorUtil.WhiteUIWidget(self.sp)
    self:StartAutoScrollView()
  else
    textFormat = _unChooseColorFormat
    self.label.text = string.format(textFormat, self.text)
    ColorUtil.BlackLabel(self.sp)
    self:StopAutoScollView()
  end
end

function PveTypeGridCell:UpdateRedTip()
  if not self.redTipGO then
    return
  end
  self.redTipGO:SetActive(self.data:HasRedTip())
end

function PveTypeGridCell:OnCellDestroy()
  if self.labelCtrl then
    self.labelCtrl:Destroy()
  end
end
