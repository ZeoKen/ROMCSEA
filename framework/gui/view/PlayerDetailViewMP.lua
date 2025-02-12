autoImport("SubMediatorView")
PlayerDetailViewMP = class("PlayerDetailViewMP", SubMediatorView)
autoImport("RoleEquipItemCell")
autoImport("ProfessionInfoViewMP")

function PlayerDetailViewMP:Init(parent)
  self:CreateSelf(parent)
  self:InitUI()
end

function PlayerDetailViewMP:CreateSelf(parent)
  if self.created == true then
    return
  end
  if parent == nil then
    parent = self:FindGO("PlayerDetailViewMP")
    self.created = true
    self.gameObject_Load = self:LoadPreferb("view/PlayerDetailViewMP", parent, true)
    self.gameObject = parent
    self:Hide()
  else
    parent = self:FindGO(parent)
    self.created = true
    self.gameObject_Load = self:LoadPreferb("view/PlayerDetailViewMP", parent, true)
    self.gameObject = parent
    self:Hide()
  end
end

function PlayerDetailViewMP:HideMP()
end

function PlayerDetailViewMP:SetLocalPosition(x, y, z)
  if Slua.IsNull(self.gameObject_Load) then
    return
  end
  self.gameObject_Load.transform.localPosition = LuaGeometry.GetTempVector3(x, y, z)
end

function PlayerDetailViewMP:AddCloseButtonEvent()
  local closeButton = self:FindGO("CloseButton")
  self:AddClickEvent(closeButton, function()
    self:Hide()
  end)
end

function PlayerDetailViewMP:TransEquipGrid(grid, width)
  local equipGrid = {}
  equipGrid.grid = grid
  equipGrid.transform = grid.transform
  equipGrid.gameObject = grid.gameObject
  
  function equipGrid.Reposition(equipGrid_self)
    equipGrid_self.grid:Reposition()
    local childCount = equipGrid_self.transform.childCount
    if childCount == 13 then
      local cell13 = equipGrid_self.transform:GetChild(12)
      if cell13 then
        cell13.transform.localPosition = LuaGeometry.GetTempVector3(216, -488)
      end
    elseif childCount == 14 then
      local cell13 = equipGrid_self.transform:GetChild(12)
      if cell13 then
        cell13.transform.localPosition = LuaGeometry.GetTempVector3(width, -488)
      end
      local cell14 = equipGrid_self.transform:GetChild(13)
      if cell14 then
        cell14.transform.localPosition = LuaGeometry.GetTempVector3(width * 2, -488)
      end
    end
  end
  
  return equipGrid
end

function PlayerDetailViewMP:InitUI()
  self:SetLocalPosition(-264, 0, 0)
  self:AddCloseButtonEvent()
  self.roleTex = self:FindComponent("RoleTexture", UITexture)
  self.roleEquips = self:FindGO("RoleEquips")
  local playerGrid = self:FindComponent("PlayerEquipGrid", UIGrid, self.roleEquips)
  self.playerEquipGrid = self:TransEquipGrid(playerGrid, 129)
  self.playerRoleEquip = {}
  for i = 1, 14 do
    local go = self:LoadPreferb("cell/RoleEquipItemCell", playerGrid)
    go.name = "RoleEquipItemCell" .. i
    self.playerRoleEquip[i] = RoleEquipItemCell.new(go, i)
    self.playerRoleEquip[i]:AddEventListener(MouseEvent.MouseClick, self.ClickEquip, self)
  end
  self.chooseSymbol = self:FindGO("ChooseSymbol")
  local roleInfo = self:FindGO("RoleInfo")
  self.playerName = self:FindComponent("Name", UILabel, roleInfo)
  self.normalStick = self:FindComponent("NormalStick", UISprite)
  self.PlayerDetailViewMP = self:FindGO("PlayerDetailViewMP")
  self.PlayerDetailViewMP_UIPanel = self:FindGO("PlayerDetailViewMP"):GetComponent(UIPanel)
  self.BeforePanel = self:FindGO("BeforePanel", self.PlayerDetailViewMP)
  self.BeforePanel_UIPanel = self:FindGO("BeforePanel", self.PlayerDetailViewMP):GetComponent(UIPanel)
end

