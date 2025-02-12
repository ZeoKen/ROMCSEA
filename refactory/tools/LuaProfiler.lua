autoImport("LuaProfilerSample")
autoImport("LogUtility")
autoImport("LuaProfilerStackCell")
LuaProfiler = class("LuaProfiler")
LuaProfiler.stackCell = {}
local state = {Stop = 0, Start = 1}
local curState = 0
local noUsePool = {}
local inUsePool = {}
local inRunningPool = {}
local stackPool = {}
local stackCellPool = {}
local newNumber = 100
local _collectgarbage = collectgarbage
local getinfo = debug.getinfo
local remove = table.remove
local stackName = ""
LuaProfiler.simpleSample1 = LuaProfilerSample.new("Simple1")
LuaProfiler.simpleSample2 = LuaProfilerSample.new("Simple2")
LuaProfiler.simpleSample3 = LuaProfilerSample.new("Simple3")
LuaProfiler.simpleSample4 = LuaProfilerSample.new("Simple4")
LuaProfiler.simpleSample5 = LuaProfilerSample.new("Simple5")

function LuaProfiler.SimpleStart()
  simpleSample1:Start()
end

function LuaProfiler.SimpleStop()
  simpleSample1:Stop()
  return simpleSample1
end

function LuaProfiler.BeginMemTest(sample)
  if curState == state.Start then
    sample:Start()
  end
end

function LuaProfiler.StopMemTest(sample)
  if curState == state.Start then
    sample:Stop()
    sample.totalMemUsage = sample.totalMemUsage + sample.usedMemory
  end
end

function LuaProfiler.BeginStart()
  if curState == state.Stop then
    curState = state.Start
    LogUtility.Info("StartTotalMem = " .. _collectgarbage("count"))
  end
end

function LuaProfiler.StopStart()
  if curState == state.Start then
    curState = state.Stop
    LogUtility.Info("EndTotalMem = " .. _collectgarbage("count"))
    LogUtility.Info("simpleSample1 = " .. LuaProfiler.simpleSample1.totalMemUsage)
    LogUtility.Info("simpleSample2 = " .. LuaProfiler.simpleSample2.totalMemUsage)
    LogUtility.Info("simpleSample3 = " .. LuaProfiler.simpleSample3.totalMemUsage)
    LogUtility.Info("simpleSample4 = " .. LuaProfiler.simpleSample4.totalMemUsage)
    LogUtility.Info("simpleSample5 = " .. LuaProfiler.simpleSample5.totalMemUsage)
  end
end

local InstantiateSample = function()
  local new
  for i = 1, newNumber do
    new = LuaProfilerSample.new()
    noUsePool[#noUsePool + 1] = new
  end
end
local InstantiateStackCell = function()
  local new
  for i = 1, newNumber do
    new = LuaProfilerStackCell.new()
    stackCellPool[#stackCellPool + 1] = new
  end
end
local GetStackCell = function()
  if #stackCellPool <= 0 then
    InstantiateStackCell()
  end
  local _cell = stackCellPool[1]
  remove(stackCellPool, 1)
  return _cell
end
local FindParent = function(_stacklayer, _index)
  if _stacklayer == 1 then
    return nil
  end
  local pool = stackPool[stackName]
  for i = _index - 1, 1, -1 do
    if pool[i].stacklayer == _stacklayer - 1 then
      return pool[i]
    end
  end
end
local AddStackName = function(key)
  stackName = stackName .. key
end
local SubStackName = function(sample)
  totalStackLen = getLen(stackName)
  tempStackLen = getLen(sample.callingSource)
  subLen(stackName, 0, totalStackLen - tempStackLen)
end

function LuaProfiler.ClearStack()
  local len
  for key, value in pairs(stackPool) do
    len = #value
    for i = 1, len do
      local cell = value[i]
      cell:Reset()
      stackCellPool[#stackCellPool + 1] = cell
      value[i] = nil
    end
  end
  stackPool = {}
  _collectgarbage("collect")
end

function LuaProfiler.Start(_tag)
  local sample
  local calling_func = getinfo(2, "Sl")
  local key = calling_func.source .. calling_func.currentline
  if 0 < #inRunningPool then
    if 0 < #noUsePool then
      sample = noUsePool[1]
      sample.tag = _tag
      sample.stacklayer = inRunningPool[#inRunningPool].stacklayer + 1
      sample.callingSource = key
      inUsePool[#inUsePool + 1] = sample
      inRunningPool[#inRunningPool + 1] = sample
      remove(noUsePool, 1)
      AddStackName(key)
    else
      inRunningPool[#inRunningPool + 1] = nil
      return
    end
  else
    if #noUsePool <= 0 then
      InstantiateSample()
    end
    sample = noUsePool[1]
    sample.tag = _tag
    sample.stacklayer = 1
    sample.callingSource = key
    inUsePool[1] = sample
    inRunningPool[1] = sample
    remove(noUsePool, 1)
    AddStackName(key)
  end
  sample:Start()
end

function LuaProfiler.Stop()
  local sample = inRunningPool[#inRunningPool]
  if sample ~= nil then
    sample:Stop()
  end
  remove(inRunningPool)
  if #inRunningPool <= 0 then
    local cell
    if stackPool[stackName] == nil then
      stackPool[stackName] = {}
      for i = 1, #inUsePool do
        cell = GetStackCell()
        cell:InitRecord(inUsePool[i], FindParent(inUsePool[i].stacklayer, i))
        stackPool[stackName][i] = cell
      end
    else
      for i = 1, #stackPool[stackName] do
        cell = stackPool[stackName][i]
        cell:AddRecord(inUsePool[i])
      end
    end
    local len = #inUsePool
    for i = 1, len do
      local s = inUsePool[i]
      s:Reset()
      noUsePool[#noUsePool + 1] = s
      inUsePool[i] = nil
    end
    stackName = ""
  end
end

function LuaProfiler.PrintWithTag(tag)
  if #inRunningPool <= 0 then
    LuaProfilerSample.printLog = ""
    for key, value in pairs(stackPool) do
      for i = 1, #value do
        local cell = value[i]
        if cell.tag == tag then
          cell:Statistics(false)
        end
      end
    end
    LogUtility.Info(LuaProfilerSample.printLog)
  end
end

function LuaProfiler.Print()
  if #inRunningPool <= 0 then
    LuaProfilerSample.printLog = ""
    for key, value in pairs(stackPool) do
      for i = 1, #value do
        value[i]:Statistics(true)
      end
      LuaProfilerSample.printLog = LuaProfilerSample.printLog .. "\n"
    end
    LogUtility.Info(LuaProfilerSample.printLog)
  end
end

function LuaProfiler.PrintPercentage()
  if #inRunningPool <= 0 then
    LuaProfilerSample.printLog = ""
    for key, value in pairs(stackPool) do
      for i = 1, #value do
        value[i]:PercentageStatistics()
      end
      LuaProfilerSample.printLog = LuaProfilerSample.printLog .. "\n"
    end
    LogUtility.Info(LuaProfilerSample.printLog)
  end
end
