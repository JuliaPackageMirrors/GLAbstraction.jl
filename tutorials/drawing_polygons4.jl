# Another "low-level" example, this one incorporating per-vertex color
# and element arrays
using ModernGL, GeometryTypes, GLAbstraction, GLWindow

# Create the window. This sets all the hints and makes the context current.
window = create_glcontext("Drawing polygons 4", resolution=(800,600))

# Create the Vertex Array Object (VAO) and make it current
# Note that while the tutorial describes this after the attributes (below),
# we need to make vao current before calling glVertexAttribPointer.
# You should also do this before creating any element arrays.
vao = Ref(GLuint(0))
glGenVertexArrays(1, vao)
glBindVertexArray(vao[])

# The vertices of our rectangle, with color
vertices = Point{5,Float32}[(-0.5,  0.5, 1, 0, 0),    # top-left
                            ( 0.5,  0.5, 0, 1, 0),    # top-right
                            ( 0.5, -0.5, 0, 0, 1),    # bottom-right
                            (-0.5, -0.5, 1, 1, 1)]    # bottom-left

elements = Vec{3,GLuint}[(0,1,2),          # the first triangle
                         (2,3,0)]          # the second triangle

# Create the Vertex Buffer Object (VBO)
vbo = Ref(GLuint(0))   # initial value is irrelevant, just allocate space
glGenBuffers(1, vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo[])
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

# Create the Element Buffer Object (EBO)
ebo = Ref(GLuint(0))
glGenBuffers(1, ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[])
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW)

# The shaders. Here we do everything manually, but life will get
# easier with GLAbstraction. See drawing_polygons5.jl for such an
# implementation.

# The vertex shader
vertex_source = """
#version 150

in vec2 position;
in vec3 color;

out vec3 Color;

void main()
{
    Color = color;
    gl_Position = vec4(position, 0.0, 1.0);
}
"""

# The fragment shader
fragment_source = """
# version 150

in vec3 Color;

out vec4 outColor;

void main()
{
    outColor = vec4(Color, 1.0);
}
"""

# Compile the vertex shader
vertex_shader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertex_shader, vertex_source)  # nicer thanks to GLAbstraction
glCompileShader(vertex_shader)
# Check that it compiled correctly
status = Ref(GLint(0))
glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, status)
if status[] != GL_TRUE
    buffer = Array(UInt8, 512)
    glGetShaderInfoLog(vertex_shader, 512, C_NULL, buffer)
    error(bytestring(buffer))
end

# Compile the fragment shader
fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragment_shader, fragment_source)
glCompileShader(fragment_shader)
# Check that it compiled correctly
status = Ref(GLint(0))
glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, status)
if status[] != GL_TRUE
    buffer = Array(UInt8, 512)
    glGetShaderInfoLog(fragment_shader, 512, C_NULL, buffer)
    error(bytestring(buffer))
end

# Connect the shaders by combining them into a program
shader_program = glCreateProgram()
glAttachShader(shader_program, vertex_shader)
glAttachShader(shader_program, fragment_shader)
glBindFragDataLocation(shader_program, 0, "outColor") # optional

glLinkProgram(shader_program)
glUseProgram(shader_program)

# Link vertex data to attributes
pos_attribute = glGetAttribLocation(shader_program, "position")
glEnableVertexAttribArray(pos_attribute)
glVertexAttribPointer(pos_attribute, 2,
                      GL_FLOAT, GL_FALSE, 5*sizeof(Float32), C_NULL)

col_attribute = glGetAttribLocation(shader_program, "color")
glEnableVertexAttribArray(col_attribute)
glVertexAttribPointer(col_attribute, 3,
                      GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Void}(2*sizeof(Float32)))

# Draw while waiting for a close event
while !GLFW.WindowShouldClose(window)
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL
