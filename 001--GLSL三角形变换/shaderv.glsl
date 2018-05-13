attribute vec4 position;        //外部传入的顶点
attribute vec4 positionColor;   //每个顶点的颜色
uniform mat4 projectionMatrix;  //投影矩阵
uniform mat4 modelViewMatrix;   //模型矩阵

varying lowp vec4 varyColor;    //每个顶点的颜色传递到片元着色器

void main()
{
    varyColor = positionColor;
    
    vec4 vPos;
    vPos = projectionMatrix * modelViewMatrix * position;
    
    //vPos = position;
    
    gl_Position = vPos;//gl_Position是内建变量
}

//顶点着色器是每个顶点都会去调用
