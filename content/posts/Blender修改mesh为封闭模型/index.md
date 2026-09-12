+++

title = 'Blender修改mesh为封闭模型'

description = '使用Blender手动修改mesh为封闭模型(watertight)'

date = 2026-05-23T09:00:00+08:00


featured = false


categories = ['学习']

tags = ['研究生活']

cover = 'cover.jpg'

draft = false

+++

## 前言

之前我一直使用Meshlab的fill holes自动修补mesh，但有些模型自动修补效果不好，需要额外手动添加三角面。

## Fill Holes

使用blender打开模型，按下`Tab`进入编辑模式，选择`Edge Mode`,按住`Shift`选择需要修补的部分，然后按`F`即可自动填充{{< fnref 1 >}}。

![编辑模式](https://static.246266.xyz/i/2024/05/27/665448f027e84.png#vwid=525&vhei=147)

![选择边](https://static.246266.xyz/i/2024/05/27/6654495569df8.png#vwid=1048&vhei=210)

## 转化为三角面

这样新添加的面可能不是三角面，需要将其修改为三角面，进入编辑模式，选择`Face Mode`,按下`Ctrl + T`自动转化为三角面{{< fnref 2 >}}。

另外，自动修补出的三角面部分法向量可能会相反，可以在此模式下，进行`Mesh->Normal->Flip`进行反转{{< fnref 3 >}}。

![反转法向量](https://static.246266.xyz/i/2024/05/27/66544def69236.png#vwid=800&vhei=379)


{{< refers   title="参考">}}
{{< refer num="1" source="https://www.youtube.com/watch?v=YliK6XkLhe" url="https://www.youtube.com/watch?v=YliK6XkLhe">}}
Blender Tutorial: Different Ways to Fill Holes
{{< /refer >}}
{{< refer num="2" source="https://docs.blender.org/manual/zh-hans/4.0/modeling/meshes/editing/face/triangulate_faces.html" url="https://docs.blender.org/manual/zh-hans/4.0/modeling/meshes/editing/face/triangulate_faces.html">}}
面三角化
{{< /refer >}}
{{< refer num="3" source="https://docs.blender.org/manual/zh-hans/3.1/modeling/meshes/editing/mesh/normals.html" url="https://docs.blender.org/manual/zh-hans/3.1/modeling/meshes/editing/mesh/normals.html">}}
翻转
{{< /refer >}}
{{< refer num="4" source="https://docs.blender.org/manual/zh-hans/3.1/modeling/meshes/editing/mesh/normals.html" url="https://docs.blender.org/manual/zh-hans/3.1/modeling/meshes/editing/mesh/normals.html" noref="true">}}
封面图
{{< /refer >}}
{{< /refers >}}