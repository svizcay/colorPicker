#include <iostream>
#include <cstdlib>

// Include GLEW (always before glfw)
#include <GL/glew.h>

// Include GLFW
#include <glfw3.h>

// Include GLM
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <common/shader.hpp>

// void updateFPSCounter(GLFWwindow * window);
void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mode);
void mouseButtonCallback(GLFWwindow * window, int button, int action, int mods);

// click in window's space
int click_x = -1;
int click_y = -1;

int main(int argc, char* argv[])
{
	// basic quad
	const GLfloat basicQuad[8] {
		-1.0f,	 1.0f,		// top left
		 1.0f,	 1.0f,		// top right
		-1.0f,	-1.0f,		// bottom left
		 1.0f,	-1.0f,		// bottom right
	};

	GLint width = 640;
	GLint height = 640;

	// Initialise GLFW
	if(!glfwInit()) {
		std::cerr << "Failed to initialize GLFW" << std::endl;
		return -1;
	}

	// window hints
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// Open a window and create its OpenGL context
	GLFWwindow* window = glfwCreateWindow(width, height, "colorPicker", nullptr, nullptr);
	if (window == nullptr) {
		std::cerr << "Failed to open GLFW window.";
		std::cerr << " If you have an Intel GPU, they are not 3.3 compatible.";
		std::cerr << " Try the 2.1 version of the tutorials." << std::endl;
		glfwTerminate();
		return -1;
	}
	glfwMakeContextCurrent(window);

	// Initialize GLEW
	glewExperimental = true; // Needed for core profile
	if (glewInit() != GLEW_OK) {
		std::cerr << "Failed to initialize GLEW" << std::endl;
		return -1;
	}

	// enable z-buffer
	// glEnable(GL_DEPTH_TEST);
	// glDepthFunc(GL_LESS);

	// callbacks
	// glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);
	glfwSetMouseButtonCallback(window, mouseButtonCallback);
	glfwSetKeyCallback(window, keyCallback);

	// white background
	glm::vec4 whiteColor (1.0f, 1.0f, 1.0f, 0.0f);
	glClearColor(whiteColor.r, whiteColor.g, whiteColor.b, whiteColor.a);

	// Create and compile our GLSL program from the shaders
	GLuint colorPickerProgram = LoadShaders( "colorPickerVert.glsl", "colorPickerFrag.glsl" );

	// Use our shader (it's not required to be using a program to bind VAOs)
	glUseProgram(colorPickerProgram);

	// left, right, bottom, top, angle1, angle2
	// glm::mat4 Projection = glm::ortho(-10.0f, 10.0f, -10.0f, 10.0f,0.0001f,10.0f); // In world coordinates
	glm::mat4 projection = glm::ortho(-10.0f, 10.0f, -10.0f, 10.0f); // In world coordinates

	/*
	glm::mat4 Projection = glm::perspective(
		45.0f,         // The horizontal Field of View, in degrees : the amount of "zoom". Think "camera lens". Usually between 90° (extra wide) and 30° (quite zoomed in)
		4.0f / 4.0f, // Aspect Ratio. Depends on the size of your window. Notice that 4/3 == 800/600 == 1280/960, sounds familiar ?
		0.1f,        // Near clipping plane. Keep as big as possible, or you'll get precision issues.
		100.0f       // Far clipping plane. Keep as little as possible.
	);		
	*/

	// Camera matrix
	/*
	 * view es una matriz cuadrada almacenada por columnas (no por filas)
	 * al poner la camara mirando al origen en una posicion z=2 (positivo),
	 * lo que hace, es generar una matriz de transformación que moverá el objeto
	 * en el eje z dos unidades de "w" */
	glm::mat4 view = glm::lookAt(
		glm::vec3(0,0,2), // Camera is at (0, 0, 2), in World Space
		glm::vec3(0,0,0), // and looks at the origin
		glm::vec3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
	);

	glm::mat4 model = glm::scale(glm::mat4(1.0f), glm::vec3(10.0f));

	// VAOs
	/*
	 * vao stores:
	 * calls to glEnableVertexAttribArray / glDisableVertexAttributeArray
	 * vertex's attribute configurations via glVertexAttributePointer
	 * vbo associated with glVertexAttributePointer
	 * and glBindBuffer calls
	 */
	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(
		0,					// attribute. No particular reason for 0, but must match the layout in the shader.
		2,					// size
		GL_FLOAT,			// type
		GL_FALSE,			// normalized?
		2 * sizeof(GLfloat),// stride (if values are tightly packed, we could set it to zero)
		(void*)0			// array buffer offset
	);
	glBufferData(GL_ARRAY_BUFFER, sizeof(basicQuad), basicQuad, GL_STATIC_DRAW);

	// get uniforms locations
	// GLint modelLocation = glGetUniformLocation(colorPickerProgram, "model");
	// GLint viewLocation = glGetUniformLocation(colorPickerProgram, "view");
	// GLint projectionLocation = glGetUniformLocation(colorPickerProgram, "projection");

	GLint circleOriginLocation = glGetUniformLocation(colorPickerProgram, "circleOrigin");
	GLint radiusLocation = glGetUniformLocation(colorPickerProgram, "radius");
	GLint windowSizeLocation = glGetUniformLocation(colorPickerProgram, "windowSize");
	GLint clickPosLocation = glGetUniformLocation(colorPickerProgram, "clickPos");

	// glUniformMatrix4fv(modelLocation, 1, GL_FALSE, &model[0][0]);
	// glUniformMatrix4fv(viewLocation, 1, GL_FALSE, &view[0][0]);
	// glUniformMatrix4fv(projectionLocation, 1, GL_FALSE, &projection[0][0]);

	glUniform2f(circleOriginLocation, 0.0f, 0.0f);
	// glUniform2f(radiusLocation, 8.0f, 9.0f);
	glUniform2f(radiusLocation, 0.8f, 0.9f);
	glUniform2f(windowSizeLocation, width, height);

	while (!glfwWindowShouldClose(window)) {

		glfwPollEvents();

		// Clear the screen
		glClear(GL_COLOR_BUFFER_BIT);

		glUniform2f(clickPosLocation, click_x, click_y);

		// update viewport 
		glfwGetWindowSize(window, &width, &height);
		glViewport(0, 0, width, height);	// (x,y) offset from lower left; (width, height)

		// draw simple quad
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		// Swap buffers
		glfwSwapBuffers(window);
	}

	glBindVertexArray(vao);
	glDisableVertexAttribArray(0);

	// Cleanup VBO and shader
	glDeleteBuffers(1, &vbo);
	glDeleteProgram(colorPickerProgram);
	glDeleteVertexArrays(1, &vao);

	// Close OpenGL window and terminate GLFW
	glfwTerminate();

	return 0;
}

