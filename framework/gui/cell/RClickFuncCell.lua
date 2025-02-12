local BaseCell = autoImport("BaseCell")
RClickFuncCell = class("RClickFuncCell", BaseCell)
RClickFuncCell.RedTip = {
  ApplyList = SceneTip_pb.EREDSYS_TEAMAPPLY
}

function RClickFuncCell:Init()
  self.bg = self.gameObject:GetComponent(UISprite)
  self.label = self:FindComponent("Label", UILabel)
  self.passEvent = true
  self:SetEvent(self.gameObject, function()
    if self.passEvent then
      self:PassEvent(MouseEvent.MouseClick, self)
    end
  end)
end

function RClickFuncCell:SetData(data)
  self.data = data
  local key = data.key
  if not PlayerTipFuncConfig[key] then
    self.gameObject:SetActive(false)
    redlog(string.format("%s Not Defined in FunctionPlayerTip", key))
    return
  end
  self.label.text = data.otherName or PlayerTipFuncConfig[key].name
  if RClickFuncCell.RedTip[key] and not self.regist then
    self.regist = true
    RedTipProxy.Instance:RegisterUI(RClickFuncCell.RedTip[key], self.bg, 22)
  end
  local isCancel = PlayerTipFuncConfig[key].isCancelFunc or data.isCancel or false
  self:SetState(data.state, isCancel)
end

local tempColor = LuaColor.New(1, 1, 1, 1)

function RClickFuncCell:SetState(state, isCancel)
  if state == nil or state == PlayerTipFuncState.Active then
    if isCancel then
      self.bg.spriteName = "com_btn_0"
      self.label.effectColor = LuaGeometry.GetTempColor(0.5137254901960784, 0.027450980392156862, 0.047058823529411764)
    else
      self.bg.spriteName = "com_btn_1s"
      self.label.effectColor = LuaGeometry.GetTempColor(0.14901960784313725, 0.24313725490196078, 0.5490196078431373)
    end
    self.bg.color = ColorUtil.NGUIWhite
    self.passEvent = true
  elseif state == PlayerTipFuncState.Grey then
    self.bg.spriteName = "com_btn_1s"
    self.label.effectColor = LuaGeometry.GetTempColor(0.6941176470588235, 0.6941176470588235, 0.6941176470588235)
    self.bg.color = LuaGeometry.GetTempColor(0.00392156862745098, 0.00784313725490196, 0.011764705882352941)
    self.passEvent = false
  elseif state == PlayerTipFuncState.Special then
    self.bg.spriteName = "com_btn_2s"
    self.label.effectColor = LuaGeometry.GetTempColor(0.47843137254901963, 0.24313725490196078, 0.0196078431372549)
    self.bg.color = ColorUtil.NGUIWhite
    self.passEvent = true
  end
end

function RClickFuncCell:SetDisable()
  self:SetTextureGrey(self.gameObject)
  local boxCollider = self.gameObject:GetComponentInChildren(BoxCollider)
  boxCollider.enabled = false
end

function RClickFuncCell:SetName(name)
  self.label.text = name
end
