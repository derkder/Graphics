#include <GL/freeglut.h>
#include <stdio.h>


static void RenderSceneCB()
{
    glClear(GL_COLOR_BUFFER_BIT);//使用状态机设置过的颜色清空帧缓冲区
    glutSwapBuffers();//双缓冲区，frontbuffer&backbuffer对调
}


int main(int argc, char** argv)
{
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH);//双缓冲，颜色缓冲区[屏幕]，深度测试

    int width = 1920;
    int height = 1080;
    glutInitWindowSize(width, height);

    int x = 200;
    int y = 100;
    glutInitWindowPosition(x, y);
    int win = glutCreateWindow("Tutorial 01");
    printf("window id: %d\n", win);

    //引出状态机的概念
    GLclampf Red = 0.0f, Green = 0.0f, Blue = 0.0f, Alpha = 0.0f;
    glClearColor(Red, Green, Blue, Alpha);//设置清空帧缓冲区时使用的颜色

    glutDisplayFunc(RenderSceneCB);//glut负责与底层窗口系统交互，用这个回调函数来完成一帧的渲染动作

    //这个调用将控制权传递给GLUT，它现在开始自己的内部循环。在这个循环中，它监听来自窗口系统的事件并通过我们配置的回调来传递它们。
    //在我们的例子中，GLUT将只调用我们注册为显示回调的函数（RenderSceneCB）来给我们一个渲染框架的机会。
    glutMainLoop();

    return 0;
}
