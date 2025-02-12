autoImport("NewGvgRankCell")
NewSuperGvgRankCell = class("NewSuperGvgRankCell", NewGvgRankCell)

function NewSuperGvgRankCell:FindObj()
  NewSuperGvgRankCell.super.FindObj(self)
  self.guildNameGvgGroupLab = self:FindGO("GuildNameGvgGroup")
  self.guildNameGvgGroupLabSp = SpriteLabel.new(self.guildNameGvgGroupLab, nil, 18, 18, true, 0.6)
end

function NewSuperGvgRankCell:SetData(data)
  NewSuperGvgRankCell.super.SetData(self, data)
  self:SetSpriteLab()
end

function NewSuperGvgRankCell:SetSpriteLab()
  if not self.guildNameGvgGroupLabSp then
    return
  end
  if not self.data then
    return
  end
  local guildName = self.data:GetGuildName()
  local gvgGroup = self.data:GetZoneId()
  self.guildNameGvgGroupLabSp:SetText(string.format(ZhString.NewGVG_GroupIDSP, guildName, gvgGroup))
end
