CardRaidBord = class("CardRaidBord", CoreView)
autoImport("Simple_OricalCardCell")
autoImport("OricalCardDetailInfo")
local loadDetailGO = function(parent)
  local cell = Game.AssetManager_UI:CreateAsset(ResourcePathHelper.UICell("OricalCardDetailInfo"))
  if not cell then
    return
  end
  cell.transform:SetParent(parent.transform, false)
  cell.transform.localPosition = LuaGeometry.Const_V3_zero
  return cell
end

function CardRaidBord.LoadPreferb_ByFullPath(path, parent, initPanel)
  local obj = Game.AssetManager_UI:CreateAsset(path, parent.gameObject)
  if obj == nil then
    errorLog(path)
    return
  end
  UIUtil.ChangeLayer(obj, parent.gameObject.layer)
  obj.transform.localPosition = LuaGeometry.GetTempVector3()
  if obj and initPanel then
    local upPanel = UIUtil.GetComponentInParents(obj, UIPanel)
    if upPanel then
      local panels = UIUtil.GetAllComponentsInChildren(obj, UIPanel, true)
      for i = 1, #panels do
        panels[i].depth = panels[i].depth + upPanel.depth
      end
    end
  end
  return obj, path
end

function CardRaidBord.CreateSelf(parent)
  local go = CardRaidBord.LoadPreferb_ByFullPath("GUI/v1/part/NewCardRaidBord", parent, true)
  return CardRaidBord.new(go)
end

function CardRaidBord:ctor(go)
  self.gameObject = go
  self:InitView()
end

function CardRaidBord:InitView()
  self.progressLab = self:FindComponent("ProgressLab", UILabel)
  self.gridGO = self:FindComponent("Cards", UIGrid)
  self.cardCtls = UIGridListCtrl.new(self.gridGO, Simple_OricalCardCell, "Simple_OricalCardCell")
  self.cardCtls:AddEventListener(MouseEvent.LongPress, self.ClickCardCell, self)
  self.bgCards = self:FindGO("BgCards")
  self.bgCards:SetActive(true)
  local cardDetailGO = loadDetailGO(self:FindGO("TipContainer"))
  self.cardDetailInfo = OricalCardDetailInfo.new(cardDetailGO)
  self.cardDetailInfo:Hide()
end

local str = "%d/%d"

function CardRaidBord:UpdateProgress()
  local dungeonProxy = DungeonProxy.Instance
  local cur = dungeonProxy:GetCurrentCardCount()
  if cur then
    self:Show(self.progressLab)
    self.progressLab.text = string.format(str, cur, dungeonProxy:GetTotalProcress())
  else
    self:Hide(self.progressLab)
  end
end

function CardRaidBord:ClickCardCell(param)
  local cell, state = param[1], param[2]
  if state then
    self:ShowCardDetailInfo(cell.data)
  else
    self.cardDetailInfo:Hide()
  end
end

function CardRaidBord:ShowCardDetailInfo(data)
  if data == nil then
    return
  end
  local cardId, num = data.id, data.num
  if cardId == nil then
    return
  end
  local cardData = Table_PveCard[cardId]
  if cardData == nil then
    self.cardDetailInfo:Hide()
    return
  end
  self.cardDetailInfo:Show()
  self.cardDetailInfo:SetData(cardData, num)
end

local animCells = {}

function CardRaidBord:PlayCardAnim()
  self:CancelCardAnimLt()
  local cells = self.cardCtls:GetCells()
  local cells_count = #cells
  local animDatas = {}
  local totalCount = 3 + #self.datas
  for i = 1, totalCount do
    if i <= cells_count then
      table.insert(animDatas, cells[i].data)
    elseif i <= 3 then
      table.insert(animDatas, 0)
    else
      table.insert(animDatas, self.datas[i - 3])
    end
  end
  self.cardCtls:ResetDatas(animDatas)
  cells = self.cardCtls:GetCells()
  local moveFunc = function()
    self:PlayCardEndAnimCall(3, function()
      self.cardCtls:ResetDatas(self.datas)
    end)
  end
  TableUtility.ArrayClear(animCells)
  for i = 1, cells_count do
    table.insert(animCells, cells[i])
  end
  self:_PlayCardEndAnim(moveFunc)
end

