autoImport("CoreView")
PetPackagePart = class("PetPackagePart", CoreView)
autoImport("BagItemCell")
autoImport("WrapListCtrl")
PetPackagePart.IsNoticeShow = "ServantMainView_IsNoticeShow"

function PetPackagePart:ctor()
end

local PetPackagePart_Path = "GUI/v1/part/PetPackagePart"

function PetPackagePart:CreateSelf(parent)
  if self.inited == true then
    return
  end
  self.inited = true
  self.gameObject = self:LoadPreferb_ByFullPath(PetPackagePart_Path, parent, true)
  self:UpdateLocalPosCache()
  self:InitPart()
end

function PetPackagePart:InitPart()
  self:InitScrollPull()
  self.closeButton = self:FindGO("CloseButton")
  self:AddClickEvent(self.closeButton, function(go)
    self:Hide()
  end)
  self.petHelpButton = self:FindGO("PetHelpButton")
  self:RegistShowGeneralHelpByHelpID(2100, self.petHelpButton)
  local container = self:FindGO("ItemContainer")
  self.itemCtrl = WrapListCtrl.new(container, BagItemCell, "BagItemCell", WrapListCtrl_Dir.Vertical, 4, 104)
  self.itemCtrl:AddEventListener(MouseEvent.MouseClick, self.ClickItemCell, self)
  self.itemCells = self.itemCtrl:GetCells()
  self.normalStick = self:FindComponent("NormalStick", UIWidget)
  self.noneTip = self:FindGO("NoneTip")
  self.closecomp = self.gameObject:GetComponent(CloseWhenClickOtherPlace)
  
  function self.closecomp.callBack(go)
    self:Hide()
  end
  
  self:MapEvent()
end

function PetPackagePart:InitScrollPull()
  self.waitting = self:FindComponent("Waitting", UILabel)
  self.scrollView = self:FindComponent("ItemScrollView", ROUIScrollView)
  self.panel = self.scrollView.gameObject:GetComponent(UIPanel)
  
  function self.scrollView.OnBackToStop()
    self.waitting.text = ZhString.ItemNormalList_Refreshing
  end
  
  function self.scrollView.OnStop()
    self.scrollView:Revert()
    ServiceItemProxy.Instance:CallPackageSort(SceneItem_pb.EPACKTYPE_PET)
  end
  
  function self.scrollView.OnPulling(offsetY, triggerY)
    self.waitting.text = offsetY < triggerY and ZhString.ItemNormalList_PullRefresh or ZhString.ItemNormalList_CanRefresh
  end
  
  function self.scrollView.OnRevertFinished()
    self.waitting.text = ZhString.ItemNormalList_PullRefresh
  end
end

function PetPackagePart:AddIgnoreBounds(obj)
  if self.gameObject and self.closecomp then
    self.closecomp:AddTarget(obj.transform)
  end
end

function PetPackagePart:ClickItemCell(cellCtl)
  local go = cellCtl and cellCtl.gameObject
  local data = cellCtl and cellCtl.data
  local newChooseId = data and data.id or 0
  if self.chooseId ~= newChooseId then
    self.chooseId = newChooseId
    self:ShowPackageItemTip(data, go)
  else
    self.chooseId = 0
    self:ShowPackageItemTip()
  end
  for _, cell in pairs(self.itemCells) do
    cell:SetChooseId(self.chooseId)
  end
end

local PACK_FASHION_LEFTVIEWSTATE = "PackageView_LeftViewState_Fashion"

function PetPackagePart:ShowPackageItemTip(data, cellGO)
  if data == nil then
    self:ShowItemTip()
    return
  end
  local offset = {}
  local x = LuaGameObject.InverseTransformPointByTransform(UIManagerProxy.Instance.UIRoot.transform, cellGO.transform, Space.World)
  if 0 < x then
    offset[1] = -650
    offset[2] = 0
  else
    offset[1] = 190
    offset[2] = 0
  end
  local callback = function()
    self.chooseId = 0
    for _, cell in pairs(self.itemCells) do
      cell:SetChooseId(self.chooseId)
    end
  end
  local state = FunctionItemFunc.Me():GetLeftViewState()
  local sdata = {
    itemdata = data,
    ignoreBounds = ignoreBounds,
    callback = callback,
    funcConfig = FunctionItemFunc.GetItemFuncIds(data.staticData.id, nil, state == PACK_FASHION_LEFTVIEWSTATE)
  }
  local itemtip = self:ShowItemTip(sdata, self.normalStick, NGUIUtil.AnchorSide.Right, offset)
  itemtip:AddIgnoreBounds(self.gameObject)
  self:AddIgnoreBounds(itemtip.gameObject)
end

function PetPackagePart:UpdateInfo()
  local petBag = BagProxy.Instance.petBagData
  local items = petBag:GetItems()
  if #items == 0 then
    self.noneTip:SetActive(true)
    self.scrollView.gameObject:SetActive(false)
    return
  else
    self.noneTip:SetActive(false)
    self.scrollView.gameObject:SetActive(true)
  end
  self.itemCtrl:ResetDatas(items)
end

local tempV3 = LuaVector3()

function PetPackagePart:SetPos(x, y, z)
  if self.gameObject then
    LuaVector3.Better_Set(tempV3, x, y, z)
    self.gameObject.transform.position = tempV3
    self:UpdateLocalPosCache()
  end
end

function PetPackagePart:UpdateLocalPosCache()
  self.localPos_x, self.localPos_y, self.localPos_z = LuaGameObject.GetLocalPosition(self.gameObject.transform)
end

function PetPackagePart:SetLocalOffset(x, y, z)
  LuaVector3.Better_Set(tempV3, self.localPos_x + x, self.localPos_y + y, self.localPos_z + z)
  self.gameObject.transform.localPosition = tempV3
end

function PetPackagePart:MapEvent()
end

function PetPackagePart:Show()
  if not self.inited then
    return
  end
  local petBag = BagProxy.Instance.petBagData
  local items = petBag:GetItems()
  local isNoticeShow = FunctionPlayerPrefs.Me():GetBool(PetPackagePart.IsNoticeShow)
  if not isNoticeShow and 0 < #items then
    self.closecomp.enabled = false
    GameFacade.Instance:sendNotification(UIEvent.ShowUI, {
      viewname = "PetPackagePopView",
      viewdata = {msgid = 8026}
    })
  end
  self.gameObject:SetActive(true)
  EventManager.Me():AddEventListener(ItemEvent.PetUpdate, self.UpdateInfo, self)
  EventManager.Me():AddEventListener(UICloseEvent.GeneralHelpClose, self.ResetClosecomp, self)
  EventManager.Me():AddEventListener(UICloseEvent.PetPackagePopViewClose, self.ResetClosecomp, self)
  self:UpdateInfo()
  self.itemCtrl:ResetPosition()
end

function PetPackagePart:Hide()
  if not self.inited then
    return
  end
  ServiceItemProxy.Instance:CallBrowsePackage(SceneItem_pb.EPACKTYPE_PET)
  self.gameObject:SetActive(false)
  EventManager.Me():RemoveEventListener(ItemEvent.PetUpdate, self.UpdateInfo, self)
  EventManager.Me():RemoveEventListener(UICloseEvent.GeneralHelpClose, self.ResetClosecomp, self)
  EventManager.Me():RemoveEventListener(UICloseEvent.PetPackagePopViewClose, self.ResetClosecomp, self)
end

function PetPackagePart:ResetClosecomp()
  self.closecomp.enabled = true
end
