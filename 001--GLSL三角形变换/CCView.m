//
//  CCView.m
//  001--GLSL三角形变换
//
//  Created by CC老师 on 2017/12/25.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import "CCView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface CCView()

@property(nonatomic,strong)CAEAGLLayer *myEagLayer; //专门用来做opengl渲染的目标
@property(nonatomic,strong)EAGLContext *myContext;  //上下文

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myProgram;    //把shader语言转化出来
@property(nonatomic,assign)GLuint myVertices;   //顶点数据


@end


@implementation CCView
{
    float xDegree;  //x轴上旋转的角度
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
    
    
}

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

//1.设置图层
-(void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer *)self.layer;    //需要实现layerClass才可以做到
    
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];//设置屏幕的缩放
    
    //CALayer默认是透明的，必须将它设置为不透明才能其可见
    self.myEagLayer.opaque = YES;
    
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];//设置颜色格式
}

//2.设置上下文
-(void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;//指定2的版本
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    if (!context) {
        NSLog(@"Create Context Failed");
        return;
    }
    
    //设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set Current Context Failed");
        return;
    }
    
    self.myContext = context;
    
}

//3.清空缓存区
-(void)deletBuffer
{
    //1.导入框架#import <OpenGLES/ES2/gl.h>
    /*
     2.创建2个帧缓存区，渲染缓存区，帧缓存区
     @property (nonatomic , assign) GLuint myColorRenderBuffer;
     @property (nonatomic , assign) GLuint myColorFrameBuffer;
     
     A.离屏渲染，详细解释见课件
     
     B.buffer的分类,详细见课件
     
     buffer分为frame buffer 和 render buffer2个大类。其中frame buffer 相当于render buffer的管理者。frame buffer object即称FBO，常用于离屏渲染缓存等。render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     //绑定buffer标识符
     glGenRenderbuffers(<#GLsizei n#>, <#GLuint *renderbuffers#>)
     glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
     //绑定空间
     glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
     glBindFramebuffer(<#GLenum target#>, <#GLuint framebuffer#>)
     */
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;
    
}

