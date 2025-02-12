GuildAssetPage = class("GuildAssetPage", SubView)
autoImport("GuildAssetCombineItemCell")
local tempColor = LuaColor.New(1, 1, 1, 1)

function GuildAssetPage:Init(parent)
  self:InitView()
  self:MapEvent()
end

function GuildAssetPage:InitView()
  self.tipData = {}
  self.tipData.funcConfig = {}
  self.GuildAssetLab = self:FindComponent("GuildAsset", UILabel)
  self.wrapContainer = self:FindGO("AssetWrap")
  local wrapConfig = {
    wrapObj = self.wrapContainer,
    pfbNum = 6,
    cellName = "GuildAssetCombineItemCell",
    control = GuildAssetCombineItemCell
  }
  self.wraplist = WrapCellHelper.new(wrapConfig)
  self.wraplist:AddEventListener(MouseEvent.MouseClick, self.HandleClickItem, self)
  self.assetNoneTip = self:FindGO("AssetNoneTip")
end

function GuildAssetPage:OnEnter()
  GuildAssetPage.super.OnEnter(self)
  self:UpdateGuildAssetInfo()
end

function GuildAssetPage:HandleClickItem(cellctl)
  if cellctl and cellctl.data then
    self.tipData.itemdata = cellctl.data
    self:ShowItemTip(self.tipData, cellctl.icon, NGUIUtil.AnchorSide.Right, {211, 0})
  end
end

function GuildAssetPage:UpdateGuildAssetInfo()
  local myGuildData = GuildProxy.Instance.myGuildData
  if myGuildData then
    self.GuildAssetLab.text = string.format(ZhString.GuildAsset_AssetNum, myGuildData.asset or 0)
    self:GreyToggle(false)
    local list = myGuildData:GetGuildAsset()
    if list then
      self:SetData(list)
    end
    local hasData = list and 0 < #list and true or false
    self.assetNoneTip:SetActive(not hasData)
    self.wrapContainer:SetActive(hasData)
  else
    self:GreyToggle(true)
  end
end

function GuildAssetPage:GreyToggle(b)
  if self.container.assetTog then
    local tog = self.container.assetTog.gameObject
    tog:GetComponent(BoxCollider).enabled = not b
    local sprite = self:FindComponent("Background", UISprite, tog)
    local label = self:FindComponent("NameLabel", UILabel, tog)
    if label then
      if b then
        LuaColor.Better_Set(tempColor, 0.00392156862745098, 0.00784313725490196, 0.011764705882352941)
        sprite.color = tempColor
        LuaColor.Better_Set(tempColor, 0.615686274509804, 0.615686274509804, 0.615686274509804)
        label.effectColor = tempColor
      else
        LuaColor.Better_Set(tempColor, 1, 1, 1, 1)
        sprite.color = tempColor
        LuaColor.Better_Set(tempColor, 0.11372549019607843, 0.17647058823529413, 0.4627450980392157)
        label.effectColor = tempColor
      end
    end
  end
end

function GuildAssetPage:SetData(datas, noResetPos)
  local newdata = self:ReUnitData(datas, 10)
  self.wraplist:UpdateInfo(newdata)
  self.wraplist:ResetPosition()
end

function GuildAssetPage:ReUnitData(datas, rowNum)
  if not self.unitData then
    self.unitData = {}
  else
    TableUtility.ArrayClear(self.unitData)
  end
  if datas ~= nil and 0 < #datas then
    for i = 1, #datas do
      local i1 = math.floor((i - 1) / rowNum) + 1
      local i2 = math.floor((i - 1) % rowNum) + 1
      self.unitData[i1] = self.unitData[i1] or {}
      self.unitData[i1][i2] = datas[i]
    end
  end
  return self.unitData
end

function GuildAssetPage:MapEvent()
  self:AddListenEvt(ServiceEvent.GuildCmdQueryPackGuildCmd, self.UpdateGuildAssetInfo)
  self:AddListenEvt(ServiceEvent.GuildCmdPackUpdateGuildCmd, self.UpdateGuildAssetInfo)
end

function GuildAssetPage:OnExit()
  TipsView.Me():HideCurrent()
  GuildAssetPage.super.OnExit(self)
end
