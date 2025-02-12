LuaColorUtility = class("LuaColorUtility")
local tempColor = LuaColor.white

function LuaColorUtility.Destroy(v)
  if nil ~= v then
    v:Destroy()
  end
  return nil
end

function LuaColorUtility.AlmostEqual(v1, v2)
  for i = 1, 4 do
    local diff = v1[i] - v2[i]
    if diff < -0.01 or 0.01 < diff then
      return false
    end
  end
  return true
end

function LuaColorUtility.Asign(to, from)
  if nil ~= to then
    LuaColor.Better_Set(to, from[1], from[2], from[3], from[4])
  else
    to = LuaColor.Better_Clone(from)
  end
  return to
end

function LuaColorUtility.TryAsign(to, from)
  if nil == from then
    return to
  end
  return LuaColorUtility.Asign(to, from)
end

function LuaColorUtility.TryLerp(cur, from, to, progress)
  if nil ~= from and nil ~= to then
    LuaColor.Better_Lerp(from, to, tempColor, progress)
    return LuaColorUtility.Asign(cur, tempColor)
  else
    return LuaColorUtility.TryAsign(cur, to)
  end
end
