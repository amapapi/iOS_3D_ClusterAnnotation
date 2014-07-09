iOS_3D_ClusterAnnotation
========================

MAMapKit 点聚合

### 前述

- [高德官方网站申请key](http://id.amap.com/?ref=http%3A%2F%2Fapi.amap.com%2Fkey%2F).
- 阅读[参考手册](http://api.amap.com/Public/reference/iOS%20API%20v2_3D/).
- 如果有任何疑问也可以发问题到[官方论坛](http://bbs.amap.com/forum.php?gid=1).

### 架构

##### Controllers
- `<UIViewController>`
  * `BaseMapViewController` 地图基类
    - `AnnotationClusterViewController` 点聚合
  * `PoiDetailViewController` 显示poi详细信息列表

##### View

* `MAAnnotationView`
  - `ClusterAnnotationView` 自定义的AnnotationView（位置根据其代表的poi平均坐标决定，大小根据其代表的poi个数决定）

##### Models

* `Conform to <MAAnnotation>`
  - `ClusterAnnotation` 记录annotation的信息，并提供两个annotation是否Equal的判断
* `CoordinateQuadTree` 封装的四叉树（建四叉树较为耗时，需另开线程，可设置delegate四叉树建好后会回调）
* `QuadTree` 四叉树基本算法

### 截图效果

![ClusterAnnotation2](https://raw.githubusercontent.com/cysgit/iOS_3D_ClusterAnnotation/master/iOS_3D_ClusterAnnotation/Resources/ClusterAnnotation2.png)
![ClusterAnnotation1](https://raw.githubusercontent.com/cysgit/iOS_3D_ClusterAnnotation/master/iOS_3D_ClusterAnnotation/Resources/ClusterAnnotation1.png)
### 在线安装Demo

* `手机扫描如下二维码直接安装`

![qrcode](https://raw.githubusercontent.com/cysgit/iOS_3D_ClusterAnnotation/master/iOS_3D_ClusterAnnotation/Resources/qrcode.png)

* `手机上打开地址:<http://fir.im/clstAnot>`
