


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

void WINAPI glMap1f( GLenum  target, GLfloat u1, GLfloat u2, GLint   stride, GLint   order, const GLfloat *points );
void WINAPI glMap1d( GLenum   target, GLdouble u1, GLdouble u2, GLint    stride, GLint    order, const GLdouble *points );
void WINAPI glMap2f( GLenum  target, GLfloat u1, GLfloat u2, GLint   ustride, GLint   uorder, GLfloat v1, GLfloat v2, GLint   vstride, GLint   vorder, const GLfloat *points );
void WINAPI glMap2d( GLenum   target, GLdouble u1, GLdouble u2, GLint    ustride, GLint    uorder, GLdouble v1, GLdouble v2, GLint    vstride, GLint    vorder, const GLdouble *points  );

void glMapGrid1d(	GLint un, GLdouble u1, GLdouble u2);
void glMapGrid1f(	GLint un, GLfloat u1, GLfloat u2);
void glMapGrid2d(	GLint un, GLdouble u1, GLdouble u2, GLint vn, GLdouble v1, GLdouble v2);
void glMapGrid2f(	GLint un, GLfloat u1, GLfloat u2, GLint vn, GLfloat v1, GLfloat v2);

void glInitNames(	void);
void glPushName(	GLuint name);
void glPopName(	void);
void glLoadName(	GLuint name);

void glEdgeFlag(	GLboolean flag);
void glEdgeFlagv(	const GLboolean * flag);
void glEdgeFlagPointer(	GLsizei stride, const GLvoid * pointer);

void glPixelMapusv(	GLenum map, GLsizei mapsize, const GLushort * values);
void glPixelMapuiv(	GLenum map, GLsizei mapsize, const GLuint * values);
void glPixelMapfv(	GLenum map, GLsizei mapsize, const GLfloat * values);

void glCallList(	GLuint list);
GLboolean glIsList(	GLuint list);
void glDeleteLists(	GLuint list, GLsizei range);

void glGetTexGeniv(	GLenum coord, GLenum pname, GLint * params);
void glGetTexGenfv(	GLenum coord, GLenum pname, GLfloat * params);
void glGetTexGendv(	GLenum coord, GLenum pname, GLdouble * params);

void glGetPixelMapusv(	GLenum map, GLushort * data);
void glGetPixelMapuiv(	GLenum map, GLuint * data);
void glGetPixelMapfv(	GLenum map, GLfloat * data);

void glGetMapdv(	GLenum target, GLenum query, GLdouble * v);
void glGetMapfv(	GLenum target, GLenum query, GLfloat * v);
void glGetMapiv(	GLenum target, GLenum query, GLint * v);

void glPushAttrib(	GLbitfield mask);
void glPopAttrib(	void);

void glPushClientAttrib(	GLbitfield mask);
void glPopClientAttrib(	void);

void glMateriali(	GLenum face, GLenum pname, GLint param);
void glMaterialiv(	GLenum face, GLenum pname, const GLint * params);

void glLighti( GLenum light, GLenum pname, GLint  param );
void glLightiv( GLenum light, GLenum pname, const GLint  *params );

void glLightModeli(  GLenum pname, GLint  param );
void glLightModeliv(  GLenum pname, const GLint  *params );

void glPixelTransferi(	GLenum pname, GLint param);
void glPixelTransferf(	GLenum pname, GLfloat param);

void glFogi(	GLenum pname, GLint param);
void glFogiv(	GLenum pname, const GLint * params);

void glClearIndex(	GLfloat c);
void glClearAccum(	GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);

void glEvalMesh1(	GLenum mode, GLint i1, GLint i2);
void glEvalMesh2(	GLenum mode, GLint i1, GLint i2, GLint j1, GLint j2);

void glEvalPoint1(	GLint i);
void glEvalPoint2(	GLint i, GLint j);

void glGetMaterialiv(	GLenum face, GLenum pname, GLint * params);

void glGetLightiv(	GLenum light, GLenum pname, GLint * params);

void glGetClipPlane(	GLenum plane, GLdouble * equation);

GLint glRenderMode(	GLenum mode);

void glPassThrough(	GLfloat token);

void glSelectBuffer(	GLsizei size, GLuint * buffer);

void glFeedbackBuffer(	GLsizei size, GLenum type, GLfloat * buffer);

void glAccum(	GLenum op, GLfloat value);

void glIndexMask(	GLuint mask);

void glPrioritizeTextures(	GLsizei n, const GLuint * textures, const GLclampf * priorities);

GLboolean glAreTexturesResident(	GLsizei n, const GLuint * textures, GLboolean * residences);

void glPixelZoom(	GLfloat xfactor, GLfloat yfactor);

void glColorMaterial(	GLenum face, GLenum mode);

void glIndexPointer(	GLenum type, GLsizei stride, const GLvoid * pointer);

void glArrayElement(	GLint i);

void glInterleavedArrays(	GLenum format,GLsizei stride,const GLvoid * pointer);

void glClipPlane(	GLenum plane, const GLdouble * equation);


