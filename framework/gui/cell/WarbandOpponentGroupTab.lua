WarbandOpponentGroupTab = class("WarbandOpponentGroupTab", BaseCell)
local groupName = {
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H"
}

function WarbandOpponentGroupTab:Init()
  WarbandOpponentGroupTab.super.Init(self)
  self.groupName = self:FindComponent("Name", UILabel)
  self.toggle = self.gameObject:GetComponent(UIToggle)
  self:SetEvent(self.gameObject, function()
    self:SetTog(true)
    self:PassEvent(MouseEvent.MouseClick, self)
  end)
end

function WarbandOpponentGroupTab:SetTog(v)
  self.toggle:Set(v)
end

function WarbandOpponentGroupTab:SetData(data)
  if data then
    self.gameObject:SetActive(true)
    self.data = data
    self.groupName.text = data.isPlayoff and ZhString.Warband_PlayoffTabName or string.format(ZhString.Warband_OppenentTabName, groupName[data.index])
  else
    self.gameObject:SetActive(false)
  end
end
