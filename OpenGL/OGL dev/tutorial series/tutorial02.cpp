#include <stdio.h>
#include <GL/glew.h>
#include <GL/freeglut.h>
#include "ogldev_math_3d.h"
//Create a dot

GLuint VBO;//全局分配一个GLuint来存储顶点缓冲区的handle(句柄)【句柄代表一个特定的资源（openGL中的资源一般都是一个句柄来引用）】

static void RenderSceneCB()
{
    glClear(GL_COLOR_BUFFER_BIT);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);//怎么又绑一次：如果有多个缓冲区存储各种模型，用缓冲区来更新管道状态
    glEnableVertexAttribArray(0);//启用每个顶点属性索引
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);//告诉管线如何解释缓冲区内的数据
    glDrawArrays(GL_POINTS, 0, 1);
    glDisableVertexAttribArray(0);
    glutSwapBuffers();
}


static void CreateVertexBuffer()
{
    Vector3f Vertices[1];//在ogldev_math_3d.h中定义了
    Vertices[0] = Vector3f(0.0f, 0.0f, 0.0f);
    glGenBuffers(1, &VBO);//glGen*函数用于生成对象，第一个参数指定创建对象的数量，第二个参数是GLuint数组的地址，用来存储驱动程序分配的句柄(handle)
    glBindBuffer(GL_ARRAY_BUFFER, VBO);//句柄要被绑到一个特定的目标上，然后在该目标上执行命令。GL_ARRAY_BUFFER意味着缓冲区将包含一个顶点阵列
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);//数据填充；GL_STATIC_DRAW表示不打算改变缓冲区的内容
}


int main(int argc, char** argv)
{
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH);
    int width = 1920;
    int height = 1080;
    glutInitWindowSize(width, height);
    int x = 200;
    int y = 100;
    glutInitWindowPosition(x, y);
    int win = glutCreateWindow("Tutorial 02");
    printf("window id: %d\n", win);

    // Must be done after glut is initialized!这里真的不是glew初始化之后
    GLenum res = glewInit();
    if (res != GLEW_OK) {
        fprintf(stderr, "Error: '%s'\n", glewGetErrorString(res));
        return 1;
    }

    GLclampf Red = 0.0f, Green = 0.0f, Blue = 0.0f, Alpha = 0.0f;
    glClearColor(Red, Green, Blue, Alpha);
    //至到上面一行，状态机创建完成

    CreateVertexBuffer();
    glutDisplayFunc(RenderSceneCB);
    glutMainLoop();

    return 0;
}
