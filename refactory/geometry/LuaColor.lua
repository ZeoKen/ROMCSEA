local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local clamp = clamp
local acos = math.acos
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local error = error
local min = math.min
local max = math.max
local abs = math.abs
local pow = math.pow
local Time = UnityEngine.Time
local ToAngle = 57.29578
local ToRad = 0.01745329
local Epsilon = 1.0E-5
local Infinite = 1 / 0
local Sqrt2 = 0.7071067811865476
local PI = 3.141592653589793
local destroy = ReusableTable.DestroyVector2
local clamp = function(v, min, max)
  return max < v and max or v < min and min or v
end
local lerpf = function(a, b, t)
  t = clamp(t, 0, 1)
  return a + (b - a) * t
end
local LuaColor = {__typename = "Color"}
local I = {__typename = "Color", __typeReuse = true}
_G.LuaColor = LuaColor
local get = {}
_G["UnityEngine.Color.Instance"] = I
local set = {}

function LuaColor.__index(t, k)
  local f = rawget(LuaColor, k)
  if f then
    return f
  end
  local f = rawget(get, k)
  if f then
    return f(t)
  end
  error("Not found " .. k)
end

function LuaColor.__newindex(t, k, v)
  local f = rawget(set, k)
  if f then
    return f(t, v)
  end
  error("Not found " .. k)
end

function I.__index(t, k)
  local f = rawget(I, k)
  if f then
    return f
  end
  local f = rawget(get, k)
  if f then
    return f(t)
  end
end

function I.__newindex(t, k, v)
  local f = rawget(set, k)
  if f then
    return f(t, v)
  end
  error("Not found " .. k)
end

function I:__tostring()
  return string.format("LuaColor(%f, %f, %f, %f)", self[1], self[2], self[3], self[4])
end

function LuaColor.New(r, g, b, a)
  a = a or 1
  local c = {
    r or 0,
    g or 0,
    b or 0,
    a or 0
  }
  setmetatable(c, I)
  rawset(c, "_alive", true)
  return c
end

function LuaColor.__call(t, r, g, b, a)
  return LuaColor.New(r, g, b, a)
end

function I.__add(a, b)
  return LuaColor.New(a[1] + b[1], a[2] + b[2], a[3] + b[3], a[4] + b[4])
end

function I.__sub(a, b)
  return LuaColor.New(a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] - b[4])
end

function I.__mul(a, b)
  if type(a) == "number" then
    return LuaColor.New(a * b[1], a * b[2], a * b[3], a * b[4])
  elseif type(b) == "number" then
    return LuaColor.New(a[1] * b, a[2] * b, a[3] * b, a[4] * b)
  else
    return LuaColor.New(a[1] * b[1], a[2] * b[2], a[3] * b[3], a[4] * b[4])
  end
end

function I.__div(a, b)
  return Color.New(a[1] / b, a[2] / b, a[3] / b, a[4] / b)
end

function LuaColor.Equal(a, b)
  return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

function I:Equal(b)
  return self[1] == b[1] and self[2] == b[2] and self[3] == b[3] and self[4] == b[4]
end

function I:Alive()
  return self._alive ~= false
end

function LuaColor:Better_Clone()
  return LuaColor.New(self[1], self[2], self[3], self[4])
end

function LuaColor.Better_Set(t, r, g, b, a)
  t[1], t[2], t[3], t[4] = r or 1, g or 1, b or 1, a or 1
end

function I:Set(r, g, b, a)
  self[1], self[2], self[3], self[4] = r or 1, g or 1, b or 1, a or 1
end

function LuaColor:Add(b)
  self[1], self[2], self[3], self[4] = self[1] + b[1], self[2] + b[2], self[3] + b[3], self[4] + b[4]
end

function LuaColor.Better_Add(a, b, t)
  t[1], t[2], t[3], t[4] = a[1] + b[1], a[2] + b[2], a[3] + b[3], a[4] + b[4]
end

function I:Add(b)
  self[1], self[2], self[3], self[4] = self[1] + b[1], self[2] + b[2], self[3] + b[3], self[4] + b[4]
end

function LuaColor:Sub(b)
  self[1], self[2], self[3], self[4] = self[1] - b[1], self[2] - b[2], self[3] - b[3], self[4] - b[4]
end

function LuaColor.Better_Sub(a, b, t)
  t[1], t[2], t[3], t[4] = a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] - b[4]
end

function I:Sub(b)
  self[1], self[2], self[3], self[4] = self[1] - b[1], self[2] - b[2], self[3] - b[3], self[4] - b[4]
end

function LuaColor:Mul(b)
  if type(b) == "number" then
    self[1], self[2], self[3], self[4] = self[1] * b, self[2] * b, self[3] * b, self[4] * b
  else
    self[1], self[2], self[3], self[4] = self[1] * b[1], self[2] * b[2], self[3] * b[3], self[4] * b[4]
  end
  return self
end

function LuaColor.Better_Mul(a, b, t)
  t[1], t[2], t[3] = a[1] * b, a[2] * b, a[3] * b
  if type(a) == "number" then
    t[1], t[2], t[3], t[4] = a * b[1], a * b[2], a * b[3], a * b[4]
  elseif type(b) == "number" then
    t[1], t[2], t[3], t[4] = a[1] * b, a[2] * b, a[3] * b, a[4] * b
  else
    t[1], t[2], t[3], t[4] = a[1] * b[1], a[2] * b[2], a[3] * b[3], a[4] * b[4]
  end
  return t
