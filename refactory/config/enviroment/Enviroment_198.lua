local Enviroment_198 = {
  global = {
    sunDir = {
      -0.686206996440887,
      -0.683184027671814,
      0.249759137630463,
      0
    },
    sunColor = {
      0.952830195426941,
      0.897899746894836,
      0.710128128528595,
      1
    }
  },
  lighting = {
    ambientMode = 0,
    ambientLight = {
      0.943396210670471,
      0.964764773845673,
      1,
      1
    },
    ambientIntensity = 1,
    defaultReflectionMode = 0,
    defaultReflectionResolution = 0,
    reflectionBounces = 1,
    reflectionIntensity = 0
  },
  fog = {
    fog = true,
    fogColor = {
      0.699999988079071,
      0.927847981452942,
      1,
      1
    },
    fogMode = 1,
    fogStartDistance = 30,
    fogEndDistance = 120,
    globalFogTuner = 0,
    heightFogMode = 1,
    heightFogCutoff = 9.99999974737875E-6,
    heightFogStart = -5,
    heightFogEnd = 150,
    scatteringDensity = 1,
    scatteringFalloff = 4,
    scatteringExponent = 12.5,
    heightFogMinOpacity = 0,
    radiusFogFactor = 1,
    nearFogColor = {
      0.980392158031464,
      0.720867097377777,
      0.26274511218071,
      1
    },
    nearFogDistance = 10,
    farFogColor = {
      0.699999988079071,
      0.927847981452942,
      1,
      1
    },
    farFogDistance = 70,
    enableLocalHeightFog = 0,
    localHeightFogStart = 0,
    localHeightFogEnd = 1,
    localHeightFogColor = {
      0,
      0,
      0,
      0
    }
  },
  volumes = {
    [1] = {
      volume = {
        type = 0,
        center = {
          0,
          0,
          0
        },
        extents = {
          150,
          50,
          150
        },
        worldToLocalMatrix = {
          {
            1,
            0,
            0,
            -52.5
          },
          {
            0,
            1,
            0,
            -58
          },
          {
            0,
            0,
            1,
            152
          },
          {
            0,
            0,
            0,
            1
          }
        },
        radius = 1,
        priority = 0
      },
      fog = {
        fog = true,
        weight = 1,
        blendDuration = 0.5,
        fogMode = 1,
        fogStartDistance = 45,
        fogEndDistance = 150,
        globalFogTuner = 0,
        heightFogMode = 1,
        heightFogCutoff = 9.99999974737875E-6,
        heightFogStart = 0,
        heightFogEnd = 150,
        scatteringDensity = 1,
        scatteringFalloff = 1,
        scatteringExponent = 12.5,
        heightFogMinOpacity = 0,
        radiusFogFactor = 1,
        nearFogColor = {
          0.968627512454987,
          0.725490212440491,
          0.290196090936661,
          1
        },
        nearFogDistance = 10,
        farFogColor = {
          0.705882370471954,
          0.921568691730499,
          0.988235354423523,
          1
        },
        farFogDistance = 70,
        enableLocalHeightFog = 0,
        localHeightFogStart = 0,
        localHeightFogEnd = 1,
        localHeightFogColor = {
          0,
          0,
          0,
          0
        }
      }
    }
  },
  flare = {flareFadeSpeed = 1, flareStrength = 0.495999991893768},
  customskybox = {
    texPath = "",
    tint = {
      1,
      1,
      1,
      1
    },
    rotation = 130,
    exposure = 1,
    finite = true,
    sunsize = 0,
    applyFog = false
  },
  bloom = {
    index = 0,
    version = 1,
    threshold = 0.600000023841858,
    intensity = 0.75,
    bExposure = false,
    scatter = 0.899999976158142,
    clamp = 0,
    highQualityFiltering = false,
    dirtIntensity = 0
  }
}
return Enviroment_198