function CardRaidBord:_PlayCardEndAnim(callBack, callBackParam)
  local cell = table.remove(animCells, 1)
  if cell == nil then
    if callBack ~= nil then
      callBack(callBackParam)
    end
    return
  end
  cell:HideContent()
  local data, go = cell.data, cell.gameObject
  self:PlayCardEndAnim(data.id, go, function()
    self:_PlayCardEndAnim(callBack, callBackParam)
  end)
end

local CARD_END_EFFECT_ID = "133cards_round"

function CardRaidBord:PlayCardEndAnim(cardid, parent, callBack, callBackParam)
  self._PlayCardEndAnim_cardid = nil
  self._PlayCardEndAnim_callBack = nil
  self._PlayCardEndAnim_callBackParam = nil
  if self.cardEffect then
    self.cardEffect:Destroy()
  end
  if cardid == nil then
    return
  end
  self._PlayCardEndAnim_cardid = cardid
  self._PlayCardEndAnim_callBack = callBack
  self._PlayCardEndAnim_callBackParam = callBackParam
  self:PlayUIEffect(CARD_END_EFFECT_ID, parent, true, self.CardEndAnimCreate, self)
end

function CardRaidBord.CardEndAnimCreate(obj, self, assetEffect)
  self.cardEffect = assetEffect
  self.cardEffect:RegisterWeakObserver(self)
  local cardid = self._PlayCardEndAnim_cardid
  self._PlayCardEndAnim_cardid = nil
  local data = Table_PveCard[cardid]
  if data == nil then
    return
  end
  local iconsp = self:FindComponent("Icon", UISprite, assetEffect.gameObject)
  local headIcon = data.HeadIcon
  if headIcon == nil or headIcon == "" then
    local monsterId = data.MonsterID
    local monsterData = Table_Monster[monsterId]
    headIcon = monsterData and monsterData.Icon
  end
  if headIcon then
    IconManager:SetFaceIcon(headIcon, iconsp)
  end
end

function CardRaidBord:ObserverDestroyed(effect)
  if effect == self.cardEffect then
    self.cardEffect = nil
    local callBack, callBackParam = self._PlayCardEndAnim_callBack, self._PlayCardEndAnim_callBackParam
    self._PlayCardEndAnim_callBack = nil
    self._PlayCardEndAnim_callBackParam = nil
    if callBack ~= nil then
      callBack(callBackParam)
    end
  end
end

function CardRaidBord:CancelCardAnimLt()
  if self.lt then
    self.lt:cancel()
  end
  self.lt = nil
end

function CardRaidBord:PlayCardEndAnimCall(offset_count, callBack, callBackParam)
  local cells = self.cardCtls:GetCells()
  local cells_count = #cells
  if cells_count <= 3 then
    if callBack ~= nil and callBackParam then
      callBack(callBackParam)
    end
    return
  end
  local GetLocalPosition = LuaGameObject.GetLocalPosition
  local offseY = 95 * offset_count
  self:CancelCardAnimLt()
  if Slua.IsNull(self.gameObject) then
    return
  end
  TimeTickManager.Me():ClearTick(self)
  TimeTickManager.Me():CreateTickFromTo(0, 0, offseY, 400, function(owner, deltaTime, curValue)
    for i = 3, cells_count do
      local go = cells[i].gameObject
      go.transform.localPosition = LuaGeometry.GetTempVector3(0, -95 * (i - 1) + curValue)
    end
  end, self):SetCompleteFunc(function(owner, id)
    if callBack ~= nil then
      callBack(callBackParam)
    end
  end)
end

function CardRaidBord:UpdateCards()
  local nextCardIds = DungeonProxy.Instance:GetNextPlayingCardIds()
  if nextCardIds then
    local init = false
    if self.datas == nil then
      self.datas = {}
      init = true
    else
      TableUtility.ArrayClear(self.datas)
    end
    for i = 1, #nextCardIds do
      local data = Table_PveCard[nextCardIds[i]]
      if data then
        table.insert(self.datas, data)
      end
    end
    if init then
      self.cardCtls:ResetDatas(self.datas)
    else
      self:PlayCardAnim()
    end
  else
    self.cardCtls:ResetDatas(_EmptyTable)
  end
  self:UpdateProgress()
end

function CardRaidBord:Finish()
  self.cardCtls:ResetDatas(_EmptyTable)
  self.bgCards:SetActive(false)
end

function CardRaidBord:Destroy()
  self.cardDetailInfo:Destroy()
  TimeTickManager.Me():ClearTick(self)
  if not Slua.IsNull(self.gameObject) then
    GameObject.DestroyImmediate(self.gameObject)
  end
  self.gameObject = nil
end
