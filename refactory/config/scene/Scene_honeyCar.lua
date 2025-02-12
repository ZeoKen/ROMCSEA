local Scene_honeyCar = {
  PVE = {
    bps = {
      {
        ID = 1,
        position = {
          -136.990005493164,
          2.85999989509583,
          -142
        },
        range = 0
      }
    }
  },
  Raids = {
    [250001] = {
      bps = {
        {
          ID = 1,
          position = {
            -137.279998779297,
            2.52000045776367,
            -139.859985351563
          },
          range = 0
        }
      },
      eps = {
        {
          ID = 1,
          commonEffectID = 16,
          position = {
            109.519996643066,
            5.66999959945679,
            67
          },
          nextSceneID = 1,
          nextSceneBornPointID = 12,
          type = 0,
          range = 1.29999995231628
        }
      },
      nps = {
        {
          uniqueID = 1,
          ID = 5002,
          position = {
            -139.929992675781,
            2.47000002861023,
            -137.910003662109
          }
        }
      }
    },
    [10009] = {
      bps = {
        {
          ID = 1,
          position = {
            -137.279998779297,
            2.52000045776367,
            -139.859985351563
          },
          range = 0
        }
      },
      eps = {
        {
          ID = 1,
          commonEffectID = 16,
          position = {
            109.519996643066,
            5.66999959945679,
            67
          },
          nextSceneID = 1,
          nextSceneBornPointID = 12,
          type = 0,
          range = 1.29999995231628
        }
      },
      nps = {
        {
          uniqueID = 1,
          ID = 5002,
          position = {
            -139.929992675781,
            2.47000002861023,
            -137.910003662109
          }
        }
      }
    }
  },
  MapInfo = {
    [0] = {
      MinPos = {x = -300, y = -246.5},
      Size = {x = 450, y = 450}
    }
  }
}
return Scene_honeyCar
