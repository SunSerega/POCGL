


void glLoadMatrixd(	const GLdouble * m);
void glMultMatrixd(	const GLdouble * m);
void glRotated(	GLdouble angle, GLdouble x, GLdouble y, GLdouble z);
void glTranslated(	GLdouble x, GLdouble y, GLdouble z);
void glScaled(	GLdouble x, GLdouble y, GLdouble z);
void glFrustum(	GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble nearVal, GLdouble farVal);
void glOrtho(	GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble nearVal, GLdouble farVal);

void glTexGeni(	GLenum coord, GLenum pname, GLint param);
void glTexGenf(	GLenum coord, GLenum pname, GLfloat param);
void glTexGend(	GLenum coord, GLenum pname, GLdouble param);
void glTexGeniv(	GLenum coord, GLenum pname, const GLint * params);
void glTexGenfv(	GLenum coord, GLenum pname, const GLfloat * params);
void glTexGendv(	GLenum coord, GLenum pname, const GLdouble * params);

void glEdgeFlag(	GLboolean flag);
void glEdgeFlagv(	const GLboolean * flag);
void glEdgeFlagPointer(	GLsizei stride, const GLvoid * pointer);

void glPixelMapusv(	GLenum map, GLsizei mapsize, const GLushort * values);
void glPixelMapuiv(	GLenum map, GLsizei mapsize, const GLuint * values);
void glPixelMapfv(	GLenum map, GLsizei mapsize, const GLfloat * values);

void glMateriali(	GLenum face, GLenum pname, GLint param);
void glMaterialiv(	GLenum face, GLenum pname, const GLint * params);

void glLighti( GLenum light, GLenum pname, GLint  param );
void glLightiv( GLenum light, GLenum pname, const GLint  *params );

void glLightModeli(  GLenum pname, GLint  param );
void glLightModeliv(  GLenum pname, const GLint  *params );

void glPixelTransferi(	GLenum pname, GLint param);
void glPixelTransferf(	GLenum pname, GLfloat param);

void glColorMaterial(	GLenum face, GLenum mode);

void glIndexPointer(	GLenum type, GLsizei stride, const GLvoid * pointer);

void glArrayElement(	GLint i);

void glInterleavedArrays(	GLenum format,GLsizei stride,const GLvoid * pointer);

void glClipPlane(	GLenum plane, const GLdouble * equation);


