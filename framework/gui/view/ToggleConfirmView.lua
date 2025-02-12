local UniqueConfirmView = autoImport("UniqueConfirmView")
ToggleConfirmView = class("ToggleConfirmView", UniqueConfirmView)
ToggleConfirmView.ViewType = UIViewType.ConfirmLayer

function ToggleConfirmView:Init()
  ToggleConfirmView.super.Init(self)
  self:FillTitle()
  self:FillCheckLabel()
end

function ToggleConfirmView:FindObjs()
  self.titleLabel = self:FindGO("Title"):GetComponent(UILabel)
  self.contentLabel = self:FindGO("ContentLabel"):GetComponent(UILabel)
  self.confirmLabel = self:FindGO("ConfirmLabel"):GetComponent(UILabel)
  self.cancelLabel = self:FindGO("CancelLabel"):GetComponent(UILabel)
  self.checkBtn = self:FindGO("CheckBtn"):GetComponent(UIToggle)
  self.checkBg = self:FindGO("CheckBg"):GetComponent(UISprite)
  self.checkLabel = self:FindGO("CheckLabel"):GetComponent(UILabel)
  self.confirmBtn = self:FindGO("ConfirmBtn")
  self.cancelBtn = self:FindGO("CancelBtn")
  self:AddButtonEvent("ConfirmBtn", function(go)
    self:DoConfirm()
    self:CloseSelf()
  end)
  self:AddButtonEvent("CancelBtn", function(go)
    self:DoCancel()
    self:CloseSelf()
  end)
end

function ToggleConfirmView:DoConfirm()
  if self.viewdata.confirmHandler ~= nil then
    self.viewdata.confirmHandler(self.checkBtn.value, self.viewdata.source)
  end
end

function ToggleConfirmView:DoCancel()
  if self.viewdata.cancelHandler ~= nil then
    self.viewdata.cancelHandler(self.viewdata.source)
  end
end

function ToggleConfirmView:FillCheckLabel(text)
  text = text or self.viewdata.checkLabel
  if text ~= nil then
    self.checkLabel.text = text
  end
  local checkLabelX = self.checkLabel.transform.localPosition.x
  self.checkBtn.transform.localPosition = LuaGeometry.GetTempVector3(-(checkLabelX - self.checkBg.width / 2 + self.checkLabel.width) / 2, 108, 0)
end

function ToggleConfirmView:CloseSelf()
  if self.viewdata and self.viewdata.closeHandler ~= nil then
    self.viewdata.closeHandler(self.viewdata.source)
  end
  ToggleConfirmView.super.CloseSelf(self)
end