void mouseButtonCallback(GLFWwindow * window, int button, int action, int mods)
{
	int width;
	int height;
	glfwGetWindowSize(window, &width, &height);

	if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
		double xpos, ypos;
		glfwGetCursorPos(window, &xpos, &ypos);
		// std::cout << "click on: " << xpos << " " << ypos << std::endl;

		// // normalized device coordinates
		// double ndcx = 2.0 * xpos / width - 1.0;
		// double ndcy = 1.0 - (2.0 * ypos) / height;

		// // std::cout << "(" << ndcx << "," << ndcy << ")" << std::endl;

		// // world coordinates
		// double worldx = ndcx * 10;
		// double worldy = ndcy * 10;

		GLfloat buffer[4] = {0, 0, 0, 0};
		glReadPixels(xpos, ypos, 1, 1, GL_RGBA, GL_FLOAT, buffer);

		std::cout << buffer[0] << " " << buffer[1] << " " << buffer[2] << std::endl;

		click_x = xpos;
		click_y = ypos;
		// std::cout << "click: " << click_x << " " << click_y << std::endl;

		// std::cout << "(" << worldx << "," << worldy << ")" << std::endl;
		// usleep(3000000);
	}
}
// 
// void updateFPSCounter(GLFWwindow * window)
// {
// 	static double previousTime = glfwGetTime();
// 	static int frameCount = 0;
// 	double currentTime = glfwGetTime();
// 	double elapsedTime = currentTime - previousTime;
// 
// 	// take averages every 0.25 seconds
// 	if (elapsedTime > 0.25) {
// 		previousTime = currentTime;
// 		double fps = static_cast<double>(frameCount) / elapsedTime;
// 		std::stringstream ss;
// 		ss << "Mondrian @fps(" << fps << ")";
// 		glfwSetWindowTitle(window, ss.str().c_str());
// 		frameCount = 0;
// 	}
// 
// 	frameCount++;
// }


void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mode)
{
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, GL_TRUE);
	}
}
