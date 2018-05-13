# Pyramid
opengl es绘制金字塔，通过shader文件进行索引绘制以及模型矩阵的变换，让金字塔绕x轴，y轴，z轴旋转。注释详细，可作为opengl es入门参考案例。

![](https://github.com/czl0325/Pyramid/blob/master/screenspot.gif?raw=true)

# OpenGL ES 绘制图片一般都是六个步骤：

```
-(void)layoutSubviews
{
    //1.设置图层
    [self setupLayer];
    
    //2.设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deletBuffer];
    
    //4.设置renderBuffer;
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.绘制
    [self render];
}
```

前五个步骤都是固定写法，重点在于第六个步骤，绘制：<br>

首先先把顶点着色器，片元着色器从shader文件中读取出来，链接到对象GLuint myProgram中。

创建索引数组，和顶点数组
把顶点值传入到shader的position变量中，把顶点颜色也传入到positionColor中
