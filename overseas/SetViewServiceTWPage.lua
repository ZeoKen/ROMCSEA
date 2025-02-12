SetViewServiceTWPage = class("SetViewServiceTWPage", SetViewSubPage)
local serviceUrl = "https://www.facebook.com/RO.ForeverLove/?ref=bookmarks"
local fbUrl = "https://www.facebook.com/RO.ForeverLove"

function SetViewServiceTWPage:Init(initParama)
  SetViewServiceTWPage.super.Init(self, initParama)
  local Service = self:FindGO("Service")
  local ServiceTitle = self:FindGO("title", Service):GetComponent(UILabel)
  local ServiceContent = self:FindGO("content", Service):GetComponent(UILabel)
  ServiceTitle.text = ZhString.SetViewServiceTitle
  ServiceContent.text = serviceUrl
  local FB = self:FindGO("FB")
  local FBTitle = self:FindGO("title", FB):GetComponent(UILabel)
  local FBContent = self:FindGO("content", FB):GetComponent(UILabel)
  FBTitle.text = ZhString.SetViewServiceFbTitle
  FBContent.text = fbUrl
  local server = FunctionLogin.Me():getCurServerData()
  local serverID = server ~= nil and server.sid or 1
  local resVersion = VersionUpdateManager.CurrentVersion
  if resVersion == nil then
    resVersion = "Unknown"
  end
  local currentVersion = CompatibilityVersion.version
  local bundleVersion = GetAppBundleVersion.BundleVersion
  local version = string.format("%s,%s,%s", resVersion, currentVersion, bundleVersion)
  self.serviceBtn = self:FindGO("bugReportBtn")
  self:AddClickEvent(self.serviceBtn, function(go)
    Application.OpenURL("https://www.gnjoy.com.tw/Cs")
  end)
  self.notiToggle = self:FindGO("noticeTog"):GetComponent("UIToggle")
  self.oldStatus = OverSeas_TW.OverSeasManager.GetInstance():GetNotificationStatus()
  self.notiToggle.value = self.oldStatus
  EventDelegate.Add(self.notiToggle.onChange, function()
    EventManager.Me():PassEvent(SetViewEvent.SaveBtnStatus)
  end)
  self.accountCancel = self:FindGO("accountCancel")
  if GameConfig.Logout_MenuId == 1 then
    self.accountCancel:SetActive(true)
    self:AddClickEvent(self.accountCancel, function(go)
      OverSeas_TW.OverSeasManager.GetInstance():AccountCancellation()
      Game.Me():BackToLogo()
    end)
  else
    self.accountCancel:SetActive(false)
  end
end

function SetViewServiceTWPage:Save()
  self.oldStatus = self.notiToggle.value
  OverSeas_TW.OverSeasManager.GetInstance():SetNotification(self.notiToggle.value)
end

function SetViewServiceTWPage:IsChanged()
  return self.oldStatus ~= self.notiToggle.value
end
