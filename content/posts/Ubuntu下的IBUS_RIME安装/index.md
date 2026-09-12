+++

title = 'Ubuntu下的IBUS_RIME安装'

description = 'Ubuntu下安装Ibus_Rime'

date = 2026-05-23T09:00:00+08:00


featured = false


categories = ['学习']

tags = ['研究生活']

cover = 'cover.jpg'

draft = false

+++

[RIME官方链接](https://github.com/rime/ibus-rime)

## 安装ibus_rime

> 需要Ubuntu版本大于12.10

### 安装ibus_rime本体

```bash
# 命令行下输入
sudo apt-get install ibus-rime
```

### 安装明月拼音方案

```bash
# 朙月拼音（預裝）
sudo apt-get install librime-data-luna-pinyin
```

> [其他方案参考](https://github.com/rime/home/wiki/RimeWithIBus)

安装完成后可以在设置中选择输入法方案。

![Ubuntu设置](https://static.246266.xyz/i/2024/01/24/65b0f5f1511bb.png#vwid=982&vhei=816)

### 一些基本的配置

[官方配置介绍](https://github.com/rime/home/wiki/CustomizationGuide)

由于ibus_rime的明月拼音下默认为繁体输入，若想要自动将繁体转化为简体（繁-〉简），需要修改配置文件。明月拼音配置文件位置为`~/.config/ibus/rime`，修改`luna_pinyin.custom.yaml`文件（若没有则新建一个），添加下面的设置。

```bash
patch:
  switches:                   # 注意縮進
    - name: ascii_mode
      reset: 0                # reset 0 的作用是當從其他輸入方案切換到本方案時，
      states: [ 中文, 西文 ]  # 重設爲指定的狀態，而不保留在前一個方案中設定的狀態。
    - name: full_shape        # 選擇輸入方案後通常需要立即輸入中文，故重設 ascii_mode = 0；
      states: [ 半角, 全角 ]  # 而全／半角則可沿用之前方案中的用法。
    - name: simplification
      reset: 1                # 增加這一行：默認啓用「繁→簡」轉換。
      states: [ 漢字, 汉字 ]
```

这个设置在切换到明月拼音时会自动启用繁体到简体的转换。

另外，Rime的候选框默认为竖向排布，也可以通过设置切换为竖向排布。修改`~/.config/ibus/rime/build/ibus_rime.yaml`,将`horizontal`由`False`改为`True`即可。修改后如下所示。

```bash
__build_info:
  rime_version: 1.7.3
  timestamps:
    ibus_rime: 1611495485
    ibus_rime.custom: 0
config_version: 1.0
style:
  cursor_type: insert
  horizontal: true
  inline_preedit: true
  preedit_style: composition
```

**修改完成后，不要忘了重新部署一下**

## 其他

ibus重启命令

```
ibus-daemon -r -d -x
```

{{< refers   title="参考">}}
{{< refer num="1" source="https://twitter.com/amayadori_uki/status/1286183090977570816" url="https://twitter.com/amayadori_uki/status/1286183090977570816" noref="true">}}
封面图
{{< /refer >}}
{{< /refers >}}
