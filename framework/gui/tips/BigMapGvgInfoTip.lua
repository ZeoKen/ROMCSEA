autoImport("BigMapGvgInfoTipCell")
BigMapGvgInfoTip = class("BigMapGvgInfoTip", CoreView)

function BigMapGvgInfoTip:ctor(go)
  BigMapGvgInfoTip.super.ctor(self, go)
  self:Init()
end

function BigMapGvgInfoTip:Init()
  self:FindObjs()
end

function BigMapGvgInfoTip:FindObjs()
  self.title = self:FindComponent("Title", UILabel)
  self.titleBg = self:FindComponent("Sprite", UISprite, self.title.gameObject)
  self.title.gameObject:SetActive(true)
  self.scrollView = self:FindComponent("StrongholdsView", UIScrollView)
  self.scrollCtl = ListCtrl.new(self:FindComponent("Grid", UIGrid, self.scrollView.gameObject), BigMapGvgInfoTipCell, "MiniMap/BigMapGvgInfoTipCell")
end

function BigMapGvgInfoTip:OnShow()
  self:SetPanelDepthByParent(self.scrollView, 1)
  self:UpdateView()
  EventManager.Me():AddEventListener(GVGEvent.GVG_PointUpdate, self.UpdateView, self)
end

function BigMapGvgInfoTip:OnHide()
  EventManager.Me():RemoveEventListener(GVGEvent.GVG_PointUpdate, self.UpdateView, self)
end

function BigMapGvgInfoTip:UpdateView()
  local datas = GvgProxy.Instance:GetGvgStrongHoldDatas() or {}
  self.scrollCtl:ResetDatas(datas)
  self.scrollCtl:ResetPosition()
  self:SetTitle()
end

local ProgressColor = {
  Blue = LuaColor.New(0.11372549019607843, 0.8431372549019608, 1, 1),
  Gray = LuaColor.New(0.6588235294117647, 0.6588235294117647, 0.6588235294117647, 1)
}

function BigMapGvgInfoTip:SetTitle()
  if not self.title then
    return
  end
  local canShowPointScore = GvgProxy.Instance:CanShowPointScore()
  if canShowPointScore then
    local max = GvgProxy.Instance:GetMaxPointScore()
    local score = GvgProxy.Instance:GetCurMapPointScore()
    self.title.text = string.format(ZhString.NewGvg_PointInfo, score, max)
  elseif GvgProxy.Instance:IsNeutral() then
    self.title.text = ZhString.NewGvg_PointInfo_Neutral
  else
    self.title.text = ZhString.NewGvg_PointInfo_other
  end
  self.titleBg.color = canShowPointScore and ProgressColor.Blue or ProgressColor.Gray
end
