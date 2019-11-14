return {
  death_by = {
    chara = {
      death_cause = function(_1)
  return ("%sに殺された。")
  :format(basename(_1))
end,
      destroyed = {
        active = "破壊した。",
        passive = function(_1)
  return ("%sは破壊された。")
  :format(name(_1))
end
      },
      killed = {
        active = "殺した。",
        passive = function(_1)
  return ("%sは殺された。")
  :format(name(_1))
end
      },
      minced = {
        active = "ミンチにした。",
        passive = function(_1)
  return ("%sはミンチにされた。")
  :format(name(_1))
end
      },
      transformed_into_meat = {
        active = "粉々の肉片に変えた。",
        passive = function(_1)
  return ("%sは粉々の肉片に変えられた。")
  :format(name(_1))
end
      }
    },
    element = {
      _50 = {
        active = "燃やし尽くした。",
        passive = function(_1)
  return ("%sは燃え尽きて灰になった。")
  :format(name(_1))
end
      },
      _51 = {
        active = "氷の塊に変えた。",
        passive = function(_1)
  return ("%sは氷の彫像になった。")
  :format(name(_1))
end
      },
      _52 = {
        active = "焦げカスにした。",
        passive = function(_1)
  return ("%sは雷に打たれ死んだ。")
  :format(name(_1))
end
      },
      _53 = {
        active = "闇に飲み込んだ。",
        passive = function(_1)
  return ("%sは闇に蝕まれて死んだ。")
  :format(name(_1))
end
      },
      _54 = {
        active = "再起不能にした。",
        passive = function(_1)
  return ("%sは発狂して死んだ。")
  :format(name(_1))
end
      },
      _55 = {
        active = "毒殺した。",
        passive = function(_1)
  return ("%sは毒に蝕まれて死んだ。")
  :format(name(_1))
end
      },
      _56 = {
        active = "冥界に墜とした。",
        passive = function(_1)
  return ("%sは冥界に墜ちた。")
  :format(name(_1))
end
      },
      _57 = {
        active = "聴覚を破壊し殺した。",
        passive = function(_1)
  return ("%sは朦朧となって死んだ。")
  :format(name(_1))
end
      },
      _58 = {
        active = "神経を破壊した。",
        passive = function(_1)
  return ("%sは神経を蝕まれて死んだ。")
  :format(name(_1))
end
      },
      _59 = {
        active = "混沌の渦に吸い込んだ。",
        passive = function(_1)
  return ("%sは混沌の渦に吸収された。")
  :format(name(_1))
end
      },
      _61 = {
        active = "千切りにした。",
        passive = function(_1)
  return ("%sは千切りになった。")
  :format(name(_1))
end
      },
      _63 = {
        active = "ドロドロに溶かした。",
        passive = function(_1)
  return ("%sは酸に焼かれ溶けた。")
  :format(name(_1))
end
      },
      default = {
        active = "殺した。",
        passive = function(_1)
  return ("%sは死んだ。")
  :format(name(_1))
end
      }
    },
    other = {
      _1 = {
        death_cause = "罠にかかって死んだ。",
        text = function(_1)
  return ("%sは罠にかかって死んだ。")
  :format(name(_1))
end
      },
      _11 = {
        death_cause = "見えざる手に葬られた。",
        text = function(_1)
  return ("%sは見えざる手に葬られた。")
  :format(name(_1))
end
      },
      _12 = {
        death_cause = "食中毒で倒れた。",
        text = function(_1)
  return ("%sは食中毒で死んだ。")
  :format(name(_1))
end
      },
      _13 = {
        death_cause = "血を流しすぎて死んだ。",
        text = function(_1)
  return ("%sは出血多量で死んだ。")
  :format(name(_1))
end
      },
      _14 = {
        death_cause = "エーテルの病に倒れた。",
        text = function(_1)
  return ("%sはエーテルに侵食され死んだ。")
  :format(name(_1))
end
      },
      _15 = {
        death_cause = "溶けて液体になった。",
        text = function(_1)
  return ("%sは溶けて液体になった。")
  :format(name(_1))
end
      },
      _16 = {
        death_cause = "自殺した。",
        text = function(_1)
  return ("%sはバラバラになった。")
  :format(name(_1))
end
      },
      _17 = {
        death_cause = "核爆発に巻き込まれて死んだ。",
        text = function(_1)
  return ("%sは核爆発に巻き込まれて塵となった。")
  :format(name(_1))
end
      },
      _18 = {
        death_cause = "アイアンメイデンにはさまれて死んだ。",
        text = function(_1)
  return ("%sはアイアンメイデンの中で串刺しになって果てた。")
  :format(name(_1))
end
      },
      _19 = {
        death_cause = "ギロチンで首を落とされて死んだ。",
        text = function(_1)
  return ("%sはギロチンで首をちょんぎられて死んだ。")
  :format(name(_1))
end
      },
      _2 = {
        death_cause = "マナの反動で消滅した。",
        text = function(_1)
  return ("%sはマナの反動で死んだ。")
  :format(name(_1))
end
      },
      _20 = {
        death_cause = "首を吊った。",
        text = function(_1)
  return ("%sは首を吊った。")
  :format(name(_1))
end
      },
      _21 = {
        death_cause = "もちを喉に詰まらせて死んだ。",
        text = function(_1)
  return ("%sはもちを喉に詰まらせて死んだ。")
  :format(name(_1))
end
      },
      _3 = {
        death_cause = "飢え死にした。",
        text = function(_1)
  return ("%sは餓死した。")
  :format(name(_1))
end
      },
      _4 = {
        death_cause = "毒にもがき苦しみながら死んだ。",
        text = function(_1)
  return ("%sは毒に蝕まれ死んだ。")
  :format(name(_1))
end
      },
      _5 = {
        death_cause = "呪い殺された。",
        text = function(_1)
  return ("%sは呪いの力で死んだ。")
  :format(name(_1))
end
      },
      _6 = {
        backpack = "荷物",
        death_cause = function(_1)
  return ("%sの重さに耐え切れず潰れた。")
  :format(_1)
end,
        text = function(_1, _2)
  return ("%sは%sの重さに耐え切れず死んだ。")
  :format(name(_1), _2)
end
      },
      _7 = {
        death_cause = "階段から転げ落ちて亡くなった。",
        text = function(_1)
  return ("%sは階段から転げ落ちて死んだ。")
  :format(name(_1))
end
      },
      _8 = {
        death_cause = "演奏中に激怒した聴衆に殺された。",
        text = function(_1)
  return ("%sは聴衆に殺された。")
  :format(name(_1))
end
      },
      _9 = {
        death_cause = "焼けて消滅した。",
        text = function(_1)
  return ("%sは焼け死んだ。")
  :format(name(_1))
end
      }
    }
  }
}