//4.设置renderBuffer
-(void)setupRenderBuffer
{
    //1.定义一个缓存区
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    //3.
    self.myColorRenderBuffer = buffer;
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
    //为color renderBuffer 分配空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

//5.设置frameBuffer
-(void)setupFrameBuffer
{
    //1.定义一个缓存区标记
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    //3.
    self.myColorFrameBuffer = buffer;
    //4.设置当前的framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //5.将_myColorRenderBuffer 装配到GL_COLOR_ATTACHMENT0 附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //接下来，可以调用OpenGL ES进行绘制处理，最后则需要在EGALContext的OC方法进行最终的渲染绘制。这里渲染的color buffer,这个方法会将buffer渲染到CALayer上。- (BOOL)presentRenderbuffer:(NSUInteger)target;
}

//6.绘制
-(void)render
{
    //清掉屏幕上的颜色
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    //视口
    glViewport(self.frame.origin.x*scale, self.frame.origin.y*scale, self.frame.size.width*scale, self.frame.size.height*scale);
    
    //获取顶点着色器和片元着色器
    NSString* vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"glsl"];
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    //加载程序到myProgram中
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    //链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    //获取连接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString* messageString = [NSString stringWithUTF8String:message];
        NSLog(@"glLinkProgram error:%@",messageString);
        return;
    } else {
        glUseProgram(self.myProgram);
    }
    
    //创建绘制索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    //判断顶点缓冲区是否为空，如果是空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    //顶点数组
    //前3顶点值(x,y,z),后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,   //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,   //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,   //左下
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,   //右上
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,   //顶点
    };
    
    //处理顶点数据
    //将_myVertices绑定到GL_ARRAY_BUFFER标识符上，即数组缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //把顶点数据从CPU内存复制到GPU上,第四个参数指定他是用来绘制用的
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    /*
     将顶点数据通过myProgram中传递到顶点着色器程序的position
     1.glGetAttribLocation,用来获取vertex attribute的入口的
     2.告诉OpenGL ES,通过glEnableVertexAttribArray.
     3.最后数据是通过glVertexAttribPointer传递过去的
     */
    GLuint position = glGetAttribLocation(self.myProgram, "position");//第二个参数字符串必须和shaderv.glsl的输入变量:position保持一致
    
    /*
     设置读取方式，把position的数据读取进来
     参数1：index，顶点数据的索引
     参数2：size，每个顶点属性的组件数量，1，2，3或4，默认初始值是4
     参数3：type，数据中每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT,默认是GL_FLOAT
     参数4：normalized，固定点数据值是否应该归一化，或者直接转换为固定值(GL_FLOAT)
     参数5：stride，连续顶点属性之间的偏移值，默认为0
     参数6：指定一个指针，指向数组中第一个顶点属性的第一个组件，默认是0
     */
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*6, NULL);
    
    //设置合适的格式从Buffer里面读取数据
    glEnableVertexAttribArray(position);
    
    //处理顶点的颜色值
    /*
     glGetAttribLocation,用来获取vertex attribute的入口
     */
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");//第二个参数字符串必须和shaderv.glsl的输入变量:positionColor保持一致
    
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*6, (float*)NULL+3);
    //设置合适的格式从Buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    
    //注意，想要获取shader里面的变量，这里记得要在glLinkProgram后面！
    /*
     一个一致变量在一个图元的绘制过程中是不会改变的，所以其值不能再glBegin/glEnd中设置。
     一致变量适合描述在一个图元中，一帧中甚至一个场景中都不会变的值。
     一致变量在顶点shader和片段shader中都是只读的。
     首先你需要获取变量在内存中的位置，这个信息只有在连接程序之后才可获得
     */
    //找到myProgram中projectionMatrix，modelViewMatrix  2个矩阵的地址，如果找到则返回地址，否则返回-1，表示没有找到2个对象
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    //创建4*4的矩阵
    KSMatrix4 _projectionMatrix;
    
    //清空，变成单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    
    //计算纵横比例 = 长/宽
    float aspect = width / height;
    
    //获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     
     */
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 100.0f);
    
    //设置glsl里面的投影矩阵
    /*
     参数1：指要更改的uniform变量的位置
     参数2：更改的矩阵个数
     参数3：是否要转置矩阵，并将它作为uniform变量的值，必须为GL_FALSE
     参数4：执行count个元素的指针，用来根性指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    //开启剔除操作效果
    glEnable(GL_CULL_FACE);
    
    //模型视图
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0f, 0.0f, -10.0f);
    //创建一个4*4矩阵，旋转矩阵
    KSMatrix4 _rorationMatrix;
    ksMatrixLoadIdentity(&_rorationMatrix);
    //旋转
    ksRotate(&_rorationMatrix, xDegree, 1.0, 0.0, 0.0);//绕x轴
    ksRotate(&_rorationMatrix, yDegree, 0.0, 1.0, 0.0);//绕y轴
    ksRotate(&_rorationMatrix, zDegree, 0.0, 0.0, 1.0);//绕z轴
    //把变换矩阵想乘，注意先后顺序，将平移矩阵与旋转矩阵相乘，结合到模型视图
    ksMatrixMultiply(&_modelViewMatrix, &_rorationMatrix, &_modelViewMatrix);
    
    //加载模型视图矩阵modelViewMatrixSlot
    //设置glsl里面的投影矩阵
    /*
     参数1：指要更改的uniform变量的位置
     参数2：更改矩阵的个数
     参数3：是否要转置矩阵，并将它作为uniform变量的值，必须为GL_FALSE
     参数4：执行count个元素的指针，用来根性指定uniform变量(从哪个位置开始读取)
     */
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    //使用索引绘图
    /*
     void GL_APIENTRY glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid* indices)
     参数1：要呈现的画图模型
       点/线/模型(GL_POINTS,GL_LINES,GL_LINE_LOOP,GL_LINE_STRIP,GL_TRIANGLES,GL_TRIANGLE_STRIP,GL_TRIANGLE_FAN)
     参数2：绘图个数
     参数3：类型(GL_BYTE,GL_UNSIGNED_BYTE,GL_SHORT,GL_UNSIGNED_SHORT,GL_INT,GL_UNSIGNED_INT
     参数4：绘制索引数组
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

//需要复写，才能强制转换
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark -- Shader的导入
-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    GLuint vertShader,fragShader;
    GLuint program = glCreateProgram(); //创建一个临时的program
    
    [self compileShader:&vertShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    //创建程序
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    //释放shader
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    return program;
}

//链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar*)[content UTF8String];
    *shader = glCreateShader(type);             //创建一个shader
    glShaderSource(*shader, 1, &source, NULL);  //设置源头
    glCompileShader(*shader);       //编译shader
}

#pragma mark - XYClick
- (IBAction)XClick:(id)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bX = !bX;
    
}
- (IBAction)YClick:(id)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bY = !bY;
}
- (IBAction)ZClick:(id)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bZ = !bZ;
}

-(void)reDegree
{
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self render];
    
}

@end
