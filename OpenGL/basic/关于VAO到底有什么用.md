OpenGL中的VAO代表着"Vertex Array Object"，它是一种OpenGL的对象，用于管理顶点数据的状态，从而简化顶点数据的设置和切换过程。
VAO存储了一组顶点属性的配置，包括顶点坐标、法线、颜色、纹理坐标等等。通过绑定合适的VAO，你可以轻松地切换顶点数据的配置，从而在绘制不同的物体时无需重新设置顶点属性。

## 下面是一个简单的例子，说明如何使用VAO：
假设你有一个三角形的顶点数据，每个顶点有位置坐标和颜色属性。首先，你需要创建一个VAO，并绑定它：
```
GLuint vao;
glGenVertexArrays(1, &vao);
glBindVertexArray(vao);

//接下来，你需要创建并绑定一个顶点缓冲对象（VBO），将顶点数据传递给OpenGL：
GLfloat vertices[] = {
    // 顶点坐标      // 颜色
    -0.5f, -0.5f,  1.0f, 0.0f, 0.0f, // 左下角
     0.5f, -0.5f,  0.0f, 1.0f, 0.0f, // 右下角
     0.0f,  0.5f,  0.0f, 0.0f, 1.0f  // 顶部
};
GLuint vbo;
glGenBuffers(1, &vbo);
glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

//然后，配置顶点属性指针，告诉OpenGL如何解析顶点数据：
// 顶点坐标属性
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)0);
glEnableVertexAttribArray(0);
// 颜色属性
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));
glEnableVertexAttribArray(1);

//最后，在渲染循环中，你只需绑定对应的VAO，即可绘制三角形：
glBindVertexArray(vao);
glDrawArrays(GL_TRIANGLES, 0, 3);
glBindVertexArray(0);
通过使用VAO，你可以避免在每次渲染循环中都重新配置顶点属性指针，从而提高效率并简化代码逻辑。
```

## 如果上面的代码不用VAO的话
#### 需要在每次渲染循环中都重新设置顶点属性指针和绑定顶点缓冲对象。
```
// 初始化顶点缓冲对象（VBO）
GLuint vbo;
glGenBuffers(1, &vbo);
glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

// 渲染循环
while (!glfwWindowShouldClose(window)) {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    // 绑定顶点缓冲对象
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    // 设置顶点属性指针 - 顶点坐标
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)0);
    glEnableVertexAttribArray(0);
    // 设置顶点属性指针 - 颜色
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));
    glEnableVertexAttribArray(1);
    // 绘制三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    // 禁用顶点属性
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glfwSwapBuffers(window);
    glfwPollEvents();
}
// 清理资源
glDeleteBuffers(1, &vbo);

```
