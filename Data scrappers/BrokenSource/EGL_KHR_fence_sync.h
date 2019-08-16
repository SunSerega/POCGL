
EGLSyncKHR eglCreateSyncKHR( EGLDisplay dpy, EGLenum type, const EGLint *attrib_list);
EGLBoolean eglDestroySyncKHR( EGLDisplay dpy, EGLSyncKHR sync);
EGLint eglClientWaitSyncKHR( EGLDisplay dpy, EGLSyncKHR sync, EGLint flags, EGLTimeKHR timeout);
EGLBoolean eglGetSyncAttribKHR( EGLDisplay dpy, EGLSyncKHR sync, EGLint attribute, EGLint *value);
