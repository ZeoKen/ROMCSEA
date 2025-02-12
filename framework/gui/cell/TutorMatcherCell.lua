autoImport("SocialBaseCell")
local baseCell = autoImport("BaseCell")
TutorMatcherCell = class("TutorMatcherCell", SocialBaseCell)
TutorMatcherCell.path = ResourcePathHelper.UICell("TutorMatcherCell")
local studentColor = LuaColor.New(0.47058823529411764, 0.5647058823529412, 0.9568627450980393)
local tutorColor = LuaColor.New(1, 0.8941176470588236, 0.5294117647058824)

function TutorMatcherCell:Init(parent)
  self:FindObjs()
  self:AddButtonEvt()
end

function TutorMatcherCell:FindObjs()
  TutorMatcherCell.super.FindObjs(self)
  self.typeLabel = self:FindGO("type"):GetComponent(UISprite)
  self.line = self:FindGO("line"):GetComponent(UISprite)
  self.lv = self:FindGO("Level"):GetComponent(UILabel)
  self.confirm = self:FindGO("Confirm")
  self.professionName = self:FindGO("profession"):GetComponent(UILabel)
  local confirmSP = self.confirm:GetComponent(UISprite)
  IconManager:SetArtFontIcon("tutor_icon_confirm", confirmSP)
  self.serverGO = self:FindGO("Server")
  self.serverLabel = self:FindGO("ServerLabel", self.serverGO):GetComponent(UILabel)
end

function TutorMatcherCell:AddButtonEvt()
  TutorMatcherCell.super.InitShow(self)
end

function TutorMatcherCell:SetType(type)
  self.type = type
end

function TutorMatcherCell:CreateSelf(parent)
  if parent then
    self.gameObject = self:CreateObj(TutorMatcherCell.path, parent)
    self:FindObjs()
  end
end

function TutorMatcherCell:SetData(data)
  TutorMatcherCell.super.SetData(self, data)
  self.data = data
  if data ~= nil then
    if data.findtutor then
      IconManager:SetUIIcon("tab_icon_08", self.typeLabel)
      self.typeLabel.color = studentColor
      self.line.color = studentColor
    else
      IconManager:SetUIIcon("tab_icon_05", self.typeLabel)
      self.typeLabel.color = tutorColor
      self.line.color = tutorColor
    end
    local sb = LuaStringBuilder.CreateAsTable()
    sb:Append("Base Lv.")
    sb:Append(data.level)
    self.lv.text = sb:ToString()
    sb:Destroy()
    self.professionName.text = ProfessionProxy.GetProfessionNameFromSocialData(data)
    if data.serverID and data.serverID ~= 0 and data.serverID ~= MyselfProxy.Instance:GetServerId() then
      self.serverGO:SetActive(true)
      self.serverLabel.text = data.serverID
    else
      self.serverGO:SetActive(false)
    end
  end
end

function TutorMatcherCell:UpdataStatus(status)
  self.confirm:SetActive(status)
end
