autoImport("FunctionLoginBase")
FunctionLoginTDSG = class("FunctionLoginTDSG", FunctionLoginBase)

function FunctionLoginTDSG.Me()
  if nil == FunctionLoginTDSG.me then
    FunctionLoginTDSG.me = FunctionLoginTDSG.new()
  end
  return FunctionLoginTDSG.me
end

function FunctionLoginTDSG:startSdkGameLogin(callback)
  LogUtility.InfoFormat("startSdkGameLogin:isLogined:{0}", self:isLogined())
  local isLogined = self:isLogined()
  if not isLogined then
    self:startSdkLogin(function(code, msg)
      self:SdkLoginHandler(code, msg, function()
        self:startAuthAccessToken(function()
          if callback then
            callback()
          end
        end)
      end)
    end)
  elseif not self.loginData then
    self:startAuthAccessToken(function()
      if callback then
        callback()
      end
    end)
  elseif callback then
    callback()
  end
end

function FunctionLoginTDSG:startAuthAccessToken(callback)
  GameFacade.Instance:sendNotification(NewLoginEvent.StartShowWaitingView)
  self.callback = callback
  self:RequestAuthAccToken()
end

function FunctionLoginTDSG:requestRegistUrlHost(url, callback, address, privateMode)
  local phoneplat = ApplicationInfo.GetRunPlatformStr()
  local timestamp = os.time()
  timestamp = string.format("&timestamp=%s&phoneplat=%s", timestamp, phoneplat)
  local requests = HttpWWWSeveralRequests()
  if privateMode or self.privateMode then
    local ip = NetConfig.PrivateAuthServerUrl
    ip = string.format("http://%s%s%s", ip, url, timestamp)
    LogUtility.InfoFormat("FunctionLogin:requestGetUrlHost address url:{0}", ip)
    local order = HttpWWWRequestOrder(ip, NetConfig.HttpRequestTimeOut, nil, false, true)
    requests:AddOrder(order)
  elseif address and "" ~= address then
    local ip = address
    ip = string.format("%s%s%s", ip, url, timestamp)
    LogUtility.InfoFormat("FunctionLogin:requestGetUrlHost address url:{0}", ip)
    local order = HttpWWWRequestOrder(ip, NetConfig.HttpRequestTimeOut, nil, false, true)
  else
    local ips = FunctionGetIpStrategy.Me():getRequestAddresss()
    for i = 1, #ips do
      local ip = ips[i]
      ip = string.format("%s%s%s", ip, url, timestamp)
      LogUtility.InfoFormat("FunctionLogin:requestGetUrlHost url:{0}", ip)
      local order = HttpWWWRequestOrder(ip, NetConfig.HttpRequestTimeOut, nil, false, true)
      requests:AddOrder(order)
    end
  end
  requests:SetCallBacks(function(response)
    callback(NetConfig.ResponseCodeOk, response.resString)
  end, function(order)
    local IsOverTime = order.IsOverTime
    LogUtility.InfoFormat("FunctionLogin:requestGetUrlHost IsOverTime:{0}", IsOverTime)
    LogUtility.InfoFormat("FunctionLogin:requestGetUrlHost occur error,url:{0},address:{1},errorMsg:{2}", url, address, order.orderError)
    callback(FunctionLogin.AuthStatus.OherError, order)
  end)
  requests:StartRequest()
end

function FunctionLoginTDSG:GetRegistUrl(token, serverData)
  local authUrl = NetConfig.GetAccDataAddress
  local version = self:getServerVersion()
  local plat = self:GetPlat()
  local sid = serverData.sid
  local clientCode = CompatibilityVersion.version
  local vd = self:getvd()
  local debug = FunctionLogin.Me():isDebug()
  if debug then
    clientCode = FunctionLogin.Me().debugClientCode
  end
  local url = string.format("%s%s&plat=%s&version=%s&clientCode=%s&vd=%s&sid=%s", authUrl, token, plat, version, clientCode, vd, sid)
  return url
end

function FunctionLoginTDSG:GetTDSG_UserInfo()
  return ""
end