function PlayerDetailViewMP:ClickEquip(cellCtl)
  if cellCtl ~= nil and self.chooseEquip ~= cellCtl then
    local data = cellCtl.data
    if data and data.id == RoleEquipItemCell.FakeID then
      return
    end
    if data then
      self:ShowPlayerEquipTip(data, cellCtl.gameObject, {-190, 0})
      self.chooseSymbol.transform:SetParent(cellCtl.gameObject.transform, false)
      self.chooseSymbol.transform.localPosition = LuaGeometry.Const_V3_zero
      self.chooseSymbol:SetActive(true)
    else
      self:CancelChoose()
      self:ShowItemTip()
    end
    self.chooseEquip = cellCtl
  else
    self:CancelChoose()
    self:ShowItemTip()
  end
end

local tipOffset = {0, 0}

function PlayerDetailViewMP:ShowPlayerEquipTip(data, ignoreBound, offset, isClickMyself)
  local callback = function()
    self:CancelChoose()
  end
  local sdata = {
    itemdata = data,
    ignoreBounds = {ignoreBound},
    callback = callback
  }
  local itemtip = self:ShowItemTip(sdata, self.normalStick, nil, offset)
  local compareData
  if isClickMyself then
    compareData = self.playerEquipDatas[data.index]
  else
    compareData = BagProxy.Instance.roleEquip:GetEquipBySite(data.index)
  end
  if itemtip then
    if compareData then
      local cell = itemtip:GetCell(1)
      if cell then
        local compareFunc = function(data)
          self:CancelChoose()
          local sdata = {}
          if isClickMyself then
            sdata.itemdata = compareData
            sdata.compdata1 = data
          else
            sdata.itemdata = data
            sdata.compdata1 = compareData
          end
          self:ShowItemTip(sdata, self.normalStick, nil, tipOffset)
        end
        cell:AddTipFunc(ZhString.PlayerDetailView_CompareTip, compareFunc, data, true)
      end
    end
    itemtip:HideEquipedSymbol()
  end
end

function PlayerDetailViewMP:CancelChoose()
  self.chooseEquip = nil
  self.chooseSymbol.transform:SetParent(self.trans, false)
  self.chooseSymbol:SetActive(false)
end

function PlayerDetailViewMP:UpdateRoleName(name)
  self.playerName.text = name
end

function PlayerDetailViewMP:UpdateRoleDress_ByUserData(userdata, rpBody, rpHair, rpEye)
  if userdata == nil then
    redlog("userdata canNot be Null")
    return
  end
  local parts = Asset_Role.CreatePartArray()
  local partIndex = Asset_Role.PartIndex
  local partIndexEx = Asset_Role.PartIndexEx
  parts[partIndex.Body] = rpBody or userdata:Get(UDEnum.BODY) or 0
  parts[partIndex.Hair] = rpHair or userdata:Get(UDEnum.HAIR) or 0
  parts[partIndex.LeftWeapon] = userdata:Get(UDEnum.LEFTHAND) or 0
  parts[partIndex.RightWeapon] = userdata:Get(UDEnum.RIGHTHAND) or 0
  parts[partIndex.Head] = userdata:Get(UDEnum.HEAD) or 0
  parts[partIndex.Wing] = userdata:Get(UDEnum.BACK) or 0
  parts[partIndex.Face] = userdata:Get(UDEnum.FACE) or 0
  parts[partIndex.Tail] = userdata:Get(UDEnum.TAIL) or 0
  parts[partIndex.Eye] = rpEye or userdata:Get(UDEnum.EYE) or 0
  parts[partIndex.Mount] = 0
  parts[partIndex.Mouth] = userdata:Get(UDEnum.MOUTH) or 0
  parts[partIndexEx.Gender] = userdata:Get(UDEnum.SEX) or 0
  parts[partIndexEx.HairColorIndex] = userdata:Get(UDEnum.HAIRCOLOR) or 0
  parts[partIndexEx.EyeColorIndex] = userdata:Get(UDEnum.EYECOLOR) or 0
  UIModelUtil.Instance:SetRoleModelTexture(self.roleTex, parts, UIModelCameraTrans.Team)
  Asset_Role.DestroyPartArray(parts)
end

function PlayerDetailViewMP:UpdatePlayerRoleEquips(roleEquipsMap)
  if roleEquipsMap == nil then
    return
  end
  for pos, equipCell in pairs(self.playerRoleEquip) do
    equipCell:SetData(roleEquipsMap[pos])
  end