end

function I:Mul(b)
  return LuaColor.Mul(self, b)
end

function LuaColor:Div(b)
  self[1], self[2], self[3], self[4] = self[1] / b, self[2] / b, self[3] / b, self[4] / b
end

function LuaColor.Better_Div(a, b, t)
  t[1], t[2], t[3], t[4] = a[1] / b, a[2] / b, a[3] / b, a[4] / b
end

function I:Div(b)
  self[1], self[2], self[3], self[4] = self[1] / b, self[2] / b, self[3] / b, self[4] / b
end

local ToLinear = function(value)
  if value <= 0.04045 then
    return value / 12.92
  elseif value < 1.0 then
    return pow((value + 0.055) / 1.055, 2.4)
  else
    return pow(value, 2.4)
  end
end
local ToGamma = function(value)
  if value <= 0.0 then
    return 0.0
  elseif value <= 0.0031308 then
    return 12.92 * value
  elseif value <= 1.0 then
    return 1.055 * pow(value, 0.41666) - 0.055
  else
    return pow(value, 0.41666)
  end
end

function get.red()
  return LuaColor.New(1, 0, 0, 1)
end

function get.green()
  return LuaColor.New(0, 1, 0, 1)
end

function get.blue()
  return LuaColor.New(0, 0, 1, 1)
end

function get.white()
  return LuaColor.New(1, 1, 1, 1)
end

function get.black()
  return LuaColor.New(0, 0, 0, 1)
end

function get.yellow()
  return LuaColor.New(1, 0.9215686, 0.01568628, 1)
end

function get.cyan()
  return LuaColor.New(0, 1, 1, 1)
end

function get.magenta()
  return LuaColor.New(1, 0, 1, 1)
end

function get.gray()
  return LuaColor.New(0.5, 0.5, 0.5, 1)
end

function get.grey()
  return LuaColor.New(0.5, 0.5, 0.5, 1)
end

function get.clear()
  return LuaColor.New(0, 0, 0, 0)
end

function get:grayscale()
  return 0.299 * self[1] + 0.587 * self[2] + 0.114 * self[3]
end

function get:linear()
  return LuaColor.New(ToLinear(self[1]), ToLinear(self[2]), ToLinear(self[3]), self[4])
end

function get:gamma()
  return LuaColor.New(ToGamma(self[1]), ToGamma(self[2]), ToGamma(self[3]), self[4])
end

function get:r()
  return self[1]
end

function get:g()
  return self[2]
end

function get:b()
  return self[3]
end

function get:a()
  return self[4]
end

function set:r(v)
  self[1] = v
end

function set:g(v)
  self[2] = v
end

function set:b(v)
  self[3] = v
end

function set:a(v)
  self[4] = v
end

function LuaColor.Black()
  return LuaColor.New(0, 0, 0, 1)
end

function LuaColor.White()
  return LuaColor.New(1, 1, 1, 1)
end

function LuaColor.WhiteClear()
  return LuaColor.New(1, 1, 1, 0)
end

function LuaColor.Green()
  return LuaColor.New(0, 1, 0, 1)
end

function LuaColor.Blue()
  return LuaColor.New(0, 0, 1, 1)
end

function LuaColor.Red()
  return LuaColor.New(1, 0, 0, 1)
end

function LuaColor.Gray()
  return LuaColor.New(0.5, 0.5, 0.5, 1)
end

function LuaColor.Clear()
  return LuaColor.New(0, 0, 0, 0)
end

function LuaColor.Lerp(a, b, t)
  t = clamp(t, 0, 1)
  return LuaColor.New(lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf(a[4], b[4], t))
end

function LuaColor.Better_Lerp(a, b, c, t)
  t = clamp(t, 0, 1)
  c[1], c[2], c[3], c[4] = lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf(a[4], b[4], t)
end

function I:Lerp(b, t)
  t = clamp(t, 0, 1)
  self[1], self[2], self[3], self[4] = lerpf(self[1], b[1], t), lerpf(self[2], b[2], t), lerpf(self[3], b[3], t), lerpf(self[4], b[4], t)
end

function LuaColor.LerpUnclamped(a, b, t)
  return LuaColor.New(lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf(a[4], b[4], t))
end

function LuaColor.Better_LerpUnclamped(a, b, c, t)
  c[1], c[2], c[3], c[4] = lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf(a[4], b[4], t)
end

function I:LerpUnclamped(b, t)
  self[1], self[2], self[3], self[4] = lerpf(self[1], b[1], t), lerpf(self[2], b[2], t), lerpf(self[3], b[3], t), lerpf(self[4], b[4], t)
end

function LuaColor.TryParseHtmlString(str)
  if not str then
    return false
  end
  return ColorHelper.TryParseHtmlString(str)
end

function LuaColor.TryParseHtmlToColor(str, defaultR, defaultG, defaultB, defaultA)
  local suc, r, g, b, a = LuaColor.TryParseHtmlString(str)
  if not suc then
    redlog("Failed to parse html: " .. str)
    r, g, b, a = defaultR, defaultG, defaultB, defaultA
  end
  return LuaColor.New(r or 1, g or 1, b or 1, a or 1)
end

function I:Destroy()
  self = nil
end

function LuaColor:Destroy()
  self = nil
end

setmetatable(LuaColor, LuaColor)
