#include <stdio.h>
#include <GL/glew.h>
#include <GL/freeglut.h>
#include "ogldev_math_3d.h"
//Create a dot

GLuint VBO;//ȫ�ַ���һ��GLuint���洢���㻺������handle(���)���������һ���ض�����Դ��openGL�е���Դһ�㶼��һ����������ã���

static void RenderSceneCB()
{
    glClear(GL_COLOR_BUFFER_BIT);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);//��ô�ְ�һ�Σ�����ж���������洢����ģ�ͣ��û����������¹ܵ�״̬
    glEnableVertexAttribArray(0);//����ÿ��������������
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);//���߹�����ν��ͻ������ڵ�����
    glDrawArrays(GL_POINTS, 0, 1);
    glDisableVertexAttribArray(0);
    glutSwapBuffers();
}


static void CreateVertexBuffer()
{
    Vector3f Vertices[1];//��ogldev_math_3d.h�ж�����
    Vertices[0] = Vector3f(0.0f, 0.0f, 0.0f);
    glGenBuffers(1, &VBO);//glGen*�����������ɶ��󣬵�һ������ָ������������������ڶ���������GLuint����ĵ�ַ�������洢�����������ľ��(handle)
    glBindBuffer(GL_ARRAY_BUFFER, VBO);//���Ҫ����һ���ض���Ŀ���ϣ�Ȼ���ڸ�Ŀ����ִ�����GL_ARRAY_BUFFER��ζ�Ż�����������һ����������
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);//������䣻GL_STATIC_DRAW��ʾ������ı仺����������
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

    // Must be done after glut is initialized!������Ĳ���glew��ʼ��֮��
    GLenum res = glewInit();
    if (res != GLEW_OK) {
        fprintf(stderr, "Error: '%s'\n", glewGetErrorString(res));
        return 1;
    }

    GLclampf Red = 0.0f, Green = 0.0f, Blue = 0.0f, Alpha = 0.0f;
    glClearColor(Red, Green, Blue, Alpha);
    //��������һ�У�״̬���������

    CreateVertexBuffer();
    glutDisplayFunc(RenderSceneCB);
    glutMainLoop();

    return 0;
}
