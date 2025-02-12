local baseCell = autoImport("BaseCell")
autoImport("AchievementCategoryChildCell")
AchievementCategoryCell = class("AchievementCategoryCell", baseCell)
local CheckInvalid = function(achievementId)
  return false
end

function AchievementCategoryCell:Init()
  self:initView()
  self:initData()
  self:AddCellClickEvent()
end

function AchievementCategoryCell:initData()
  self.isShowChild = false
  self:Hide(self.childGrid.gameObject)
end

function AchievementCategoryCell:initView()
  self.Name = self:FindGO("Name"):GetComponent(UILabel)
  self.selectedBg = self:FindGO("selectedBg")
  self.Value = self:FindComponent("Value", UILabel)
  self.bg = self:FindComponent("bg", UISprite)
  self.childGrid = self:FindComponent("child", UIGrid)
  self.categoryGrid = UIGridListCtrl.new(self.childGrid, AchievementCategoryChildCell, "AchievementCategoryChildCell")
  self.categoryGrid:AddEventListener(MouseEvent.MouseClick, self.childCellClick, self)
  self.slider = self:FindComponent("foreSp", UISlider)
  self.foreSp = self:FindComponent("foreSp", UISprite)
  self.progress = self:FindGO("progress")
  self.totalProcessLabel = self:FindGO("TotalProcessLabel"):GetComponent(UILabel)
end

function AchievementCategoryCell:childCellClick(cellCtl)
  if cellCtl and cellCtl.isSelected then
    return
  end
  self:PassEvent(AdventureAchievementPage.childGroupCellClick, cellCtl)
  local cells = self.categoryGrid:GetCells()
  if cells and 0 < #cells then
    for i = 1, #cells do
      local cell = cells[i]
      if cell == cellCtl then
        cell:setSelected(true)
      else
        cell:setSelected(false)
      end
    end
  end
end

function AchievementCategoryCell:getSubChildCells()
  return self.categoryGrid:GetCells()
end

function AchievementCategoryCell:SetData(data)
  self.data = data
  self.Name.text = data.staticData.Name
  if data.staticData.id == AdventureAchieveProxy.HomeCategoryId then
    self:Hide(self.Value.gameObject)
    self:Hide(self.progress)
    self:Show(self.totalProcessLabel.gameObject)
    local unlock, total = AdventureAchieveProxy.Instance:getTotalAchieveProgress()
    local value = math.floor(unlock / total * 1000) / 10
    self.totalProcessLabel.text = string.format(ZhString.AdventureAchievePage_AchievementTabTitle, value)
  else
    self:Show(self.progress)
    self:Show(self.Value.gameObject)
    self:Hide(self.totalProcessLabel.gameObject)
    local unlock, total = AdventureAchieveProxy.Instance:getAchieveAndTotalNum(data.staticData.id)
    self.foreSp.spriteName = self.data.staticData.BackImage
    self.Value.text = unlock .. "/" .. total
    self.slider.value = unlock / total
    local list = {}
    for k, v in pairs(data.childs) do
      if not CheckInvalid(v.staticData.id) then
        local childUnlock, childTotal = AdventureAchieveProxy.Instance:getAchieveAndTotalNum(data.staticData.id, v.staticData.id)
        if 0 < childTotal then
          table.insert(list, v)
        end
      end
    end
    table.sort(list, function(l, r)
      return l.staticData.id < r.staticData.id
    end)
    self.categoryGrid:ResetDatas(list)
  end
end

function AchievementCategoryCell:clickEvent()
  if self.isSelected then
    self.isShowChild = not self.isShowChild
    self.childGrid.gameObject:SetActive(self.isShowChild)
  end
end

function AchievementCategoryCell:setSelected(isSelected)
  if self.isSelected ~= isSelected then
    self.isSelected = isSelected
    self.selectedBg.gameObject:SetActive(isSelected)
    if isSelected then
      self.isShowChild = true
      self:Show(self.childGrid.gameObject)
    else
      self.isShowChild = false
      self:Hide(self.childGrid.gameObject)
      self:childCellClick()
    end
  end
end
