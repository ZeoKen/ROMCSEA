AstrolabeTipView = class("AstrolabeTipView", BaseTip)
autoImport("AstrolabeMaterilaCell")
local tempVector3 = LuaVector3.Zero()
local minWidth = 200
local maxWidth = 360
local minHeight = 210
local maxHeight = 415
local singleLineHeight = 20
local fix = 80

function AstrolabeTipView:Init()
  self.closecomp = self.gameObject:GetComponent(CustomTouchUpCall)
  local root = self:FindGO("BG")
  
  function self.closecomp.call(go)
    self:CloseSelf()
  end
  
  self.BGImg = self:FindComponent("BG", UISprite)
  self.name = self:FindComponent("name", UILabel)
  self.top = self:FindComponent("Top", UIWidget)
  self.attri = self:FindComponent("attri", UILabel)
  self.material = self:FindComponent("material", UILabel)
  self.uiTable = self:FindComponent("materialRoot", UITable)
  self.bottomLine = self:FindComponent("seperatorflag_Bottom", UIWidget)
  self.line = self:FindComponent("line", UISprite)
  self.materialCtl = UIGridListCtrl.new(self.uiTable, AstrolabeMaterilaCell, "AstrolabeMaterilaCell")
  self.scrollPanel = self:FindComponent("AttrScroll", UIPanel)
  self.scrollView = self:FindComponent("AttrScroll", UIScrollView)
  self:_AddAnchor(self:FindComponent("TipValidArea", UIWidget))
  self:_AddAnchor(self:FindComponent("Top", UIWidget))
  self:_AddAnchor(self.bottomLine)
  self:_AddAnchor(self:FindComponent("Bottom", UIWidget))
  self:_AddAnchor(self:FindComponent("materialRoot", UIWidget))
  self:_AddAnchor(self:FindComponent("seperatorflag", UIWidget))
  self:_AddAnchor(self:FindComponent("DragCollider", UIWidget))
  self:_AddAnchor(self.scrollPanel)
end

function AstrolabeTipView:SetCheckClick(func, funcParam)
  if self.closecomp then
    function self.closecomp.check()
      return func ~= nil and func(funcParam) or false
    end
  end
end

function AstrolabeTipView:CloseSelf()
  TipsView.Me():HideCurrent()
  self:sendNotification(AstrolabeEvent.TipClose)
end

function AstrolabeTipView:SetData(data)
  self.name.text = data:GetName()
  self:_ParseAttr(data)
  local materialData = data:GetCost()
  for i = #materialData, 1, -1 do
    if materialData[i][2] == 0 then
      table.remove(materialData, i)
    end
  end
  self.materialCtl:ResetDatas(materialData)
  self:CalculateWidth()
  self:_UpdateAnchor()
  self:_ResetAttrPos()
end

function AstrolabeTipView:OnEnter()
  AstrolabeTipView.super.OnEnter(self)
  self.closecomp.enabled = false
  self.closecomp.enabled = true
end

function AstrolabeTipView:GetSize()
  return self.BGImg.width, self.BGImg.height
end

function AstrolabeTipView:_ParseAttr(data)
  local base = data:GetEffect()
  if base then
    local sb = LuaStringBuilder.CreateAsTable()
    local config, displayName
    local PropNameConfig = Game.Config_PropName
    for k, v in pairs(base) do
      config = PropNameConfig[k]
      if config then
        displayName = config.RuneName ~= "" and config.RuneName or config.PropName
        sb:Append(displayName)
        if 0 < v then
          sb:Append("+")
        end
        if config.IsPercent == 1 then
          sb:Append(v * 100)
          sb:AppendLine("%")
        else
          sb:AppendLine(v)
        end
      end
    end
    sb:RemoveLast()
    self.attri.text = sb:ToString()
    sb:Destroy()
  end
  local special = data:GetSpecialEffect()
  if special then
    local specialConfig = Table_RuneSpecial[special]
    if specialConfig then
      local str = specialConfig.Runetip
      if Table_RuneSpecialDesc and Table_RuneSpecialDesc[str] then
        str = Table_RuneSpecialDesc[str].Text
      end
      if specialConfig.SkillTipParm then
        str = string.format(str, unpack(specialConfig.SkillTipParm))
      end
      self.attri.text = str
    end
  end
end

function AstrolabeTipView:_AddAnchor(widget)
  if self.anchors == nil then
    self.anchors = {}
  end
  self.anchors[#self.anchors + 1] = widget
end

function AstrolabeTipView:_UpdateAnchor()
  if self.anchors then
    for i = 1, #self.anchors do
      self.anchors[i]:ResetAndUpdateAnchors()
    end
  end
end

function AstrolabeTipView:SetPos(pos)
  if self.gameObject ~= nil then
    local p = self.gameObject.transform.position
    pos.z = p.z
    self.gameObject.transform.position = pos
  else
    self.pos = pos
  end
end

function AstrolabeTipView:CalculateWidth()
  local maxLabelWidth = 0
  local childCells = self.materialCtl:GetCells()
  local singleMaterialHeight = 0
  if self.materialCtl then
    for i = 1, #childCells do
      local childCell = childCells[i]
      local width = childCell:GetLabelWidth()
      singleMaterialHeight = childCell:GetHeight()
      if maxLabelWidth < width then
        maxLabelWidth = width
      end
    end
  end
  local materialCount = #childCells
  singleLineHeight = self.top.height + 82
  local fixedHeight = singleMaterialHeight * materialCount + singleLineHeight
  LuaVector3.Better_Set(tempVector3, 0, singleMaterialHeight * materialCount, 0)
  self.bottomLine.transform.localPosition = tempVector3
  local tempWidth = math.max(self.name.width, maxLabelWidth)
  local tempWidth = math.max(tempWidth, minWidth)
  local tempHeight = 0
  local attrSizeX, attrSizeY = self:_WrapText(fix)
  self.attri.width = attrSizeX
  self.attri:ProcessText()
  tempWidth = math.max(tempWidth, attrSizeX + fix)
  local height = attrSizeY + fixedHeight
  tempHeight = math.max(minHeight, height)
  tempHeight = math.min(maxHeight, tempHeight)
  if nil ~= self.BGImg then
    self.BGImg.width = tempWidth
    self.BGImg.height = tempHeight
  end
end

function AstrolabeTipView:_WrapText(fix)
  local width = 0
  self.attri:UpdateNGUIText()
  NGUIText.rectWidth = 10000
  NGUIText.regionWidth = 10000
  local size = NGUIText.CalculatePrintedSize(self.attri.text)
  width = math.max(size.x, minWidth - fix)
  width = math.min(width, maxWidth - fix)
  self.attri:UpdateNGUIText()
  NGUIText.rectWidth = width
  NGUIText.regionWidth = width
  size = NGUIText.CalculatePrintedSize(self.attri.text)
  return width, size.y
end

function AstrolabeTipView:_ResetAttrPos()
  tempVector3[1] = -(self.BGImg.width - fix) / 2
  self.attri.transform.localPosition = tempVector3
  self.scrollView:ResetPosition()
end

function AstrolabeTipView:AddIgnoreBounds(obj)
  if self.gameObject and self.closecomp then
    self.closecomp:AddTarget(obj.transform)
  end
end

function AstrolabeTipView:DestroySelf()
  GameObject.Destroy(self.gameObject)
end

function AstrolabeTipView:OnExit()
  self.anchors = nil
  return true
end