end

local SearChBagTypes = {
  1,
  2,
  4,
  6,
  7,
  9
}

function PlayerDetailViewMP:TransRoleEquipData_ByEquipsInfoSaveDatas(saveEquipDatas)
  if self.roleEquipsMap == nil then
    self.roleEquipsMap = {}
  else
    TableUtility.TableClear(self.roleEquipsMap)
  end
  local _BagProxy = BagProxy.Instance
  for k, v in pairs(saveEquipDatas) do
    local itemData = _BagProxy:GetItemByGuid(v.guid, SearChBagTypes)
    if itemData == nil then
      itemData = ItemData.new(RoleEquipItemCell.FakeID, v.type_id)
    end
    self.roleEquipsMap[v.pos] = itemData
  end
  return self.roleEquipsMap
end

function PlayerDetailViewMP:UpdateViewInfo_byUserSaveInfoData(dataInfo)
  if dataInfo == nil then
    return
  end
  self:UpdateRoleName(dataInfo:GetRoleName())
  local userdata = dataInfo:GetUserData()
  local count = 0
  for k, v in pairs(userdata.datas) do
    count = count + 1
  end
  local rpBody, rpHair, rpEye
  if userdata.datas ~= nil and count == 0 then
    userdata = Game.Myself.data.userdata
    rpBody, rpHair, rpEye = ProfessionProxy.Instance:ReplaceUserDataByProfession(userdata, dataInfo.job)
  end
  self:UpdateRoleDress_ByUserData(userdata, rpBody, rpHair, rpEye)
  local saveEquips = dataInfo:GetRoleEquipsSaveDatas() or {}
  local roleEquipsMap = self:TransRoleEquipData_ByEquipsInfoSaveDatas(saveEquips)
  self:UpdatePlayerRoleEquips(roleEquipsMap)
end

function PlayerDetailViewMP:UpdateViewInfo_byMyself()
  local myself = Game.Myself
  self:UpdateRoleName(myself.data.name)
  self:UpdateRoleDress_ByUserData(myself.data.userdata)
  self:UpdatePlayerRoleEquips(BagProxy.Instance.roleEquip.siteMap)
end

function PlayerDetailViewMP:OnClickBtn(userSaveInfoData)
  if userSaveInfoData == nil then
    return
  end
  self:Show()
  self:UpdateViewInfo_byUserSaveInfoData(userSaveInfoData)
end

function PlayerDetailViewMP:OnClickBtnFromProfessionInfoViewMP(data)
  if data == nil then
    self:Hide()
    return
  end
  local uipanels = Game.GameObjectUtil:GetAllComponentsInChildren(self.gameObject, UIPanel, true)
  local panel = Game.GameObjectUtil:FindCompInParents(self.gameObject, UIPanel)
  self.PlayerDetailViewMP_UIPanel.depth = panel.depth + 1
  for i = 1, #uipanels do
    uipanels[i].depth = uipanels[i].depth + panel.depth
  end
  self:Show()
  if data.showType == MPShowType.FromSave then
    self:UpdateViewInfo_byUserSaveInfoData(data.userSaveInfoData)
  elseif data.showType == MPShowType.FromSelf then
    self:UpdateViewInfo_byMyself()
  elseif data.showType == MPShowType.FromPurchasePreview then
    local myself = Game.Myself
    self:UpdateRoleName(myself.data.name)
    self:UpdateRoleDress_ByUserData(myself.data.userdata)
  end
end

function PlayerDetailViewMP:ShowMP()
  self.gameObject.transform.localPosition = LuaGeometry.Const_V3_zero
end

function PlayerDetailViewMP:Show()
  PlayerDetailViewMP.super.Show(self)
  if self.playerEquipGrid_resetPos ~= true then
    self.playerEquipGrid_resetPos = true
    self.playerEquipGrid:Reposition()
  end
end

function PlayerDetailViewMP:CloseUI(...)
  PlayerDetailViewMP.super.Hide(self)
end

function PlayerDetailViewMP:OnExit()
  PlayerDetailViewMP.super.OnExit(self)
  if self.playerRoleEquip then
    TableUtility.TableClear(self.playerRoleEquip)
  end
  if self.roleEquipsMap then
    TableUtility.TableClear(self.roleEquipsMap)
  end
end