function FunctionLoginTDSG:GetTDSG_MacKey()
  local debug = FunctionLogin.Me():isDebug()
  if debug then
    return FunctionLogin.Me().debugToken
  else
    local macKey = FunctionSDK.Instance:GetMacKey()
    helplog("tdsg macKey ", tostring(macKey))
    if not macKey or macKey == "" then
      return nil
    else
      return macKey
    end
  end
end

function FunctionLoginTDSG:GetTDSG_ClientID()
  local BundleID = AppBundleConfig.BundleID
  return AppBundleConfig.TDSG_Config[BundleID] or ""
end

function FunctionLoginTDSG:RequestAuthAccToken()
  FunctionTyrantdb.Instance:trackEvent("#GameAuthVerifyStart", nil)
  OverseaHostHelper:RefreshPriceInfo()
  local phoneplat = ApplicationInfo.GetRunPlatformStr()
  local appPreVersion = CompatibilityVersion.appPreVersion
  local accToken = self:getToken()
  Debug.LogFormat("getToken accToken : {0}", tostring(accToken))
  if accToken then
    local version = self:getServerVersion()
    local plat = self:GetPlat()
    local clientCode = CompatibilityVersion.version
    local clientV2Code = 0
    local resVersion = VersionUpdateManager.CurrentVersion
    if resVersion == nil then
      resVersion = "Unknown"
    end
    pcall(function()
      if not BranchMgr.IsChina() then
        clientV2Code = OverseaHostHelper:GetClientV2Code()
      end
    end)
    local url
    local macKey = self:GetTDSG_MacKey()
    local old_deviceId = self:GetOld_DeviceID()
    local new_deviceId = self:GetNew_DeviceID()
    url = string.format("%s/auth?sid=%s&p=%s&sver=%s&cver=%s&client_id=%s&mac_key=%s&lang=%s", NetConfig.NewAccessTokenAuthHost[1], accToken, plat, version, clientCode, self:GetTDSG_ClientID(), macKey, ApplicationInfo.GetSystemLanguage())
    url = string.format("%s&old_deviceid=%s&new_deviceid=%s", url, old_deviceId, new_deviceId)
    url = string.format("%s&appPreVersion=%s&phoneplat=%s", url, appPreVersion, phoneplat)
    url = string.format("%s&ver=6.x", url)
    local finger_print = BuglyManager.GetInstance():GetOneidData()
    local form = WWWForm()
    form:AddField("finger_print", finger_print)
    OverseaHostHelper.lastAuthUrl = url
    Debug.LogFormat("Oversea RequestAuthAccToken url : {0}", url)
    local order = HttpWWWRequestOrder(url, NetConfig.HttpRequestTimeOut, form, false, true)
    if order then
      self.hasHandleResp = false
      order:SetCallBacks(function(response)
        GameFacade.Instance:sendNotification(NewLoginEvent.StopShowWaitingView)
        self.hasHandleResp = true
        self:LoginDataHandler(NetConfig.ResponseCodeOk, response.resString, self.callback)
      end, function(order)
        self.hasHandleResp = true
        GameFacade.Instance:sendNotification(NewLoginEvent.StopShowWaitingView)
        self:LoginDataHandler(FunctionLogin.AuthStatus.OverTime, "", self.callback)
      end, function(order)
        self.hasHandleResp = true
        GameFacade.Instance:sendNotification(NewLoginEvent.StopShowWaitingView)
        local errorCode = FunctionLogin.AuthStatus.OherError
        if nil ~= order then
          errorCode = order.errorWraper.ErrorCode
          local errorMsg = order.errorWraper.ErrorMessage
          helplog("RequestAuthAccToken lerrorMsg:", errorMsg)
        end
        self:LoginDataHandler(errorCode, "", self.callback)
      end)
      Game.HttpWWWRequest:RequestByOrder(order)
    end
  else
    MsgManager.ShowMsgByIDTable(1017, {
      FunctionLogin.ErrorCode.RequestAuthAccToken_NoneToken
    })
    GameFacade.Instance:sendNotification(NewLoginEvent.LoginFailure)
  end
end
