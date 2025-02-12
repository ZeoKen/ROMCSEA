local BaseCell = autoImport("BaseCell")
GuildJobChangeCell = class("GuildJobChangeCell", BaseCell)
GuildJobChangeCell.ChooseSprite = "com_btn_2"
GuildJobChangeCell.ChooseLabelColor = Color(0.6235294117647059, 0.30980392156862746, 0.03529411764705882)
GuildJobChangeCell.UnChooseSprite = "com_btn_1"
GuildJobChangeCell.UnChooseLabelColor = Color(0.18823529411764706, 0.2549019607843137, 0.5764705882352941)

function GuildJobChangeCell:Init()
  self.label = self:FindComponent("Label", UILabel)
  self.bg = self:FindComponent("Bg", UISprite)
  self:AddCellClickEvent()
end

function GuildJobChangeCell:SetData(data)
  self.data = data
  if data then
    if self.data.id == GuildJobType.ViceChairman then
      local nowNum = #GuildProxy.Instance.myGuildData:GetViceChairmanList()
      local maxNum = GuildProxy.Instance.myGuildData:GetGuildConfig().Management
      self.label.text = string.format("%s(%s/%s)", self.data.name, tostring(nowNum), tostring(maxNum))
    else
      self.label.text = data.name
    end
    self:SetChoose()
    self:SetEnable()
  end
end

function GuildJobChangeCell:SetEnable(b)
  if not b then
    if not self.data.choose then
      local myGuildMemberData = GuildProxy.Instance:GetMyGuildMemberData()
      if self.data.id == GuildJobType.Chairman then
        b = GuildProxy.Instance:CanJobDoAuthority(myGuildMemberData.job, GuildAuthorityMap.ChangePresident)
      else
        b = myGuildMemberData.job < self.data.id
      end
    else
      b = true
    end
  end
  if not b then
    self:SetTextureGrey(self.gameObject)
    local boxCollider = self.gameObject:GetComponentInChildren(BoxCollider)
    boxCollider.enabled = false
  else
    local boxCollider = self.gameObject:GetComponentInChildren(BoxCollider)
    boxCollider.enabled = true
  end
end

function GuildJobChangeCell:SetChoose(choose)
  choose = choose or self.data.choose
  self.bg.spriteName = choose and GuildJobChangeCell.ChooseSprite or GuildJobChangeCell.UnChooseSprite
  self.label.effectColor = choose and GuildJobChangeCell.ChooseLabelColor or GuildJobChangeCell.UnChooseLabelColor
end
